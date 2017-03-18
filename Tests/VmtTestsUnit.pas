unit VmtTestsUnit;

interface

uses
  Classes,
  TestFramework;

type
  TMyClass = class
  strict protected
    procedure AddState(const Value: string); virtual;
  public
    function SafeCallException(ExceptObject: TObject; ExceptAddr: Pointer): HResult; override;
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    procedure Dispatch(var Message); override;
    procedure DefaultHandler(var Message); override;
    class function NewInstance: TObject; override;
    procedure FreeInstance; override;
    destructor Destroy; override;
    procedure MethodA(var A: Integer); virtual;
    procedure MethodB(out A: Integer); virtual; abstract;
    function MethodC: Integer; virtual;
    procedure Method; virtual;
  end;

  TMyDescendent = class(TMyClass)
    procedure MethodA(var A: Integer); override;
    procedure MethodB(out A: Integer); override;
    function MethodC: Integer; override;
    procedure Method; override;
  end;

  ISubject = interface
    ['{10BC8F84-79F9-42D9-8933-04806B1147D8}']
    function Instance: TMyClass;
  end;

  TSubject = class(TInterfacedObject, ISubject)
  strict private
    FInstance: TMyClass;
  private
    function Instance: TMyClass;
  public
    constructor Create; overload;
    constructor Create(const AInstance: TMyClass); overload;
    destructor Destroy; override;
  end;

type
  TVmtTestCase = class(TTestCase)
  strict private
    FState: string;
    FStateStrings: TStrings;
    function Build: TSubject;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  public
    destructor Destroy; override;
    procedure AddState(const Value: string); virtual;
    property State: string read FState;
  published
    procedure TMyClass_Create_AfterConstruction_State_Matches;
    procedure TMyClass_Create_BeforeDestruction_State_Matches;
    procedure TMyClass_Create_ClassName_Equals_TMyClass;
    procedure TMyClass_Create_DefaultHandler_State_Matches;
    procedure TMyClass_Create_Dispatch_State_Matches;
    procedure TMyClass_Create_Parent_ClassName_Equals_TObject;
    procedure TMyClass_Create_SafeCallException_State_Matches;
    procedure TMyClass_Create_SelfPtr_ClassName_Equals_TMyClass;
    procedure TMyClass_Create_State_Matches;
    procedure TMyClass_Direct_NewInstance_LastState_Matches;
    procedure TMyClass_Vmt_Destroy_LastState_Matches;
    procedure TMyClass_Vmt_NewInstance_LastState_Matches;
    procedure TMyDescendent_MethodB_State_Matches;
    procedure TMyDescendent_MethodC_State_Matches;
    procedure VMTOFFSET_CallMyMethod_State_Matches;
    procedure VMTOFFSET_MyMethodIndex_Not_Zero;
    procedure VMTOFFSET_MyMethodOffSet_Not_Zero;
  end;

implementation

uses
  SysUtils,
  HVVMT;

var
  FVmtTestCase: TVmtTestCase = nil;

{ TMyClass }

function MyMethodOffset: Integer;
asm
  MOV    EAX, VMTOFFSET TMyClass.Method
end;

function MyMethodIndex: Integer;
begin
  Result := MyMethodOffset div SizeOf(Pointer);
end;

procedure CallMyMethod(Instance: TMyClass);
asm
  MOV    ECX, [EAX]
  CALL  [ECX + VMTOFFSET TMyClass.Method]
end;

procedure TMyClass.AfterConstruction;
begin
  inherited;
  AddState('AfterConstruction');
end;

procedure TMyClass.BeforeDestruction;
begin
  AddState('BeforeDestruction');
  inherited;
end;

procedure TMyClass.DefaultHandler(var Message);
begin
  inherited;
  AddState('DefaultHandler');
end;

destructor TMyClass.Destroy;
begin
  AddState('Destroy');
  inherited;
end;

procedure TMyClass.Dispatch(var Message);
begin
  inherited;
  AddState('Dispatch');
end;

procedure TMyClass.FreeInstance;
begin
  AddState('FreeInstance');
  inherited;
end;

class function TMyClass.NewInstance: TObject;
var
  Instance: TMyClass;
begin
  Result := inherited NewInstance;
  Instance := Result as TMyClass;
  Instance.AddState('NewInstance');
end;

function TMyClass.SafeCallException(ExceptObject: TObject; ExceptAddr: Pointer): HResult;
begin
  Result := inherited SafeCallException(ExceptObject, ExceptAddr);
  AddState('SafeCallException');
end;

procedure TMyClass.Method;
begin
  AddState('Method');
end;

procedure TMyClass.MethodA(var A: Integer);
begin

end;

