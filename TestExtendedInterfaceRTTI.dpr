program TestExtendedInterfaceRTTI;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  TypInfo,
  HVVMT in 'HVVMT.pas',
  HVInterfaceMethods in 'HVInterfaceMethods.pas',
  HVMethodSignature in 'HVMethodSignature.pas';

procedure DumpInterface(InterfaceTypeInfo: PTypeInfo);
var
  InterfaceInfo: TInterfaceInfo;
  i: Integer;
begin
  GetInterfaceInfo(InterfaceTypeInfo, InterfaceInfo);

  Writeln('unit ', InterfaceInfo.UnitName, ';');
  Writeln('type');
  Write('  ', InterfaceInfo.Name, ' = ');
  if not(ifDispInterface in InterfaceInfo.Flags) then
  begin
    Write('interface');
    if Assigned(InterfaceInfo.ParentInterface) then
      Write(' (', InterfaceInfo.ParentInterface.Name, ')');
    Writeln;
  end
  else
    Writeln('dispinterface');
  if ifHasGuid in InterfaceInfo.Flags then
    Writeln('    [''', GuidToString(InterfaceInfo.Guid), ''']');
  if InterfaceInfo.HasMethodRTTI then
    for i := Low(InterfaceInfo.Methods) to High(InterfaceInfo.Methods) do
      Writeln('    ', MethodSignatureToString(InterfaceInfo.Methods[i]))
  else
    for i := 1 to InterfaceInfo.MethodCount do
      Writeln('    procedure UnknownName', i, ';');
  Writeln('  end;');
  Writeln;
end;

type
{$M-}
  IMyInterface = interface
    procedure Foo;
    procedure Bar;
    procedure Nada;
  end;

  IMyDispatchInterface = interface(IDispatch)
    ['{9BC5459B-6C31-4F5B-B733-DCA8FC8C1345}']
    procedure Foo;
  end;

  IMyDispInterface = dispinterface
    ['{8574E276-4671-49AC-B775-B299E6EF01C5}']
    procedure Foo;
  end;

  IMyGUIDInterface = interface
    ['{8B07020B-F326-45BC-A686-9322890B1051}']
    procedure Foo;
    procedure SetBar(Value: Integer);
    function GetBar: Integer;
    property Bar: Integer read GetBar write SetBar;
  end;

type
  TNumber = Integer;
  TNewNumber = type Integer;
  TIntegerArray = array of Integer;

  TNormalClass = class
  end;

  TSetOfByte = set of byte;
  TEnum = (enOne, enTwo, enThree);

type
  {.$M+}{.$TYPEINFO ON}
{$METHODINFO ON} // Wrt interface RTTI, this has the same effect as $M and $TYPEINFO
  IMyMPInterface = interface
    ['{AA503475-0187-4108-8E27-41475F4EF818}']
    procedure Foo(A: Integer; var B: string); register;
    procedure Bar(LongParaName: TObject; const B: string; var C: Integer; out D: byte); stdcall;
    function Number: TNumber; cdecl;
    function NewNumber: TNewNumber; cdecl;
    function AsString: string; pascal;
    function AsString2: string; safecall;
    // Unsupported parameter types
    procedure A2(const A: TIntegerArray);
    procedure OkParam1(Value: TSetOfByte);
    procedure OkParam2(Value: TSetOfByte);
    procedure OkParam3(Value: Variant);
    procedure OkParam4(Value: TNormalClass);
{$DEFINE ERRORS}
{$IFDEF ERRORS}
    // Parameter types that is not supported -
    // - All pointer types
    // - open array parameters (array of Type), named dynmaic array is ok
    // - class references (such as TClass)
    // - record types (such as TRect)
    // - untyped var and out parameters
    // gives confusing D7 compiler warning "[Warning] Redeclaration of 'Test3' hides a member in the base class"
    // D7: [Error] : Type '%s' has no type info
    // procedure Test3(R: TClass);
    // procedure Test3(R: PInteger);
    // procedure Test3(R: Pointer);
    // procedure Test3(R: PChar);
    // procedure Test3(var R); // untyped var/out parameter
    // procedure Test3(out R); // untyped var/out parameter
    // procedure Test3(const R: array of Integer);
    // procedure Test3(const R: TRect);

    // Return types that are not supported
    function OkReturn1: shortstring;
    function OkReturn2: TObject;
    function OkReturn3: IInterface;
    function OkReturn4: TSetOfByte;
    // Return types that is not supported -
    // gives confusing D7 compiler warning "[Warning] Redeclaration of 'Test10' hides a member in the base class"
    function OkReturn5: TNormalClass;
    function OkReturn6: TEnum;
    function OkReturn7: TClass;
    function OkReturn8: Pointer;
    function OkReturn9: PChar;
    function OkReturn10: TIntegerArray;

    // Safecall calling convention is not supported
    // D7: [Fatal Error] Internal error: D6238
    procedure Test3(out R: Integer); safecall;
{$ENDIF ERRORS}
  end;
{$M-}

{$WARN SYMBOL_PLATFORM OFF}

procedure Test;
begin
  DumpInterface(TypeInfo(IMyInterface));
  DumpInterface(TypeInfo(IMyGUIDInterface));
  DumpInterface(TypeInfo(IMyDispInterface));
  DumpInterface(TypeInfo(IMyDispatchInterface));
  DumpInterface(TypeInfo(IMyMPInterface));
end;

begin
  try
    Test;
  except
    on E: Exception do
      Writeln(E.Message);
  end;
  Readln;

  (* Expected output:

unit TestExtendedInterfaceRTTI;
type
  IMyInterface = interface (IInterface)
    procedure UnknownName1;
    procedure UnknownName2;
    procedure UnknownName3;
  end;

unit TestExtendedInterfaceRTTI;
type
  IMyGUIDInterface = interface (IInterface)
    ['{8B07020B-F326-45BC-A686-9322890B1051}']
    procedure UnknownName1;
    procedure UnknownName2;
    procedure UnknownName3;
  end;

unit TestExtendedInterfaceRTTI;
type
  IMyDispInterface = dispinterface
    ['{8574E276-4671-49AC-B775-B299E6EF01C5}']
    procedure UnknownName1;
  end;

unit TestExtendedInterfaceRTTI;
type
  IMyDispatchInterface = interface (IDispatch)
    ['{9BC5459B-6C31-4F5B-B733-DCA8FC8C1345}']
    procedure UnknownName1;
  end;

unit TestExtendedInterfaceRTTI;
type
  IMyMPInterface = interface (IInterface)
    ['{AA503475-0187-4108-8E27-41475F4EF818}']
    procedure Foo(A: Integer; var B: string);
    procedure Bar(LongParaName: TObject; const B: string; var C: Integer; out D: Byte); stdcall;
    function Number(): Integer; cdecl;
    function NewNumber(): TNewNumber; cdecl;
    function AsString(): string; pascal;
    function AsString2(): string; safecall;
    procedure A2(const A: TIntegerArray);
    procedure OkParam1(Value: TSetOfByte);
    procedure OkParam2(Value: TSetOfByte);
    procedure OkParam3(Value: Variant);
    procedure OkParam4(Value: TNormalClass);
    function OkReturn1(): ShortString;
    function OkReturn2(): TObject;
    function OkReturn3(): IInterface;
    function OkReturn4(): TSetOfByte;
    function OkReturn5(): TNormalClass;
    function OkReturn6(): TEnum;
    function OkReturn7(): TClass;
    function OkReturn8(): Pointer;
    function OkReturn9(): PAnsiChar;
    function OkReturn10(): TIntegerArray;
    procedure Test3(out R: Integer); safecall;
  end;

 *)
end.
