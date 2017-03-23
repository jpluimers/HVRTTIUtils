unit PublishedFieldDumperUnit;

interface

uses
  Classes,
  HVVMT;

type
  TPublishedFieldAndValue = record
    Field: PPublishedField;
    Value: Pointer;
  end;
  TPublishedFieldAndValuesArray = array of TPublishedFieldAndValue;
  TPublishedFieldDumper = class
  strict private
    FOutput: TStrings;
    FFieldsAndValues: TPublishedFieldAndValuesArray;
    procedure Append(const Line: string);
    procedure AppendHeader(const CurrentClass: TClass);
    procedure AppendField(const FieldIndexInClass: Integer; const AClass: TClass; const Field: PPublishedField; const Value: Pointer = nil);
    function GetOutput: string;
  public
    constructor Create;
    destructor Destroy; override;
    procedure DumpPublishedFields(const AClass: TClass); overload;
    procedure DumpPublishedFields(const Instance: TObject); overload;
    procedure DumpPublishedFields2(const AClass: TClass); overload;
    procedure DumpPublishedFields2(const Instance: TObject); overload;
    property FieldsAndValues: TPublishedFieldAndValuesArray read FFieldsAndValues;
    property Output: string read GetOutput;
  end;

implementation

uses
  SysUtils;

{ TPublishedFieldDumper }

constructor TPublishedFieldDumper.Create;
begin
  inherited Create();
  FOutput := TStringList.Create();
end;

destructor TPublishedFieldDumper.Destroy;
begin
  FOutput.Free();
  FOutput := nil;
  inherited Destroy();
end;

procedure TPublishedFieldDumper.Append(const Line: string);
begin
  FOutput.Add(Line);
end;

procedure TPublishedFieldDumper.AppendHeader(const CurrentClass: TClass);
begin
  Append('Published methods in ' + CurrentClass.ClassName);
end;

procedure TPublishedFieldDumper.AppendField(const FieldIndexInClass: Integer; const AClass: TClass; const Field: PPublishedField; const Value: Pointer = nil);
var
  FieldAndValue: TPublishedFieldAndValue;
  FieldType: TClass;
  NewIndex: Integer;
begin
  FieldType := GetPublishedFieldType(AClass, Field);
  if Assigned(Value) then
    Append(Format('    %s: %s; // Offs=%d, Index=%d, Value=%p', //
            [Field.Name, FieldType.ClassName, Field.Offset, Field.TypeIndex, Pointer(Value)]))
  else
    Append(Format('    %s: %s; // Offs=%d, Index=%d', //
            [Field.Name, FieldType.ClassName, Field.Offset, Field.TypeIndex]));
  NewIndex := Length(FFieldsAndValues);
  SetLength(FFieldsAndValues, NewIndex + 1);
  FieldAndValue.Field := Field;
  FieldAndValue.Value := Value;
  FFieldsAndValues[NewIndex] := FieldAndValue;
end;

procedure DumpPublishedFields(Instance: TObject); overload;
var
  i: Integer;
  Count: Integer;
  Field: PPublishedField;
  AClass: TClass;
  FieldValue: TObject;
  FieldType: TClass;
  ParentClass: string;
begin
  AClass := Instance.ClassType;
  while Assigned(AClass) do
  begin
    Count := GetPublishedFieldCount(AClass);
    if Count > 0 then
    begin
      if AClass.ClassParent <> nil then
        ParentClass := '(' + AClass.ClassParent.ClassName + ')'
      else
        ParentClass := '';
      Writeln('type');
      Writeln('  ', AClass.ClassName, ' = class', ParentClass);
      Writeln('  published');
      Field := GetFirstPublishedField(AClass);
      for i := 0 to Count - 1 do
      begin
        FieldType := GetPublishedFieldType(AClass, Field);
        FieldValue := GetPublishedFieldValue(Instance, Field);
        Writeln(Format('    %s: %s; // Offs=%d, Index=%d, Value=%p', //
          [Field.Name, FieldType.ClassName, Field.Offset, Field.TypeIndex, //
          Pointer(FieldValue)]));
        Field := GetNextPublishedField(AClass, Field);
      end;
      Writeln('  end;');
      Writeln;
    end;
    AClass := AClass.ClassParent;
  end;
end;

procedure TPublishedFieldDumper.DumpPublishedFields(const AClass: TClass);
var
  CurrentClass: TClass;
  i: Integer;
  Field: PPublishedField;
begin
  CurrentClass := AClass;
  while Assigned(CurrentClass) do
  begin
    AppendHeader(CurrentClass);
    for i := 0 to GetPublishedFieldCount(CurrentClass) - 1 do
    begin
      Field := GetPublishedField(CurrentClass, i);
      AppendField(i, CurrentClass, Field);
    end;
    CurrentClass := CurrentClass.ClassParent;
  end;
end;

procedure TPublishedFieldDumper.DumpPublishedFields(const Instance: TObject);
var
  CurrentClass: TClass;
  i: Integer;
  Field: PPublishedField;
  FieldValue: TObject;
begin
  CurrentClass := Instance.ClassType;
  while Assigned(CurrentClass) do
  begin
    AppendHeader(CurrentClass);
    for i := 0 to GetPublishedFieldCount(CurrentClass) - 1 do
    begin
      Field := GetPublishedField(CurrentClass, i);
      FieldValue := GetPublishedFieldValue(Instance, Field);
      AppendField(i, CurrentClass, Field, FieldValue);
    end;
    CurrentClass := CurrentClass.ClassParent;
  end;
end;

procedure TPublishedFieldDumper.DumpPublishedFields2(const AClass: TClass);
var
  CurrentClass: TClass;
  i: Integer;
  Field: PPublishedField;
begin
  CurrentClass := AClass;
  while Assigned(CurrentClass) do
  begin
    AppendHeader(CurrentClass);
    Field := GetFirstPublishedField(CurrentClass);
    for i := 0 to GetPublishedFieldCount(CurrentClass) - 1 do
    begin
      AppendField(i, CurrentClass, Field);
      Field := GetNextPublishedField(CurrentClass, Field);
    end;
    CurrentClass := CurrentClass.ClassParent;
  end;
end;

procedure TPublishedFieldDumper.DumpPublishedFields2(const Instance: TObject);
var
  CurrentClass: TClass;
  i: Integer;
  Field: PPublishedField;
  FieldValue: TObject;
begin
  CurrentClass := Instance.ClassType;
  while Assigned(CurrentClass) do
  begin
    AppendHeader(CurrentClass);
    Field := GetFirstPublishedField(CurrentClass);
    for i := 0 to GetPublishedFieldCount(CurrentClass) - 1 do
    begin
      FieldValue := GetPublishedFieldValue(Instance, Field);
      AppendField(i, CurrentClass, Field, FieldValue);
      Field := GetNextPublishedField(CurrentClass, Field);
    end;
    CurrentClass := CurrentClass.ClassParent;
  end;
end;

function TPublishedFieldDumper.GetOutput: string;
begin
  Result := FOutput.CommaText;
end;

end.
