unit PolymorphicPublishedMethodsTestsUnit;

// from TestPolyPub

interface

uses
  TestFramework;

type
  TPolymorphicPublishedMethodsTestCase = class(TTestCase)
  private
    function CallPolymporphicDirect(const Subject: TObject): string;
    function CallPolymporphicIndirect(const Subject: TObject): string;
  published
    procedure TChild_Polymorphic_Direct_Matches;
    procedure TChild_Polymorphic_Indirect_Matches;
    procedure TOther_Polymorphic_Direct_Matches;
    procedure TOther_Polymorphic_Indirect_Matches;
    procedure TParent_Polymorphic_Direct_Matches;
    procedure TParent_Polymorphic_Indirect_Matches;
  end;

implementation

uses
  Contnrs,
  SysUtils;

type
{$M+}
  TParent = class
  published
    function Polymorphic(const S: string): string;
  end;

  TChild = class
  published
    function Polymorphic(const S: string): string;
  end;

  TOther = class
  published
    function Polymorphic(const S: string): string;
  end;

function TParent.Polymorphic(const S: string): string;
begin
  Result := 'TParent.Polymorphic: ' + S;
end;

function TChild.Polymorphic(const S: string): string;
begin
  Result := 'TChild.Polymorphic: ' + S;
end;

function TOther.Polymorphic(const S: string): string;
begin
  Result := 'TOther.Polymorphic: ' + S;
end;

type
  TPolymorphic = function(Self: TObject; const S: string): string;

{ TPolymorphicPublishedMethodsTestCase }

function TPolymorphicPublishedMethodsTestCase.CallPolymporphicDirect(const Subject: TObject): string;
begin
  try
    Result := TPolymorphic(Subject.MethodAddress('Polymorphic'))(Subject, 'Direct');
  finally
    Subject.Free();
  end;
end;

function TPolymorphicPublishedMethodsTestCase.CallPolymporphicIndirect(const Subject: TObject): string;
var
  Polymorphic: function(Self: TObject; const S: string): string;
begin
  try
    Polymorphic := Subject.MethodAddress('Polymorphic');
    Check(Assigned(Polymorphic));
    Result := Polymorphic(Subject, 'Indirect');
  finally
    Subject.Free();
  end;
end;

procedure TPolymorphicPublishedMethodsTestCase.TChild_Polymorphic_Direct_Matches;
var
  Actual: string;
begin
  Actual := CallPolymporphicDirect(TChild.Create());
  CheckEquals('TChild.Polymorphic: Direct', Actual);
end;

procedure TPolymorphicPublishedMethodsTestCase.TChild_Polymorphic_Indirect_Matches;
var
  Actual: string;
begin
  Actual := CallPolymporphicIndirect(TChild.Create());
  CheckEquals('TChild.Polymorphic: Indirect', Actual);
end;

procedure TPolymorphicPublishedMethodsTestCase.TOther_Polymorphic_Direct_Matches;
var
  Actual: string;
begin
  Actual := CallPolymporphicDirect(TOther.Create());
  CheckEquals('TOther.Polymorphic: Direct', Actual);
end;

procedure TPolymorphicPublishedMethodsTestCase.TOther_Polymorphic_Indirect_Matches;
var
  Actual: string;
begin
  Actual := CallPolymporphicIndirect(TOther.Create());
  CheckEquals('TOther.Polymorphic: Indirect', Actual);
end;

procedure TPolymorphicPublishedMethodsTestCase.TParent_Polymorphic_Direct_Matches;
var
  Actual: string;
begin
  Actual := CallPolymporphicDirect(TParent.Create());
  CheckEquals('TParent.Polymorphic: Direct', Actual);
end;

procedure TPolymorphicPublishedMethodsTestCase.TParent_Polymorphic_Indirect_Matches;
var
  Actual: string;
begin
  Actual := CallPolymporphicIndirect(TParent.Create());
  CheckEquals('TParent.Polymorphic: Indirect', Actual);
end;

initialization
  RegisterTest(TPolymorphicPublishedMethodsTestCase.Suite);
end.
