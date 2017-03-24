unit HVInterfaceMethods;

interface

uses
  TypInfo,
  HVMethodSignature;

type
  // Easy-to-use fixed size structure
  PInterfaceInfo = ^TInterfaceInfo;

  TInterfaceInfo = record
    // the whole point is to make these structures easy to use, so string is better than TSymbolName here - HV
    UnitName: string; // TSymbolName; // same type as System.TypInfo.TTypeData.IntfUnit : TSymbolName
    Name: string;     // TSymbolName; // same type as System.TypInfo.TTypeInfo.Name: TSymbolName-
    Flags: TIntfFlags;
    ParentInterface: PTypeInfo;
    Guid: TGUID;
    MethodCount: Word;
    HasMethodRTTI: Boolean;
    Methods: TMethodSignatureList;
  end;

procedure GetInterfaceInfo(const InterfaceTypeInfo: PTypeInfo; var InterfaceInfo: TInterfaceInfo);

implementation

uses
  HVVMT;

{$IF CompilerVersion < 20} // Older than Delphi 2009
type
  PByte = PAnsiChar; // Redeclare PByte to the only type that supported pointer arithmetics in D2007 and earlier
{$IFEND CompilerVersion < 20}

type
  // compiler implementation-specific structures, subject to change in future Delphi versions
  PPackedShortString = ^TPackedShortString;
  TPackedShortString = byte; // string[1]; // Note: String[1] has a size of 2 bytes, and causes issues when adjusting pointers to fields after the name fields...
  PInterfaceParameterRTTI = ^TInterfaceParameterRTTI;

  TInterfaceParameterRTTI = packed record
    Flags: TParamFlags;
    ParamName: TPackedShortString;
    TypeName: TPackedShortString;
    TypeInfo: PPTypeInfo;
{$IF CompilerVersion >= 20} // Delphi 2009 or later
    // Per-parameter attribute RTTI - skipped for now
    AttribSize: Word;
//    AttribData: array[00..AttribSize] of byte;
{$IFEND CompilerVersion >= 20}
  end;

  PInterfaceResultRTTI = ^TInterfaceResultRTTI;

  TInterfaceResultRTTI = packed record
    Name: TPackedShortString;
    TypeInfo: PPTypeInfo;
  end;

  PInterfaceMethodRTTI = ^TInterfaceMethodRTTI;

  TInterfaceMethodRTTI = packed record
    Name: TPackedShortString;
    Kind: TMethodKind; // mkProcedure or mkFunction
    CallConv: TCallConv;
    ParamCount: Byte; // including Self
    Parameters: packed array [0 .. High(Byte) - 1] of TInterfaceParameterRTTI;
//    case TMethodKind of
//      mkFunction:
    ResultRTTI: TInterfaceResultRTTI;
{$IF CompilerVersion >= 20} // Delphi 2009 or later
    // Per-method attribute RTTI - skipped for now
    AttribSize: Word;
//    AttribData: array[00..AttribSize] of byte;
{$IFEND CompilerVersion >= 20}
  end;

  PExtraInterfaceData = ^TExtraInterfaceData;
  TExtraInterfaceData = packed record
    MethodCount: Word; // #methods
    HasMethodRTTI: Word; // $FFFF if no method RTTI, #methods again if has RTTI
    Methods: TInterfaceMethodRTTI;
