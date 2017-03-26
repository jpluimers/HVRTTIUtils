program TestMethodTable;

{$APPTYPE CONSOLE}

uses
{$IF CompilerVersion >= 25} // Delphi XE4 or newer
  AnsiStrings,
{$IFEND CompilerVersion >= 25} // Delphi XE4 or newer
  Classes,
  SysUtils,
  TypInfo,
  HVVMT in 'HVVMT.pas';

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

{class}function TObject_MethodName(Address: Pointer): ShortString;
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
  // For easier use of the "dynamic" arrays
  TDynamicMethodTable = record
    Count: Word;
    Indicies: PDmtIndices; // really [0..Count-1]
    Methods: PDmtMethods; // really [0..Count-1]
  end;

procedure DumpPublishedMethods(const AClass: TClass);
var
  CurrentClass: TClass;
  i: Integer;
  Method: PPublishedMethod;
begin
  CurrentClass := AClass;
  while Assigned(CurrentClass) do
  begin
    Writeln('Published methods in ', CurrentClass.ClassName);
    for i := 0 to GetPublishedMethodCount(CurrentClass) - 1 do
    begin
      Method := GetPublishedMethod(CurrentClass, i);
      Writeln(Format('%d. MethodAddr = %p, Name = %s', //
        [i, Method.Address, Method.Name]));
    end;
    CurrentClass := CurrentClass.ClassParent;
  end;
end;

procedure DumpPublishedMethods2(const AClass: TClass);
var
  CurrentClass: TClass;
  i: Integer;
  Method: PPublishedMethod;
begin
  CurrentClass := AClass;
  while Assigned(CurrentClass) do
  begin
    Writeln('Published methods in ', CurrentClass.ClassName);
    Method := GetFirstPublishedMethod(CurrentClass);
    for i := 0 to GetPublishedMethodCount(CurrentClass) - 1 do
    begin
      Writeln(Format('%d. MethodAddr = %p, Name = %s', //
        [i, Method.Address, Method.Name]));
      Method := GetNextPublishedMethod(CurrentClass, Method);
    end;
    CurrentClass := CurrentClass.ClassParent;
  end;
end;

type
  {.$M+}// Compiler bug: includes published methods in VMT RTTI info even in $M- mode!!
{$M-}
  // From impl. of Classes unit:
  TPropFixup = class
  public
    FInstance: Integer;
  published
    function MakeGlobalReference: Boolean;
  end;

  TMyClass = class
    // I: Integer; // Not allowed in $M+ mode
    // public // Note: default access level is published
    procedure FirstDynamic; dynamic; // This could have RTTI depending on $M+
    procedure SecondDynamic; dynamic; abstract;
    class procedure ThirdDynamic; dynamic;
    class procedure FourthDynamic; dynamic;
    procedure MessageMethod(var Msg); message 42;
  private
    FA: Integer;
  published // These *always* have RTTI, even in $M-! Bug?
    constructor Create; // "Bug": ignores published constructor and destructors
    destructor Destroy; override;
    procedure MsgHandler(var Msg); message 1;
    procedure FirstPublished; virtual; abstract;
    procedure SecondPublished(A: Integer); virtual; abstract;
    procedure ThirdPublished(A: Integer)stdcall; virtual; abstract;
    function FourthPublished(A: string): string stdcall; virtual; abstract;
    procedure ThirdPublished2(A: Integer)cdecl; virtual; abstract;
    function FourthPublished2(A: string): string pascal; virtual; abstract;
    // properties only have RTTI in $M+ mode
    property A: Integer read FA write FA;
  end;

  TMyDescendent = class(TMyClass)
    // public
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
  // Writeln(ClassName, ': TMyClass.FirstDynamic');
end;

{ procedure TMyClass.SecondDynamic;
  begin
  Writeln(ClassName, '.SecondDynamic');
  end; }

class procedure TMyClass.ThirdDynamic;
begin
  Writeln(ClassName, '.ThirdDynamic');
end;

class procedure TMyClass.FourthDynamic;
begin
  Writeln(ClassName, '.FourthDynamic');
end;

procedure TMyClass.MessageMethod(var Msg);
begin
  inherited; // Special case - calls TObject.DefaultHandler
  Writeln(ClassName, '.MessageMethod');
