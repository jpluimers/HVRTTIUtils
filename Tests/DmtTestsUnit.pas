unit DmtTestsUnit;

interface

uses
  Classes,
  TestFramework;

type
  TMyClass = class
  strict protected
    class procedure AddState(const AClass: TClass; const AValue: string); virtual;
  public
    procedure FirstDynamic; dynamic;
    procedure SecondDynamic; dynamic; abstract;
    class procedure ThirdDynamic; dynamic;
    class procedure FourthDynamic; dynamic;
    procedure MessageMethod(var Msg); message 42;
  end;

  TMyDescendent = class(TMyClass)
  public
    procedure FirstDynamic; override;
    procedure SecondDynamic; override;
    class procedure ThirdDynamic; override;
    class procedure FourthDynamic; override;
  end;

  TMyDescendent2 = class(TMyClass)
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
  IStringsSubject = interface
  ['{0401B6F5-D485-4117-99C2-6C592F2B22A1}']
    function Instance: TStrings;
  end;

  TStringsSubject = class(TInterfacedObject, IStringsSubject)
  strict private
    FInstance: TStrings;
  private
    function Instance: TStrings;
  public
    constructor Create; overload;
    constructor Create(const AInstance: TStrings); overload;
    destructor Destroy; override;
  end;

type
  TDynamicMethod = record
    ClassType: TClass;
    Index: Integer;
    MethodAddr: Pointer;
  end;
  TDynamicMethods = array of TDynamicMethod;

type
  TDmtTestCase = class(TTestCase)
  strict private
    FState: string;
    FStateStrings: TStrings;
    function Build: TSubject;
    function BuildDescendent: TSubject;
  private
    function BuildSubjects: IStringsSubject;
    procedure CheckDynamicMethods(const DynamicMethods: TDynamicMethods; const AllowNilMethodAddr: Boolean = False);
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  public
    destructor Destroy; override;
    procedure AddState(const Value: string); virtual;
    property State: string read FState;
  published
    procedure TMyClass_Create_FirstDynamic_State_Matches;
    procedure TMyClass_MyDynamicMethodIndex_Matches;
    procedure TMyDescendent2_Create_FasterDynamicListLoop2_Succeeds;
    procedure TMyDescendent2_Create_FasterDynamicListLoop_Succeeds;
    procedure TMyDescendent2_Create_SlowDynamicListLoop_Succeeds;
    procedure TMyDescendent_Create_CallFirstDynamicMethod_State_Matches;
    procedure TMyDescendent_Create_DumpDynamicMethods_State_Matches;
    procedure TMyDescendent_Create_DumpFoundDynamicMethods_State_Matches;
    procedure TMyDescendent_Create_FasterDynamicListLoop2_Succeeds;
    procedure TMyDescendent_Create_FasterDynamicListLoop_Succeeds;
    procedure TMyDescendent_Create_FasterDynamicLoop_Outperforms_SlowDynamicLoop;
    procedure TMyDescendent_Create_FourthDynamic_State_Matches;
    procedure TMyDescendent_Create_SecondDynamic_State_Matches;
    procedure TMyDescendent_Create_SlowDynamicListLoop_Succeeds;
    procedure TMyDescendent_Create_StaticCallFirstDynamicMethod_State_Matches;
    procedure TMyDescendent_Create_ThirdDynamic_State_Matches;
  end;

implementation

uses
  Windows,
  SysUtils,
  HVVMT,
  HVDMT,
  AbstractTestHelperUnit;

var
  FVmtTestCase: TDmtTestCase = nil;

{ TMyClass }

function MyDynamicMethodIndex: Integer;
asm
  MOV EAX, DMTIndex TMyClass.FirstDynamic
end;

procedure StaticCallFirstDynamicMethod(Self: TMyClass);
asm
  CALL TMyClass.FirstDynamic // Static call
end;

procedure CallFirstDynamicMethod(Self: TMyClass);
asm
  PUSH ESI
  MOV  ESI, DMTIndex TMyClass.FirstDynamic
  CALL System.@CallDynaInst
  POP  ESI // CallDynaInst trashes ESI, so restore it
