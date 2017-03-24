unit InterfaceVariantsTestsUnit;

// from TestInterfaceVariants

interface

uses
  TestFramework;

type
  TInterfaceVariantsTestCase = class(TTestCase)
  strict private
    procedure Check_Variant_Matches_VType(const V: Variant; const Expected: Word);
  published
    procedure Unassigned_Variant_Matches_VType;
    procedure IMyDispInterface_DumpInterface_Output_Matches;
    procedure NilInterface_Variant_Matches_VType;
    procedure NilDispatch_Variant_Matches_VType;
  end;

implementation

uses
  SysUtils,
  Variants;

const
  NilInterface: IUnknown = nil;
  NilDispatch: IDispatch = nil;

{ TInterfaceVariantsTestCase }

procedure TInterfaceVariantsTestCase.Check_Variant_Matches_VType(const V: Variant; const Expected: Word);
var
  Actual: Integer; // is Word, but for Delphi <= 2007, otherwise [DCC Error] E2251 Ambiguous overloaded call to 'CheckEquals'
  Zero: Integer;
begin
  Actual := TVarData(V).VType;
  CheckEquals(Expected, Actual, Format('VType mismatch; expected=%4.4x; actual=%4.4x', [Expected, Actual]));
  Zero := 0; // for Delphi <= 2007, otherwise [DCC Error] E2251 Ambiguous overloaded call to 'CheckEquals'
  CheckEquals(Zero, TVarData(V).Reserved1);
  CheckEquals(Zero, TVarData(V).Reserved2);
  CheckEquals(Zero, TVarData(V).Reserved3);
end;

procedure TInterfaceVariantsTestCase.Unassigned_Variant_Matches_VType;
var
  V: Variant;
begin
  V := Unassigned;
  Check_Variant_Matches_VType(V, varEmpty);
end;

procedure TInterfaceVariantsTestCase.IMyDispInterface_DumpInterface_Output_Matches;
var
  V: Variant;
begin
  V := OleVariant(IUnknown(Unassigned));
  Check_Variant_Matches_VType(V, varUnknown);
end;

procedure TInterfaceVariantsTestCase.NilInterface_Variant_Matches_VType;
var
  V: Variant;
begin
  // V := IUnknown(nil);  // [Error] Invalid typecast
  V := NilInterface;
  Check_Variant_Matches_VType(V, varUnknown);
end;

procedure TInterfaceVariantsTestCase.NilDispatch_Variant_Matches_VType;
var
  V: Variant;
begin
  V := NilDispatch;
  Check_Variant_Matches_VType(V, varDispatch);
end;

initialization
  RegisterTest(TInterfaceVariantsTestCase.Suite);
end.
