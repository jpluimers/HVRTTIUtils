unit HVInterfaceMethods;

interface

uses
  TypInfo,
{$IF CompilerVersion <= 23}  // Delphi XE3 or older
  HVVMT,
{$IFEND CompilerVersion <= 23}  // Delphi XE3 or older
  HVMethodSignature;

type
  // Easy-to-use fixed size structure
  PInterfaceInfo = ^TInterfaceInfo;

  TInterfaceInfo = record
    UnitName: TSymbolName; // same type as System.TypInfo.TTypeData.IntfUnit : TSymbolName
    Name: TSymbolName; // same type as System.TypInfo.TTypeInfo.Name: TSymbolName
    Flags: TIntfFlags;
    ParentInterface: PTypeInfo;
    Guid: TGUID;
    MethodCount: Word;
    HasMethodRTTI: Boolean;
    Methods: TMethodSignatureList;
  end;

procedure GetInterfaceInfo(const InterfaceTypeInfo: PTypeInfo; var InterfaceInfo: TInterfaceInfo);

implementation

type
  // compiler implementation-specific structures, subject to change in future Delphi versions
  PPackedShortString = ^TPackedShortString;
  TPackedShortString = string[1];
  PInterfaceParameterRTTI = ^TInterfaceParameterRTTI;

  TInterfaceParameterRTTI = packed record
    Flags: TParamFlags;
    ParamName: TPackedShortString;
    TypeName: TPackedShortString;
    TypeInfo: PPTypeInfo;
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
    case TMethodKind of
      mkFunction:
        (Result: TInterfaceResultRTTI);
  end;

  PExtraInterfaceData = ^TExtraInterfaceData;

  TExtraInterfaceData = packed record
    MethodCount: Word; // #methods
    HasMethodRTTI: Word; // $FFFF if no method RTTI, #methods again if has RTTI
    Methods: packed array [0 .. High(Word) - 1] of TInterfaceMethodRTTI;
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

procedure GetInterfaceInfo(const InterfaceTypeInfo: PTypeInfo; var InterfaceInfo: TInterfaceInfo);
// Converts from raw RTTI structures to user-friendly Info structures
var
  TypeData: PTypeData;
  ExtraData: PExtraInterfaceData;
  i, j: Integer;
  MethodInfo: PMethodSignature;
  MethodRTTI: PInterfaceMethodRTTI;
  ParameterInfo: PMethodParam;
  ParameterRTTI: PInterfaceParameterRTTI;
  InterfaceResultRTTI: PInterfaceResultRTTI;
begin
  Assert(Assigned(InterfaceTypeInfo));
  Assert(InterfaceTypeInfo.Kind = tkInterface);

  Finalize(InterfaceInfo);
  FillChar(InterfaceInfo, SizeOf(InterfaceInfo), 0);

  TypeData := GetTypeData(InterfaceTypeInfo);
  ExtraData := Skip(@TypeData.IntfUnit);

  // Interface
  InterfaceInfo.UnitName := TypeData.IntfUnit;
  InterfaceInfo.Name := InterfaceTypeInfo.Name;
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
  MethodRTTI := @ExtraData.Methods[0];
  for i := Low(InterfaceInfo.Methods) to High(InterfaceInfo.Methods) do
  begin
    MethodInfo := @InterfaceInfo.Methods[i];
    MethodInfo.Name := Skip(@MethodRTTI.Name, MethodRTTI)^;
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
      ParameterInfo.ParamName := Skip(@ParameterRTTI.ParamName, ParameterRTTI)^;
      ParameterInfo.TypeName := Skip(@ParameterRTTI.TypeName, ParameterRTTI)^;
      ParameterInfo.TypeInfo := Dereference(ParameterRTTI.TypeInfo);
      ParameterInfo.Location := plUnknown;
      ParameterRTTI := Skip(@ParameterRTTI.TypeInfo, SizeOf(ParameterRTTI.TypeInfo));
    end;

    // Function result
    if MethodInfo.MethodKind = mkFunction then
    begin
      InterfaceResultRTTI := Pointer(ParameterRTTI);
      MethodInfo.ResultTypeName := Skip(@InterfaceResultRTTI.Name, InterfaceResultRTTI)^;
      MethodInfo.ResultTypeInfo := Dereference(InterfaceResultRTTI.TypeInfo);
      MethodRTTI := Skip(@InterfaceResultRTTI.TypeInfo, SizeOf(InterfaceResultRTTI.TypeInfo));
    end
    else
      MethodRTTI := Pointer(ParameterRTTI);
  end;
end;

end.
