unit HVVMT;
// Written by Hallvard Vassbotn, 2006 - http://hallvards.blogspot.com/
// Currently assumes D7-D2006 (*probably* works in D5 and D6)

interface

uses
{$IF CompilerVersion <= 20} // Delphi 2009 and older
  IntfInfo,
{$IFEND CompilerVersion <= 20} // Delphi 2009 and older
  TypInfo;

type
  // For testing / typecasting at debug time
  PAnsiChars = ^TAnsiChars;
  TAnsiChars = array [0..4095] of AnsiChar;

type
{$IFDEF UNICODE}
  TSymbolChar = AnsiChar;
  PSymbolChar = PAnsiChar;
{$ELSE}
  TSymbolChar = Char;
  PSymbolChar = PChar;
{$ENDIF UNICODE}
{$IF CompilerVersion <= 23}  // Delphi XE3 or older
  TSymbolNameBase = string[255];
  TSymbolName = type TSymbolNameBase;
{$ELSE}
  TSymbolNameBase = TypInfo.TSymbolNameBase;
  TSymbolName = TypInfo.TSymbolNameBase;
{$IFEND CompilerVersion <= 23}  // Delphi XE3 or older
  PSymbolName = ^TSymbolName;
{$IF CompilerVersion >= 21} // Delphi 2010 and newer
  TCallConv = TypInfo.TCallConv;
{$ELSE}
  TCallConv = IntfInfo.TCallConv;
{$IFEND CompilerVersion >= 21} // Delphi 2010 and newer
  PObject = ^TObject;
  PClass = ^TClass;

  // TObject virtual methods' signatures
{$IFDEF AUTOREFCOUNT} // In XE6, but only mobile platforms? (before?)
  P__ObjAddRef = function (Self: TObject): Integer;
  P__ObjRelease = function (Self: TObject): Integer;
{$ENDIF}
{$IF CompilerVersion >= 20} // Delphi 2009 or newer
  PEquals = function (Self: TObject; Obj: TObject): Boolean;
  PGetHashCode = function (Self: TObject): Integer;
  PToString = function (Self: TObject): string;
{$IFEND CompilerVersion >= 20} // Delphi 2009 or newer
  PSafeCallException = function(Self: TObject; ExceptObject: TObject; ExceptAddr: Pointer): HResult;
  PAfterConstruction = procedure(Self: TObject);
  PBeforeDestruction = procedure(Self: TObject);
  PDispatch = procedure(Self: TObject; var Message);
  PDefaultHandler = procedure(Self: TObject; var Message);
  PNewInstance = function(Self: TClass): TObject;
  PFreeInstance = procedure(Self: TObject);
  PDestroy = procedure(Self: TObject; OuterMost: ShortInt);

  // Dynamic methods table
  TDMTIndex = Smallint;
  PDmtIndices = ^TDmtIndices;
  TDmtIndices = array [0 .. High(Word) - 1] of TDMTIndex;
  PDmtMethods = ^TDmtMethods;
  TDmtMethods = array [0 .. High(Word) - 1] of Pointer;
  PDmt = ^TDmt;

  TDmt = packed record
    Count: Word;
    Indicies: TDmtIndices; // really [0..Count-1]
    Methods: TDmtMethods; // really [0..Count-1]
  end;

  // Published methods table
  PPublishedMethod = ^TPublishedMethod;

  TPublishedMethod = packed record
    Size: Word;
    Address: Pointer;
    Name: { packed } TSymbolName; // same type as System.TypInfo.TVmtMethodEntry.Name: TSymbolName;
  end;

const // MandatoryTPublishedMethodTailVersion seems to follow MandatoryTReturnInfoVersion
{$IF CompilerVersion >= 21} // Delphi 2010 or newer
  MandatoryTPublishedMethodTailVersion = 3;
{$ELSE}
{$IF CompilerVersion = 20} // Delphi 2009
  MandatoryTPublishedMethodTailVersion = 2;
{$ELSE} // Delphi 2007 or older
  MandatoryTPublishedMethodTailVersion = 1;
{$IFEND CompilerVersion = 20} // Delphi 2009
{$IFEND CompilerVersion >= 21} // Delphi 2010 or newer

