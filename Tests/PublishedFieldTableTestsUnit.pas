unit PublishedFieldTableTestsUnit;

interface

uses
  Classes,
  TestFramework,
  TypInfo,
  HVVMT;

type
  TInstanceValue = (ivEmpty, ivPresent);
  TPublishedFieldTableTestCase = class(TTestCase)
  strict private
    procedure CheckField(const ExpectedFieldOffset, ExpectedFieldTypeIndex: Integer; const ExpectedFieldName: TSymbolName);
    procedure CheckInstanceField(const ExpectedFieldOffset, ExpectedFieldTypeIndex: Integer; const ExpectedFieldName: TSymbolName; InstanceValue: TInstanceValue);
  published
    procedure TMyClass_DumpPublishedFields_Equals_DumpPublishedFields2;
    procedure TMyClass_FindPublishedFieldByName_A_Matches;
    procedure TMyClass_FindPublishedFieldByName_LongName_Matches;
    procedure TMyClass_FindPublishedFieldByName_B_Matches;
    procedure TMyClass_FindPublishedFieldByName_C_Matches;
    procedure TMyClass_FindPublishedFieldByName_A2_Matches;
    procedure TMyClass_FindPublishedFieldByName_L2ongName_Matches;
    procedure TMyClass_FindPublishedFieldByName_B2_Matches;
    procedure TMyClass_FindPublishedFieldByName_C2_Matches;
    procedure TMyClass_Instance_FindPublishedFieldByName_A2_Matches;
    procedure TMyClass_Instance_FindPublishedFieldByName_A_Matches;
    procedure TMyClass_Instance_FindPublishedFieldByName_B2_Matches;
    procedure TMyClass_Instance_FindPublishedFieldByName_B_Matches;
    procedure TMyClass_Instance_FindPublishedFieldByName_C2_Matches;
    procedure TMyClass_Instance_FindPublishedFieldByName_C_Matches;
    procedure TMyClass_Instance_FindPublishedFieldByName_L2ongName_Matches;
    procedure TMyClass_Instance_FindPublishedFieldByName_LongName_Matches;
  end;

implementation

uses
  SysUtils,
  AbstractTestHelperUnit,
  PublishedFieldDumperUnit;

type
{$M+}
  TMyClass = class
  published
    A: TObject;
    LongName: TComponent;
    B: TObject;
    C: TList;
    A2: TObject;
    L2ongName: TComponent;
    B2: TObject;
    C2: TList;
  public
    constructor Create;
    destructor Destroy; override;
  end;

{ TMyClass }

constructor TMyClass.Create;
begin
  inherited Create;
  A := TObject.Create;
  LongName := TComponent.Create(nil);
  B := TStringList.Create;
  C := TList.Create;
end;

destructor TMyClass.Destroy;
begin
  A.Free();
  LongName.Free();
  B.Free();
  C.Free();
  inherited Destroy();
end;

{ TPublishedFieldTableTestCase }

procedure TPublishedFieldTableTestCase.CheckField(const ExpectedFieldOffset, ExpectedFieldTypeIndex: Integer; const ExpectedFieldName: TSymbolName);
var
  Field: PPublishedField;
begin
  Field := FindPublishedFieldByName(TMyClass, ExpectedFieldName);
  CheckNotEqualsPointer(nil, Field);
  CheckEquals(ExpectedFieldOffset, Field.Offset);
  CheckEquals(ExpectedFieldTypeIndex, Field.TypeIndex);
  CheckEquals(ExpectedFieldName, Field.Name);
end;

procedure TPublishedFieldTableTestCase.CheckInstanceField(const ExpectedFieldOffset, ExpectedFieldTypeIndex: Integer; const ExpectedFieldName: TSymbolName; InstanceValue: TInstanceValue);
var
  Field: PPublishedField;
  FieldValue: TObject;
  Instance: TMyClass;
