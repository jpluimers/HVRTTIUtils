unit HVMethodSignature;

interface

uses
  Classes,
  SysUtils,
  TypInfo,
  HVVMT;

type
  TParamLocation = (plUnknown = -1, plEAX = 0, plEDX = 1, plECX = 2, plStack1 = 3, plStackN = $FFFF);
{$IF not Declared(TParamFlag)}
  TParamFlag = (pfVar, pfConst, pfArray, pfAddress, pfReference, pfOut, pfResult);
  TParamFlags = set of TParamFlag;
{$IFEND}
  PMethodParam = ^TMethodParam;

  TMethodParam = record
    // Structures in our units are to make the RTTI easier to use, so use string type and convert data from TSymbolName in the original structures
    Flags: TParamFlags;
    ParamName: string; // same content as System.TypInfo.TTypeData.ParamList[].ParamName: ShortString; so use TSymbolName
    TypeName: string; // same content as System.TypInfo.TTypeInfo.Name: TSymbolName;
    TypeInfo: PTypeInfo;
    Location: TParamLocation;
  end;

  TMethodParamList = array of TMethodParam;
  PMethodSignature = ^TMethodSignature;

  TMethodSignature = record
    // Structures in our units are to make the RTTI easier to use, so use string type and convert data from TSymbolName in the original structures
    Name: string; // same content as TPublishedMethod.Name: TSymbolName
    MethodKind: TMethodKind;
    CallConv: TCallConv;
    HasSignatureRTTI: Boolean;
    Address: Pointer;
    ParamCount: Byte;
    Parameters: TMethodParamList;
    ResultTypeName: string; // same content as System.TypInfo.TTypeInfo.Name: TSymbolName;
    ResultTypeInfo: PTypeInfo;
  end;
  TMethodSignatureList = array of TMethodSignature;

  PPackedShortString = ^TPackedShortString;
  TPackedShortString = string[1];

function SizeOfNameField(const Value: PSymbolName): Integer;
function GetNameField(const Value: PSymbolName): string; overload;
function AfterNameField(const Value: PSymbolName): Pointer;

function SkipBytes(const CurrField: Pointer; const FieldSize: Integer): Pointer; overload; experimental;

function Dereference(const P: PPTypeInfo): PTypeInfo;

function MethodKindString(const MethodKind: TMethodKind): string;

function MethodParamString(const MethodParam: TMethodParam; const ExcoticFlags: Boolean = False): string;

function MethodParametesString(const MethodSignature: TMethodSignature; const SkipSelf: Boolean = True): string;

function MethodSignatureToString(const Name: string; const MethodSignature: TMethodSignature): string; overload;

function MethodSignatureToString(const MethodSignature: TMethodSignature): string; overload;

implementation

{$IF CompilerVersion <= 20} // Delphi 2009 and older
uses
  IntfInfo;
{$IFEND CompilerVersion <= 20} // Delphi 2009 and older

function GetNameField(const Value: PSymbolName): string;
{$IFDEF UNICODE}
var
  Dest: array[0..511] of Char;
{$ENDIF}
begin
{$IFDEF UNICODE}
  SetString(Result, Dest, UTF8ToUnicode(Dest, Length(Dest), PSymbolChar(@Value^[1]), Length(Value^))-1);
{$ELSE}
  Result := SymbolNameToString(Value^);
{$ENDIF}
end;

function SizeOfNameField(const Value: PSymbolName): Integer;
begin
  Result := SizeOf(Value^[0]) + Length(Value^);
end;

function AfterNameField(const Value: PSymbolName): Pointer;
begin
  Result := Value;
  Inc(PSymbolChar(Result), SizeOfNameField(Value));
end;

function SkipBytes(const CurrField: Pointer; const FieldSize: Integer): Pointer;
begin
  Result := PSymbolChar(Currfield) + FieldSize;
end;

