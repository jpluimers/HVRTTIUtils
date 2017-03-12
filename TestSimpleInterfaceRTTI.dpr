program TestSimpleInterfaceRTTI;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  TypInfo;

(*
type
  TIntfFlag = (ifHasGuid, ifDispInterface, ifDispatch);
  TIntfFlagsBase = set of TIntfFlag;
  // …
  PTypeData = ^TTypeData;
  TTypeData = packed record
    case TTypeKind of
      // …
      tkInterface: (
        IntfParent : PPTypeInfo; { ancestor }
        IntfFlags : TIntfFlagsBase;
        Guid : TGUID;
        IntfUnit : ShortStringBase;
       {PropData: TPropData});
      // …
  end;
*)

type
  PExtraInterfaceData = ^TExtraInterfaceData;

  TExtraInterfaceData = packed record
    MethodCount: Word; { # methods }
  end;

function SkipPackedShortString(Value: PShortstring): pointer;
begin
  Result := Value;
  Inc(PChar(Result), SizeOf(Value^[0]) + Length(Value^));
end;

procedure DumpSimpleInterface(InterfaceTypeInfo: PTypeInfo);
var
  TypeData: PTypeData;
  ExtraData: PExtraInterfaceData;
  i: Integer;
begin
  Assert(Assigned(InterfaceTypeInfo));
  Assert(InterfaceTypeInfo.Kind = tkInterface);
  TypeData := GetTypeData(InterfaceTypeInfo);
  ExtraData := SkipPackedShortString(@TypeData.IntfUnit);
  Writeln('unit ', TypeData.IntfUnit, ';');
  Writeln('type');
  Write('  ', InterfaceTypeInfo.Name, ' = ');
  if not(ifDispInterface in TypeData.IntfFlags) then
  begin
    Write('interface');
    if Assigned(TypeData.IntfParent) then
      Write(' (', TypeData.IntfParent^.Name, ')');
    Writeln;
  end
  else
    Writeln('dispinterface');
  if ifHasGuid in TypeData.IntfFlags then
    Writeln('    [''', GuidToString(TypeData.Guid), ''']');
  for i := 1 to ExtraData.MethodCount do
    Writeln('    procedure UnknownName', i, ';');
  Writeln('  end;');
  Writeln;
end;

type
{$M-}
  IMyInterface = interface
    procedure Foo(A: Integer);
    procedure Bar(const B: string);
    procedure Nada(const C: array of Integer; D: TObject);
  end;

  IMyDispatchInterface = interface(IDispatch)
    ['{9BC5459B-6C31-4F5B-B733-DCA8FC8C1345}']
    procedure Foo; dispid 0;
  end;

  IMyDispInterface = dispinterface
    ['{8574E276-4671-49AC-B775-B299E6EF01C5}']
    procedure Bar;
  end;

begin
  DumpSimpleInterface(TypeInfo(IMyInterface));
  DumpSimpleInterface(TypeInfo(IMyDispatchInterface));
  DumpSimpleInterface(TypeInfo(IMyDispInterface));
  Readln;

end.
