program TestMorePubMethodParams;

{$APPTYPE CONSOLE}

uses
  Classes,
  SysUtils,
  TypInfo,
  ObjAuto,
{$IF CompilerVersion < 26} // Older than Delphi XE5
  WebSnapObjs,
{$IFEND CompilerVersion < 26} // Older than Delphi XE5
  HVVMT in 'HVVMT.pas',
  IntfInfo,
  HVPublishedMethodParams in 'HVPublishedMethodParams.pas',
  HVInterfaceMethods in 'HVInterfaceMethods.pas',
  HVMethodSignature in 'HVMethodSignature.pas',
  HVMethodInfoClasses in 'HVMethodInfoClasses.pas';

procedure DumpClass(ClassTypeInfo: PTypeInfo);
var
  ClassInfo: TClassInfo;
  i: Integer;
begin
  GetClassInfo(ClassTypeInfo, ClassInfo);
  Writeln('unit ', ClassInfo.UnitName, ';');
  Writeln('type');
  Write('  ', ClassInfo.Name, ' = ');
  Write('class');
  if Assigned(ClassInfo.ParentClass) then
    Write(' (', ClassInfo.ParentClass.ClassName, ')');
  Writeln;
  for i := Low(ClassInfo.Methods) to High(ClassInfo.Methods) do
    Writeln('    ', MethodSignatureToString(ClassInfo.Methods[i]));
  Writeln('  end;');
  Writeln;
end;

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

{.$WARN SYMBOL_PLATFORM OFF}

procedure Test;
begin
  DumpClass(TypeInfo(TMyClass));
end;

procedure TestCall;
var
  MyClass: TMyClass;
  MethodInfo: PMethodInfoHeader;
begin
  MyClass := TMyClass.Create;
  MethodInfo := GetMethodInfo(MyClass, 'Test2');
  if Assigned(MethodInfo) then
    Writeln(ObjectInvoke(MyClass, MethodInfo, [], ['Hallvard']));
  MethodInfo := GetMethodInfo(MyClass, 'Test1');
  if Assigned(MethodInfo) then
    Writeln(ObjectInvoke(MyClass, MethodInfo, [], ['Hallvard']));
end;

begin
  try
    Test;
  except
    on E: Exception do
      Writeln(E.Message);
  end;
  Readln;

  { Not sure this is the Expected output:

RTTI for the published method "Test1" of class "TMyClass" has 47 extra bytes of unknown data!

  }
end.
