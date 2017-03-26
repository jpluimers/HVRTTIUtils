unit HVMethodInfoClassesTestsUnit;

// from TestHVMethodInfoClasses

interface

uses
  TypInfo,
  TestFramework;

type
  // TODO -o##jpl -cAmend : Convert the rest of the `Test` from `TestHVMethodInfoClasses` to unit tests
  TInterfaceMethodsTestCase = class(TTestCase)
  published
    procedure TMyClass_GetClassInfo_Succeeds;
  end;

implementation

uses
  HVMethodInfoClasses;

type
{$METHODINFO OFF}
  TNormalClass = class
  end;

  TSetOfByte = set of byte;
  TEnum = (enOne, enTwo, enThree);

type
{$METHODINFO ON}
  // TMyClass = class;
  TMyClass = class
  public
    function Test1(const A: string): string;
    function Test2(const A: string): byte;
    procedure Test3(R: Integer);
    procedure Test4(R: TObject);
    procedure Test5(R: TNormalClass);
    procedure Test6(R: TSetOfByte);
    procedure Test7(R: shortstring);
    procedure Test8(R: openstring);
    procedure Test9(R: TEnum);
    function Test10: TNormalClass;
    function Test11: Integer;

    // Parameter types that are not supported -
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
    // procedure Test24(out R: Integer); safecall;
  end;

function TMyClass.Test1;
begin
  Writeln(A);
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
  Writeln(A);
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

procedure TMyClass.Test7;
begin
end;

procedure TMyClass.Test8;
begin
end;

procedure TMyClass.Test9;
begin
end;

{ TInterfaceMethodsTestCase }

procedure TInterfaceMethodsTestCase.TMyClass_GetClassInfo_Succeeds;
var
  ClassInfo: TClassInfo;
  ClassTypeInfo: PTypeInfo;
begin
  ClassTypeInfo := TypeInfo(TMyClass);
  GetClassInfo(ClassTypeInfo, ClassInfo);
  Check(True); // pass
end;

initialization
  RegisterTest(TInterfaceMethodsTestCase.Suite);
end.
