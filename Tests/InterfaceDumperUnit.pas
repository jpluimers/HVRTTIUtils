unit InterfaceDumperUnit;

interface

uses
  Classes,
  HVVMT;

type
  PInterfaceEntryArray = array of PInterfaceEntry;
  TInterfaceDumper = class
  strict private
    FOutput: TStrings;
    FInterfaceEntries: PInterfaceEntryArray;
    procedure Append(const Line: string);
    procedure AppendHeader(const CurrentClass: TClass);
    procedure AppendInterfaceEntry(const IndexInClass: Integer; const InterfaceEntry: PInterfaceEntry);
    function GetOutput: string;
  public
    constructor Create;
    destructor Destroy; override;
    procedure DumpInterfaces(const AClass: TClass);
    property InterfaceEntries: PInterfaceEntryArray read FInterfaceEntries;
    property Output: string read GetOutput;
  end;

implementation

uses
  SysUtils;

{ TInterfaceDumper }

constructor TInterfaceDumper.Create;
begin
  inherited Create();
  FOutput := TStringList.Create();
end;

destructor TInterfaceDumper.Destroy;
begin
  FOutput.Free();
  FOutput := nil;
  inherited Destroy();
end;

procedure TInterfaceDumper.Append(const Line: string);
begin
  FOutput.Add(Line);
end;

procedure TInterfaceDumper.AppendHeader(const CurrentClass: TClass);
begin
  Append('Implemented interfaces in ' + CurrentClass.ClassName);
end;

procedure TInterfaceDumper.AppendInterfaceEntry(const IndexInClass: Integer; const InterfaceEntry: PInterfaceEntry);
var
  NewIndex: Integer;
begin
  Append(Format('%d. GUID = %s', [IndexInClass, GUIDToString(InterfaceEntry.IID)]));

  NewIndex := Length(FInterfaceEntries);
  SetLength(FInterfaceEntries, NewIndex + 1);
  FInterfaceEntries[NewIndex] := InterfaceEntry;
end;

procedure TInterfaceDumper.DumpInterfaces(const AClass: TClass);
var
  CurrentClass: TClass;
  i: Integer;
  InterfaceTable: PInterfaceTable;
  InterfaceEntry: PInterfaceEntry;
begin
  CurrentClass := AClass;
  while Assigned(CurrentClass) do
  begin
    InterfaceTable := CurrentClass.GetInterfaceTable;
    if Assigned(InterfaceTable) then
    begin
      AppendHeader(CurrentClass);
      for i := 0 to InterfaceTable.EntryCount - 1 do
      begin
        InterfaceEntry := @InterfaceTable.Entries[i];
        AppendInterfaceEntry(i, InterfaceEntry);
      end;
    end;
    CurrentClass := CurrentClass.ClassParent;
  end;
end;

function TInterfaceDumper.GetOutput: string;
begin
  Result := FOutput.CommaText;
end;

end.