end;

function DumpDynamicMethods(const AClass: TClass): TDynamicMethods;
var
  Count: Integer;
  CurrentClass: TClass;
  i: Integer;
  DynamicMethod: TDynamicMethod;
  ResultIndex: Integer;
begin
  CurrentClass := AClass;
  while Assigned(CurrentClass) do
  begin
//    Writeln('Dynamic methods in ', CurrentClass.ClassName);
    Count := GetDynamicMethodCount(CurrentClass);
    for i := 0 to Count - 1 do
    begin
      DynamicMethod.ClassType := CurrentClass;
      DynamicMethod.Index := GetDynamicMethodIndex(CurrentClass, i);
      DynamicMethod.MethodAddr := GetDynamicMethodProc(CurrentClass, i);
      ResultIndex := Length(Result);
      SetLength(Result, ResultIndex+1);
      Result[ResultIndex] := DynamicMethod;
//      Writeln(Format('%d. Index = %2d, MethodAddr = %p', [i, Index, MethodAddr]));
    end;
    CurrentClass := CurrentClass.ClassParent;
  end;
end;

function DumpFoundDynamicMethods(const AClass: TClass): TDynamicMethods;
  function Dump(const DMTIndex: TDMTIndex): TDynamicMethod;
  var
    Proc: Pointer;
  begin
    Proc := FindDynamicMethod(AClass, DMTIndex);
    Result.ClassType := AClass;
    Result.Index := DMTIndex;
    Result.MethodAddr := Proc;
//    Writeln(Format('Dynamic Method Index = %2d, Method = %p', [DMTIndex, Proc]));
  end;
begin
  SetLength(Result, 4);
  Result[0] := Dump(-1);
  Result[1] := Dump(1);
  Result[2] := Dump(13);
  Result[3] := Dump(42);
end;

procedure SlowDynamicListLoop(Instances: TStrings);
var
  Current: TObject;
  i: Integer;
  Instance: TMyClass;
begin
  for i := 0 to Instances.Count - 1 do
  begin
    Current := Instances.Objects[i];
    Instance := Current as TMyClass;
    Instance.FirstDynamic;
  end;
end;

procedure FasterDynamicListLoop(Instances: TStrings);
var
  Current: TObject;
  i: Integer;
  Instance: TMyClass;
  FirstDynamic: procedure(Self: TObject);
begin
  FirstDynamic := @TMyClass.FirstDynamic;
  for i := 0 to Instances.Count - 1 do
  begin
    Current := Instances.Objects[i];
    Instance := Current as TMyClass;
    Assert(Instance.ClassType = TMyClass, 'Instance.ClassType ' + Instance.ClassType.ClassName + ' <> TMyClass ' + TMyClass.ClassName);
    FirstDynamic(Instance);
  end;
end;

function TMyClassFirstDynamicNotOverridden(Instance: TMyClass): boolean;
var
  FirstDynamic: procedure of object;
begin
  FirstDynamic := Instance.FirstDynamic;
  Result := TMethod(FirstDynamic).Code = @TMyClass.FirstDynamic;
end;

procedure FasterDynamicListLoop2(Instances: TStrings);
type
  PMethod = TMethod;
var
  Current: TObject;
  i: Integer;
  Instance: TMyClass;
  FirstDynamic: procedure(Self: TObject);
begin
  FirstDynamic := @TMyClass.FirstDynamic;
  for i := 0 to Instances.Count - 1 do
  begin
    Current := Instances.Objects[i];
    Instance := Current as TMyClass;
    Assert(TObject(Instance) is TMyClass);
    Assert(TMyClassFirstDynamicNotOverridden(Instance));
    FirstDynamic(Instance);
  end;
end;

class procedure TMyClass.AddState(const AClass: TClass; const AValue: string);
begin
  if Assigned(FVmtTestCase) then
    FVmtTestCase.AddState(AClass.ClassName + '.' + AValue);
end;

procedure TMyClass.FirstDynamic;
begin
  inherited;
  AddState(TMyClass, 'FirstDynamic');
