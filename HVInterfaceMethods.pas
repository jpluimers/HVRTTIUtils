unit HVInterfaceMethods;

interface

uses
  TypInfo,
  HVMethodSignature;

type
  // Easy-to-use fixed size structure
  PInterfaceInfo = ^TInterfaceInfo;

  TInterfaceInfo = record
    // Structures in our units are to make the RTTI easier to use, so use string type and convert data from TSymbolName in the original structures
    Name: string;     // same content as System.TypInfo.TTypeInfo.Name: TSymbolName-
    UnitName: string; // same content as System.TypInfo.TTypeData.IntfUnit : TSymbolName
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

type
  // compiler implementation-specific structures, subject to change in future Delphi versions
  PPackedShortString = ^TPackedShortString;
  TPackedShortString = Byte; // string[1]; // Note: String[1] has a size of 2 bytes, and causes issues when adjusting pointers to fields after the name fields...
  PInterfaceParameterRTTI = ^TInterfaceParameterRTTI;

  TInterfaceParameterRTTI = packed record
    Flags: TParamFlags;
    ParamName: TPackedShortString;
    TypeName: TPackedShortString;
    TypeInfo: PPTypeInfo;
{$IF CompilerVersion >= 21} // Delphi 2010 or later has attributes
    // Per-parameter attribute RTTI - skipped for now
    AttributeSize: Word;
//    AttributeData: array[0..AttributeSize] of Byte;
{$IFEND CompilerVersion >= 21} // Delphi 2010 or later has attributes
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
    ResultRTTI: TInterfaceResultRTTI; // only if Kind: TMethodKind has value mkFunction
    // CompilerVersion 21 (Delphi 2010) has attributes, but no AttributeSize field
{$IF CompilerVersion >= 22} // Delphi XE or later have attributes with an AttributeSize field
    // Per-method attribute RTTI - skipped for now
    AttributeSize: Word;
//    AttribData: array[0..AttribSize] of Byte;
{$IFEND CompilerVersion >= 22} // Delphi XE or later have attributes with an AttributeSize field
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
{$IF CompilerVersion >= 22} // Delphi XE or later have attributes with an AttributeSize field
  SizeOfAttribField = SizeOf(word);
{$ELSE}
  SizeOfAttribField = 0;
{$IFEND CompilerVersion >= 22} // Delphi XE or later have attributes with an AttributeSize field
var
  TypeData: PTypeData;
  ExtraData: PExtraInterfaceData;
  i, j: Integer;
  MethodInfo: PMethodSignature;
  MethodRTTI: PInterfaceMethodRTTI;
  ParameterInfo: PMethodParam;
  ParameterRTTI: PInterfaceParameterRTTI;
  InterfaceResultRTTI: PInterfaceResultRTTI;
  AttributeSize: Integer;
  AttributeAdjust: Integer;
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
      ParameterInfo.Flags := TParameterFlags(ParameterRTTI.Flags);
      ParameterInfo.ParamName := GetNameField(@ParameterRTTI.ParamName, ParameterRTTI);
      ParameterInfo.TypeName := GetNameField(@ParameterRTTI.TypeName, ParameterRTTI);
      ParameterInfo.TypeInfo := Dereference(ParameterRTTI.TypeInfo);
      ParameterInfo.Location := plUnknown;
{$IF CompilerVersion >= 22} // Delphi XE or later have attributes with an AttributeSize field
      ParameterRTTI := SkipBytes(@ParameterRTTI.AttributeSize, ParameterRTTI.AttributeSize);
{$ELSE}
      ParameterRTTI := SkipBytes(@ParameterRTTI.TypeInfo, SizeOf(ParameterRTTI.TypeInfo));
{$IFEND CompilerVersion >= 22} // Delphi XE or later have attributes with an AttributeSize field
    end;

    // Function result
    AttributeAdjust := 0;
    if MethodInfo.MethodKind = mkFunction then
    begin
      InterfaceResultRTTI := Pointer(ParameterRTTI);
      MethodInfo.ResultTypeName := GetNameField(@InterfaceResultRTTI.Name, InterfaceResultRTTI);
      MethodInfo.ResultTypeInfo := Dereference(InterfaceResultRTTI.TypeInfo);
      MethodRTTI := SkipBytes(@InterfaceResultRTTI.TypeInfo, SizeOf(InterfaceResultRTTI.TypeInfo) - SizeOf(MethodRTTI^) + SizeOfAttribField);
{$IF CompilerVersion >= 22} // Delphi XE or later have attributes with an AttributeSize field
      AttributeAdjust := -2;
{$IFEND CompilerVersion >= 22} // Delphi XE or later have attributes with an AttributeSize field
    end
    else
    begin
      MethodRTTI := SkipBytes(ParameterRTTI, - SizeOf(MethodRTTI^));
    end;

{$IF CompilerVersion >= 22} // Delphi XE or later have attributes with an AttributeSize field
    AttributeSize := MethodRTTI.AttributeSize;
{$ELSE}
    AttributeSize := 0;
{$IFEND CompilerVersion >= 22} // Delphi XE or later have attributes with an AttributeSize field
    MethodRTTI := SkipBytes(MethodRTTI, SizeOf(MethodRTTI^) + AttributeSize + AttributeAdjust);
  end;
end;

end.
