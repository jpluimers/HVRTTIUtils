program TestPubFieldTable;

{$APPTYPE CONSOLE}

uses
  Classes,
  SysUtils,
  WebSnapObjs,
  TypInfo, // system  webcomp
  HVVMT in 'HVVMT.pas';

procedure DumpPublishedFields(AClass: TClass); overload;
var
  i : integer;
  Count: integer;
  Field: PPublishedField;
  FieldType: TClass;
  ParentClass: string;
begin
  while Assigned(AClass) do
  begin
    Count := GetPublishedFieldCount(AClass);
    if Count > 0 then
    begin
      if AClass.ClassParent <> nil 
      then ParentClass := '('+AClass.ClassParent.ClassName+')'
      else ParentClass := '';
      writeln('type');
      writeln('  ', AClass.ClassName, ' = class', ParentClass);
      writeln('  published');
      Field := GetFirstPublishedField(AClass);
      for i := 0 to Count-1 do
      begin
        FieldType  := GetPublishedFieldType(AClass, Field);
        writeln(Format('    %s: %s; // Offs=%d, Index=%d',
          [Field.Name, FieldType.ClassName, Field.Offset, Field.TypeIndex]));
        Field := GetNextPublishedField(AClass, Field);
      end;
      writeln('  end;');
      writeln;
    end;
    AClass := AClass.ClassParent;
  end;
end;

procedure DumpPublishedFields(Instance: TObject); overload;
var
  i : integer;
  Count: integer;
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
      if AClass.ClassParent <> nil 
      then ParentClass := '('+AClass.ClassParent.ClassName+')'
      else ParentClass := '';
      writeln('type');
      writeln('  ', AClass.ClassName, ' = class', ParentClass);
      writeln('  published');
      Field := GetFirstPublishedField(AClass);
      for i := 0 to Count-1 do
      begin
        FieldType  := GetPublishedFieldType(AClass, Field);
        FieldValue := GetPublishedFieldValue(Instance, Field);
        writeln(Format('    %s: %s; // Offs=%d, Index=%d, Value=%p',
                       [Field.Name, FieldType.ClassName, Field.Offset, Field.TypeIndex,
                       Pointer(FieldValue)]));
        Field := GetNextPublishedField(AClass, Field);
      end;
      writeln('  end;');
      writeln;
    end;
    AClass := AClass.ClassParent;
  end;
end;


type
  {$M+}
  TMyClass = class
  published
    A: TObject;
    LongName: TComponent;
    B: TObject;
    C: TList;
    A2: TObject;
    L2ongName: TComponent;
    B2: TObject;
    C2: TList;
  public
    constructor Create;
  end;

constructor TMyClass.Create;
begin
  inherited Create;
  A := TObject.Create;
  LongName := TComponent.Create(nil);
  B := TStringList.Create;
  C := TList.Create;
end;

procedure Test;
begin
  DumpPublishedFields(TMyClass);
  DumpPublishedFields(TMyClass.Create);
end;

{ TMyClass }

begin
  Test;
  readln;
end.
