unit InterfaceMethodsTestsUnit;

// from TestSimpleInterfaceRTTI.dpr

interface

uses
  TypInfo,
  TestFramework;

type
  TInterfaceMethodsTestCase = class(TTestCase)
  strict private
    procedure Check_DumpSimpleInterface_Output_Matches(const InterfaceTypeInfo: PTypeInfo; const Expected: string);
  published
    procedure IMyInterface_DumpSimpleInterface_Output_Matches;
    procedure IMyDispatchInterface_DumpSimpleInterface_Output_Matches;
    procedure IMyDispInterface_DumpSimpleInterface_Output_Matches;
  end;

implementation

uses
  InterfaceMethodsDumperUnit;

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

{$WARN SYMBOL_PLATFORM OFF} // no warnings about using IMyDispInterface

{ TInterfaceMethodsTestCase }

procedure TInterfaceMethodsTestCase.Check_DumpSimpleInterface_Output_Matches(const InterfaceTypeInfo: PTypeInfo; const Expected: string);
var
  Actual: string;
  Dumper: TInterfaceMethodsDumper;
begin
  Dumper := TInterfaceMethodsDumper.Create();
  try
    Dumper.DumpSimpleInterface(InterfaceTypeInfo);
    Actual := Dumper.Output;
  finally
    Dumper.Free();
  end;
  CheckEquals(Expected, Actual);
end;

procedure TInterfaceMethodsTestCase.IMyInterface_DumpSimpleInterface_Output_Matches;
begin
  Check_DumpSimpleInterface_Output_Matches(TypeInfo(IMyInterface), //
    '"unit InterfaceMethodsTestsUnit;",type,"  IMyInterface = dispinterface","    procedure UnknownName1;","    procedure UnknownName2;","    procedure UnknownName3;","  end;",');
end;

procedure TInterfaceMethodsTestCase.IMyDispatchInterface_DumpSimpleInterface_Output_Matches;
begin
  Check_DumpSimpleInterface_Output_Matches(TypeInfo(IMyDispatchInterface), //
    '"unit InterfaceMethodsTestsUnit;",type,"  IMyDispatchInterface = dispinterface","    [''{9BC5459B-6C31-4F5B-B733-DCA8FC8C1345}'']","    procedure UnknownName1;","  end;",');
end;

procedure TInterfaceMethodsTestCase.IMyDispInterface_DumpSimpleInterface_Output_Matches;
begin
  Check_DumpSimpleInterface_Output_Matches(TypeInfo(IMyDispInterface), //
    '"unit InterfaceMethodsTestsUnit;",type,"  IMyDispInterface = interface (IDispatch)","    [''{8574E276-4671-49AC-B775-B299E6EF01C5}'']","    procedure UnknownName1;","  end;",');
end;

initialization
  RegisterTest(TInterfaceMethodsTestCase.Suite);
end.
