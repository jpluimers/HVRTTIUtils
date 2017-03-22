unit MethodTableTestsUnit;

interface

uses
  Classes,
  TestFramework;

type
  {.$M+}// Compiler bug: includes published methods in VMT RTTI info even in $M- mode!!
{$M-}
  // From impl. of Classes unit:
  TPropFixup = class
  public
    FInstance: Integer;
  published
    function MakeGlobalReference: Boolean;
  end;

  TMyClass = class
    // I: Integer; // Not allowed in $M+ mode
    // public // Note: default access level is published
    procedure FirstDynamic; dynamic; // This could have RTTI depending on $M+
    procedure SecondDynamic; dynamic; abstract;
    class procedure ThirdDynamic; dynamic;
    class procedure FourthDynamic; dynamic;
    procedure MessageMethod(var Msg); message 42;
  private
    FA: Integer;
  published // These *always* have RTTI, even in $M-! Bug?
    constructor Create; // "Bug": ignores published constructor and destructors
    destructor Destroy; override;
    procedure MsgHandler(var Msg); message 1;
    procedure FirstPublished; virtual; abstract;
    procedure SecondPublished(A: Integer); virtual; abstract;
    procedure ThirdPublished(A: Integer)stdcall; virtual; abstract;
    function FourthPublished(A: string): string stdcall; virtual; abstract;
    procedure ThirdPublished2(A: Integer)cdecl; virtual; abstract;
    function FourthPublished2(A: string): string pascal; virtual; abstract;
    // properties only have RTTI in $M+ mode
    property A: Integer read FA write FA;
  end;

  TMyDescendent = class(TMyClass)
    // public
    procedure FirstDynamic; override;
  published
    procedure SecondDynamic; override;
    class procedure ThirdDynamic; override;
    class procedure FourthDynamic; override;
  end;

  TMyDescendent2 = class(TMyClass)
  end;

type
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
  TMethodTableTestCase = class(TTestCase)
  strict private
    FSkipAddState: Boolean;
    FState: string;
    FStateStrings: TStrings;
    SkipAddState: Boolean;
    function Build: TSubject;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  public
    destructor Destroy; override;
    procedure AddState(const Value: string); virtual;
    property State: string read FState;
  published
    procedure TPropFixup_DumpPublishedMethods2_ValuesOk;
    procedure TMyDescendent_DumpPublishedMethods_Equals_DumpPublishedMethods2;
    procedure TMyDescendent_FindPublishedMethodByAddr_FirstDynamic_HasValue;
    procedure TMyDescendent_FindPublishedMethodByAddr_From_FindPublishedMethodByAddr_ThirdMethod_HasValue;
    procedure TMyDescendent_FindPublishedMethodByAddr_nil_HasNoValue;
    procedure TMyDescendent_FindPublishedMethodByAddr_ThirdMethod_HasValue;
    procedure TMyDescendent_FindPublishedMethodByName_NotThere_HasNoValue;
    procedure TMyDescendent_FindPublishedMethodByName_ThirdMethod_HasValue;
    procedure TMyDescendent_GetPropInfo_A_HasValue;
  end;

implementation

uses
  SysUtils,
  TypInfo,
  HVVMT,
  AbstractTestHelperUnit;

var
  FVmtTestCase: TMethodTableTestCase = nil;

type
  PPublishedMethodArray = array of PPublishedMethod;
  TPublishedMethodDumper = class
  strict private
    FOutput: TStrings;
    FMethods: PPublishedMethodArray;
    procedure Append(const Line: string);
    procedure AppendHeader(const CurrentClass: TClass);
    procedure AppendMethod(const MethodIndexInClass: Integer; const Method: PPublishedMethod);
    procedure Clear;
    function GetOutput: string;
  public
    constructor Create;
    destructor Destroy; override;
    procedure DumpPublishedMethods(const AClass: TClass);
    procedure DumpPublishedMethods2(const AClass: TClass);
    property Methods: PPublishedMethodArray read FMethods;
    property Output: string read GetOutput;
  end;

{ TPropFixup }

function TPropFixup.MakeGlobalReference: Boolean;
begin
  Result := False;
end;

{ TMyClass }

procedure TMyClass.FirstDynamic;
begin
  inherited;
  // Writeln(ClassName, ': TMyClass.FirstDynamic');
end;

{
procedure TMyClass.SecondDynamic;
begin
  Writeln(ClassName, '.SecondDynamic');
end;
}

class procedure TMyClass.ThirdDynamic;
begin
  Writeln(ClassName, '.ThirdDynamic');