function Dereference(const P: PPTypeInfo): PTypeInfo;
begin
  if Assigned(P) then
    Result := P^
  else
    Result := nil;
end;

function MethodKindString(const MethodKind: TMethodKind): string;
begin
  case MethodKind of
    mkSafeProcedure, //
    mkProcedure:
      Result := 'procedure';
    mkSafeFunction, //
    mkFunction:
      Result := 'function';
    mkConstructor:
      Result := 'constructor';
    mkDestructor:
      Result := 'destructor';
    mkClassProcedure:
      Result := 'class procedure';
    mkClassFunction:
      Result := 'class function';
  end;
end;

function MethodParamString(const MethodParam: TMethodParam; const ExcoticFlags: Boolean = False): string;
begin
  if pfVar in MethodParam.Flags then
    Result := 'var '
  else if pfConst in MethodParam.Flags then
    Result := 'const '
  else if pfOut in MethodParam.Flags then
    Result := 'out '
  else
    Result := '';
  if ExcoticFlags then
  begin
    if pfAddress in MethodParam.Flags then
      Result := '{addr} ' + Result;
    if pfReference in MethodParam.Flags then
      Result := '{ref} ' + Result;
{$IF Declared(pfResult)}
    if pfResult in MethodParam.Flags then
      Result := '{result} ' + Result;
{$IFEND Declared(pfResult)}
  end;

  Result := Result + MethodParam.ParamName + ': ';
  if pfArray in MethodParam.Flags then
    Result := Result + 'array of ';
  Result := Result + MethodParam.TypeName;
end;

function MethodParametesString(const MethodSignature: TMethodSignature; const SkipSelf: Boolean = True): string;
var
  i: Integer;
  MethodParam: PMethodParam;
  ParamIndex: Integer;
begin
  Result := '';
  ParamIndex := 0;
  if MethodSignature.HasSignatureRTTI then
    for i := 0 to MethodSignature.ParamCount - 1 do
    begin
      MethodParam := @MethodSignature.Parameters[i];
      // Skip the implicit Self parameter for class and interface methods
      // Note that Self is not included in event types
      if SkipSelf and //
        (i = 0) and //
        (MethodParam.ParamName = 'Self') and //
        (MethodParam.TypeInfo.Kind in [tkInterface, tkClass]) //
        then
          Continue;
{$IF Declared(pfResult)}
      if pfResult in MethodParam.Flags then
        Continue;
{$IFEND Declared(pfResult)}
      if ParamIndex > 0 then
        Result := Result + '; ';
      Result := Result + MethodParamString(MethodParam^);
      Inc(ParamIndex);
    end
  else
    Result := '{??}';
end;

function CallingConventionToString(const CallConv: TCallConv): string;
begin
  case CallConv of
    ccReg:
      Result := 'register';
    ccCdecl:
      Result := 'cdecl';
    ccPascal:
      Result := 'pascal';
    ccStdCall:
      Result := 'stdcall';
    ccSafeCall:
      Result := 'safecall';
  else
    Result := 'TCallConv(' + IntToStr(Ord(CallConv)) + ')';
  end;
end;

function MethodSignatureToString(const Name: string; const MethodSignature: TMethodSignature): string;
begin
  Result := Format('%s %s(%s)', //
    [MethodKindString(MethodSignature.MethodKind), //
    Name, //
    MethodParametesString(MethodSignature)]);
  if MethodSignature.HasSignatureRTTI and (MethodSignature.MethodKind = mkFunction) then
    Result := Result + ': ' + MethodSignature.ResultTypeName;
  Result := Result + ';';
  if MethodSignature.CallConv <> ccReg then
    Result := Result + ' ' + CallingConventionToString(MethodSignature.CallConv) + ';';
end;

function MethodSignatureToString(const MethodSignature: TMethodSignature): string;
begin
  Result := MethodSignatureToString(MethodSignature.Name, MethodSignature);
end;

end.
