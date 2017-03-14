program TestPubFieldTable;

{$APPTYPE CONSOLE}

uses
  Classes,
  SysUtils,
{$IF CompilerVersion < 26} // Older than Delphi XE5
  WebSnapObjs,
{$IFEND CompilerVersion < 26} // Older than Delphi XE5
  TypInfo, // system  webcomp
  HVVMT in 'HVVMT.pas';

procedure DumpPublishedFields(AClass: TClass); overload;
var
  i: Integer;
  Count: Integer;
  Field: PPublishedField;
  FieldType: TClass;
  ParentClass: string;
begin
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
        Writeln(Format('    %s: %s; // Offs=%d, Index=%d', //
          [Field.Name, FieldType.ClassName, Field.Offset, Field.TypeIndex]));
        Field := GetNextPublishedField(AClass, Field);
      end;
      Writeln('  end;');
      Writeln;
    end;
    AClass := AClass.ClassParent;
  end;
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
  Readln;

  { Expected output like (all nil values must be nil, all non nil values must be non-nil):

type
  TMyClass = class(TObject)
  published
    A: TObject; // Offs=4, Index=0
    LongName: TComponent; // Offs=8, Index=1
    B: TObject; // Offs=12, Index=0
    C: TList; // Offs=16, Index=2
    A2: TObject; // Offs=20, Index=0
    L2ongName: TComponent; // Offs=24, Index=1
    B2: TObject; // Offs=28, Index=0
    C2: TList; // Offs=32, Index=2
  end;

type
  TMyClass = class(TObject)
  published
    A: TObject; // Offs=4, Index=0, Value=00850DB0
    LongName: TComponent; // Offs=8, Index=1, Value=008667B0
    B: TObject; // Offs=12, Index=0, Value=0086DA20
    C: TList; // Offs=16, Index=2, Value=00849D40
    A2: TObject; // Offs=20, Index=0, Value=00000000
    L2ongName: TComponent; // Offs=24, Index=1, Value=00000000
    B2: TObject; // Offs=28, Index=0, Value=00000000
    C2: TList; // Offs=32, Index=2, Value=00000000
  end;

  }
end.
