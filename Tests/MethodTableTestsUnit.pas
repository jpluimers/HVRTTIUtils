unit MethodTableTestsUnit;

// From TestMethodTable

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
// public // because of {$M-}
    procedure FirstDynamic; override;
  published
    procedure SecondDynamic; override;
    class procedure ThirdDynamic; override;
    class procedure FourthDynamic; override;
  end;

  TMyDescendent2 = class(TMyClass)
  end;

type
  TMethodTableTestCase = class(TTestCase)
  published
    procedure TPropFixup_DumpPublishedMethods2_ValuesOk;
    procedure TMyDescendent_DumpPublishedMethods_Equals_DumpPublishedMethods2;
    procedure TMyDescendent_FindPublishedMethodByAddr_FirstDynamic_HasValue;
    procedure TMyDescendent_FindPublishedMethodByAddr_From_FindPublishedMethodByAddr_ThirdPublished_HasValue;
    procedure TMyDescendent_FindPublishedMethodByAddr_nil_HasNoValue;
    procedure TMyDescendent_FindPublishedMethodByAddr_ThirdMethod_HasValue;
    procedure TMyDescendent_FindPublishedMethodByName_NotThere_HasNoValue;
    procedure TMyDescendent_FindPublishedMethodByName_ThirdPublished_HasValue;
    procedure TMyDescendent_GetPropInfo_A_HasValue;
  end;

implementation

uses
  TypInfo,
  HVVMT,
  AbstractTestHelperUnit,
  PublishedMethodDumperUnit;

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

{ TMethodTableTestCase }

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
  CheckEquals('MakeGlobalReference', string(Method.Name));
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

procedure TMethodTableTestCase.TMyDescendent_FindPublishedMethodByAddr_FirstDynamic_HasValue;
var
  Actual: PPublishedMethod;
begin
  Actual := FindPublishedMethodByAddr(TMyDescendent, @TMyDescendent.FirstDynamic);
  CheckNotEqualsPointer(nil, Actual);
end;

procedure TMethodTableTestCase.TMyDescendent_FindPublishedMethodByAddr_From_FindPublishedMethodByAddr_ThirdPublished_HasValue;
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

procedure TMethodTableTestCase.TMyDescendent_FindPublishedMethodByName_ThirdPublished_HasValue;
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

initialization
  RegisterTest(TMethodTableTestCase.Suite);
end.
