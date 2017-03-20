unit MPlusTestsUnit;

interface

uses
  Classes,
  TestFramework;

type
{$M-} // disable RTTI generation for default sections
  TMMinus = class
    DefField: TObject;
    property DefProp: TObject read DefField write DefField;
    procedure DefMethod;
  published
    PubField: TObject;
    property PubProp: TObject read PubField write PubField;
    procedure PubMethod;
  end;

{$M+} // enable RTTI generation for default sections
  TMPlus = class
    DefField: TObject;
    property DefProp: TObject read DefField write DefField;
    procedure DefMethod;
  published
    PubField: TObject;
    property PubProp: TObject read PubField write PubField;
    procedure PubMethod;
  end;

type
  ISubject = interface
    ['{46D14665-D265-4BB9-ACC0-E3826A8D1593}']
    function Instance: TObject;
  end;

  TSubject = class(TInterfacedObject, ISubject)
  strict private
    FInstance: TObject;
  private
    function Instance: TObject;
  public
    constructor Create; overload;
    constructor Create(const AInstance: TObject); overload;
    destructor Destroy; override;
  end;

type
  /// These fields should generate nil RTTI for TMMinus and actual RTTI for TMPlus:
  /// - DefField
  /// - DefProp
  /// - DefMethod
  MPlusTests = class(TTestCase)
  strict private
    function BuildTMMinus: TSubject;
    function BuildTMPlus: TSubject;
  published
    procedure TMMinus_ClassName_HasValue;
    procedure TMMinus_Create_FieldAddress_DefField_HasValue;
    procedure TMPlus_Create_FieldAddress_DefField_HasValue;
    procedure TMMinus_PropInfo_DefProp_HasValue;
    procedure TMMinus_MethodAddress_DefMethod_HasValue;
    procedure TMMinus_Create_FieldAddress_PubField_HasValue;
    procedure TMPlus_Create_FieldAddress_PubField_HasValue;
    procedure TMPlus_MethodAddress_DefMethod_HasValue;
    procedure TMMinus_PropInfo_PubProp_HasValue;
    procedure TMMinus_MethodAddress_PubMethod_HasValue;
    procedure TMPlus_MethodAddress_PubMethod_HasValue;
    procedure TMPlus_PropInfo_DefProp_HasValue;
    procedure TMPlus_PropInfo_PubProp_HasValue;
    procedure TMPlus_ClassName_HasValue;
  end;

implementation

uses
  SysUtils,
  TypInfo,
  AbstractTestHelperUnit;

{ TSubject }

constructor TSubject.Create;
var
  Instance: TObject;
begin
{$WARN CONSTRUCTING_ABSTRACT OFF} // Ignore [dcc32 Warning] VmtTestsUnit.pas(219): W1020 Constructing instance of 'TObject' containing abstract method 'TObject.MethodB'
  Instance := TObject.Create();
{$WARN CONSTRUCTING_ABSTRACT ON}
  Create(Instance);
end;

constructor TSubject.Create(const AInstance: TObject);
begin
  inherited Create;
  FInstance := AInstance;
end;

destructor TSubject.Destroy;
begin
  FInstance.Free();
  FInstance := nil;
  inherited Destroy();
end;

function TSubject.Instance: TObject;
begin
  Result := FInstance;
end;

{ MPlusTests }

function MPlusTests.BuildTMMinus: TSubject;
begin
  Result := TSubject.Create(TMMinus.Create());
end;

function MPlusTests.BuildTMPlus: TSubject;
begin
  Result := TSubject.Create(TMPlus.Create());
end;

procedure MPlusTests.TMMinus_ClassName_HasValue;
begin
  CheckNotEquals('', TMMinus.ClassName);
end;

procedure MPlusTests.TMMinus_Create_FieldAddress_DefField_HasValue;
var
  SubjectUnderTest: TSubject;
begin
  SubjectUnderTest := BuildTMMinus;
  CheckEqualsPointer(nil, SubjectUnderTest.Instance.FieldAddress('DefField'));
