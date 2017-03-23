unit PublishedMethodParametersTestsUnit;

interface

uses
  Classes,
  TestFramework;

type
  TPublishedMethodTableTestCase = class(TTestCase)
  strict private
    procedure Check_TMyClass_GetPublishedMethodsWithParameters_Specific_Index_Value(const ExpectedIndex: Integer; const ExpectedValue: string);
  published
    procedure TMyClass_GetPublishedMethodsWithParameters_Line0_Matches;
    procedure TMyClass_GetPublishedMethodsWithParameters_Line1_Matches;
    procedure TMyClass_GetPublishedMethodsWithParameters_Line2_Matches;
    procedure TMyClass_GetPublishedMethodsWithParameters_Line3_Matches;
    procedure TMyClass_GetPublishedMethodsWithParameters_Line4_Matches;
    procedure TMyClass_GetPublishedMethodsWithParameters_Line5_Matches;
    procedure TMyClass_GetPublishedMethodsWithParameters_Line6_Matches;
  end;

implementation

uses
  TypInfo,
  HVVMT,
  HVPublishedMethodParams;

type
{$M+}
  TMyClass = class;
  TOnFour = function(A: array of byte; const B: array of byte; var C: array of byte; out D: array of byte): TComponent of object;
  TOnFive = procedure(Component1: TComponent; var Component2: TComponent; out Component3: TComponent; const Component4: TComponent) of object;
  TOnSix = function(const A: string; var Two: Integer; out Three: TMyClass; Four: PInteger; Five: array of Byte; Six: Integer): string of object;

  TMyClass = class
  private
    FOnFour: TOnFour;
    FOnFive: TOnFive;
    FOnSix: TOnSix;
  published
    function FourthPublished(A: array of byte; const B: array of byte; //
      var C: array of byte; out D: array of byte): TComponent;
    procedure FifthPublished(Component1: TComponent; var Component2: TComponent; //
      out Component3: TComponent; const Component4: TComponent);
    function SixthPublished(const A: string; var Two: Integer; //
      out Three: TMyClass; Four: PInteger; Five: array of Byte; Six: Integer): string;
    property OnFour: TOnFour read FOnFour write FOnFour;
    property OnFive: TOnFive read FOnFive write FOnFive;
    property OnSix: TOnSix read FOnSix write FOnSix;
  end;

function TMyClass.FourthPublished;
begin
  Result := nil;
end;

procedure TMyClass.FifthPublished;
begin
end;

function TMyClass.SixthPublished;
begin
end;

{ TPublishedMethodTableTestCase }

procedure TPublishedMethodTableTestCase.Check_TMyClass_GetPublishedMethodsWithParameters_Specific_Index_Value(const ExpectedIndex: Integer; const ExpectedValue: string);
var
  MyClass: TMyClass;
  Strings: TStringList;
begin
  MyClass := TMyClass.Create;
  MyClass.OnFour := MyClass.FourthPublished;
  MyClass.OnFive := MyClass.FifthPublished;
  MyClass.OnSix := MyClass.SixthPublished;

  Strings := TStringList.Create;
  try
    GetPublishedMethodsWithParameters(MyClass, Strings);
    Check(Strings.Count > ExpectedIndex);
    CheckEquals(ExpectedValue, Strings[ExpectedIndex]);
  finally
    Strings.Free;
  end;
end;

procedure TPublishedMethodTableTestCase.TMyClass_GetPublishedMethodsWithParameters_Line0_Matches;
begin
  Check_TMyClass_GetPublishedMethodsWithParameters_Specific_Index_Value(0, 'Scanning TMyClass');
end;

procedure TPublishedMethodTableTestCase.TMyClass_GetPublishedMethodsWithParameters_Line1_Matches;
begin

  Check_TMyClass_GetPublishedMethodsWithParameters_Specific_Index_Value(1, 'Published methods in TMyClass');
end;

procedure TPublishedMethodTableTestCase.TMyClass_GetPublishedMethodsWithParameters_Line2_Matches;
begin
  Check_TMyClass_GetPublishedMethodsWithParameters_Specific_Index_Value(2, 'function FourthPublished(A: array of Byte; const B: array of Byte; var C: array of Byte; out D: array of Byte): TComponent;');
end;

procedure TPublishedMethodTableTestCase.TMyClass_GetPublishedMethodsWithParameters_Line3_Matches;
begin
  Check_TMyClass_GetPublishedMethodsWithParameters_Specific_Index_Value(3, 'procedure FifthPublished(Component1: TComponent; var Component2: TComponent; out Component3: TComponent; const Component4: TComponent);');
end;

procedure TPublishedMethodTableTestCase.TMyClass_GetPublishedMethodsWithParameters_Line4_Matches;
begin
  Check_TMyClass_GetPublishedMethodsWithParameters_Specific_Index_Value(4, 'function SixthPublished(const A: string; var Two: Integer; out Three: TMyClass; Four: PInteger; Five: array of Byte; Six: Integer): string;');
end;

procedure TPublishedMethodTableTestCase.TMyClass_GetPublishedMethodsWithParameters_Line5_Matches;
begin
  Check_TMyClass_GetPublishedMethodsWithParameters_Specific_Index_Value(5, 'Scanning TObject');
end;

procedure TPublishedMethodTableTestCase.TMyClass_GetPublishedMethodsWithParameters_Line6_Matches;
begin
  Check_TMyClass_GetPublishedMethodsWithParameters_Specific_Index_Value(6, 'No published methods in TObject');
end;

initialization
  RegisterTest(TPublishedMethodTableTestCase.Suite);
end.