end;

class procedure TMyClass.FourthDynamic;
begin
  Writeln(ClassName, '.FourthDynamic');
end;

procedure TMyClass.MessageMethod(var Msg);
begin
  inherited; // Special case - calls TObject.DefaultHandler
  Writeln(ClassName, '.MessageMethod');
end;

constructor TMyClass.Create;
begin
  inherited;
end;

destructor TMyClass.Destroy;
begin

  inherited;
end;

procedure TMyClass.MsgHandler(var Msg);
begin

end;

{ TMyDescendent }

procedure TMyDescendent.FirstDynamic;
begin
  // Writeln(ClassName, ': TMyDescendent.FirstDynamic');
end;

procedure TMyDescendent.SecondDynamic;
begin
  inherited;
  Writeln(ClassName, '.SecondDynamic');
end;

class procedure TMyDescendent.ThirdDynamic;
begin
  Writeln(ClassName, '.ThirdDynamic');
end;

class procedure TMyDescendent.FourthDynamic;
begin
  inherited;
  Writeln(ClassName, '.FourthDynamic');
end;

{ TSubject }

constructor TSubject.Create;
var
  Instance: TMyClass;
begin
{$WARN CONSTRUCTING_ABSTRACT OFF} // Ignore [dcc32 Warning] MethodTableTestsUnit.pas(205): W1020 Constructing instance of 'TMyClass' containing abstract method 'TMyClass.SecondDynamic'
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

{ TMethodTableTestCase }

destructor TMethodTableTestCase.Destroy;
begin
  FStateStrings.Free();
  FStateStrings := nil;
  inherited Destroy();
end;

procedure TMethodTableTestCase.AddState(const Value: string);
begin
  if FSkipAddState then
    Exit;
  if not Assigned(FStateStrings) then
  begin
    FStateStrings := TStringList.Create();
  end;
  FStateStrings.Add(Value);
  FState := FStateStrings.CommaText;
end;

function TMethodTableTestCase.Build: TSubject;
begin
  Result := TSubject.Create();
end;

procedure TMethodTableTestCase.TPropFixup_DumpPublishedMethods2_ValuesOk;
var
  Actual: PPublishedMethodArray;
  Dumper: TPublishedMethodDumper;
  Method: PPublishedMethod;
begin
  Dumper := TPublishedMethodDumper.Create();
  try
    Dumper.DumpPublishedMethods2(TPropFixup);
    Actual := Dumper.Methods;
  finally
    Dumper.Free();
  end;
  CheckEquals(1, Length(Actual));
  Method := Actual[0];
  CheckEquals('MakeGlobalReference', Method.Name);
  CheckNotEqualsPointer(nil, Method.Address);
end;

procedure TMethodTableTestCase.TMyDescendent_DumpPublishedMethods_Equals_DumpPublishedMethods2;
var
  Actual: string;
  Dumper: TPublishedMethodDumper;
  Expected: string;
begin
  Dumper := TPublishedMethodDumper.Create();
  try
    Dumper.DumpPublishedMethods(TMyDescendent);
    Expected := Dumper.Output;
  finally
    Dumper.Free();
  end;
  Dumper := TPublishedMethodDumper.Create();
  try
    Dumper.DumpPublishedMethods2(TMyDescendent);
    Actual := Dumper.Output;
  finally
    Dumper.Free();
  end;
  CheckEquals(Expected, Actual);
end;

procedure TMethodTableTestCase.SetUp;
begin
  inherited SetUp();
  FVmtTestCase := Self;
end;

procedure TMethodTableTestCase.TearDown;
begin
  FVmtTestCase := nil;
  inherited TearDown();
end;

procedure TMethodTableTestCase.TMyDescendent_FindPublishedMethodByAddr_FirstDynamic_HasValue;
var
  Actual: PPublishedMethod;
begin
  Actual := FindPublishedMethodByAddr(TMyDescendent, @TMyDescendent.FirstDynamic);
  CheckNotEqualsPointer(nil, Actual);
end;

procedure TMethodTableTestCase.TMyDescendent_FindPublishedMethodByAddr_From_FindPublishedMethodByAddr_ThirdMethod_HasValue;
var
  Actual: PPublishedMethod;
  Address: Pointer;
begin
  Address := FindPublishedMethodByName(TMyDescendent, 'ThirdPublished').Address;
  Actual := FindPublishedMethodByAddr(TMyDescendent, Address);
  CheckNotEqualsPointer(nil, Actual);
