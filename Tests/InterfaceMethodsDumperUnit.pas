unit InterfaceMethodsDumperUnit;

interface

uses
  Classes,
  TypInfo,
  HVMethodSignature,
  HVInterfaceMethods;

type
  PInterfaceEntryArray = array of PInterfaceEntry;
  TInterfaceMethodsDumper = class
  strict private
    FOutput: TStrings;
    FInterfaceEntries: PInterfaceEntryArray;
    FTMethodSignatureList: TMethodSignatureList;
    procedure Append(const Line: string);
    procedure AppendHeader(const InterfaceTypeInfo: PTypeInfo; const InterfaceInfo: TInterfaceInfo);
    function GetOutput: string;
  public
    constructor Create;
    destructor Destroy; override;
    procedure DumpInterface(const InterfaceTypeInfo: PTypeInfo);
    procedure DumpSimpleInterface(const InterfaceTypeInfo: PTypeInfo);
    property InterfaceEntries: PInterfaceEntryArray read FInterfaceEntries;
    property MethodSignatureList: TMethodSignatureList read FTMethodSignatureList;
    property Output: string read GetOutput;
  end;

implementation

uses
  SysUtils;

{ TInterfaceMethodsDumper }

constructor TInterfaceMethodsDumper.Create;
begin
  inherited Create();
  FOutput := TStringList.Create();
end;

destructor TInterfaceMethodsDumper.Destroy;
begin
  FOutput.Free();
  FOutput := nil;
  inherited Destroy();
end;

procedure TInterfaceMethodsDumper.Append(const Line: string);
begin
  FOutput.Add(Line);
end;

procedure TInterfaceMethodsDumper.AppendHeader(const InterfaceTypeInfo: PTypeInfo; const InterfaceInfo: TInterfaceInfo);
var
  InterfaceFlags: TIntfFlags;
  Line: string;
  ParentInterface: PTypeInfo;
begin
  Append(Format('unit %s;', [InterfaceInfo.UnitName]));
  Append('type');
  Line := Format('  %s = ', [InterfaceTypeInfo.Name]);
  InterfaceFlags := InterfaceInfo.Flags;
  if not(ifDispInterface in InterfaceFlags) then
  begin
    Line := Line + 'dispinterface';
  end
  else
  begin
    Line := Line + 'interface';
    ParentInterface := InterfaceInfo.ParentInterface;
    if Assigned(ParentInterface) then
      Line := Format('%s (%s)', [Line, ParentInterface^.Name]);
  end;
  Append(Line);
  if ifHasGuid in InterfaceFlags then
    Append(Format('    [''%s'']', [GuidToString(InterfaceInfo.Guid)]));
end;

procedure TInterfaceMethodsDumper.DumpInterface(const InterfaceTypeInfo: PTypeInfo);
var
  InterfaceInfo: TInterfaceInfo;
  i: Integer;
begin
  Assert(Assigned(InterfaceTypeInfo));
  Assert(InterfaceTypeInfo.Kind = tkInterface);

  GetInterfaceInfo(InterfaceTypeInfo, InterfaceInfo);
  AppendHeader(InterfaceTypeInfo, InterfaceInfo);

  if InterfaceInfo.HasMethodRTTI then
  begin
    for i := Low(InterfaceInfo.Methods) to High(InterfaceInfo.Methods) do
    begin
      Append('    ' + MethodSignatureToString(InterfaceInfo.Methods[i]))
    end
  end
  else
  begin
    for i := 1 to InterfaceInfo.MethodCount do
    begin
      Append(Format('    procedure UnknownName%d;', [i]));
    end;
  end;
  Append('  end;');
  Append('');
end;

procedure TInterfaceMethodsDumper.DumpSimpleInterface(const InterfaceTypeInfo: PTypeInfo);
var
  InterfaceInfo: TInterfaceInfo;
  i: Integer;
begin
  Assert(Assigned(InterfaceTypeInfo));
  Assert(InterfaceTypeInfo.Kind = tkInterface);

  GetInterfaceInfo(InterfaceTypeInfo, InterfaceInfo);
  AppendHeader(InterfaceTypeInfo, InterfaceInfo);


  for i := 1 to InterfaceInfo.MethodCount do
    Append(Format('    procedure UnknownName%d;', [i]));
  Append('  end;');
  Append('');
end;

function TInterfaceMethodsDumper.GetOutput: string;
begin
  Result := FOutput.CommaText;
end;

end.