end;

{
procedure TMyClass.SecondDynamic;
begin
  AddState('SecondDynamic');
end;
}

class procedure TMyClass.ThirdDynamic;
begin
  AddState(TMyClass, 'ThirdDynamic');
end;

class procedure TMyClass.FourthDynamic;
begin
  AddState(TMyClass, 'FourthDynamic');
end;

procedure TMyClass.MessageMethod(var Msg);
begin
  inherited; // Special case - calls TObject.DefaultHandler
  AddState(TMyClass, 'MessageMethod');
end;

{ TMyDescendent}

procedure TMyDescendent.FirstDynamic;
begin
  AddState(TMyDescendent, 'FirstDynamic');
end;

procedure TMyDescendent.SecondDynamic;
begin
  inherited;
  AddState(TMyDescendent, 'SecondDynamic');
end;

class procedure TMyDescendent.ThirdDynamic;
begin
  AddState(TMyDescendent, 'ThirdDynamic');
end;

class procedure TMyDescendent.FourthDynamic;
begin
  inherited;
  AddState(TMyDescendent, 'FourthDynamic');
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

{ TStringsSubject }

constructor TStringsSubject.Create;
var
  Instance: TStrings;
begin
  Instance := TStringList.Create();
  Create(Instance);
end;

constructor TStringsSubject.Create(const AInstance: TStrings);
begin
  inherited Create;
  FInstance := AInstance;
end;

destructor TStringsSubject.Destroy;
begin
  FInstance.Free();
  FInstance := nil;
  inherited Destroy();
end;

function TStringsSubject.Instance: TStrings;
begin
  Result := FInstance;
end;

{ TDmtTestCase }

destructor TDmtTestCase.Destroy;
begin
  FStateStrings.Free();
  FStateStrings := nil;
  inherited Destroy();
end;

procedure TDmtTestCase.AddState(const Value: string);
begin
  if not Assigned(FStateStrings) then
  begin
    FStateStrings := TStringList.Create();
  end;
  FStateStrings.Add(Value);
  FState := FStateStrings.CommaText;
end;

function TDmtTestCase.Build: TSubject;
begin
  Result := TSubject.Create();
end;

function TDmtTestCase.BuildDescendent: TSubject;
begin
  Result := TSubject.Create(TMyDescendent.Create());
end;

function TDmtTestCase.BuildSubjects: IStringsSubject;
begin
  Result := TStringsSubject.Create();
{$WARN CONSTRUCTING_ABSTRACT OFF} // Ignore [dcc32 Warning] DmtTestsUnit.pas(395): W1020 Constructing instance of 'TMyClass' containing abstract method 'TMyClass.SecondDynamic'
  Result.Instance.AddObject('', TMyClass.Create);
  Result.Instance.AddObject('', TMyClass.Create);
  Result.Instance.AddObject('', TMyClass.Create);
{$WARN CONSTRUCTING_ABSTRACT ON}
end;

procedure TDmtTestCase.CheckDynamicMethods(const DynamicMethods: TDynamicMethods; const AllowNilMethodAddr: Boolean = False);
var
  DynamicMethod: TDynamicMethod;
begin
  for DynamicMethod in DynamicMethods do
  begin
    CheckNotEqualsPointer(nil, Pointer(DynamicMethod.ClassType), 'DynamicMethod.ClassType');
    // Compiler generated indexes are negative;
    // user generated (using the `message` keyword can be positive or negative but are usually positive
    CheckNotEquals(0, DynamicMethod.Index, 'DynamicMethod.Index');
    if not AllowNilMethodAddr then
      CheckNotEqualsPointer(nil, DynamicMethod.MethodAddr, 'DynamicMethod.MethodAddr');
  end;
end;

procedure TDmtTestCase.SetUp;
begin
  inherited SetUp();
  FVmtTestCase := Self;
end;

procedure TDmtTestCase.TearDown;
begin
  FVmtTestCase := nil;
  inherited TearDown();
end;

procedure TDmtTestCase.TMyClass_Create_FirstDynamic_State_Matches;
var
  SubjectUnderTest: TSubject;