type
  // Depending on the Delphi version, TPublishedMethod is followed by TPublishedMethodTail
  PPublishedMethodTail = ^TPublishedMethodTail;

  //1 The first part looks very similar to System.ObjAuto.TReturnInfo: could it be the same?
  TPublishedMethodTail = packed record
    Version: Byte; // =3
    CallingConvention: TCallConv;
    ResultType: PPTypeInfo; // nil for procedures
    ParameterOffset: Word; // total size of data needed for stack parameters + 8 (ret-addr + pushed EBP)
{$IF CompilerVersion >= 21} // Delphi 2010 and newer
    ParameterCount: Byte;
{$IFEND CompilerVersion >= 21} // Delphi 2010 and newer
   {Parameters: array[1..ParameterCount] of TVmtMethodParam;
    AttrData: TAttrData;}
  end;

  PPublishedMethodParameter = ^TPublishedMethodParameter;

  // Depending on the Delphi version, TPublishedMethodTail is followed by TPublishedMethodParameters
  TPublishedMethodParameter = packed record
    Flags: Byte;
    ParameterType: PPTypeInfo;
    ParameterOffset: Word; // TYpInfo wrongly indicates type Byte; // Parameter location: 0..2 for reg, >=8 for stack
    Name: { packed } TSymbolName; // same type as System.TypInfo.TVmtMethodParam.Name: TSymbolName;
//    Padding: Byte;
  end;

  TPublishedMethodParameters = array of TPublishedMethodParameter;

{$IF CompilerVersion >= 21} // Delphi 2010 and newer
  PAttribute = ^TAttribute;

  TAttribute = packed record
    AttributeType: PPTypeInfo;
    AttributeConstructor: Pointer;
    ArgumentsLength: Word;
    ArgumentsData: array[1..High(Word) {ArgumentsLength - 2}] of Byte;
  end;

  TAttributes = array of TAttribute;

  // Depending on the Delphi version, TPublishedMethodParameters and TPublishedMethodParameter are followed by TAttributeData

  PAttributeData = ^TAttributeData;

  TAttributeData = packed record
    Length: Word; // byte length of the structure
    Attributes: TAttributes;
  end;
{$IFEND CompilerVersion >= 21} // Delphi 2010 and newer

  TPublishedMethods = packed array [0 .. High(Word) - 1] of TPublishedMethod;
  PPmt = ^TPmt;

  TPmt = packed record
    Count: Word;
    Methods: TPublishedMethods; // really [0..Count-1]
  end;

  // Published fields table
  PPublishedField = ^TPublishedField;

  TPublishedField = packed record
    Offset: Integer;
    TypeIndex: Word; // Index into the FieldTypes array below
    Name: { packed } TSymbolName; // really string[Length(Name)]; same type as System.TypInfo.TVmtFieldEntry.Name: TSymbolName
  end;

  PPublishedFieldTypes = ^TPublishedFieldTypes;

  TPublishedFieldTypes = packed record
    TypeCount: Word;
    Types: array [0 .. High(Word) - 1] of PClass; // really [0..TypeCount-1]
  end;

  TPublishedFields = packed array [0 .. High(Word) - 1] of TPublishedField;
  PPft = ^TPft;

  TPft = packed record
    Count: Word;
    FieldTypes: PPublishedFieldTypes;
    Fields: TPublishedFields; // really [0..Count-1]
  end;

  // Virtual method table
  PVmt = ^TVmt;

  TVmt = packed record
    SelfPtr: TClass;
    IntfTable: Pointer;
    AutoTable: Pointer;
    InitTable: Pointer;
    TypeInfo: Pointer;
    FieldTable: PPft;
    MethodTable: PPmt;
    DynamicTable: PDmt;
    ClassName: PSymbolName;
    InstanceSize: PLongint;
    Parent: PClass;
{$IFDEF AUTOREFCOUNT}
    __ObjAddRef: P__ObjAddRef;
    __ObjRelease: P__ObjRelease;
{$ENDIF}
{$IF CompilerVersion >= 20} // Delphi 2009 or newer
    Equals: PEquals;
    GetHashCode: PGetHashCode;
    ToString: PToString;
{$IFEND CompilerVersion >= 20} // Delphi 2009 or newer
    SafeCallException: PSafeCallException;
    AfterConstruction: PAfterConstruction;
    BeforeDestruction: PBeforeDestruction;
    Dispatch: PDispatch;
    DefaultHandler: PDefaultHandler;
    NewInstance: PNewInstance;
    FreeInstance: PFreeInstance;
    Destroy: PDestroy;
    { UserDefinedVirtuals: array[0..999] of procedure; }
  end;

