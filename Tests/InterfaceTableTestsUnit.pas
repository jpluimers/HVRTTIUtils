unit InterfaceTableTestsUnit;

// From TestIntfTable

interface

uses
  Classes,
  TestFramework;

type
  TInstanceValue = (ivEmpty, ivPresent);
  TInterfaceTableTestCase = class(TTestCase)
  strict private
    procedure Check_DumpInterfaces_Output_Matches(const ClassToDump: TClass; const Expected: string);
  published
    procedure TComponent_DumpInterfaces_Output_Matches;
    procedure TComObject_DumpInterfaces_Output_Matches;
    procedure TComObjectFactory_DumpInterfaces_Output_Matches;
  end;

implementation

uses
  ComObj,
  InterfaceDumperUnit;

procedure TInterfaceTableTestCase.Check_DumpInterfaces_Output_Matches(const ClassToDump: TClass; const Expected: string);
var
  Actual: string;
  Dumper: TInterfaceDumper;
begin
  Dumper := TInterfaceDumper.Create();
  try
    Dumper.DumpInterfaces(ClassToDump);
    Actual := Dumper.Output;
  finally
    Dumper.Free();
  end;
  CheckEquals(Expected, Actual);
end;

procedure TInterfaceTableTestCase.TComponent_DumpInterfaces_Output_Matches;
begin
  Check_DumpInterfaces_Output_Matches(TComponent, '"Implemented interfaces in TComponent","0. GUID = {E28B1858-EC86-4559-8FCD-6B4F824151ED}","1. GUID = {00000000-0000-0000-C000-000000000046}"');
end;

procedure TInterfaceTableTestCase.TComObject_DumpInterfaces_Output_Matches;
begin
  Check_DumpInterfaces_Output_Matches(TComObject, '"Implemented interfaces in TComObject","0. GUID = {DF0B3D60-548F-101B-8E65-08002B2BD119}","1. GUID = {00000000-0000-0000-C000-000000000046}"');
end;

procedure TInterfaceTableTestCase.TComObjectFactory_DumpInterfaces_Output_Matches;
begin
  Check_DumpInterfaces_Output_Matches(TComObjectFactory, '"Implemented interfaces in TComObjectFactory","0. GUID = {B196B28F-BAB4-101A-B69C-00AA00341D07}","1. GUID = {00000001-0000-0000-C000-000000000046}","2. GUID = {00000000-0000-0000-C000-000000000046}"');
end;

initialization
  RegisterTest(TInterfaceTableTestCase.Suite);
end.
