program TestPubMethodParams;

{$APPTYPE CONSOLE}

uses
  Classes,
  SysUtils,
  TypInfo,
  HVVMT in 'HVVMT.pas',
  HVPublishedMethodParams in 'HVPublishedMethodParams.pas';

type
{$M+}
  TMyClass = class;
  TOnFour = function(A: array of byte; const B: array of byte; var C: array of byte; out D: array of byte): TComponent of object;
  TOnFive = procedure(Component1: TComponent; var Component2: TComponent; out Component3: TComponent; const Component4: TComponent) of object;
  TOnSix = function(const A: string; var Two: Integer; out Three: TMyClass; Four: PInteger; Five: array of Byte; Six: Integer): string of object;

  TMyClass = class
  private
    FOnFour: TOnFour;
    FOnFive: TOnFive;
    FOnSix: TOnSix;
  published
    function FourthPublished(A: array of byte; const B: array of byte; //
      var C: array of byte; out D: array of byte): TComponent;
    procedure FifthPublished(Component1: TComponent; var Component2: TComponent; //
      out Component3: TComponent; const Component4: TComponent);
    function SixthPublished(const A: string; var Two: Integer; //
      out Three: TMyClass; Four: PInteger; Five: array of Byte; Six: Integer): string;
    property OnFour: TOnFour read FOnFour write FOnFour;
    property OnFive: TOnFive read FOnFive write FOnFive;
    property OnSix: TOnSix read FOnSix write FOnSix;
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

procedure DumpPublishedMethodsParameters(Instance: TObject);
var
  i: Integer;
  List: TStringList;
begin
  List := TStringList.Create;
  try
    GetPublishedMethodsWithParameters(Instance, List);
    for i := 0 to List.Count - 1 do
      Writeln(List[i]);
  finally
    List.Free;
  end;
end;

procedure Test;
var
  MyClass: TMyClass;
begin
  MyClass := TMyClass.Create;
  MyClass.OnFour := MyClass.FourthPublished;
  MyClass.OnFive := MyClass.FifthPublished;
  MyClass.OnSix := MyClass.SixthPublished;
  DumpPublishedMethodsParameters(MyClass);
end;

begin
  Test;
  Readln;

  { Expected output like (all nil values must be nil, all non nil values must be non-nil):

Scanning TMyClass
Published methods in TMyClass
function FourthPublished(A: array of Byte; const B: array of Byte; var C: array of Byte; out D: array of Byte): TComponent;
procedure FifthPublished(Component1: TComponent; var Component2: TComponent; out Component3: TComponent; const Component4: TComponent);
function SixthPublished(const A: string; var Two: Integer; out Three: TMyClass; Four: PInteger; Five: array of Byte; Six: Integer): string;
Scanning TObject
No published methods in TObject

  }
end.