// Virtual method table
function GetVmt(const AClass: TClass): PVmt; overload;
function GetVmt(const Instance: TObject): PVmt; overload;

// Published methods
function GetPmt(const AClass: TClass): PPmt;
function GetPublishedMethodCount(const AClass: TClass): Integer;
function GetPublishedMethod(const AClass: TClass; const Index: Integer): PPublishedMethod;
function GetFirstPublishedMethod(const AClass: TClass): PPublishedMethod;
function GetNextPublishedMethod(const AClass: TClass; const PublishedMethod: PPublishedMethod): PPublishedMethod;
function FindPublishedMethodByName(const AClass: TClass; const AName: TSymbolName): PPublishedMethod;
function FindPublishedMethodByAddr(const AClass: TClass; const AAddr: Pointer): PPublishedMethod;
function FindPublishedMethodAddr(const AClass: TClass; const AName: TSymbolName): Pointer;
function FindPublishedMethodName(const AClass: TClass; const AAddr: Pointer): TSymbolName;

// Published fields
function GetPft(const AClass: TClass): PPft;
function GetPublishedFieldCount(const AClass: TClass): Integer;
function GetNextPublishedField(const AClass: TClass; const PublishedField: PPublishedField): PPublishedField;
function GetPublishedField(const AClass: TClass; const TypeIndex: Integer): PPublishedField;
function GetFirstPublishedField(const AClass: TClass): PPublishedField;
function FindPublishedFieldByName(const AClass: TClass; const AName: TSymbolName): PPublishedField;
function FindPublishedFieldByOffset(const AClass: TClass; const AOffset: Integer): PPublishedField;
function FindPublishedFieldByAddr(const Instance: TObject; const AAddr: Pointer): PPublishedField;
function FindPublishedFieldOffset(const AClass: TClass; const AName: TSymbolName): Integer;
function FindPublishedFieldAddr(const Instance: TObject; const AName: TSymbolName): PObject;
function FindPublishedFieldName(const AClass: TClass; const AOffset: Integer): TSymbolName; overload;
function FindPublishedFieldName(const Instance: TObject; const AAddr: Pointer): TSymbolName; overload;
function GetPublishedFieldType(const AClass: TClass; const Field: PPublishedField): TClass;
function GetPublishedFieldAddr(const Instance: TObject; const Field: PPublishedField): PObject;
function GetPublishedFieldValue(const Instance: TObject; const Field: PPublishedField): TObject;

implementation

uses
{$IF CompilerVersion >= 25} // Delphi XE4 or newer
  AnsiStrings,
{$IFEND CompilerVersion >= 25} // Delphi XE4 or newer
  Classes,
  SysUtils;

{$IF CompilerVersion < 20} // Older than Delphi 2009
type
  PByte = PAnsiChar;
{$IFEND CompilerVersion < 20} // Older than Delphi 2009

// Virtual method table

function GetVmt(const AClass: TClass): PVmt;
begin
  Result := PVmt(AClass);
  Dec(Result);
  if Result.SelfPtr <> AClass then
    raise Exception.CreateFmt('Vmt of %s is not as expected', [AClass.Classname]);
end;

function GetVmt(const Instance: TObject): PVmt;
begin
  Result := GetVmt(Instance.ClassType);
end;

// Published methods

