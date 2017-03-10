program TestMethodTable;

{$APPTYPE CONSOLE}

uses
  Classes, SysUtils, TypInfo;

{class }function TObject_MethodAddress(const Name: ShortString): Pointer;
asm
        { ->    EAX     Pointer to class        }
        {       EDX     Pointer to name }
        PUSH    EBX
        PUSH    ESI
        PUSH    EDI
        XOR     ECX,ECX
        XOR     EDI,EDI
        MOV     BL,[EDX]
        JMP     @@haveVMT
@@outer:                                { upper 16 bits of ECX are 0 !  }
        MOV     EAX,[EAX]
@@haveVMT:
        MOV     ESI,[EAX].vmtMethodTable
        TEST    ESI,ESI
        JE      @@parent
        MOV     DI,[ESI]                { EDI := method count           }
        ADD     ESI,2
@@inner:                                { upper 16 bits of ECX are 0 !  }
        MOV     CL,[ESI+6]              { compare length of strings     }
        CMP     CL,BL
        JE      @@cmpChar
@@cont:                                 { upper 16 bits of ECX are 0 !  }
        MOV     CX,[ESI]                { fetch length of method desc   }
        ADD     ESI,ECX                 { point ESI to next method      }
        DEC     EDI
        JNZ     @@inner
@@parent:
        MOV     EAX,[EAX].vmtParent     { fetch parent vmt              }
        TEST    EAX,EAX
        JNE     @@outer
        JMP     @@exit                  { return NIL                    }

@@notEqual:
        MOV     BL,[EDX]                { restore BL to length of name  }
        JMP     @@cont

@@cmpChar:                              { upper 16 bits of ECX are 0 !  }
        MOV     CH,0                    { upper 24 bits of ECX are 0 !  }
@@cmpCharLoop:
        MOV     BL,[ESI+ECX+6]          { case insensitive string cmp   }
        XOR     BL,[EDX+ECX+0]          { last char is compared first   }
        AND     BL,$DF
        JNE     @@notEqual
        DEC     ECX                     { ECX serves as counter         }
        JNZ     @@cmpCharLoop

        { found it }
        MOV     EAX,[ESI+2]

@@exit:
        POP     EDI
        POP     ESI
        POP     EBX
end;

{class} function TObject_MethodName(Address: Pointer): ShortString;
asm
        { ->    EAX     Pointer to class        }
        {       EDX     Address         }
        {       ECX Pointer to result   }
        PUSH    EBX
        PUSH    ESI
        PUSH    EDI
        MOV     EDI,ECX
        XOR     EBX,EBX
        XOR     ECX,ECX
        JMP     @@haveVMT
@@outer:
        MOV     EAX,[EAX]
@@haveVMT:
        MOV     ESI,[EAX].vmtMethodTable { fetch pointer to method table }
        TEST    ESI,ESI
        JE      @@parent
        MOV     CX,[ESI]
        ADD     ESI,2
@@inner:
        CMP     EDX,[ESI+2]
        JE      @@found
        MOV     BX,[ESI]
        ADD     ESI,EBX
        DEC     ECX
        JNZ     @@inner
@@parent:
        MOV     EAX,[EAX].vmtParent
        TEST    EAX,EAX
        JNE     @@outer
        MOV     [EDI],AL
        JMP     @@exit

@@found:
        ADD     ESI,6
        XOR     ECX,ECX
        MOV     CL,[ESI]
        INC     ECX
        REP     MOVSB

@@exit:
        POP     EDI
        POP     ESI
        POP     EBX
end;

