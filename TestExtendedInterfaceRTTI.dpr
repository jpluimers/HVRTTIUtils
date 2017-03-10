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
  i: integer;
begin
  GetInterfaceInfo(InterfaceTypeInfo, InterfaceInfo);

  writeln('unit ', InterfaceInfo.UnitName, ';');
  writeln('type');
  write('  ', InterfaceInfo.Name, ' = '); 
  if not (ifDispInterface in InterfaceInfo.Flags) then
  begin
    write('interface');
    if Assigned(InterfaceInfo.ParentInterface) then
      write(' (', InterfaceInfo.ParentInterface.Name, ')');
    writeln;
  end
  else  
    writeln('dispinterface');
  if ifHasGuid in InterfaceInfo.Flags then
    writeln('    [''', GuidToString(InterfaceInfo.Guid), ''']');
  if InterfaceInfo.HasMethodRTTI then  
    for i := Low(InterfaceInfo.Methods) to High(InterfaceInfo.Methods) do
      writeln('    ', MethodSignatureToString(InterfaceInfo.Methods[i]))
  else
    for i := 1 to InterfaceInfo.MethodCount do  
      writeln('    procedure UnknownName',i,';');
  writeln('  end;');
  writeln;
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
    procedure SetBar(Value: integer);
    function GetBar: integer;
    property Bar: integer read GetBar write SetBar;
  end;  
type
  TNumber = integer;
  TNewNumber = type integer;
  TIntegerArray = array of integer;
  TNormalClass = class
  end;
  TSetOfByte = set of byte;
  TEnum = (enOne, enTwo, enThree);
type
  {.$M+} {.$TYPEINFO ON}
  {$METHODINFO ON} // Wrt interface RTTI, this has the same effect as $M and $TYPEINFO
  IMyMPInterface = interface
    ['{AA503475-0187-4108-8E27-41475F4EF818}']
    procedure Foo(A: integer; var B: string); register;
    procedure Bar(LongParaName: TObject; const B: string; var C: integer; out D: byte); stdcall;
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
//    procedure Test3(R: TClass); 
//    procedure Test3(R: PInteger); 
//    procedure Test3(R: Pointer); 
//    procedure Test3(R: PChar); 
//    procedure Test3(var R); // untyped var/out parameter
//    procedure Test3(out R); // untyped var/out parameter
//    procedure Test3(const R: array of integer);
//    procedure Test3(const R: TRect);

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
    procedure Test3(out R: integer); safecall;
{$ENDIF}
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
    on E:Exception do
      writeln(E.Message);
  end;
  readln;
end.

