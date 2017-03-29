unit HVPublishedMethodParams;

interface

uses
  Classes,
  SysUtils,
  TypInfo,
  HVVMT,
  HVMethodSignature;

function SkipPackedShortString(const Value: PSymbolName): Pointer;

function GetMethodSignature(const Event: PPropInfo): TMethodSignature;

function FindEventProperty(const Instance: TObject; const Code: Pointer): PPropInfo;

function FindEventFor(const Instance: TObject; const Code: Pointer): PPropInfo;

function FindPublishedMethodSignature(const Instance: TObject; const Code: Pointer; var MethodSignature: TMethodSignature): Boolean;

function PublishedMethodToString(const Instance: TObject; const Method: PPublishedMethod): string;

procedure GetPublishedMethodsWithParameters(const Instance: TObject; const List: TStrings);

implementation

{$IF CompilerVersion <= 20} // Delphi 2009 and older
uses
  IntfInfo;
{$IFEND CompilerVersion <= 20} // Delphi 2009 and older

function SkipPackedShortString(const Value: PSymbolName): Pointer;
begin
  Result := Value;
  Inc(PSymbolChar(Result), SizeOf(Value^[0]) + Length(Value^));
end;

function PackedShortString(const Value: PSymbolName; var NextField { : Pointer }): PSymbolName; overload;
begin
  Result := Value;
  PSymbolName(NextField) := Value;
  Inc(PSymbolChar(NextField), SizeOf(Result^[0]) + Length(Result^));
end;

function PackedShortString(var NextField { : Pointer }): PSymbolName; overload;
begin
  Result := PSymbolName(NextField);
  Inc(PSymbolChar(NextField), SizeOf(Result^[0]) + Length(Result^));
end;

function GetMethodSignature(const Event: PPropInfo): TMethodSignature;
(* TParamListRecord is based on this part of System.TypInfo:
   TTypeData = packed record
    case TTypeKind of
     ...
     tkMethod: (
        MethodKind: TMethodKind;
        ParamCount: Byte;
        Parameters: array[0..1023] of Char
       {Parameters: array[1..ParamCount] of
          record
            Flags: TParamFlags;
            ParamName: ShortString;
            TypeName: ShortString;
          end;
        ResultTypeName: ShortString;
        ResultType: ShortString; // only if MethodKind = mkFunction
        ResultTypeRef: PPTypeInfo; // only if MethodKind = mkFunction
        CC: TCallConv; // >= D2010
        ParamTypeRefs: array[1..ParamCount] of PPTypeInfo; // >= 2010
        MethSig: PProcedureSignature; // >= 2010
        MethAttrData: TAttrData}); // >= 2010
*)
type
  PParamListRecord = ^TParamListRecord;

  TParamListRecord = packed record
    Flags: TParamFlags;
    ParamName: { packed } TSymbolName; // Really string[Length(ParamName)]
    TypeName: { packed } TSymbolName; // Really string[Length(TypeName)]
  end;
var
  EventData: PTypeData;
  i: Integer;
  MethodKind: TMethodKind;
  MethodParam: PMethodParam;
  ParamListRecord: PParamListRecord;
begin
  Assert(Assigned(Event) and Assigned(Event.PropType));
  Assert(Event.PropType^.Kind = tkMethod);
  EventData := GetTypeData(Event.PropType^);
  Finalize(Result);
  FillChar(Result, SizeOf(Result), 0);
  Result.CallConv := ccReg; // Educated guess
  Result.HasSignatureRTTI := True; { TODO -o##jpl -cVerify : check if this will give correct signatures }
  MethodKind := EventData.MethodKind;
  Result.MethodKind := MethodKind;
  Result.ParamCount := EventData.ParamCount;
  SetLength(Result.Parameters, Result.ParamCount);
  ParamListRecord := @EventData.ParamList;
  for i := 0 to Result.ParamCount - 1 do
  begin
    MethodParam := @Result.Parameters[i];
    MethodParam.Flags := ParamListRecord.Flags;
    MethodParam.ParamName := SymbolNameToString(PackedShortString(@ParamListRecord.ParamName, ParamListRecord)^);
    MethodParam.TypeName := SymbolNameToString(PackedShortString(ParamListRecord)^);
  end;
  if MethodKind = mkProcedure then
    Result.ResultTypeName := ''
  else
    Result.ResultTypeName := SymbolNameToString(PackedShortString(ParamListRecord)^);
end;

function FindEventProperty(const Instance: TObject; const Code: Pointer): PPropInfo;
// Tries to find an event property that is assigned to a specific code address
var
  Count: Integer;
  PropList: PPropList;
  i: Integer;
  Method: TMethod;
begin
  Assert(Assigned(Instance));
  Count := GetPropList(Instance, PropList);
  if Count > 0 then
    try
      for i := 0 to Count - 1 do
      begin
        Result := PropList^[i];
        if Result.PropType^.Kind = tkMethod then
        begin
          Method := GetMethodProp(Instance, Result);
          if Method.Code = Code then
            Exit;
        end;
      end;
    finally
      FreeMem(PropList);
    end;
  Result := nil;
end;

function FindEventFor(const Instance: TObject; const Code: Pointer): PPropInfo;
// Tries to find an event property that is assigned to a specific code address
// In this instance or in one if its owned components (if the instance is a component)
var
  i: Integer;
  Component: TComponent;
begin
  Result := FindEventProperty(Instance, Code);
  if Assigned(Result) then
    Exit;
  if Instance is TComponent then
  begin
    Component := TComponent(Instance);
    for i := 0 to Component.ComponentCount - 1 do
    begin
      Result := FindEventFor(Component.Components[i], Code);
      if Assigned(Result) then
        Exit;
    end;
  end;
  Result := nil;
  // TODO -oHallvard: Check published fields system
end;

function FindPublishedMethodSignature(const Instance: TObject; const Code: Pointer; var MethodSignature: TMethodSignature): Boolean;
var
  Event: PPropInfo;
begin
  Assert(Assigned(Code));
  Event := FindEventFor(Instance, Code);
  Result := Assigned(Event);
  if Result then
    MethodSignature := GetMethodSignature(Event);
end;

function PublishedMethodToString(const Instance: TObject; const Method: PPublishedMethod): string;
var
  MethodSignature: TMethodSignature;
begin
  if FindPublishedMethodSignature(Instance, Method.Address, MethodSignature) then
    Result := MethodSignatureToString(SymbolNameToString(Method.Name), MethodSignature)
  else
    Result := Format('procedure %s(???);', [Method.Name]);
end;

procedure GetPublishedMethodsWithParameters(const Instance: TObject; const List: TStrings);
var
  i: Integer;
  Method: PPublishedMethod;
  AClass: TClass;
  ClassName: string;
  Count: Integer;
begin
  List.BeginUpdate;
  try
    List.Clear;
    AClass := Instance.ClassType;
    while Assigned(AClass) do
    begin
      ClassName := AClass.ClassName;
      List.Add(Format('Scanning %s', [ClassName]));
      Count := GetPublishedMethodCount(AClass);
      if Count = 0 then
      begin
        List.Add(Format('No published methods in %s', [ClassName]));
      end
      else
      begin
        List.Add(Format('Published methods in %s', [ClassName]));
        Method := GetFirstPublishedMethod(AClass);
        for i := 0 to Count - 1 do
        begin
          List.Add(PublishedMethodToString(Instance, Method));
          Method := GetNextPublishedMethod(AClass, Method);
        end;
      end;
      AClass := AClass.ClassParent;
    end;
  finally
    List.EndUpdate;
  end;
end;

end.
