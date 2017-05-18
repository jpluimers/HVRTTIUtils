unit ExtendedInterfaceMethodsTestsUnit;

// from TestExtendedInterfaceRTTI

interface

uses
  TypInfo,
  TestFramework;

type
  TExtendedInterfaceMethodsTestCase = class(TTestCase)
  strict private
    procedure Check_DumpInterface_Output_Matches(const InterfaceTypeInfo: PTypeInfo; const Expected: string);
  published
    procedure IMyDispatchInterface_DumpInterface_Output_Matches;
    procedure IMyDispInterface_DumpInterface_Output_Matches;
    procedure IMyGUIDInterface_DumpInterface_Output_Matches;
    procedure IMyInterface_DumpInterface_Output_Matches;
    procedure IMyMPInterface_DumpInterface_Output_Matches;
  end;

implementation

uses
  InterfaceMethodsDumperUnit;

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
{$IF CompilerVersion >= 21} // Delphi 2010 or newer require TYPEINFO IN to generate RTTI for interfaces2010 and up
{$TYPEINFO ON}
{$IFEND CompilerVersion >= 21} // Delphi 2010 or newer require TYPEINFO IN to generate RTTI for interfaces2010 and up
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
    // TODO -oHallvard : check other Delphi versions
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

    // TODO -oHallvard : check other Delphi versions
    // Return types that are not supported
    function OkReturn1: shortstring;
    function OkReturn2: TObject;
    function OkReturn3: IInterface;
    function OkReturn4: TSetOfByte;
    // TODO -oHallvard : check other Delphi versions
    // Return types that is not supported -
    // gives confusing D7 compiler warning "[Warning] Redeclaration of 'Test10' hides a member in the base class"
    function OkReturn5: TNormalClass;
    function OkReturn6: TEnum;
    function OkReturn7: TClass;
    function OkReturn8: Pointer;
    function OkReturn9: PAnsiChar;
    function OkReturn10: TIntegerArray;
    function OkReturn11: PWideChar;

    // TODO -oHallvard : check other Delphi versions
    // Safecall calling convention is not supported
    // D7: [Fatal Error] Internal error: D6238
    procedure Test3(out R: Integer); safecall;
{$ENDIF ERRORS}
  end;
{$M-}

{$WARN SYMBOL_PLATFORM OFF} // no warnings about using IMyDispInterface

{ TExtendedInterfaceMethodsTestCase }

procedure TExtendedInterfaceMethodsTestCase.Check_DumpInterface_Output_Matches(const InterfaceTypeInfo: PTypeInfo; const Expected: string);
var
  Actual: string;
  Dumper: TInterfaceMethodsDumper;
begin
  Dumper := TInterfaceMethodsDumper.Create();
  try
    Dumper.DumpInterface(InterfaceTypeInfo);
    Actual := Dumper.Output;
  finally
    Dumper.Free();
  end;
  CheckEquals(Expected, Actual);
end;

procedure TExtendedInterfaceMethodsTestCase.IMyDispatchInterface_DumpInterface_Output_Matches;
begin
  Check_DumpInterface_Output_Matches(TypeInfo(IMyDispatchInterface), //
    '"unit ExtendedInterfaceMethodsTestsUnit;",type,"  IMyDispatchInterface = dispinterface","    [''{9BC5459B-6C31-4F5B-B733-DCA8FC8C1345}'']","    procedure UnknownName1;","  end;",');
end;

procedure TExtendedInterfaceMethodsTestCase.IMyDispInterface_DumpInterface_Output_Matches;
begin
  Check_DumpInterface_Output_Matches(TypeInfo(IMyDispInterface), //
    '"unit ExtendedInterfaceMethodsTestsUnit;",type,"  IMyDispInterface = interface (IDispatch)","    [''{8574E276-4671-49AC-B775-B299E6EF01C5}'']","    procedure UnknownName1;","  end;",');
end;

procedure TExtendedInterfaceMethodsTestCase.IMyGUIDInterface_DumpInterface_Output_Matches;
begin
  Check_DumpInterface_Output_Matches(TypeInfo(IMyGUIDInterface), //
    '"unit ExtendedInterfaceMethodsTestsUnit;",type,"  IMyGUIDInterface = dispinterface","    [''{8B07020B-F326-45BC-A686-9322890B1051}'']","    procedure UnknownName1;","    procedure UnknownName2;","    procedure UnknownName3;","  end;",');
end;

procedure TExtendedInterfaceMethodsTestCase.IMyInterface_DumpInterface_Output_Matches;
begin
  Check_DumpInterface_Output_Matches(TypeInfo(IMyInterface), //
    '"unit ExtendedInterfaceMethodsTestsUnit;",type,"  IMyInterface = dispinterface","    procedure UnknownName1;","    procedure UnknownName2;","    procedure UnknownName3;","  end;",');
end;

procedure TExtendedInterfaceMethodsTestCase.IMyMPInterface_DumpInterface_Output_Matches;
begin
  Check_DumpInterface_Output_Matches(TypeInfo(IMyMPInterface), //
       '"unit ExtendedInterfaceMethodsTestsUnit;",type,"  IMyMPInterface = dispinterface","    [''{AA503475-0187-4108-8E27-41475F4EF818}'']",' + //
       '"    procedure Foo(A: Integer; var B: string);",' + //
       '"    procedure Bar(LongParaName: TObject; const B: string; var C: Integer; out D: Byte); stdcall;",' + //
       '"    function Number(): Integer; cdecl;",' + //
       '"    function NewNumber(): TNewNumber; cdecl;",' + //
       '"    function AsString(): string; pascal;",' + //
       '"    function AsString2(): string; safecall;",' + //
       '"    procedure A2(const A: TIntegerArray);",' + //
       '"    procedure OkParam1(Value: TSetOfByte);",' + //
       '"    procedure OkParam2(Value: TSetOfByte);",' + //
       '"    procedure OkParam3(Value: Variant);",' + //
       '"    procedure OkParam4(Value: TNormalClass);",' + //
       '"    function OkReturn1(): ShortString;",' + //
       '"    function OkReturn2(): TObject;",' + //
       '"    function OkReturn3(): IInterface;",' + //
       '"    function OkReturn4(): TSetOfByte;",' + //
       '"    function OkReturn5(): TNormalClass;",' + //
       '"    function OkReturn6(): TEnum;",' + //
       '"    function OkReturn7(): TClass;",' + //
       '"    function OkReturn8(): Pointer;",' + //
       '"    function OkReturn9(): PAnsiChar;",' + //
       '"    function OkReturn10(): TIntegerArray;",' + //
       '"    function OkReturn11(): PWideChar;",' + //
       '"    procedure Test3(out R: Integer); safecall;",' + //
       '"  end;",'
  );
end;

initialization
  RegisterTest(TExtendedInterfaceMethodsTestCase.Suite);
end.