type
  PClass = ^TClass;
  PSafeCallException = function  (Self: TObject; ExceptObject: TObject;
                         ExceptAddr: Pointer): HResult;
  PAfterConstruction = procedure (Self: TObject);
  PBeforeDestruction = procedure (Self: TObject);
  PDispatch          = procedure (Self: TObject; var Message);
  PDefaultHandler    = procedure (Self: TObject; var Message);
  PNewInstance       = function  (Self: TClass) : TObject;
  PFreeInstance      = procedure (Self: TObject);
  PDestroy           = procedure (Self: TObject; OuterMost: ShortInt);
  TDMTIndex   = Smallint;
  PDmtIndices = ^TDmtIndices;
  TDmtIndices = array[0..High(Word)-1] of TDMTIndex;
  PDmtMethods = ^TDmtMethods;
  TDmtMethods = array[0..High(Word)-1] of Pointer;
  PDmt = ^TDmt;
  TDmt = packed record
    Count: word;
    Indicies: TDmtIndices; // really [0..Count-1]
    Methods : TDmtMethods; // really [0..Count-1]
  end;
  PPublishedMethod = ^TPublishedMethod;
  TPublishedMethod = packed record
    Size: word;  // Why this? Always equals: SizeOf(Size) + SizeOf(Address) + 1 + Length(Name)
    Address: Pointer;
    Name: {packed} Shortstring;
  end;
  TPublishedMethods = array[0..High(Word)-1] of TPublishedMethod;
  PPmt = ^TPmt;
  TPmt = packed record
    Count: Word;
    Methods: TPublishedMethods; // really [0..Count-1]
  end;

  PVmt = ^TVmt;
  TVmt = packed record
    SelfPtr           : TClass;
    IntfTable         : Pointer;
    AutoTable         : Pointer;
    InitTable         : Pointer;
    TypeInfo          : Pointer;
    FieldTable        : Pointer;
    MethodTable       : PPmt;
    DynamicTable      : PDmt;
    ClassName         : PShortString;
    InstanceSize      : PLongint;
    Parent            : PClass;
    SafeCallException : PSafeCallException;
    AfterConstruction : PAfterConstruction;
    BeforeDestruction : PBeforeDestruction;
    Dispatch          : PDispatch;
    DefaultHandler    : PDefaultHandler;
    NewInstance       : PNewInstance;
    FreeInstance      : PFreeInstance;
    Destroy           : PDestroy;
   {UserDefinedVirtuals: array[0..999] of procedure;}
  end;
  // For easier use of the "dynamic" arrays
  TDynamicMethodTable = record
    Count: word;
    Indicies: PDmtIndices; // really [0..Count-1]
    Methods : PDmtMethods; // really [0..Count-1]
  end;

function GetVmt(AClass: TClass): PVmt;
begin
  Result := PVmt(AClass);
  Dec(Result);
end;

function GetDmt(AClass: TClass): PDmt;
var
  Vmt: PVmt;
begin
  Vmt := GetVmt(AClass);
  if Assigned(Vmt)
  then Result := Vmt.DynamicTable
  else Result := nil;
end;

function GetPmt(AClass: TClass): PPmt;
var
  Vmt: PVmt;
begin
  Vmt := GetVmt(AClass);
  if Assigned(Vmt)
  then Result := Vmt.MethodTable
  else Result := nil;
end;

function GetPublishedMethodCount(AClass: TClass): integer;
var
  Pmt: PPmt;
begin
  Pmt := GetPmt(AClass);
  if Assigned(Pmt)
  then Result := Pmt.Count
  else Result := 0;
end;

function GetPublishedMethod(AClass: TClass; Index: integer): PPublishedMethod;
var
  Pmt: PPmt;
begin
  Pmt := GetPmt(AClass);
  if Assigned(Pmt) and (Index < Pmt.Count) then
  begin
    Result := @Pmt.Methods[0];
    while Index > 0 do
    begin
      Inc(PChar(Result), Result.Size);
      Dec(Index);
    end;
  end
  else
    Result := nil;
end;

function GetFirstPublishedMethod(AClass: TClass): PPublishedMethod;
begin
  Result := GetPublishedMethod(AClass, 0);
end;

function GetNextPublishedMethod(AClass: TClass; PublishedMethod: PPublishedMethod): PPublishedMethod;
// Note: Caller is responsible for calling this the correct number of times (using GetPublishedMethodCount)
begin
  Result := PublishedMethod;
  if Assigned(Result) then
    Inc(PChar(Result), Result.Size);
end;

procedure DumpPublishedMethods(AClass: TClass);
var
  i : integer;
  Method: PPublishedMethod;
begin
  while Assigned(AClass) do
  begin
    writeln('Published methods in ', AClass.ClassName);
    for i := 0 to GetPublishedMethodCount(AClass)-1 do
    begin
      Method := GetPublishedMethod(AClass, i);
      writeln(Format('%d. MethodAddr = %p, Name = %s',
                     [i, Method.Address, Method.Name]));
    end;
    AClass := AClass.ClassParent;
  end;
end;

procedure DumpPublishedMethods2(AClass: TClass);
var
  i : integer;
  Method: PPublishedMethod;
begin
  while Assigned(AClass) do
  begin
    writeln('Published methods in ', AClass.ClassName);
    Method := GetFirstPublishedMethod(AClass);
    for i := 0 to GetPublishedMethodCount(AClass)-1 do
    begin
      writeln(Format('%d. MethodAddr = %p, Name = %s',
                     [i, Method.Address, Method.Name]));
      Method := GetNextPublishedMethod(AClass, Method);
    end;
    AClass := AClass.ClassParent;
  end;
end;

function FindPublishedMethodByName(AClass: TClass; const AName: ShortString): PPublishedMethod;
var
  i : integer;
