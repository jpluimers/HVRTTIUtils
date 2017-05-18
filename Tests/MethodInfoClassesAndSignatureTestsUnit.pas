unit MethodInfoClassesAndSignatureTestsUnit;

// From TestHVMethodInfoClasses and TestPublishedMethodParams which is identical to TestMorePubMethodParams

interface

uses
  TypInfo,
  TestFramework,
  StatePerTestCaseUnit;

type
  TMethodInfoClassesAndSignature = class(TStatePerTestCase)
  strict private
    procedure DumpClass(const ClassTypeInfo: PTypeInfo);
  published
    procedure TMyClass_Dump_Matches;
    procedure TMyClass_GetMethodInfo_Test1_Matches;
    procedure TMyClass_GetMethodInfo_Test2_Matches;
  end;

implementation

uses
  ObjAuto,
  SysUtils,
  HVMethodInfoClasses,
  HVMethodSignature;

type
{$METHODINFO OFF}
  TNormalClass = class
  end;

  TSetOfByte = set of Byte;
  TEnum = (enOne, enTwo, enThree);

type
{$METHODINFO ON}
  // TMyClass = class;
  TMyClass = class
  strict private
    FLastStringParameter: string;
  public
    function Test1(const A: string): string;
    function Test2(const A: string): Byte;
    procedure Test3(R: Integer);
    procedure Test4(R: TObject);
    procedure Test5(R: TNormalClass);
    procedure Test6(R: TSetOfByte);
    procedure Test7(R: ShortString);
    procedure Test8(R: Openstring);
    procedure Test9(R: TEnum);
    function Test10: TNormalClass;
    function Test11: Integer;

    // TODO -oHallvard : D7 Parameter types that are not supported -
    // gives confusing D7 compiler warning "[Warning] Redeclaration of 'Test3' hides a member in the base class"
    // procedure Test12(R: TClass);
    // procedure Test13(R: PInteger);
    // procedure Test14(R: Pointer);
    // procedure Test15(var R); // untyped var/out parameter
    // procedure Test16(const R: array of Integer);
    // procedure Test17(const R: TRect);
    // function Test23: TClass;

    // Parameter types that are supported -
    function Test18: shortstring;
    function Test19: TObject;
    function Test20: IInterface;
    function Test21: TSetOfByte;
    function Test22: TEnum;

    // Safecall calling convention is not supported
    // D7: [Fatal Error] Internal error: D6238
    // D2007: F2084 Internal Error: D13472
    // procedure Test24(out R: Integer); safecall;
    property LastStringParameter: string read FLastStringParameter;
  end;

function TMyClass.Test1;
begin
  FLastStringParameter := A;
  Result := 'Hello from Test ' + A;
end;

function TMyClass.Test10;
begin
  Result := nil;
end;

function TMyClass.Test11: Integer;
begin
  Result := 42;
end;

function TMyClass.Test18: shortstring;
begin
  Result := ''
end;

function TMyClass.Test19: TObject;
begin
  Result := nil;
end;

function TMyClass.Test2;
begin
  FLastStringParameter := A;
  Result := 42;
end;

function TMyClass.Test20: IInterface;
begin
  Result := nil;
end;

function TMyClass.Test21: TSetOfByte;
begin
  Result := [];
end;

function TMyClass.Test22: TEnum;
begin
  Result := enOne;
end;

procedure TMyClass.Test3;
begin
end;

procedure TMyClass.Test4;
begin
end;

procedure TMyClass.Test5;
begin
end;

procedure TMyClass.Test6;
begin
end;

procedure TMyClass.Test7(R: ShortString);
begin
end;

procedure TMyClass.Test8(R: Openstring);
begin
end;

procedure TMyClass.Test9;
begin
end;

procedure TMethodInfoClassesAndSignature.DumpClass(const ClassTypeInfo: PTypeInfo);
var
  ClassInfo: TClassInfo;
  i: Integer;
  Line: string;