end;

procedure TMethodTableTestCase.TMyDescendent_FindPublishedMethodByAddr_nil_HasNoValue;
var
  Actual: PPublishedMethod;
begin
  Actual := FindPublishedMethodByAddr(TMyDescendent, nil);
  CheckEqualsPointer(nil, Actual);
end;

procedure TMethodTableTestCase.TMyDescendent_FindPublishedMethodByAddr_ThirdMethod_HasValue;
var
  Actual: PPublishedMethod;
begin
  Actual := FindPublishedMethodByAddr(TMyDescendent, @TMyDescendent.ThirdPublished);
  CheckNotEqualsPointer(nil, Actual);
end;

procedure TMethodTableTestCase.TMyDescendent_FindPublishedMethodByName_NotThere_HasNoValue;
var
  Actual: PPublishedMethod;
begin
  Actual := FindPublishedMethodByName(TMyDescendent, 'NotThere');
  CheckEqualsPointer(nil, Actual);
end;

procedure TMethodTableTestCase.TMyDescendent_FindPublishedMethodByName_ThirdMethod_HasValue;
var
  Actual: PPublishedMethod;
begin
  Actual := FindPublishedMethodByName(TMyDescendent, 'ThirdPublished');
  CheckNotEqualsPointer(nil, Actual);
end;

procedure TMethodTableTestCase.TMyDescendent_GetPropInfo_A_HasValue;
var
  Actual: Pointer;
begin
  Actual := GetPropInfo(TMyDescendent, 'A');
  // Note: Delphi 2007 and earlier do not generate ClassInfo (= TypeInfo) RTTI for $M- classes, even if they have published sections
{$IF CompilerVersion <= 19} // Delphi 2007 or older
  if TMyDescendent.ClassInfo = nil then
    Check(True) // pass
  else
{$IFEND CompilerVersion <= 19} // Delphi 2007 or older
    CheckNotEqualsPointer(nil, Actual);
end;

{ TPublishedMethodDumper }

constructor TPublishedMethodDumper.Create;
begin
  inherited Create();
  FOutput := TStringList.Create();
end;

destructor TPublishedMethodDumper.Destroy;
begin
  FOutput.Free();
  FOutput := nil;
  inherited Destroy();
end;

procedure TPublishedMethodDumper.Append(const Line: string);
begin
  FOutput.Add(Line);
end;

procedure TPublishedMethodDumper.AppendHeader(const CurrentClass: TClass);
begin
  Append('Published methods in ' + CurrentClass.ClassName);
end;

procedure TPublishedMethodDumper.AppendMethod(const MethodIndexInClass: Integer; const Method: PPublishedMethod);
var
  NewIndex: Integer;
begin
  Append(Format('%d. MethodAddr = %p, Name = %s', [MethodIndexInClass, Method.Address, Method.Name]));

  NewIndex := Length(FMethods);
  SetLength(FMethods, NewIndex + 1);
  FMethods[NewIndex] := Method;
end;

procedure TPublishedMethodDumper.Clear;
begin
  FOutput.Clear();
end;

procedure TPublishedMethodDumper.DumpPublishedMethods(const AClass: TClass);
var
  CurrentClass: TClass;
  i: Integer;
  Method: PPublishedMethod;
begin
  CurrentClass := AClass;
  while Assigned(CurrentClass) do
  begin
    AppendHeader(CurrentClass);
    for i := 0 to GetPublishedMethodCount(CurrentClass) - 1 do
    begin
      Method := GetPublishedMethod(CurrentClass, i);
      AppendMethod(i, Method);
    end;
    CurrentClass := CurrentClass.ClassParent;
  end;
end;

procedure TPublishedMethodDumper.DumpPublishedMethods2(const AClass: TClass);
var
  CurrentClass: TClass;
  i: Integer;
  Method: PPublishedMethod;
begin
  CurrentClass := AClass;
  while Assigned(CurrentClass) do
  begin
    AppendHeader(CurrentClass);
    Method := GetFirstPublishedMethod(CurrentClass);
    for i := 0 to GetPublishedMethodCount(CurrentClass) - 1 do
    begin
      AppendMethod(i, Method);
      Method := GetNextPublishedMethod(CurrentClass, Method);
    end;
    CurrentClass := CurrentClass.ClassParent;
  end;
end;

function TPublishedMethodDumper.GetOutput: string;
begin
  Result := FOutput.CommaText;
end;

initialization
  RegisterTest(TMethodTableTestCase.Suite);
end.