begin
  while Assigned(AClass) do
  begin
    Result := GetFirstPublishedMethod(AClass);
    for i := 0 to GetPublishedMethodCount(AClass)-1 do
    begin
      // Note: Length(ShortString) expands to efficient inline code
      if (Length(Result.Name) = Length(AName)) and
         (StrLIComp(@Result.Name[1], @AName[1], Length(AName)) = 0) then
        Exit;
      Result := GetNextPublishedMethod(AClass, Result);
    end;
    AClass := AClass.ClassParent;
  end;
  Result := nil;
end;

function FindPublishedMethodByAddr(AClass: TClass; AAddr: Pointer): PPublishedMethod;
var
  i : integer;
begin
  while Assigned(AClass) do
  begin
    Result := GetFirstPublishedMethod(AClass);
    for i := 0 to GetPublishedMethodCount(AClass)-1 do
    begin
      if Result.Address = AAddr then
        Exit;
      Result := GetNextPublishedMethod(AClass, Result);
    end;
    AClass := AClass.ClassParent;
  end;
  Result := nil;
end;

function FindPublishedMethodAddr(AClass: TClass; const AName: ShortString): Pointer;
var
  Method: PPublishedMethod;
begin
  Method := FindPublishedMethodByName(AClass, AName);
  if Assigned(Method)
  then Result := Method.Address
  else Result := nil;
end;

function FindPublishedMethodName(AClass: TClass; AAddr: Pointer): Shortstring;
var
  Method: PPublishedMethod;
begin
  Method := FindPublishedMethodByAddr(AClass, AAddr);
  if Assigned(Method)
  then Result := Method.Name
  else Result := '';
end;

function FindDynamicMethod(AClass: TClass; DMTIndex: TDMTIndex): Pointer;
// Pascal variant of the faster BASM version in System.GetDynaMethod
var
  Dmt: PDmt;
  DmtMethods: PDmtMethods;
  i: integer;
begin
  while Assigned(AClass) do
  begin
    Dmt := GetDmt(AClass);
    if Assigned(Dmt) then
      for i := 0 to Dmt.Count-1 do
        if DMTIndex = Dmt.Indicies[i] then
        begin
          DmtMethods := @Dmt.Indicies[Dmt.Count];
          Result := DmtMethods[i];
          Exit;
        end;
    // Not in this class, try the parent class
    AClass := AClass.ClassParent;
  end;
  Result := nil;
end;

procedure DumpFoundDynamicMethods(AClass: TClass);
  procedure Dump(DMTIndex: TDMTIndex);
  var
    Proc: Pointer;
  begin
    Proc := FindDynamicMethod(AClass, DMTIndex);
    writeln(Format('Dynamic Method Index = %2d, Method = %p',
                   [DMTIndex, Proc]));
  end;
begin
  Dump(-1);
  Dump(1);
  Dump(13);
  Dump(42);
end;

type
  {.$M+} // Compiler bug: includes published methods in VMT RTTI info even in $M- mode!!
  {$M-}

  // From impl. of Classes unit:
  TPropFixup = class
  public
    FInstance: integer;
  published
    function MakeGlobalReference: Boolean;
  end;


  TMyClass = class
//    I: integer; // Not allowed in $M+ mode
//  public // Note: default access level is published
    procedure FirstDynamic; dynamic;     // This could have RTTI depending on $M+
    procedure SecondDynamic; dynamic; abstract;
    class procedure ThirdDynamic; dynamic;
    class procedure FourthDynamic; dynamic;
    procedure MessageMethod(var Msg); message 42;
  private
    FA: Integer;
  published // These *always* have RTTI, even in $M-! Bug?
    constructor Create;  // "Bug": ignores published constructor and destructors
    destructor Destroy; override;
    procedure MsgHandler(var Msg); message 1;
    procedure FirstPublished; virtual; abstract;
    procedure SecondPublished(A: integer); virtual; abstract;
    procedure ThirdPublished(A: integer)  stdcall; virtual; abstract;
    function FourthPublished(A: string): string stdcall; virtual; abstract;
    procedure ThirdPublished2(A: integer)  cdecl; virtual; abstract;
    function FourthPublished2(A: string): string pascal; virtual; abstract;
    // properties only have RTTI in $M+ mode
    property A: integer read FA write FA;
  end;
  TMyDescendent = class(TMyClass)
//  public
    procedure FirstDynamic; override;
  published
    procedure SecondDynamic; override;
    class procedure ThirdDynamic; override;
    class procedure FourthDynamic; override;
  end;
  TMyDescendent2 = class(TMyClass)
  end;

procedure TMyClass.FirstDynamic;
begin
  inherited;
//  Writeln(Classname, ': TMyClass.FirstDynamic');
end;

{procedure TMyClass.SecondDynamic;
begin
  Writeln(Classname, '.SecondDynamic');
end;}

class procedure TMyClass.ThirdDynamic;
begin
  Writeln(Classname, '.ThirdDynamic');
end;

class procedure TMyClass.FourthDynamic;
begin
  Writeln(Classname, '.FourthDynamic');
