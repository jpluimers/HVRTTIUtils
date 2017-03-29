unit HVMethodInfoClasses;

interface

uses
  TypInfo,
  HVMethodSignature,
  HVVMT;

type
  // Easy-to-use fixed size structure
  PClassInfo = ^TClassInfo;

  TClassInfo = record
    UnitName: TSymbolName; // same type as System.TypInfo.TTypeData.UnitName: TSymbolName
    Name: string; // same type as TObject.ClassName: string, so no need for TSymbolName
    ClassType: TClass;
    ParentClass: TClass;
    MethodCount: Word;
    Methods: TMethodSignatureList;
  end;

procedure GetClassInfo(const ClassTypeInfo: PTypeInfo; var ClassInfo: TClassInfo);

implementation

uses
{$IF CompilerVersion <= 20} // Delphi 2009 and older
  IntfInfo,
{$IFEND CompilerVersion <= 20} // Delphi 2009 and older
  ObjAuto,
  SysUtils;

const
{$IF CompilerVersion >= 21} // Delphi 2010 or newer
  MandatoryTReturnInfoVersion = 3;
{$ELSE}
{$IF CompilerVersion = 20} // Delphi 2009
  MandatoryTReturnInfoVersion = 2; // even though Delphi 2010 ObjAuto.pas says "TReturnInfo.Version Must be 2", the Delphi 2010 compiler returns 3
{$ELSE} // Delphi 2007 or older
  MandatoryTReturnInfoVersion = 1;
{$IFEND CompilerVersion = 20} // Delphi 2009
{$IFEND CompilerVersion >= 21} // Delphi 2010 or newer

function ClassOfTypeInfo(const P: PPTypeInfo): TClass;
begin
  Result := nil;
  if Assigned(P) and (P^.Kind = tkClass) then
    Result := GetTypeData(P^).ClassType;
end;

function NextParameter(const Param: PParamInfo): PParamInfo;
begin
  Result := AfterNameField(@Param.Name);
{$IF CompilerVersion >= 21} // Delphi 2010 and newer have `attributes`
  // Skip attribute data
  Inc(PByte(Result), PWord(Result)^);
{$IFEND CompilerVersion >= 21} // Delphi 2010 and newer have `attributes`
end;

procedure GetClassInfo(const ClassTypeInfo: PTypeInfo; var ClassInfo: TClassInfo);
// Converts from raw RTTI structures to user-friendly Info structures
var
  TypeData: PTypeData;
  i, j: Integer;
  MethodInfo: PMethodSignature;
  PublishedMethod: PPublishedMethod;
  MethodParam: PMethodParam;
  ReturnRTTI: PReturnInfo;
  ParameterRTTI: PParamInfo;
  SignatureEnd: Pointer;
begin
  Assert(Assigned(ClassTypeInfo));
  Assert(ClassTypeInfo.Kind = tkClass);

  // Class
  TypeData := GetTypeData(ClassTypeInfo);
  Finalize(ClassInfo);
  FillChar(ClassInfo, SizeOf(ClassInfo), 0);
  ClassInfo.UnitName := TypeData.UnitName;
  ClassInfo.ClassType := TypeData.ClassType;
  ClassInfo.Name := TypeData.ClassType.ClassName;
  ClassInfo.ParentClass := ClassOfTypeInfo(TypeData.ParentInfo);
  ClassInfo.MethodCount := GetPublishedMethodCount(ClassInfo.ClassType);
  SetLength(ClassInfo.Methods, ClassInfo.MethodCount);

  // Methods
  PublishedMethod := GetFirstPublishedMethod(ClassInfo.ClassType);
  for i := Low(ClassInfo.Methods) to High(ClassInfo.Methods) do
  begin
    // Method
    MethodInfo := @ClassInfo.Methods[i];
    MethodInfo.Name := SymbolNameToString(PublishedMethod.Name);
    MethodInfo.Address := PublishedMethod.Address;
    MethodInfo.MethodKind := mkProcedure; // Assume procedure by default

    // Return info and calling convention
    ReturnRTTI := AfterNameField(@PublishedMethod.Name);
    Assert(ReturnRTTI.Version = MandatoryTReturnInfoVersion, Format('ReturnRTTI.Version %d does not match expected version %d', [ReturnRTTI.Version, MandatoryTReturnInfoVersion]));
    SignatureEnd := Pointer(Cardinal(PublishedMethod) //
      + PublishedMethod.Size);
    if Cardinal(ReturnRTTI) >= Cardinal(SignatureEnd) then
    begin
      MethodInfo.CallConv := ccReg; // Assume register calling convention
      MethodInfo.HasSignatureRTTI := False;
    end
    else
    begin
      MethodInfo.ResultTypeInfo := Dereference(PPTypeInfo(ReturnRTTI.ReturnType));
      if Assigned(MethodInfo.ResultTypeInfo) then
      begin
        MethodInfo.MethodKind := mkFunction;
        MethodInfo.ResultTypeName := SymbolNameToString(MethodInfo.ResultTypeInfo.Name);
      end
      else
        MethodInfo.MethodKind := mkProcedure;
{$IF CompilerVersion <= 25} // Delphi XE4 and older have TCallingConvention as a separate type, but ordinally compatible
      MethodInfo.CallConv := TCallConv(ReturnRTTI.CallingConvention);
{$ELSE}
      MethodInfo.CallConv := ReturnRTTI.CallingConvention;
{$IFEND CompilerVersion <= 25} // Delphi XE4 and older have TCallingConvention as a separate type, but ordinally compatible
      MethodInfo.HasSignatureRTTI := True;
      // Count parameters