//    Methods: packed array [0 .. High(Word) - 1] of TInterfaceMethodRTTI;
  end;
  {
    (MethodCount:1; HasMethodRTTI:1;
    Test:(
    Name: #3, 'F', 'o', 'o',
    Kind: #0,
    CallConv: #0,
    ParamCount: #3,
    Flags: #8,
    ParamName: #4, 'S', 'e', 'l', 'f',
    TypeName: #14, 'I', 'M', 'y', 'M', 'P', 'I', 'n', 't', 'e', 'r', 'f', 'a', 'c', 'e',
    TypeInfo: #24, 'T', 'O', #0,
    Flags: #0,
    Name: #1, 'A',
    TypeName: #7, 'I', 'n', 't', 'e', 'g', 'e', 'r',
  }

function GetNameField(const Value: PSymbolName; var AdjustField {: Pointer}): string; overload;
begin
  Result := GetNameField(Value);
  Pointer(AdjustField) := SkipBytes(Pointer(AdjustField), SizeOfNameField(Value) - SizeOf(TPackedShortString)); // Subtract for the size of TPackedShortString
end;

{$O-}
procedure GetInterfaceInfo(const InterfaceTypeInfo: PTypeInfo; var InterfaceInfo: TInterfaceInfo);
// Converts from raw RTTI structures to user-friendly Info structures
const
{$IF CompilerVersion >= 20} // Delphi 2009 or later
    SizeOfAttribField = SizeOf(word);
{$ELSE}
    SizeOfAttribField = 0;
{$IFEND CompilerVersion >= 20}
var
  TypeData: PTypeData;
  ExtraData: PExtraInterfaceData;
  i, j: Integer;
  MethodInfo: PMethodSignature;
  MethodRTTI: PInterfaceMethodRTTI;
  ParameterInfo: PMethodParam;
  ParameterRTTI: PInterfaceParameterRTTI;
  InterfaceResultRTTI: PInterfaceResultRTTI;
  AttribSize, AttribAdjust: integer;
begin
  Assert(Assigned(InterfaceTypeInfo));
  Assert(InterfaceTypeInfo.Kind = tkInterface);

  Finalize(InterfaceInfo);
  FillChar(InterfaceInfo, SizeOf(InterfaceInfo), 0);

  TypeData := GetTypeData(InterfaceTypeInfo);
  ExtraData := AfterNameField(@TypeData.IntfUnit);

  // Interface
  InterfaceInfo.UnitName := GetNameField(@TypeData.IntfUnit);
  InterfaceInfo.Name := GetNameField(@InterfaceTypeInfo.Name);
  InterfaceInfo.Flags := TypeData.IntfFlags;
  InterfaceInfo.ParentInterface := Dereference(TypeData.IntfParent);
  InterfaceInfo.Guid := TypeData.Guid;
  InterfaceInfo.MethodCount := ExtraData.MethodCount;
  InterfaceInfo.HasMethodRTTI := (ExtraData.HasMethodRTTI = ExtraData.MethodCount);
  if InterfaceInfo.HasMethodRTTI then
    SetLength(InterfaceInfo.Methods, InterfaceInfo.MethodCount)
  else
    SetLength(InterfaceInfo.Methods, 0);

  // Methods
  MethodRTTI := @ExtraData.Methods; // [0];
  for i := Low(InterfaceInfo.Methods) to High(InterfaceInfo.Methods) do
  begin
    MethodInfo := @InterfaceInfo.Methods[i];
    MethodInfo.Name := GetNameField(@MethodRTTI.Name, MethodRTTI);
    MethodInfo.MethodKind := MethodRTTI.Kind;
    MethodInfo.CallConv := MethodRTTI.CallConv;
    MethodInfo.HasSignatureRTTI := True;
    MethodInfo.ParamCount := MethodRTTI.ParamCount;
    SetLength(MethodInfo.Parameters, MethodInfo.ParamCount);

    // Parameters
    ParameterRTTI := @MethodRTTI.Parameters;
    for j := Low(MethodInfo.Parameters) to High(MethodInfo.Parameters) do
    begin
      ParameterInfo := @MethodInfo.Parameters[j];
      ParameterInfo.Flags := ParameterRTTI.Flags;
      ParameterInfo.ParamName := GetNameField(@ParameterRTTI.ParamName, ParameterRTTI);
      ParameterInfo.TypeName := GetNameField(@ParameterRTTI.TypeName, ParameterRTTI);
      ParameterInfo.TypeInfo := Dereference(ParameterRTTI.TypeInfo);
      ParameterInfo.Location := plUnknown;
{$IF CompilerVersion >= 20} // Delphi 2009 or later
      ParameterRTTI := SkipBytes(@ParameterRTTI.AttribSize, ParameterRTTI.AttribSize);
{$ELSE}
      ParameterRTTI := SkipBytes(@ParameterRTTI.TypeInfo, SizeOf(ParameterRTTI.TypeInfo));
{$IFEND CompilerVersion >= 20}
    end;

    // Function result
    AttribAdjust := 0;
    if MethodInfo.MethodKind = mkFunction then
    begin
      InterfaceResultRTTI := Pointer(ParameterRTTI);
      MethodInfo.ResultTypeName := GetNameField(@InterfaceResultRTTI.Name, InterfaceResultRTTI);
      MethodInfo.ResultTypeInfo := Dereference(InterfaceResultRTTI.TypeInfo);
      MethodRTTI := SkipBytes(@InterfaceResultRTTI.TypeInfo, SizeOf(InterfaceResultRTTI.TypeInfo) - SizeOf(MethodRTTI^) + SizeOfAttribField);
{$IF CompilerVersion >= 20} // Delphi 2009 or later
      AttribAdjust := -2;
{$IFEND CompilerVersion >= 20}
    end
    else
    begin
      MethodRTTI := SkipBytes(ParameterRTTI, - SizeOf(MethodRTTI^));
    end;

{$IF CompilerVersion >= 20} // Delphi 2009 or later
    AttribSize := MethodRTTI.AttribSize;
{$ELSE}
    AttribSize := 0;
{$IFEND CompilerVersion >= 20}
    MethodRTTI := SkipBytes(MethodRTTI, SizeOf(MethodRTTI^) + AttribSize + AttribAdjust);

  end;
end;

end.
