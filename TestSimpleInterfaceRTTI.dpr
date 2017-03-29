program TestSimpleInterfaceRTTI;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  TypInfo,
  HVInterfaceMethods in 'HVInterfaceMethods.pas';

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

procedure DumpSimpleInterface(const InterfaceTypeInfo: PTypeInfo);
var
  InterfaceInfo: TInterfaceInfo;
  i: Integer;
  InterfaceFlags: TIntfFlags;
  ParentInterface: PTypeInfo;
begin
  GetInterfaceInfo(InterfaceTypeInfo, InterfaceInfo);
  Assert(Assigned(InterfaceTypeInfo));
  Assert(InterfaceTypeInfo.Kind = tkInterface);
  Writeln('unit ', InterfaceInfo.UnitName, ';');
  Writeln('type');
  Write('  ', InterfaceTypeInfo.Name, ' = ');
  InterfaceFlags := InterfaceInfo.Flags;
  if not(ifDispInterface in InterfaceFlags) then
  begin
    Write('interface');
    ParentInterface := InterfaceInfo.ParentInterface;
    if Assigned(ParentInterface) then
      Write(' (', ParentInterface^.Name, ')');
    Writeln;
  end
  else
    Writeln('dispinterface');
  if ifHasGuid in InterfaceFlags then
    Writeln('    [''', GuidToString(InterfaceInfo.Guid), ''']');
  for i := 1 to InterfaceInfo.MethodCount do
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

(* Expected output:

unit TestSimpleInterfaceRTTI;
type
  IMyInterface = interface (IInterface)
    procedure UnknownName1;
    procedure UnknownName2;
    procedure UnknownName3;
  end;

unit TestSimpleInterfaceRTTI;
type
  IMyDispatchInterface = interface (IDispatch)
    ['{9BC5459B-6C31-4F5B-B733-DCA8FC8C1345}']
    procedure UnknownName1;
  end;

unit TestSimpleInterfaceRTTI;
type
  IMyDispInterface = dispinterface
    ['{8574E276-4671-49AC-B775-B299E6EF01C5}']
    procedure UnknownName1;
  end;
*)
end.