begin
  SubjectUnderTest := Build;
//  Call dynamic instance method (System._CallDynaInst)
  SubjectUnderTest.Instance.FirstDynamic;
  CheckEquals(TMyClass.ClassName + '.FirstDynamic', State);
end;

procedure TDmtTestCase.TMyClass_MyDynamicMethodIndex_Matches;
var
  Actual: Integer;
begin
  Actual := MyDynamicMethodIndex;
  CheckEquals(-1, Actual);
end;

procedure TDmtTestCase.TMyDescendent2_Create_FasterDynamicListLoop2_Succeeds;
var
  Instance: TStrings;
  Once: string;
  Subjects: IStringsSubject;
begin
  Subjects := BuildSubjects;
  Instance := Subjects.Instance;
  Instance.AddObject('', TMyDescendent2.Create());
  FasterDynamicListLoop2(Instance);
  Once := TMyClass.ClassName + '.FirstDynamic,';
  CheckEquals(Once+Once+Once+TMyClass.ClassName + '.FirstDynamic', State);
end;

procedure TDmtTestCase.TMyDescendent2_Create_FasterDynamicListLoop_Succeeds;
var
  Instance: TStrings;
  Once: string;
  Subjects: IStringsSubject;
begin
  Subjects := BuildSubjects;
  Instance := Subjects.Instance;
  Instance.AddObject('', TMyDescendent2.Create());
  FasterDynamicListLoop(Instance);
  Once := TMyClass.ClassName + '.FirstDynamic,';
  CheckEquals(Once+Once+Once+TMyClass.ClassName + '.FirstDynamic', State);
end;

procedure TDmtTestCase.TMyDescendent2_Create_SlowDynamicListLoop_Succeeds;
var
  Instance: TStrings;
  Once: string;
  Subjects: IStringsSubject;
begin
  Subjects := BuildSubjects;
  Instance := Subjects.Instance;
  Instance.AddObject('', TMyDescendent2.Create());
  SlowDynamicListLoop(Instance);
  Once := TMyClass.ClassName + '.FirstDynamic,';
  CheckEquals(Once+Once+Once+TMyClass.ClassName + '.FirstDynamic', State);
end;

procedure TDmtTestCase.TMyDescendent_Create_CallFirstDynamicMethod_State_Matches;
var
  SubjectUnderTest: TSubject;
begin
  SubjectUnderTest := BuildDescendent;
// Call dynamic instance method via BASM
  CallFirstDynamicMethod(SubjectUnderTest.Instance);
  CheckEquals(TMyDescendent.ClassName + '.FirstDynamic', State);
end;

procedure TDmtTestCase.TMyDescendent_Create_DumpDynamicMethods_State_Matches;
var
  DynamicMethods: TDynamicMethods;
begin
  DynamicMethods := DumpDynamicMethods(TMyDescendent);
  CheckDynamicMethods(DynamicMethods);
end;

procedure TDmtTestCase.TMyDescendent_Create_DumpFoundDynamicMethods_State_Matches;
var
  DynamicMethods: TDynamicMethods;
begin
  DynamicMethods := DumpFoundDynamicMethods(TMyDescendent);
  CheckDynamicMethods(DynamicMethods, True);
end;

procedure TDmtTestCase.TMyDescendent_Create_FasterDynamicListLoop2_Succeeds;
var
  Subjects: IStringsSubject;
begin
  Subjects := BuildSubjects;
  FasterDynamicListLoop2(Subjects.Instance);
  CheckEquals(TMyClass.ClassName + '.FirstDynamic,'+TMyClass.ClassName + '.FirstDynamic,'+TMyClass.ClassName + '.FirstDynamic', State);
end;

procedure TDmtTestCase.TMyDescendent_Create_FasterDynamicListLoop_Succeeds;
var
  Subjects: IStringsSubject;
begin
  Subjects := BuildSubjects;
  FasterDynamicListLoop(Subjects.Instance);
  CheckEquals(TMyClass.ClassName + '.FirstDynamic,'+TMyClass.ClassName + '.FirstDynamic,'+TMyClass.ClassName + '.FirstDynamic', State);