function TMyClass.MethodC: Integer;
begin
  Result := 43;
  AddState(IntToStr(Result));
end;

procedure TMyClass.AddState(const Value: string);
begin
  if Assigned(FVmtTestCase) then
    FVmtTestCase.AddState(Value);
end;

{ TMyDescendent }

procedure TMyDescendent.Method;
begin
  inherited;

end;

procedure TMyDescendent.MethodA(var A: Integer);
begin
  inherited;

end;

procedure TMyDescendent.MethodB(out A: Integer);
begin
  inherited;
  AddState(IntToStr(A));
end;

function TMyDescendent.MethodC: Integer;
begin
  // inherited; // Error
  // Result := inherited; // Error
  Result := inherited MethodC; // Ok
end;

{ TSubject }

constructor TSubject.Create;
var
  Instance: TMyClass;
begin
{$WARN CONSTRUCTING_ABSTRACT OFF} // Ignore [dcc32 Warning] VmtTestsUnit.pas(219): W1020 Constructing instance of 'TMyClass' containing abstract method 'TMyClass.MethodB'
  Instance := TMyClass.Create();
{$WARN CONSTRUCTING_ABSTRACT ON}
  Create(Instance);
end;

constructor TSubject.Create(const AInstance: TMyClass);
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

function TSubject.Instance: TMyClass;
begin
  Result := FInstance;
end;

destructor TVmtTestCase.Destroy;
begin
  FStateStrings.Free();
  FStateStrings := nil;
  inherited Destroy();
end;

procedure TVmtTestCase.AddState(const Value: string);
begin
  if not Assigned(FStateStrings) then
  begin
    FStateStrings := TStringList.Create();
  end;
  FStateStrings.Add(Value);
  FState := FStateStrings.CommaText;
end;

{ TVmtTestCase }

function TVmtTestCase.Build: TSubject;
begin
  Result := TSubject.Create();
end;

procedure TVmtTestCase.SetUp;
begin
  inherited SetUp();
  FVmtTestCase := Self;
end;

procedure TVmtTestCase.TearDown;
begin
  FVmtTestCase := nil;
  inherited TearDown();
end;

procedure TVmtTestCase.TMyClass_Create_AfterConstruction_State_Matches;
var
  Instance: TMyClass;
  SubjectUnderTest: TSubject;
  Vmt: PVmt;
begin
  SubjectUnderTest := Build;
  Instance := SubjectUnderTest.Instance;
  Vmt := GetVmt(Instance);
  Vmt^.AfterConstruction(Instance);
  CheckEquals('NewInstance,AfterConstruction,AfterConstruction', State);
end;

procedure TVmtTestCase.TMyClass_Create_BeforeDestruction_State_Matches;
var
  Instance: TMyClass;
  SubjectUnderTest: TSubject;
  Vmt: PVmt;
begin
  SubjectUnderTest := Build;
  Instance := SubjectUnderTest.Instance;
  Vmt := GetVmt(Instance);
  Vmt^.BeforeDestruction(Instance);
  CheckEquals('NewInstance,AfterConstruction,BeforeDestruction', State);
end;

procedure TVmtTestCase.TMyClass_Create_ClassName_Equals_TMyClass;
var
  SubjectUnderTest: TSubject;
  SymbolName: string;
  Vmt: PVmt;
begin
  SubjectUnderTest := Build;
  Vmt := GetVmt(SubjectUnderTest.Instance);
  SymbolName :=
{$IFDEF Unicode}
    UTF8ToString
{$ENDIF Unicode}
    (Vmt^.ClassName^);
  CheckEquals(TMyClass.ClassName, SymbolName);
end;

procedure TVmtTestCase.TMyClass_Create_DefaultHandler_State_Matches;
var
  Instance: TMyClass;
  SubjectUnderTest: TSubject;
  Msg: Word;
  Vmt: PVmt;
begin
  SubjectUnderTest := Build;
  Instance := SubjectUnderTest.Instance;
  Vmt := GetVmt(Instance);
  Msg := 0;
  Vmt^.DefaultHandler(Instance, Msg);
  CheckEquals('NewInstance,AfterConstruction,DefaultHandler', State);
end;

procedure TVmtTestCase.TMyClass_Create_Dispatch_State_Matches;
var
  Instance: TMyClass;
  Msg: Word;
  SubjectUnderTest: TSubject;
  Vmt: PVmt;
begin
  SubjectUnderTest := Build;
  Instance := SubjectUnderTest.Instance;
  Vmt := GetVmt(Instance);
  Msg := 0;
  Vmt^.Dispatch(Instance, Msg);
  CheckEquals('NewInstance,AfterConstruction,DefaultHandler,Dispatch', State);
end;