function GetPmt(const AClass: TClass): PPmt;
var
  Vmt: PVmt;
begin
  Vmt := GetVmt(AClass);
  if Assigned(Vmt) then
    Result := Vmt.MethodTable
  else
    Result := nil;
end;

function GetPublishedMethodCount(const AClass: TClass): Integer;
var
  Pmt: PPmt;
begin
  Pmt := GetPmt(AClass);
  if Assigned(Pmt) then
    Result := Pmt.Count
  else
    Result := 0;
end;

function GetPublishedMethod(const AClass: TClass; const Index: Integer): PPublishedMethod;
var
  CurrentIndex: Integer;
  Pmt: PPmt;
begin
  Pmt := GetPmt(AClass);
  CurrentIndex := Index;
  if Assigned(Pmt) and (CurrentIndex < Pmt.Count) then
  begin
    Result := @Pmt.Methods[0];
    while CurrentIndex > 0 do
    begin
      Result := GetNextPublishedMethod(AClass, Result);
      Dec(CurrentIndex);
    end;
  end
  else
    Result := nil;
end;

function GetFirstPublishedMethod(const AClass: TClass): PPublishedMethod;
begin
  Result := GetPublishedMethod(AClass, 0);
end;

function SkipBytes(const CurrentField: Pointer; const FieldSize: Integer): Pointer;
begin
  Result := PByte(CurrentField) + FieldSize;
end;