{$IF CompilerVersion >= 21} // Delphi 2010 and newer have ReturnRTTI.ParamCount; use it:
      MethodInfo.ParamCount := ReturnRTTI.ParamCount;
{$ELSE}
      ParameterRTTI := Pointer(Cardinal(ReturnRTTI) + SizeOf(ReturnRTTI^));
      MethodInfo.ParamCount := 0;
      while Cardinal(ParameterRTTI) < Cardinal(SignatureEnd) do
      begin
        Inc(MethodInfo.ParamCount); // Assume less than 255 parameters ;)!
        ParameterRTTI := NextParameter(ParameterRTTI);
      end;
{$IFEND CompilerVersion >= 21} // Delphi 2010 and newer have ReturnRTTI.ParamCount; use it:
      // Read parameter info
      ParameterRTTI := Pointer(Cardinal(ReturnRTTI) + SizeOf(ReturnRTTI^));
      SetLength(MethodInfo.Parameters, MethodInfo.ParamCount);
      for j := Low(MethodInfo.Parameters) to High(MethodInfo.Parameters) do
      begin
        MethodParam := @MethodInfo.Parameters[j];
{$IF CompilerVersion <= 22} // Delphi XE and older have TCallingConvention as a separate type, but ordinally compatible
        MethodParam.Flags := TypInfo.TParamFlags(ParameterRTTI.Flags);
{$ELSE}
        MethodParam.Flags := ParameterRTTI.Flags;
{$IFEND CompilerVersion <= 22} // Delphi XE and older have TCallingConvention as a separate type, but ordinally compatible
        if pfResult in ParameterRTTI.Flags then
          MethodParam.ParamName := 'Result'
        else
          MethodParam.ParamName := SymbolNameToString(ParameterRTTI.Name);
        MethodParam.TypeInfo := Dereference(PPTypeInfo(ParameterRTTI.ParamType));
        if Assigned(MethodParam.TypeInfo) then
          MethodParam.TypeName := SymbolNameToString(MethodParam.TypeInfo.Name);
        MethodParam.Location := TParamLocation(ParameterRTTI.Access);
        ParameterRTTI := NextParameter(ParameterRTTI);
      end;
    end;
    PublishedMethod := GetNextPublishedMethod(ClassInfo.ClassType, //
      PublishedMethod);
  end;
end;

{$WARN SYMBOL_DEPRECATED OFF}

{$IFOPT C+} // If asserts are on
{$IF Declared(TCallingConvention)}

const
  LowTCallingConvention = Ord(Low(TCallingConvention));
  LowTCallConv = Ord(Low(TCallConv));
  HighTCallingConvention = Ord(High(TCallingConvention));
  HighTCallConv = Ord(High(TCallConv));
// Todo -o##jpl : Find a way to verify that both the TParamFlags types are the same for Delphi versions where they do not indirect:
// ObjAuto:   TParamFlags = set of (pfVar, pfConst, pfArray, pfAddress, pfReference, pfOut, pfResult);
// TypInfo:   TParamFlag = (pfVar, pfConst, pfArray, pfAddress, pfReference, pfOut);
// TypInfo:   TParamFlags = set of TParamFlag;
initialization
  Assert(LowTCallingConvention = LowTCallConv);
  Assert(HighTCallingConvention = HighTCallConv);
finalization

{$IFEND Declared(TCallingConvention)}
{$ENDIF C+} // If asserts are on

end.
