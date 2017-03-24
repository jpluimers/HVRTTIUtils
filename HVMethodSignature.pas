unit HVMethodSignature;

interface

uses
  Classes,
  SysUtils,
{$IF CompilerVersion <= 20} // Delphi 2009 and older
  IntfInfo,
{$IFEND CompilerVersion >= 21} // Delphi 2010 and newer
  TypInfo,
  HVVMT;

type
  TParamLocation = (plUnknown = -1, plEAX = 0, plEDX = 1, plECX = 2, plStack1 = 3, plStackN = $FFFF);
{$IF CompilerVersion >= 21} // Delphi 2010 and newer
  TCallConv = TypInfo.TCallConv;
{$ELSE}
  TCallConv = IntfInfo.TCallConv;
{$IFEND CompilerVersion >= 21} // Delphi 2010 and newer
{$IF not Declared(TParamFlag)}
  TParamFlag = (pfVar, pfConst, pfArray, pfAddress, pfReference, pfOut, pfResult);
  TParamFlags = set of TParamFlag;
{$IFEND}
  PMethodParam = ^TMethodParam;

  TMethodParam = record
    Flags: TParamFlags;
    ParamName: string; // same type as System.TypInfo.TTypeData.ParamList[].ParamName: ShortString; so use TSymbolName
    TypeName: string; // same type as System.TypInfo.TTypeInfo.Name: TSymbolName;
    TypeInfo: PTypeInfo;
    Location: TParamLocation;
  end;

  TMethodParamList = array of TMethodParam;
  PMethodSignature = ^TMethodSignature;

  TMethodSignature = record
    Name: string; // same type as TPublishedMethod.Name: TSymbolName
    MethodKind: TMethodKind;
    CallConv: TCallConv;
    HasSignatureRTTI: Boolean;
    Address: Pointer;
    ParamCount: Byte;
    Parameters: TMethodParamList;
    ResultTypeName: string; // same type as System.TypInfo.TTypeInfo.Name: TSymbolName;
    ResultTypeInfo: PTypeInfo;
  end;
  TMethodSignatureList = array of TMethodSignature;

  PPackedShortString = ^TPackedShortString;
  TPackedShortString = string[1];

function SizeOfNameField(const Value: PSymbolName): integer;
function GetNameField(const Value: PSymbolName): string; overload;
function AfterNameField(const Value: PSymbolName): pointer;
//function GetAndSkipNameField(const Value: PSymbolName; var Name: string): pointer;

//function Skip(const Value: PPackedShortString; var NextField { : Pointer } ): PSymbolName; overload; // experimental; // TODO -o##jpl : change to type PSymbolName ??
function SkipBytes(const CurrField: Pointer; const FieldSize: Integer): Pointer; overload; // experimental;

function Dereference(const P: PPTypeInfo): PTypeInfo;

function MethodKindString(const MethodKind: TMethodKind): string;

function MethodParamString(const MethodParam: TMethodParam; const ExcoticFlags: Boolean = False): string;

function MethodParametesString(const MethodSignature: TMethodSignature; const SkipSelf: Boolean = True): string;

function MethodSignatureToString(const Name: string; const MethodSignature: TMethodSignature): string; overload;

function MethodSignatureToString(const MethodSignature: TMethodSignature): string; overload;

implementation

function GetNameField(const Value: PSymbolName): string;
{$IFDEF UNICODE}
var
  Dest: array[0..511] of Char;
{$ENDIF}
begin
{$IFDEF UNICODE}
  SetString(Result, Dest, UTF8ToUnicode(Dest, Length(Dest), PAnsiChar(@Value^[1]), Length(Value^))-1);
{$ELSE}
  Result := string(Value^);
{$ENDIF}
end;

function SizeOfNameField(const Value: PSymbolName): integer;
begin
  Result := SizeOf(Value^[0]) + Length(Value^);
end;

function AfterNameField(const Value: PSymbolName): pointer;
begin
  Result := Value;
  Inc(PSymbolChar(Result), SizeOfNameField(Value));
end;

//function GetAndSkipNameField(const Value: PSymbolName; var Name: string): pointer;
//begin
//  Name := GetNameField(Value);
//  Result := AfterNameField(Value);
//end;

//function Skip(const Value: PPackedShortString; var NextField): PSymbolName;
//begin
//  asm
//    int 3
//  end;
//  Result := PSymbolName(Value); // TODO: -o##jpl  change to Value type PSymbolName ??
//  Inc(PSymbolChar(NextField), SizeOf(Char) + Length(Result^) - SizeOf(TPackedShortString)); // TODO -o##jpl : is SizeOf(Char) correct?
//end;

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

  Result := Result + string(MethodParam.ParamName) + ': ';
  if pfArray in MethodParam.Flags then
    Result := Result + 'array of ';
  Result := Result + string(MethodParam.TypeName);
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
    Result := Result + ': ' + string(MethodSignature.ResultTypeName);
  Result := Result + ';';
  if MethodSignature.CallConv <> ccReg then
    Result := Result + ' ' + CallingConventionToString(MethodSignature.CallConv) + ';';
end;

function MethodSignatureToString(const MethodSignature: TMethodSignature): string;
begin
  Result := MethodSignatureToString(MethodSignature.Name, MethodSignature);
end;

end.