{ .$DEFINE DEBUG }
{ .$UNDEF DEBUG }
function GetNextPublishedMethod(const AClass: TClass; const PublishedMethod: PPublishedMethod): PPublishedMethod;
// Note: Caller is responsible for calling this the
// correct number of times (using GetPublishedMethodCount)
{$IFDEF DEBUG}
var
  ExpectedSize: Integer;
  HeadSize: Integer;
  ParameterIndex: Integer;
  PublishedMethodParameter: PPublishedMethodParameter;
  PublishedMethodParameterSize: Integer;
  PublishedMethodParametersSize: Integer;
{$IF CompilerVersion >= 21} // Delphi 2010 and newer
  PublishedMethodParameterAttributeData: PAttributeData;
{$IFEND CompilerVersion >= 21} // Delphi 2010 and newer
{$IF CompilerVersion <= 20} // Delphi 2009 and older
  RunningHeadSize: Integer;
{$IFEND CompilerVersion <= 20} // Delphi 2009 and older
  TailHeaderSize: Integer;
  TailSize: Integer;
  Tail: PPublishedMethodTail;
{$IF CompilerVersion >= 21} // Delphi 2010 and newer
  TailParameterCount: Integer;
{$IFEND CompilerVersion >= 21} // Delphi 2010 and newer
{$ENDIF}
begin
  Result := PublishedMethod;
{$IFDEF DEBUG}
  HeadSize := SizeOf(Result.Size) //
    + SizeOf(Result.Address) //
    + SizeOf(Result.Name[0]) //
    + Length(Result.Name);

  if Result.Size = HeadSize then
  begin
    TailSize := 0;
  end
  else
  begin
    // Depending on the Delphi version, Result + HeadSize now points to the tail of
    // PublishedMethod^ or to the next PPublishedMethod entry.

    // Determine if there is a Tail, and what the TailSize is
    Tail := SkipBytes(PublishedMethod, HeadSize);
    if Tail.Version = MandatoryTPublishedMethodTailVersion then
    begin
      TailHeaderSize := SizeOf(Tail^);
      PublishedMethodParametersSize := 0;

      PublishedMethodParameter := SkipBytes(Tail, TailHeaderSize);

      // The below code is complicated because of the various Delphi version changes.
      // - Delphi 2010 and newer maintain a Tail.ParameterCount which results the IF structure coming down to
      //   1. an if when there are no parameters (I'm not sure this can even happen)
      //   2. a for loop involving TailParameterCount counting the size of all parameters (and attributes)
      // - Delphi 2009 and older lack the Tail.ParameterCount so we have a while loop
      //   that counts the bytes used by the parameters and stops as soon as we match or exceed the expected Result.Size
{$IF CompilerVersion >= 21} // Delphi 2010 and newer
      TailParameterCount := Tail.ParameterCount;
      if TailParameterCount = 0 then
      begin
{$IF CompilerVersion >= 21} // Delphi 2010 and newer
        // skip attributes for the method
        PublishedMethodParameterAttributeData := SkipBytes(Tail, TailHeaderSize);
{$IFEND CompilerVersion >= 21} // Delphi 2010 and newer
      end
      else
{$ELSE}
      RunningHeadSize := HeadSize + TailHeaderSize;
{$IFEND CompilerVersion >= 21} // Delphi 2010 and newer
      begin
{$IF CompilerVersion >= 21} // Delphi 2010 and newer
        for ParameterIndex := 1 to TailParameterCount do
{$ELSE}
        while RunningHeadSize < Result.Size do
{$IFEND CompilerVersion >= 21} // Delphi 2010 and newer
        begin
          PublishedMethodParameterSize :=
            SizeOf(PublishedMethodParameter.Flags) +
            SizeOf(PublishedMethodParameter.ParameterType) +
            SizeOf(PublishedMethodParameter.ParameterOffset) +
            SizeOf(PublishedMethodParameter.Name[0]) +
            Length(PublishedMethodParameter.Name);
          // skip attributes for the parameter
{$IF CompilerVersion >= 21} // Delphi 2010 and newer
          PublishedMethodParameterAttributeData := SkipBytes(PublishedMethodParameter, PublishedMethodParameterSize);
{$IFEND CompilerVersion >= 21} // Delphi 2010 and newer
          PublishedMethodParametersSize :=
{$IF CompilerVersion >= 21} // Delphi 2010 and newer
            PublishedMethodParameterAttributeData.Length +
{$IFEND CompilerVersion >= 21} // Delphi 2010 and newer
            PublishedMethodParametersSize + PublishedMethodParameterSize;
          PublishedMethodParameter := SkipBytes(PublishedMethodParameter,
{$IF CompilerVersion >= 21} // Delphi 2010 and newer
            PublishedMethodParameterAttributeData.Length +
{$IFEND CompilerVersion >= 21} // Delphi 2010 and newer
            PublishedMethodParameterSize);
{$IF CompilerVersion <= 20} // Delphi 2009 and older
            Inc(RunningHeadSize, PublishedMethodParameterSize);
{$IFEND CompilerVersion <= 20} // Delphi 2009 and older
        end;
      end;
{$IF CompilerVersion >= 21} // Delphi 2010 and newer
      // skip attributes for the method
      PublishedMethodParameterAttributeData := SkipBytes(PublishedMethodParameterAttributeData, PublishedMethodParameterAttributeData.Length);
{$IFEND CompilerVersion >= 21} // Delphi 2010 and newer
      TailSize := TailHeaderSize +
{$IF CompilerVersion >= 21} // Delphi 2010 and newer
        PublishedMethodParameterAttributeData.Length +
{$IFEND CompilerVersion >= 21} // Delphi 2010 and newer
        PublishedMethodParametersSize;
    end
    else
    begin
      TailSize := 0;
    end;
  end;

  ExpectedSize := HeadSize + TailSize;
  if Result.Size <> ExpectedSize then
    raise Exception.CreateFmt( //
      'RTTI for the published method "%s" of class "%s" has %d extra bytes of unknown data!', //
      [Result.Name, AClass.ClassName, Result.Size - ExpectedSize]);
{$ENDIF}
  if Assigned(Result) then
    Inc(PByte(Result), Result.Size);
end;

function MatchingSymbolNames(const AName1, AName2: TSymbolName): boolean;
begin
  Result := (Length(AName1) = Length(AName2)) and //
            ({$IF CompilerVersion >= 25}AnsiStrings.{$IFEND CompilerVersion >= 25} //
             StrLIComp(PAnsiChar(@AName1[1]), PAnsiChar(@AName2[1]), Length(AName2)) = 0); //
end;