end;

procedure MPlusTests.TMPlus_Create_FieldAddress_DefField_HasValue;
var
  SubjectUnderTest: TSubject;
begin
  SubjectUnderTest := BuildTMPlus;
  CheckNotEqualsPointer(nil, SubjectUnderTest.Instance.FieldAddress('DefField'));
end;

procedure MPlusTests.TMMinus_PropInfo_DefProp_HasValue;
begin
  CheckEqualsPointer(nil, TypInfo.GetPropInfo(TMMinus, 'DefProp'));
end;

procedure MPlusTests.TMMinus_MethodAddress_DefMethod_HasValue;
begin
  CheckEqualsPointer(nil, TMMinus.MethodAddress('DefMethod'));
end;

procedure MPlusTests.TMMinus_Create_FieldAddress_PubField_HasValue;
var
  SubjectUnderTest: TSubject;
begin
  SubjectUnderTest := BuildTMMinus;
  CheckNotEqualsPointer(nil, SubjectUnderTest.Instance.FieldAddress('PubField'));
end;

procedure MPlusTests.TMPlus_Create_FieldAddress_PubField_HasValue;
var
  SubjectUnderTest: TSubject;
begin
  SubjectUnderTest := BuildTMPlus;
  CheckNotEqualsPointer(nil, SubjectUnderTest.Instance.FieldAddress('PubField'));
end;

procedure MPlusTests.TMPlus_MethodAddress_DefMethod_HasValue;
begin
  CheckNotEqualsPointer(nil, TMPlus.MethodAddress('DefMethod'));
end;

procedure MPlusTests.TMMinus_PropInfo_PubProp_HasValue;
begin
  CheckNotEqualsPointer(nil, TypInfo.GetPropInfo(TMMinus, 'PubProp'));
end;

procedure MPlusTests.TMMinus_MethodAddress_PubMethod_HasValue;
begin
  CheckNotEqualsPointer(nil, TMMinus.MethodAddress('PubMethod'));
end;

procedure MPlusTests.TMPlus_MethodAddress_PubMethod_HasValue;
begin
  CheckNotEqualsPointer(nil, TMPlus.MethodAddress('PubMethod'));
end;

procedure MPlusTests.TMPlus_PropInfo_DefProp_HasValue;
begin
  CheckNotEqualsPointer(nil, TypInfo.GetPropInfo(TMPlus, 'DefProp'));
end;

procedure MPlusTests.TMPlus_PropInfo_PubProp_HasValue;
begin
  CheckNotEqualsPointer(nil, TypInfo.GetPropInfo(TMPlus, 'PubProp'));
end;

procedure MPlusTests.TMPlus_ClassName_HasValue;
begin
  CheckNotEquals('', TMPlus.ClassName);
end;

procedure DumpMClass(AClass: TClass);
begin
  Writeln(Format('Testing %s:', [AClass.ClassName]));
  Writeln(Format('DefField=%p', [AClass.Create.FieldAddress('DefField')]));
  Writeln(Format('DefProp=%p', [TypInfo.GetPropInfo(AClass, 'DefProp')]));
  Writeln(Format('DefMethod=%p', [AClass.MethodAddress('DefMethod')]));
  Writeln(Format('PubField=%p', [AClass.Create.FieldAddress('PubField')]));
  Writeln(Format('PubProp=%p', [TypInfo.GetPropInfo(AClass, 'PubProp')]));
  Writeln(Format('PubMethod=%p', [AClass.MethodAddress('PubMethod')]));
  Writeln;
end;

{ TMMinus }

procedure TMMinus.DefMethod;
begin
end;

procedure TMMinus.PubMethod;
begin
end;

{ TMPlus }

procedure TMPlus.DefMethod;
begin
end;

procedure TMPlus.PubMethod;
begin
end;

initialization
  RegisterTest(MPlusTests.Suite);
end.