procedure TVmtTestCase.TMyClass_Create_Parent_ClassName_Equals_TObject;
var
  SubjectUnderTest: TSubject;
  Vmt: PVmt;
begin
  SubjectUnderTest := Build;
  Vmt := GetVmt(SubjectUnderTest.Instance);
  CheckEquals(TObject.ClassName, Vmt^.Parent^.ClassName);
end;

procedure TVmtTestCase.TMyClass_Create_SafeCallException_State_Matches;
var
  Instance: TMyClass;
  SubjectUnderTest: TSubject;
  Vmt: PVmt;
begin
  SubjectUnderTest := Build;
  Instance := SubjectUnderTest.Instance;
  Vmt := GetVmt(Instance);
  Vmt^.SafeCallException(Instance, nil, nil);
  CheckEquals('NewInstance,AfterConstruction,SafeCallException', State);
end;

procedure TVmtTestCase.TMyClass_Create_SelfPtr_ClassName_Equals_TMyClass;
var
  SubjectUnderTest: TSubject;
  Vmt: PVmt;
begin
  SubjectUnderTest := Build;
  Vmt := GetVmt(SubjectUnderTest.Instance);
  CheckEquals(TMyClass.ClassName, Vmt^.SelfPtr.ClassName);
end;

procedure TVmtTestCase.TMyClass_Create_State_Matches;
var
  SubjectUnderTest: TSubject;
begin
  SubjectUnderTest := Build;
  CheckEquals('NewInstance,AfterConstruction', State);
  if Assigned(SubjectUnderTest) then; // prevent [dcc32 Hint] VmtTestsUnit.pas(387): H2077 Value assigned to 'SubjectUnderTest' never used
end;

procedure TVmtTestCase.TMyClass_Direct_NewInstance_LastState_Matches;
var
  SubjectUnderTest: TMyClass;
begin
  SubjectUnderTest := TMyClass.NewInstance() as TMyClass;
  try
    CheckEquals('NewInstance', State);
  finally
    SubjectUnderTest.Free();
  end;
end;

procedure TVmtTestCase.TMyClass_Vmt_Destroy_LastState_Matches;
var
  SubjectUnderTest: TMyClass;
  Vmt: PVmt;
begin
  Vmt := GetVmt(TMyClass);
  SubjectUnderTest := Vmt^.NewInstance(TMyClass) as TMyClass;
  Vmt^.Destroy(SubjectUnderTest, 1);
  CheckEquals('NewInstance,BeforeDestruction,Destroy,FreeInstance', State);
end;

procedure TVmtTestCase.TMyClass_Vmt_NewInstance_LastState_Matches;
var
  SubjectUnderTest: TMyClass;
  Vmt: PVmt;
begin
  Vmt := GetVmt(TMyClass);
  SubjectUnderTest := Vmt^.NewInstance(TMyClass) as TMyClass;
  try
    CheckEquals('NewInstance', State);
  finally
    SubjectUnderTest.Free();
  end;
end;

procedure TVmtTestCase.TMyDescendent_MethodB_State_Matches;
var
  A: Integer;
  SubjectUnderTest: TMyClass;
begin
  SubjectUnderTest := TMyDescendent.Create;
  try
    A := 123;
    SubjectUnderTest.MethodB(A);
    CheckEquals('NewInstance,AfterConstruction,123', State);
  finally
    SubjectUnderTest.Free();
  end;
end;

procedure TVmtTestCase.TMyDescendent_MethodC_State_Matches;
var
  A: Integer;
  SubjectUnderTest: TMyClass;
begin
  SubjectUnderTest := TMyDescendent.Create;
  try
    A := SubjectUnderTest.MethodC();
    CheckEquals(43, A);
    CheckEquals('NewInstance,AfterConstruction,43', State);
  finally
    SubjectUnderTest.Free();
  end;
end;

procedure TVmtTestCase.VMTOFFSET_CallMyMethod_State_Matches;
var
  Instance: TMyClass;
  SubjectUnderTest: TSubject;
begin
  SubjectUnderTest := Build;
  Instance := SubjectUnderTest.Instance;
  CallMyMethod(Instance);
  CheckEquals('NewInstance,AfterConstruction,Method', State);
end;

procedure TVmtTestCase.VMTOFFSET_MyMethodIndex_Not_Zero;
var
  Index: Integer;
begin
  Index := MyMethodIndex;
  CheckNotEquals(0, Index);
end;

procedure TVmtTestCase.VMTOFFSET_MyMethodOffSet_Not_Zero;
var
  Offset: Integer;
begin
  Offset := MyMethodOffset;
  CheckNotEquals(0, Offset);
end;

initialization
  RegisterTest(TVmtTestCase.Suite);
end.