end;

procedure TMyClass.MessageMethod(var Msg);
begin
  inherited; // Special case - calls TObject.DefaultHandler
  Writeln(Classname, '.MessageMethod');
end;

procedure TMyDescendent.FirstDynamic;
begin
//  Writeln(Classname, ': TMyDescendent.FirstDynamic');
end;

procedure TMyDescendent.SecondDynamic;
begin
  inherited;
  Writeln(Classname, '.SecondDynamic');
end;

class procedure TMyDescendent.ThirdDynamic;
begin
  Writeln(Classname, '.ThirdDynamic');
end;

class procedure TMyDescendent.FourthDynamic;
begin
  inherited;
  Writeln(Classname, '.FourthDynamic');
end;

function MyDynamicMethodIndex: integer;
asm
  MOV EAX, DMTIndex TMyClass.FirstDynamic
end;

procedure CallFirstDynamicMethod(Self: TMyClass);
asm
  MOV ESI, DMTIndex TMyClass.FirstDynamic
  CALL System.@CallDynaInst
end;

procedure StaticCallFirstDynamicMethod(Self: TMyClass);
asm
  CALL TMyClass.FirstDynamic // Static call
end;

procedure SlowDynamicLoop(Instance: TMyClass);
var
  i: integer;
begin
   for i := 0 to 1000000 do
     Instance.FirstDynamic;
end;

procedure FasterDynamicLoop(Instance: TMyClass);
var
  i: integer;
  FirstDynamic: procedure of object;
begin
  FirstDynamic := Instance.FirstDynamic;
   for i := 0 to 1000000 do
     FirstDynamic;
end;

procedure SlowDynamicListLoop(Instances: TList);
var
  i: integer;
  Instance: TMyClass;
begin
  for i := 0 to Instances.Count-1 do
  begin
    Instance := Instances.List[i];
    Instance.FirstDynamic;
  end;
end;

procedure FasterDynamicListLoop(Instances: TList);
var
  i: integer;
  Instance: TMyClass;
  FirstDynamic: procedure(Self: TObject);
begin
  FirstDynamic := @TMyClass.FirstDynamic;
  for i := 0 to Instances.Count-1 do
  begin
    Instance := Instances.List[i];
    Assert(Instance.ClassType=TMyClass);
    FirstDynamic(Instance);
  end;
end;

function TMyClassFirstDynamicNotOverridden(Instance: TMyClass): boolean;
var
  FirstDynamic: procedure of object;
begin
  FirstDynamic := Instance.FirstDynamic;
  Result := TMethod(FirstDynamic).Code = @TMyClass.FirstDynamic;
end;

procedure FasterDynamicListLoop2(Instances: TList);
type
  PMethod = TMethod;
var
  i: integer;
  Instance: TMyClass;
  FirstDynamic: procedure (Self: TObject);
begin
  FirstDynamic := @TMyClass.FirstDynamic;
  for i := 0 to Instances.Count-1 do
  begin
    Instance := Instances.List[i];
    Assert(TObject(Instance) is TMyClass);
    Assert(TMyClassFirstDynamicNotOverridden(Instance));
    FirstDynamic(Instance);
  end;
end;
procedure DumpMethod(Method: PPublishedMethod);
begin
  if Assigned(Method) then
    Writeln(Format('%p=%s', [Method.Address, Method.Name]))
  else
    Writeln('nil');
end;

procedure Test;
begin
  DumpPublishedMethods(TMyDescendent);
  DumpPublishedMethods2(TMyDescendent);
  writeln(Format('A=%p', [GetPropInfo(TMyDescendent, 'A')]));
  DumpMethod(FindPublishedMethodByName(TMyDescendent, 'ThirdPublished'));
  DumpMethod(FindPublishedMethodByName(TMyDescendent, 'NotThere'));
  DumpMethod(FindPublishedMethodByAddr(TMyDescendent, @TMyDescendent.ThirdPublished));
  DumpMethod(FindPublishedMethodByAddr(TMyDescendent, FindPublishedMethodByName(TMyDescendent, 'ThirdPublished').Address));
  DumpMethod(FindPublishedMethodByAddr(TMyDescendent, nil));
  DumpMethod(FindPublishedMethodByAddr(TMyDescendent, @TMyDescendent.FirstDynamic));
  DumpPublishedMethods2(TPropFixup);
end;

constructor TMyClass.Create;
begin
  inherited;
end;

destructor TMyClass.Destroy;
begin

  inherited;
end;

procedure TMyClass.MsgHandler(var Msg);
begin

end;

{ TPropFixup }

function TPropFixup.MakeGlobalReference: Boolean;
begin
  Result := False;
end;

begin
  try
  Test;
  except
    on E: Exception do
      writeln(E.MEssage);
  end;
  readln;
end.

