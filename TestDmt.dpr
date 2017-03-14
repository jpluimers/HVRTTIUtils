program TestDmt;

{$APPTYPE CONSOLE}

uses
  Classes,
  SysUtils,
  HVVMT in 'HVVMT.pas';

procedure GetDynaMethod;
{ function GetDynaMethod(vmt: TClass; selector: Smallint) : Pointer; }
asm
        { ->    EAX     vmt of class            }
        {       SI      dynamic method index    }
        { <-    ESI pointer to routine  }
        {       ZF = 0 if found         }
        {       trashes: EAX, ECX               }

        PUSH    EDI
        XCHG    EAX,ESI
        JMP     @@haveVMT
@@outerLoop:
        MOV     ESI,[ESI]
@@haveVMT:
        MOV     EDI,[ESI].vmtDynamicTable
        TEST    EDI,EDI
        JE      @@parent
        MOVZX   ECX,Word ptr [EDI]
        PUSH    ECX
        ADD     EDI,2
        REPNE   SCASW
        JE      @@found
        POP     ECX
@@parent:
        MOV     ESI,[ESI].vmtParent
        TEST    ESI,ESI
        JNE     @@outerLoop
        JMP     @@exit

@@found:
        POP     EAX
        ADD     EAX,EAX
        SUB     EAX,ECX         { this will always clear the Z-flag ! }
        MOV     ESI,[EDI+EAX*2-4]

@@exit:
        POP     EDI
end;

procedure _AbstractError;
asm
        CMP     AbstractErrorProc, 0
        JE      @@NoAbstErrProc
        CALL    AbstractErrorProc

@@NoAbstErrProc:
        MOV     EAX,210
        JMP     System.@RunError
end;

procedure _CallDynaInst;
asm
        PUSH    EAX
        PUSH    ECX
        MOV     EAX,[EAX]
        CALL    GetDynaMethod
        POP     ECX
        POP     EAX
        JE      @@Abstract
        JMP     ESI
@@Abstract:
        POP     ECX
        JMP     _AbstractError
end;

type
  // For easier use of the "dynamic" arrays
  TDynamicMethodTable = record
    Count: Word;
    Indicies: PDmtIndices; // really [0..Count-1]
    Methods: PDmtMethods; // really [0..Count-1]
  end;

function GetDmt(const AClass: TClass): PDmt;
var
  Vmt: PVmt;
begin
  Vmt := GetVmt(AClass);
  if Assigned(Vmt) then
    Result := Vmt.DynamicTable
  else
    Result := nil;
end;

function GetDynamicMethodCount(const AClass: TClass): Integer;
var
  Dmt: PDmt;
begin
  Dmt := GetDmt(AClass);
  if Assigned(Dmt) then
    Result := Dmt.Count
  else
    Result := 0;
end;

function GetDynamicMethodIndex(const AClass: TClass; const Slot: Integer): Integer;
var
  Dmt: PDmt;
begin
  Dmt := GetDmt(AClass);
  if Assigned(Dmt) and (Slot < Dmt.Count) then
    Result := Dmt.Indicies[Slot]
  else
    Result := 0; // Or raise exception
end;

function GetDynamicMethodProc(const AClass: TClass; const Slot: Integer): Pointer;
var
  Dmt: PDmt;
  DmtMethods: PDmtMethods;
begin
  Dmt := GetDmt(AClass);
  if Assigned(Dmt) and (Slot < Dmt.Count) then
  begin
    DmtMethods := @Dmt.Indicies[Dmt.Count];
    Result := DmtMethods[Slot];
  end
  else
    Result := nil; // Or raise exception
end;

function GetDynamicMethodTable(const AClass: TClass): TDynamicMethodTable;
var
  Dmt: PDmt;
begin
  Dmt := GetDmt(AClass);
  if Assigned(Dmt) then
  begin
    Result.Count := Dmt.Count;
    Result.Indicies := @Dmt.Indicies;
    Result.Methods := @Dmt.Indicies[Result.Count];
  end
  else
    Result.Count := 0;
end;

function FindDynamicMethod(const AClass: TClass; const DMTIndex: TDMTIndex): Pointer;
// Pascal variant of the faster BASM version in System.GetDynaMethod
var
  CurrentClass: TClass;
  Dmt: PDmt;
  DmtMethods: PDmtMethods;
  i: Integer;
begin
  CurrentClass := AClass;
  while Assigned(CurrentClass) do
  begin
    Dmt := GetDmt(CurrentClass);
    if Assigned(Dmt) then
      for i := 0 to Dmt.Count - 1 do
        if DMTIndex = Dmt.Indicies[i] then
        begin
          DmtMethods := @Dmt.Indicies[Dmt.Count];
          Result := DmtMethods[i];
          Exit;
        end;
    // Not in this class, try the parent class
    CurrentClass := CurrentClass.ClassParent;
  end;
  Result := nil;
end;

procedure DumpDynamicMethods(const AClass: TClass);
var
  CurrentClass: TClass;
  i: Integer;
  Index: Integer;
  MethodAddr: Pointer;
