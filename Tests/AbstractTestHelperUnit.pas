unit AbstractTestHelperUnit;

interface

uses
  TestFramework;

type
  TAbstractTestHelper = class helper for TAbstractTest
  public
    procedure CheckEqualsPointer(const expected, actual: Pointer; const msg: string = ''; const digits: Integer = 8);
    procedure CheckNotEqualsPointer(const expected, actual: Pointer; const msg: string = ''; const digits: Integer = 8);
  end;

implementation

uses
  SysUtils;

procedure TAbstractTestHelper.CheckEqualsPointer(const expected, actual: Pointer; const msg: string = ''; const digits: Integer = 8);
begin
  CheckEqualsHex(Cardinal(expected), Cardinal(actual), msg, digits);
end;

procedure TAbstractTestHelper.CheckNotEqualsPointer(const expected, actual: Pointer; const msg: string = ''; const digits: Integer = 8);
begin
  CheckNotEqualsHex(Cardinal(expected), Cardinal(actual), msg, digits);
end;

end.