function FindPublishedMethodByName(const AClass: TClass; const AName: TSymbolName): PPublishedMethod;
var
  CurrentClass: TClass;
  i: Integer;
begin
  CurrentClass := AClass;
  while Assigned(CurrentClass) do
  begin
    Result := GetFirstPublishedMethod(CurrentClass);
    for i := 0 to GetPublishedMethodCount(CurrentClass) - 1 do
    begin
      if MatchingSymbolNames(Result.Name, AName) then
        Exit;
      Result := GetNextPublishedMethod(CurrentClass, Result);
    end;
    CurrentClass := CurrentClass.ClassParent;
  end;
  Result := nil;
end;

function FindPublishedMethodByAddr(const AClass: TClass; const AAddr: Pointer): PPublishedMethod;
var
  CurrentClass: TClass;
  i: Integer;
begin
  CurrentClass := AClass;
  while Assigned(CurrentClass) do
  begin
    Result := GetFirstPublishedMethod(CurrentClass);
    for i := 0 to GetPublishedMethodCount(CurrentClass) - 1 do
    begin
      if Result.Address = AAddr then
        Exit;
      Result := GetNextPublishedMethod(CurrentClass, Result);
    end;
    CurrentClass := CurrentClass.ClassParent;
  end;
  Result := nil;
end;

function FindPublishedMethodAddr(const AClass: TClass; const AName: TSymbolName): Pointer;
var
  Method: PPublishedMethod;
begin
  Method := FindPublishedMethodByName(AClass, AName);
  if Assigned(Method) then
    Result := Method.Address
  else
    Result := nil;
end;

function FindPublishedMethodName(const AClass: TClass; const AAddr: Pointer): TSymbolName;
var
  Method: PPublishedMethod;
begin
  Method := FindPublishedMethodByAddr(AClass, AAddr);
  if Assigned(Method) then
    Result := Method.Name
  else
    Result := '';
end;

// Published fields

function GetPft(const AClass: TClass): PPft;
var
  Vmt: PVmt;
begin
  Vmt := GetVmt(AClass);
  if Assigned(Vmt) then
    Result := Vmt.FieldTable
  else
    Result := nil;
end;

function GetPublishedFieldCount(const AClass: TClass): Integer;
var
  Pft: PPft;
begin
  Pft := GetPft(AClass);
  if Assigned(Pft) then
    Result := Pft.Count
  else
    Result := 0;
end;

function GetNextPublishedField(const AClass: TClass; const PublishedField: PPublishedField): PPublishedField;
// Note: Caller is responsible for calling this the
// correct number of times (using GetPublishedFieldCount)
begin
  Result := PublishedField;
  if Assigned(Result) then
    Inc(PByte(Result), SizeOf(Result.Offset) //
      + SizeOf(Result.TypeIndex) //
      + SizeOf(Result.Name[0]) //
      + Length(Result.Name));
end;

function GetPublishedField(const AClass: TClass; const TypeIndex: Integer): PPublishedField;
var
  CurrentTypeIndex: Integer;
  Pft: PPft;
begin
  Pft := GetPft(AClass);
  CurrentTypeIndex := TypeIndex;
  if Assigned(Pft) and (CurrentTypeIndex < Pft.Count) then
  begin
    Result := @Pft.Fields[0];
    while CurrentTypeIndex > 0 do
    begin
      Result := GetNextPublishedField(AClass, Result);
      Dec(CurrentTypeIndex);
    end;
  end
  else
    Result := nil;
end;

function GetFirstPublishedField(const AClass: TClass): PPublishedField;
begin
  Result := GetPublishedField(AClass, 0);
end;

function FindPublishedFieldByName(const AClass: TClass; const AName: TSymbolName): PPublishedField;
var
  CurrentClass: TClass;
  i: Integer;
begin
  CurrentClass := AClass;
  while Assigned(CurrentClass) do
  begin
    Result := GetFirstPublishedField(CurrentClass);
    for i := 0 to GetPublishedFieldCount(CurrentClass) - 1 do
    begin
      if MatchingSymbolNames(Result.Name, AName) then
        Exit;
      Result := GetNextPublishedField(CurrentClass, Result);
    end;
    CurrentClass := CurrentClass.ClassParent;
  end;
  Result := nil;