begin
  CurrentClass := AClass;
  while Assigned(CurrentClass) do
  begin
    Writeln('Dynamic methods in ', CurrentClass.ClassName);
    for i := 0 to GetDynamicMethodCount(CurrentClass) - 1 do
    begin
      Index := GetDynamicMethodIndex(CurrentClass, i);
      MethodAddr := GetDynamicMethodProc(CurrentClass, i);
      Writeln(Format('%d. Index = %2d, MethodAddr = %p', [i, Index, MethodAddr]));
    end;
    CurrentClass := CurrentClass.ClassParent;
  end;
end;

procedure DumpFoundDynamicMethods(const AClass: TClass);
  procedure Dump(const DMTIndex: TDMTIndex);
  var
    Proc: Pointer;
  begin
    Proc := FindDynamicMethod(AClass, DMTIndex);
    Writeln(Format('Dynamic Method Index = %2d, Method = %p', [DMTIndex, Proc]));
  end;

begin
  Dump(-1);
  Dump(1);
  Dump(13);
  Dump(42);
end;

type
  TMyClass = class
    procedure FirstDynamic; dynamic;
    procedure SecondDynamic; dynamic; abstract;
    class procedure ThirdDynamic; dynamic;
    class procedure FourthDynamic; dynamic;
    procedure MessageMethod(var Msg); message 42;
  end;

  TMyDescendent = class(TMyClass)
    procedure FirstDynamic; override;
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
    Assert(Instance.ClassType = TMyClass, 'Instance.ClassType ' + Instance.ClassType.ClassName + ' <> TMyClass ' + TMyClass.ClassName);
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

{$WARNINGS OFF} // Ignore abstract method warnings

procedure Test;
var
  Instance: TMyClass;
  Proc: procedure of object;
  Instances: TList;
begin
  Writeln(MyDynamicMethodIndex);
  Instance := TMyDescendent.Create;
  Writeln('Using compiler-magic/RTL mechanics:');
  Writeln('Call dynamic instance method (System._CallDynaInst)');
  Instance.FirstDynamic;
  Writeln('Find and call dynamic instance method (System._FindDynaInst)');
  Proc := Instance.SecondDynamic;
  Proc;
  Writeln('Call dynamic class method (System._CallDynaClass)');
  Instance.ThirdDynamic;
  Writeln('Find and call dynamic class method (System._FindDynaClass)');
  Proc := Instance.FourthDynamic;
  Proc;
  Writeln('Call dynamic instance method via BASM:');
  StaticCallFirstDynamicMethod(Instance);
  CallFirstDynamicMethod(Instance);
  DumpDynamicMethods(TMyDescendent);
  DumpFoundDynamicMethods(TMyDescendent);

  SlowDynamicLoop(Instance);
  FasterDynamicLoop(Instance);

  Instances := TList.Create;
  Instances.Add(TMyClass.Create);
  Instances.Add(TMyClass.Create);
  Instances.Add(TMyClass.Create);
  SlowDynamicListLoop(Instances);
  FasterDynamicListLoop(Instances);
  FasterDynamicListLoop2(Instances);
  Instances.Add(TMyDescendent2.Create);
  SlowDynamicListLoop(Instances);
  FasterDynamicListLoop2(Instances);
  FasterDynamicListLoop(Instances);
end;
{$WARNINGS ON}

begin
  try
    Test;
  except
    on E: Exception do
      Writeln(E.Message);
  end;
  Readln;

  { Not sure if this is the Expected output:

-1
Using compiler-magic/RTL mechanics:
Call dynamic instance method (System._CallDynaInst)
Find and call dynamic instance method (System._FindDynaInst)
TMyDescendent.SecondDynamic
Call dynamic class method (System._CallDynaClass)
TMyDescendent.ThirdDynamic
Find and call dynamic class method (System._FindDynaClass)
TMyDescendent.FourthDynamic
TMyDescendent.FourthDynamic
Call dynamic instance method via BASM:
Dynamic methods in TMyDescendent
0. Index = -1, MethodAddr = 00410854
1. Index = -2, MethodAddr = 00410858
2. Index = -3, MethodAddr = 004108AC
3. Index = -4, MethodAddr = 00410900
Dynamic methods in TMyClass
0. Index = -1, MethodAddr = 0041074C
1. Index = -2, MethodAddr = 00403080
2. Index = -3, MethodAddr = 00410750
3. Index = -4, MethodAddr = 004107A4
4. Index = 42, MethodAddr = 004107F8
Dynamic methods in TObject
Dynamic Method Index = -1, Method = 00410854
Dynamic Method Index =  1, Method = 00000000
Dynamic Method Index = 13, Method = 00000000
Dynamic Method Index = 42, Method = 004107F8
Instance.ClassType TMyDescendent2 <> TMyClass TMyClass (C:\Users\Developer\Versioned\HVRTTIUtils\TestDmt.dpr, line 334)
  }
end.