end;

procedure TDmtTestCase.TMyDescendent_Create_FasterDynamicLoop_Outperforms_SlowDynamicLoop;
const
  CountPlus1 = 1000; // 10000; // 1000000;
  procedure SlowDynamicLoop(Instance: TMyClass);
  var
    i: Integer;
  begin
    for i := 0 to CountPlus1 do
      Instance.FirstDynamic;
  end;

  procedure FasterDynamicLoop(Instance: TMyClass);
  var
    i: Integer;
    FirstDynamic: procedure of object;
  begin
    FirstDynamic := Instance.FirstDynamic;
    for i := 0 to CountPlus1 do
      FirstDynamic;
  end;
var
  FasterElapsedTicks: Cardinal;
  FinishTime: Cardinal;
  Instance: TMyClass;
  IntermediateTime: Cardinal;
  SlowElapsedTicks: Cardinal;
  StartTime: Cardinal;
  SubjectUnderTest: TSubject;
begin
  SubjectUnderTest := BuildDescendent;
  StartTime := GetTickCount();
  Instance := SubjectUnderTest.Instance;
  SlowDynamicLoop(Instance);
  IntermediateTime := GetTickCount();
  FasterDynamicLoop(Instance);
  FinishTime := GetTickCount();
  SlowElapsedTicks := IntermediateTime - StartTime;
  FasterElapsedTicks := FinishTime - IntermediateTime;
  CheckTrue(FasterElapsedTicks < SlowElapsedTicks, Format('SlowDynamicLoop took %d ticks; FasterDynamicLoop %d ticks', [SlowElapsedTicks, FasterElapsedTicks]));
end;

procedure TDmtTestCase.TMyDescendent_Create_FourthDynamic_State_Matches;
var
  Proc: procedure of object;
  SubjectUnderTest: TSubject;
begin
  SubjectUnderTest := BuildDescendent;
// Find and call dynamic class method (System._FindDynaClass)
  Proc := SubjectUnderTest.Instance.FourthDynamic;
  Proc;
  CheckEquals(TMyClass.ClassName + '.FourthDynamic,' + TMyDescendent.ClassName + '.FourthDynamic', State);
end;

procedure TDmtTestCase.TMyDescendent_Create_SecondDynamic_State_Matches;
var
  Proc: procedure of object;
  SubjectUnderTest: TSubject;
begin
  SubjectUnderTest := BuildDescendent;
//  Find and call dynamic instance method (System._FindDynaInst)
  Proc := SubjectUnderTest.Instance.SecondDynamic;
  Proc;
  CheckEquals(TMyDescendent.ClassName + '.SecondDynamic', State);
end;

procedure TDmtTestCase.TMyDescendent_Create_SlowDynamicListLoop_Succeeds;
var
  Subjects: IStringsSubject;
begin
  Subjects := BuildSubjects;
  SlowDynamicListLoop(Subjects.Instance);
  CheckEquals(TMyClass.ClassName + '.FirstDynamic,'+TMyClass.ClassName + '.FirstDynamic,'+TMyClass.ClassName + '.FirstDynamic', State);
end;

procedure TDmtTestCase.TMyDescendent_Create_StaticCallFirstDynamicMethod_State_Matches;
var
  SubjectUnderTest: TSubject;
begin
  SubjectUnderTest := BuildDescendent;
// Call dynamic instance method via BASM
  StaticCallFirstDynamicMethod(SubjectUnderTest.Instance);
  CheckEquals(TMyClass.ClassName + '.FirstDynamic', State);
end;

procedure TDmtTestCase.TMyDescendent_Create_ThirdDynamic_State_Matches;
var
  SubjectUnderTest: TSubject;
begin
  SubjectUnderTest := BuildDescendent;
  SubjectUnderTest.Instance.ThirdDynamic;
  CheckEquals(TMyDescendent.ClassName + '.ThirdDynamic', State);
end;

initialization
  RegisterTest(TDmtTestCase.Suite);
end.