begin
  Instance := TMyClass.Create();
  try
    CheckField(ExpectedFieldOffset, ExpectedFieldTypeIndex, ExpectedFieldName);
    Field := FindPublishedFieldByName(TMyClass, ExpectedFieldName);
    FieldValue := GetPublishedFieldValue(Instance, Field);
    case InstanceValue of
      ivEmpty: CheckEqualsPointer(nil, FieldValue);
      ivPresent: CheckNotEqualsPointer(nil, FieldValue);
    end;
  finally
    Instance.Free();
  end;
end;

procedure TPublishedFieldTableTestCase.TMyClass_DumpPublishedFields_Equals_DumpPublishedFields2;
var
  Actual: string;
  Dumper: TPublishedFieldDumper;
  Expected: string;
begin
  Dumper := TPublishedFieldDumper.Create();
  try
    Dumper.DumpPublishedFields(TMyClass);
    Expected := Dumper.Output;
  finally
    Dumper.Free();
  end;
  Dumper := TPublishedFieldDumper.Create();
  try
    Dumper.DumpPublishedFields2(TMyClass);
    Actual := Dumper.Output;
  finally
    Dumper.Free();
  end;
  CheckEquals(Expected, Actual);
end;

procedure TPublishedFieldTableTestCase.TMyClass_FindPublishedFieldByName_A_Matches;
begin
  CheckField(4, 0, 'A');
end;

procedure TPublishedFieldTableTestCase.TMyClass_FindPublishedFieldByName_LongName_Matches;
begin
  CheckField(8, 1, 'LongName');
end;

procedure TPublishedFieldTableTestCase.TMyClass_FindPublishedFieldByName_B_Matches;
begin
  CheckField(12, 0, 'B');
end;

procedure TPublishedFieldTableTestCase.TMyClass_FindPublishedFieldByName_C_Matches;
begin
  CheckField(16, 2, 'C');
end;

procedure TPublishedFieldTableTestCase.TMyClass_FindPublishedFieldByName_A2_Matches;
begin
  CheckField(20, 0, 'A2');
end;

procedure TPublishedFieldTableTestCase.TMyClass_FindPublishedFieldByName_L2ongName_Matches;
begin
  CheckField(24, 1, 'L2ongName');
end;

procedure TPublishedFieldTableTestCase.TMyClass_FindPublishedFieldByName_B2_Matches;
begin
  CheckField(28, 0, 'B2');
end;

procedure TPublishedFieldTableTestCase.TMyClass_FindPublishedFieldByName_C2_Matches;
begin
  CheckField(32, 2, 'C2');
end;

procedure TPublishedFieldTableTestCase.TMyClass_Instance_FindPublishedFieldByName_A2_Matches;
begin
  CheckInstanceField(20, 0, 'A2', ivEmpty);
end;

procedure TPublishedFieldTableTestCase.TMyClass_Instance_FindPublishedFieldByName_A_Matches;
begin
  CheckInstanceField(4, 0, 'A', ivPresent);
end;

procedure TPublishedFieldTableTestCase.TMyClass_Instance_FindPublishedFieldByName_B2_Matches;
begin
  CheckInstanceField(28, 0, 'B2', ivEmpty);
end;

procedure TPublishedFieldTableTestCase.TMyClass_Instance_FindPublishedFieldByName_B_Matches;
begin
  CheckInstanceField(12, 0, 'B', ivPresent);
end;

procedure TPublishedFieldTableTestCase.TMyClass_Instance_FindPublishedFieldByName_C2_Matches;
begin
  CheckInstanceField(32, 2, 'C2', ivEmpty);
end;

procedure TPublishedFieldTableTestCase.TMyClass_Instance_FindPublishedFieldByName_C_Matches;
begin
  CheckInstanceField(16, 2, 'C', ivPresent);
end;

procedure TPublishedFieldTableTestCase.TMyClass_Instance_FindPublishedFieldByName_L2ongName_Matches;
begin
  CheckInstanceField(24, 1, 'L2ongName', ivEmpty);
end;

procedure TPublishedFieldTableTestCase.TMyClass_Instance_FindPublishedFieldByName_LongName_Matches;
begin
  CheckInstanceField(8, 1, 'LongName', ivPresent);
end;

initialization
  RegisterTest(TPublishedFieldTableTestCase.Suite);
end.