end;

function FindPublishedFieldByOffset(const AClass: TClass; const AOffset: Integer): PPublishedField;
var
  CurrentClass: TClass;
  i: Integer;
begin
  CurrentClass := AClass;
  while Assigned(CurrentClass) do
  begin
    Result := GetFirstPublishedField(CurrentClass);
    for i := 0 to GetPublishedFieldCount(CurrentClass) - 1 do
    begin
      if Result.Offset = AOffset then
        Exit;
      Result := GetNextPublishedField(CurrentClass, Result);
    end;
    CurrentClass := CurrentClass.ClassParent;
  end;
  Result := nil;
end;

function FindPublishedFieldByAddr(const Instance: TObject; const AAddr: Pointer): PPublishedField;
begin
  asm
    int 3
  end;
  Result := FindPublishedFieldByOffset(Instance.ClassType, PByte(AAddr) - PByte(Instance));
end;

function FindPublishedFieldOffset(const AClass: TClass; const AName: TSymbolName): Integer;
var
  Field: PPublishedField;
begin
  Field := FindPublishedFieldByName(AClass, AName);
  if Assigned(Field) then
    Result := Field.Offset
  else
    Result := -1;
end;

function FindPublishedFieldAddr(const Instance: TObject; const AName: TSymbolName): PObject;
var
  Offset: Integer;
begin
  Offset := FindPublishedFieldOffset(Instance.ClassType, AName);
  asm
    int 3
  end;
  if Offset >= 0 then
    Result := PObject(PByte(Instance) + Offset)
  else
    Result := nil;
end;

function FindPublishedFieldName(const AClass: TClass; const AOffset: Integer): TSymbolName;
var
  Field: PPublishedField;
begin
  Field := FindPublishedFieldByOffset(AClass, AOffset);
  if Assigned(Field) then
    Result := Field.Name
  else
    Result := '';
end;

function FindPublishedFieldName(const Instance: TObject; const AAddr: Pointer): TSymbolName;
var
  Field: PPublishedField;
begin
  Field := FindPublishedFieldByAddr(Instance, AAddr);
  if Assigned(Field) then
    Result := Field.Name
  else
    Result := '';
end;

function GetPublishedFieldType(const AClass: TClass; const Field: PPublishedField): TClass;
var
  Pft: PPft;
begin
  Pft := GetPft(AClass);
  if Assigned(Pft) and Assigned(Field) and (Field.TypeIndex < Pft.FieldTypes.TypeCount) then
    Result := Pft.FieldTypes.Types[Field.TypeIndex]^
  else
    Result := nil;
end;

function GetPublishedFieldAddr(const Instance: TObject; const Field: PPublishedField): PObject;
begin
  if Assigned(Field) then
    Result := PObject(PByte(Instance) + Field.Offset)
  else
    Result := nil;
end;

function GetPublishedFieldValue(const Instance: TObject; const Field: PPublishedField): TObject;
var
  FieldAddr: PObject;
begin
  FieldAddr := GetPublishedFieldAddr(Instance, Field);
  if Assigned(FieldAddr) then
    Result := FieldAddr^
  else
    Result := nil;
end;

{$IFOPT C+} // If asserts are on
const
  TSymbolChar_Size = SizeOf(TSymbolChar);
{$IF Declared(TVmtFieldEntry)}
  TVmtFieldEntry_Size = SizeOf(TVmtFieldEntry);
  TPublishedField_Size = SizeOf(TPublishedField);
{$IFEND Declared(TVmtFieldEntry)}
initialization
  Assert(TSymbolChar_Size = 1);
{$IF Declared(TVmtFieldEntry)}
  Assert(TPublishedField_Size = TVmtFieldEntry_Size);
{$IFEND Declared(TVmtFieldEntry)}
finalization
{$ENDIF C+} // If asserts are on

end.