begin
  GetClassInfo(ClassTypeInfo, ClassInfo);
  AddState(Format('unit %s;', [ClassInfo.UnitName]));
  AddState('type');
  AddState(Format('  %s = ', [ClassInfo.Name]));
  Line := 'class';
  if Assigned(ClassInfo.ParentClass) then
    Line := Line + Format(' (%s)', [ClassInfo.ParentClass.ClassName]);
  AddState(Line);
  for i := Low(ClassInfo.Methods) to High(ClassInfo.Methods) do
    AddState('    ' + MethodSignatureToString(ClassInfo.Methods[i]));
  AddState('  end;');
end;

procedure TMethodInfoClassesAndSignature.TMyClass_Dump_Matches;
var
  Actual: string;
  Expected: string;
begin
  DumpClass(TypeInfo(TMyClass));
  Actual := State;
  Expected := '"unit MethodInfoClassesAndSignatureTestsUnit;",' +
    'type,"  TMyClass = ",' +
    '"class (TObject)",' +
{$IF CompilerVersion <= 19} // Delphi 2007 or older compilers do not emit pfConst
    '"    function Test1(A: string): string;",' +
{$ELSE}
    '"    function Test1(const A: string): string;",' +
{$IFEND CompilerVersion <= 19} // Delphi 2007 or older compilers do not emit pfConst
{$IF CompilerVersion <= 19} // Delphi 2007 or older compilers do not emit pfConst
    '"    function Test2(A: string): Byte;",' +
{$ELSE}
    '"    function Test2(const A: string): Byte;",' +
{$IFEND CompilerVersion <= 19} // Delphi 2007 or older compilers do not emit pfConst
    '"    procedure Test3(R: Integer);",' +
    '"    procedure Test4(R: TObject);",' +
    '"    procedure Test5(R: TNormalClass);",' +
    '"    procedure Test6(R: TSetOfByte);",' +
    '"    procedure Test7(R: ShortString);",' +
    '"    procedure Test8(R: ShortString);",' +
    '"    procedure Test9(R: TEnum);",' +
    '"    function Test10(): TNormalClass;",' +
    '"    function Test11(): Integer;",' +
    '"    function Test18(): ShortString;",' +
    '"    function Test19(): TObject;",' +
    '"    function Test20(): IInterface;",' +
    '"    function Test21(): TSetOfByte;",' +
    '"    function Test22(): TEnum;",' +
    '"  end;"';
  CheckEquals(Expected, Actual);
end;

procedure TMethodInfoClassesAndSignature.TMyClass_GetMethodInfo_Test1_Matches;
var
  Actual: Variant;
  Expected: string;
  MyClass: TMyClass;
  MethodInfo: PMethodInfoHeader;
begin
  MyClass := TMyClass.Create;
  MethodInfo := GetMethodInfo(MyClass, 'Test1');
  if Assigned(MethodInfo) then
  begin
    Actual := ObjectInvoke(MyClass, MethodInfo, [], ['Hallvard']);
    CheckEquals('Hallvard', MyClass.LastStringParameter);
    Expected := 'Hello from Test ' + 'Hallvard';
    CheckEquals(Expected, Actual);
  end
  else
    Check(False, 'Could not get MethodInfo of Test1'); // fail
end;

procedure TMethodInfoClassesAndSignature.TMyClass_GetMethodInfo_Test2_Matches;
var
  Actual: Variant;
  Expected: Integer;
  MyClass: TMyClass;
  MethodInfo: PMethodInfoHeader;
begin
  MyClass := TMyClass.Create;
  MethodInfo := GetMethodInfo(MyClass, 'Test2');
  if Assigned(MethodInfo) then
  begin
    Actual := ObjectInvoke(MyClass, MethodInfo, [], ['Hallvard']);
    CheckEquals('Hallvard', MyClass.LastStringParameter);
    Expected := 42;
    CheckEquals(Expected, Integer(Actual));
  end
  else
    Check(False, 'Could not get MethodInfo of Test2'); // fail
end;

initialization
  RegisterTest(TMethodInfoClassesAndSignature.Suite);
end.
