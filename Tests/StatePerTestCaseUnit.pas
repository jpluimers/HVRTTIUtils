unit StatePerTestCaseUnit;

interface

uses
  Classes,
  TestFramework;

type
  TStatePerTestCase = class(TTestCase)
  strict private
    FState: string;
    FStateStrings: TStrings;
  protected
    procedure SetUp; override;
  public
    destructor Destroy; override;
    procedure AddState(const Value: string); virtual;
    procedure ClearState; virtual;
    property State: string read FState;
  end;

implementation

destructor TStatePerTestCase.Destroy;
begin
  ClearState();
  inherited Destroy();
end;

procedure TStatePerTestCase.AddState(const Value: string);
begin
  if not Assigned(FStateStrings) then
  begin
    FStateStrings := TStringList.Create();
  end;
  FStateStrings.Add(Value);
  FState := FStateStrings.CommaText;
end;

procedure TStatePerTestCase.ClearState;
begin
  FStateStrings := nil;
  FState := '';
end;

procedure TStatePerTestCase.SetUp;
begin
  inherited SetUp();
  ClearState();
end;

end.