end;

procedure TMyDescendent.FirstDynamic;
begin
  // Writeln(ClassName, ': TMyDescendent.FirstDynamic');
end;

procedure TMyDescendent.SecondDynamic;
begin
  inherited;
  Writeln(ClassName, '.SecondDynamic');
end;

class procedure TMyDescendent.ThirdDynamic;
begin
  Writeln(ClassName, '.ThirdDynamic');
end;

class procedure TMyDescendent.FourthDynamic;
begin
  inherited;
  Writeln(ClassName, '.FourthDynamic');
end;

function MyDynamicMethodIndex: Integer;
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
  i: Integer;
begin
  for i := 0 to 1000000 do
    Instance.FirstDynamic;
end;

procedure FasterDynamicLoop(Instance: TMyClass);
var
  i: Integer;
  FirstDynamic: procedure of object;
begin
  FirstDynamic := Instance.FirstDynamic;
  for i := 0 to 1000000 do
    FirstDynamic;
end;

procedure SlowDynamicListLoop(Instances: TList);
var
  i: Integer;
  Instance: TMyClass;
begin
  for i := 0 to Instances.Count - 1 do
  begin
    Instance := Instances.List[i];
    Instance.FirstDynamic;
  end;
end;

procedure FasterDynamicListLoop(Instances: TList);
var
  i: Integer;
  Instance: TMyClass;
  FirstDynamic: procedure(Self: TObject);
begin
  FirstDynamic := @TMyClass.FirstDynamic;
  for i := 0 to Instances.Count - 1 do
  begin
    Instance := Instances.List[i];
    Assert(Instance.ClassType = TMyClass);
    FirstDynamic(Instance);
  end;
end;

function TMyClassFirstDynamicNotOverridden(Instance: TMyClass): Boolean;
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
  i: Integer;
  Instance: TMyClass;
  FirstDynamic: procedure(Self: TObject);
begin
  FirstDynamic := @TMyClass.FirstDynamic;
  for i := 0 to Instances.Count - 1 do
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
  Writeln(Format('A=%p', [GetPropInfo(TMyDescendent, 'A')]));
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
      Writeln(E.Message);
  end;
  Readln;

  { Expected output like (all nil values must be nil, all non nil values must be non-nil):

Published methods in TMyDescendent
0. MethodAddr = 004CEF28, Name = FirstDynamic
1. MethodAddr = 004CEF2C, Name = SecondDynamic
2. MethodAddr = 004CEFBC, Name = ThirdDynamic
3. MethodAddr = 004CF048, Name = FourthDynamic
Published methods in TMyClass
0. MethodAddr = 004CF370, Name = MsgHandler
1. MethodAddr = 004CEB48, Name = FirstPublished
2. MethodAddr = 004CEB50, Name = SecondPublished
3. MethodAddr = 004CEB58, Name = ThirdPublished
4. MethodAddr = 004CEB60, Name = FourthPublished
5. MethodAddr = 004CEB68, Name = ThirdPublished2
6. MethodAddr = 004CEB70, Name = FourthPublished2
Published methods in TObject
Published methods in TMyDescendent
0. MethodAddr = 004CEF28, Name = FirstDynamic
1. MethodAddr = 004CEF2C, Name = SecondDynamic
2. MethodAddr = 004CEFBC, Name = ThirdDynamic
3. MethodAddr = 004CF048, Name = FourthDynamic
Published methods in TMyClass
0. MethodAddr = 004CF370, Name = MsgHandler
1. MethodAddr = 004CEB48, Name = FirstPublished
2. MethodAddr = 004CEB50, Name = SecondPublished
3. MethodAddr = 004CEB58, Name = ThirdPublished
4. MethodAddr = 004CEB60, Name = FourthPublished
5. MethodAddr = 004CEB68, Name = ThirdPublished2
6. MethodAddr = 004CEB70, Name = FourthPublished2
Published methods in TObject
A=004CEB16
004CEB58=ThirdPublished
nil
004CEB58=ThirdPublished
004CEB58=ThirdPublished
nil
004CEF28=FirstDynamic
Published methods in TPropFixup
0. MethodAddr = 004CF374, Name = MakeGlobalReference
Published methods in TObject
  }
end.
