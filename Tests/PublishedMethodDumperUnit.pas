unit PublishedMethodDumperUnit;

interface

uses
  Classes,
  HVVMT;

type
  PPublishedMethodArray = array of PPublishedMethod;
  TPublishedMethodDumper = class
  strict private
    FOutput: TStrings;
    FMethods: PPublishedMethodArray;
    procedure Append(const Line: string);
    procedure AppendHeader(const CurrentClass: TClass);
    procedure AppendMethod(const MethodIndexInClass: Integer; const Method: PPublishedMethod);
    function GetOutput: string;
  public
    constructor Create;
    destructor Destroy; override;
    procedure DumpPublishedMethods(const AClass: TClass);
    procedure DumpPublishedMethods2(const AClass: TClass);
    property Methods: PPublishedMethodArray read FMethods;
    property Output: string read GetOutput;
  end;

implementation

uses
  SysUtils;

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

end.
