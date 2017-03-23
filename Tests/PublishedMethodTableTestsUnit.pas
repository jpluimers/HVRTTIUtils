unit PublishedMethodTableTestsUnit;

interface

uses
  Classes,
  TestFramework;

type
  TPublishedMethodTableTestCase = class(TTestCase)
  published
    procedure TMyClass_DumpPublishedMethods_Equals_DumpPublishedMethods2;
    procedure TMyClass_FindPublishedMethodByAddr_FourthPublished_HasValue;
    procedure TMyClass_FindPublishedMethodByAddr_From_FindPublishedMethodByAddr_FifthPublished_HasValue;
    procedure TMyClass_FindPublishedMethodByAddr_nil_HasNoValue;
    procedure TMyClass_FindPublishedMethodByAddr_ThirdPublished_HasValue;
    procedure TMyClass_FindPublishedMethodByName_FindPublishedMethodName_SecondPublished_HasValue;
    procedure TMyClass_FindPublishedMethodByName_FirstPublished_HasValue;
    procedure TMyClass_FindPublishedMethodByName_NotThere_HasNoValue;
    procedure TMyClass_FindPublishedMethodByName_SixthPublished_HasValue;
  end;

implementation

uses
  SysUtils,
  TypInfo,
  HVVMT,
  AbstractTestHelperUnit,
  PublishedMethodDumperUnit;

type
{$M+}
  TMyClass = class
  published
    procedure FirstPublished;
    procedure SecondPublished(A: Integer);
    procedure ThirdPublished(A: Integer); stdcall;
    function FourthPublished(A: TComponent): TComponent; stdcall;
    procedure FifthPublished(Component: TComponent); stdcall;
    function SixthPublished(A: string; Two, Three, Four, Five, Six: Integer): string; pascal;
  end;

{ TMyClass }

procedure TMyClass.FirstPublished;
begin
end;

procedure TMyClass.SecondPublished;
begin
end;

procedure TMyClass.ThirdPublished;
begin
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

procedure TPublishedMethodTableTestCase.TMyClass_DumpPublishedMethods_Equals_DumpPublishedMethods2;
var
  Actual: string;
  Dumper: TPublishedMethodDumper;
  Expected: string;
begin
  Dumper := TPublishedMethodDumper.Create();
  try
    Dumper.DumpPublishedMethods(TMyClass);
    Expected := Dumper.Output;
  finally
    Dumper.Free();
  end;
  Dumper := TPublishedMethodDumper.Create();
  try
    Dumper.DumpPublishedMethods2(TMyClass);
    Actual := Dumper.Output;
  finally
    Dumper.Free();
  end;
  CheckEquals(Expected, Actual);
end;

procedure TPublishedMethodTableTestCase.TMyClass_FindPublishedMethodByAddr_FourthPublished_HasValue;
var
  Actual: PPublishedMethod;
  Address: Pointer;
begin
  Address := FindPublishedMethodAddr(TMyClass, 'FourthPublished');
  Actual := FindPublishedMethodByAddr(TMyClass, Address);
  CheckNotEqualsPointer(nil, Actual);
end;

procedure TPublishedMethodTableTestCase.TMyClass_FindPublishedMethodByAddr_From_FindPublishedMethodByAddr_FifthPublished_HasValue;
var
  Actual: PPublishedMethod;
  Address: Pointer;
begin
  Address := FindPublishedMethodByName(TMyClass, 'FifthPublished').Address;
  Actual := FindPublishedMethodByAddr(TMyClass, Address);
  CheckNotEqualsPointer(nil, Actual);
end;

procedure TPublishedMethodTableTestCase.TMyClass_FindPublishedMethodByAddr_nil_HasNoValue;
var
  Actual: PPublishedMethod;
begin
  Actual := FindPublishedMethodByAddr(TMyClass, nil);
  CheckEqualsPointer(nil, Actual);
end;

procedure TPublishedMethodTableTestCase.TMyClass_FindPublishedMethodByAddr_ThirdPublished_HasValue;
var
  Actual: PPublishedMethod;
begin
  Actual := FindPublishedMethodByAddr(TMyClass, @TMyClass.ThirdPublished);
  CheckNotEqualsPointer(nil, Actual);
end;

procedure TPublishedMethodTableTestCase.TMyClass_FindPublishedMethodByName_FindPublishedMethodName_SecondPublished_HasValue;
var
  Actual: PPublishedMethod;
  MethodName: TSymbolName;
begin
  MethodName := FindPublishedMethodName(TMyClass, @TMyClass.SecondPublished);
  Actual := FindPublishedMethodByName(TMyClass, MethodName);
  CheckNotEqualsPointer(nil, Actual);
end;

procedure TPublishedMethodTableTestCase.TMyClass_FindPublishedMethodByName_FirstPublished_HasValue;
var
  Actual: PPublishedMethod;
begin
  Actual := FindPublishedMethodByName(TMyClass, 'FirstPublished');
  CheckNotEqualsPointer(nil, Actual);
end;

procedure TPublishedMethodTableTestCase.TMyClass_FindPublishedMethodByName_NotThere_HasNoValue;
var
  Actual: PPublishedMethod;
begin
  Actual := FindPublishedMethodByName(TMyClass, 'NotThere');
  CheckEqualsPointer(nil, Actual);
end;

procedure TPublishedMethodTableTestCase.TMyClass_FindPublishedMethodByName_SixthPublished_HasValue;
var
  Actual: PPublishedMethod;
begin
  Actual := FindPublishedMethodByName(TMyClass, 'SixthPublished');
  CheckNotEqualsPointer(nil, Actual);
end;

initialization
  RegisterTest(TPublishedMethodTableTestCase.Suite);
end.
