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
  published // Note: It is as expected to get a warning here in D2005 and later: [dcc32 Warning] MPlusTestsUnit.pas(15): W1055 PUBLISHED caused RTTI ($M+) to be added to type 'TMMinus'
            // see http://hallvards.blogspot.no/2007/03/review-delphi-2007-for-win32-beta-part_06.html
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
  TMPlusTests = class(TTestCase)
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
  TypInfo,
  AbstractTestHelperUnit;

{ TSubject }

constructor TSubject.Create;
var
  Instance: TObject;
begin
  Instance := TObject.Create();
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

{ TMPlusTests }

function TMPlusTests.BuildTMMinus: TSubject;
begin
  Result := TSubject.Create(TMMinus.Create());
end;

function TMPlusTests.BuildTMPlus: TSubject;
begin
  Result := TSubject.Create(TMPlus.Create());
end;

procedure TMPlusTests.TMMinus_ClassName_HasValue;
begin
  CheckNotEquals('', TMMinus.ClassName);
end;

procedure TMPlusTests.TMMinus_Create_FieldAddress_DefField_HasValue;
var
  SubjectUnderTest: TSubject;
begin
  SubjectUnderTest := BuildTMMinus;
  CheckEqualsPointer(nil, SubjectUnderTest.Instance.FieldAddress('DefField'));
end;

procedure TMPlusTests.TMPlus_Create_FieldAddress_DefField_HasValue;
var
  SubjectUnderTest: TSubject;
begin
  SubjectUnderTest := BuildTMPlus;
  CheckNotEqualsPointer(nil, SubjectUnderTest.Instance.FieldAddress('DefField'));
end;

procedure TMPlusTests.TMMinus_PropInfo_DefProp_HasValue;
begin
  CheckEqualsPointer(nil, TypInfo.GetPropInfo(TMMinus, 'DefProp'));
end;

procedure TMPlusTests.TMMinus_MethodAddress_DefMethod_HasValue;
begin
  CheckEqualsPointer(nil, TMMinus.MethodAddress('DefMethod'));
end;

procedure TMPlusTests.TMMinus_Create_FieldAddress_PubField_HasValue;
var
  SubjectUnderTest: ISubject;
begin
  SubjectUnderTest := BuildTMMinus;
  CheckNotEqualsPointer(nil, SubjectUnderTest.Instance.FieldAddress('PubField'));
end;

procedure TMPlusTests.TMPlus_Create_FieldAddress_PubField_HasValue;
var
  SubjectUnderTest: TSubject;
begin
  SubjectUnderTest := BuildTMPlus;
  CheckNotEqualsPointer(nil, SubjectUnderTest.Instance.FieldAddress('PubField'));
end;

procedure TMPlusTests.TMPlus_MethodAddress_DefMethod_HasValue;
begin
  CheckNotEqualsPointer(nil, TMPlus.MethodAddress('DefMethod'));
end;

procedure TMPlusTests.TMMinus_PropInfo_PubProp_HasValue;
begin
  // Note: Delphi 2007 and earlier do not generate ClassInfo (= TypeInfo) RTTI for $M- classes, even if they have published sections
{$IF CompilerVersion <= 19} // Delphi 2007 or older
  if TMMinus.ClassInfo = nil then
    Check(True) // pass
  else
{$IFEND CompilerVersion <= 19} // Delphi 2007 or older
    CheckNotEqualsPointer(nil, TypInfo.GetPropInfo(TMMinus, 'PubProp'));
end;

procedure TMPlusTests.TMMinus_MethodAddress_PubMethod_HasValue;
begin
  CheckNotEqualsPointer(nil, TMMinus.MethodAddress('PubMethod'));
end;

procedure TMPlusTests.TMPlus_MethodAddress_PubMethod_HasValue;
begin
  CheckNotEqualsPointer(nil, TMPlus.MethodAddress('PubMethod'));
end;

procedure TMPlusTests.TMPlus_PropInfo_DefProp_HasValue;
begin
  CheckNotEqualsPointer(nil, TypInfo.GetPropInfo(TMPlus, 'DefProp'));
end;

procedure TMPlusTests.TMPlus_PropInfo_PubProp_HasValue;
begin
  CheckNotEqualsPointer(nil, TypInfo.GetPropInfo(TMPlus, 'PubProp'));
end;

procedure TMPlusTests.TMPlus_ClassName_HasValue;
begin
  CheckNotEquals('', TMPlus.ClassName);
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
  RegisterTest(TMPlusTests.Suite);
end.
