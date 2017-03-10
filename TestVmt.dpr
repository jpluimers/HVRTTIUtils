program TestVmt;

{$APPTYPE CONSOLE}

uses
  SysUtils;

type
  PClass = ^TClass;
  PSafeCallException = function  (Self: TObject; ExceptObject:
    TObject; ExceptAddr: Pointer): HResult;
  PAfterConstruction = procedure (Self: TObject);
  PBeforeDestruction = procedure (Self: TObject);
  PDispatch          = procedure (Self: TObject; var Message);
  PDefaultHandler    = procedure (Self: TObject; var Message);
  PNewInstance       = function  (Self: TClass) : TObject;
  PFreeInstance      = procedure (Self: TObject);
  PDestroy           = procedure (Self: TObject; OuterMost: ShortInt);
  PVmt = ^TVmt;
  TVmt = packed record
    SelfPtr           : TClass;
    IntfTable         : Pointer;
    AutoTable         : Pointer;
    InitTable         : Pointer;
    TypeInfo          : Pointer;
    FieldTable        : Pointer;
    MethodTable       : Pointer;
    DynamicTable      : Pointer;
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

function GetVmt(AClass: TClass): PVmt; overload;
begin
  Result := PVmt(AClass);
  Dec(Result);
end;

function GetVmt(Instance: TObject): PVmt; overload;
begin
  Result := GetVmt(Instance.ClassType);
end;

type
  TMyClass = class
    function SafeCallException(ExceptObject: TObject;
      ExceptAddr: Pointer): HResult; override;
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    procedure Dispatch(var Message); override;
    procedure DefaultHandler(var Message); override;
    class function NewInstance: TObject; override;
    procedure FreeInstance; override;
    destructor Destroy; override;
    procedure MethodA(var A: integer); virtual;
    procedure MethodB(out A: integer); virtual; abstract;
    function MethodC: integer; virtual;
    procedure Method; virtual;
  end;
  TMyDescendent = class(TMyClass)
    procedure MethodA(var A: integer); override;
    procedure MethodB(out A: integer); override;
    function MethodC: integer; override;
    procedure Method; override;
  end;

function MyMethodOffset: integer;
asm
  MOV EAX, VMTOFFSET TMyClass.Method
end;

function MyMethodIndex: integer;
begin
  Result := MyMethodOffset div SizeOf(Pointer);
end;

procedure CallMyMethod(Instance: TMyClass);
asm
  MOV    ECX, [EAX]
  CALL  [ECX + VMTOFFSET TMyClass.Method]
end;

procedure TMyClass.AfterConstruction;
begin
  inherited;
  writeln(ClassName, '.AfterConstruction');
end;

procedure TMyClass.BeforeDestruction;
begin
  writeln(ClassName, '.BeforeDestruction');
  inherited;
end;

procedure TMyClass.DefaultHandler(var Message);
begin
  inherited;
  writeln(ClassName, '.DefaultHandler');
end;

destructor TMyClass.Destroy;
begin
  writeln(ClassName, '.Destroy');
  inherited;
end;

procedure TMyClass.Dispatch(var Message);
begin
  inherited;
  writeln(ClassName, '.Dispatch');
end;

procedure TMyClass.FreeInstance;
begin
  writeln(ClassName, '.FreeInstance');
  inherited;
end;

class function TMyClass.NewInstance: TObject;
begin
  Result := inherited NewInstance;
  writeln(ClassName, '.NewInstance');
end;

function TMyClass.SafeCallException(ExceptObject: TObject; ExceptAddr: Pointer): HResult;
begin
  Result := inherited SafeCallException(ExceptObject, ExceptAddr);
  writeln(ClassName, '.SafeCallException');
end;

procedure TMyClass.Method;
begin
  writeln(ClassName, '.Method');
end;

procedure TMyClass.MethodA(var A: integer);
begin

end;

{$WARNINGS OFF} // Ignore abstract method warnings
procedure Test;
var
  Instance: TMyClass;
  Instance2: TMyClass;
  Vmt: PVmt;
  Msg: Word;
begin
  Instance := TMyClass.Create;
  Vmt := GetVmt(Instance);
  Writeln('Calling virtual methods explicitly through an obtained VMT pointer (playing the compiler):');
  writeln('SelfPtr = ', Vmt.SelfPtr.Classname);
  writeln('Parent = ', Vmt.Parent^.Classname);
  writeln(Vmt.Classname^);
  Vmt^.SafeCallException(Instance, nil, nil);
  Vmt^.AfterConstruction(Instance);
  Vmt^.BeforeDestruction(Instance);
  Msg := 0;
  Vmt^.Dispatch(Instance, Msg);
  Vmt^.DefaultHandler(Instance, Msg);
  Instance2 := Vmt^.NewInstance(TMyClass) as TMyClass;
  Instance.Destroy;
  Vmt^.Destroy(Instance2, 1);
  readln;
end;

procedure Test2;
var
  Instance: TMyClass;
begin
  Instance := TMyClass.Create;
  writeln('VMT offset of Method: ', MyMethodOffset);
  writeln('VMT Index of Method: ', MyMethodIndex);
  CallMyMethod(Instance);
  readln;
end;
{$WARNINGS ON} 

{procedure TMyClass.MethodB(out A: integer);
begin
  A := 42;
end;}

function TMyClass.MethodC: integer;
begin
  Result := 43;
end;

{ TMyDescendent }

procedure TMyDescendent.Method;
begin
  inherited;

end;

procedure TMyDescendent.MethodA(var A: integer);
begin
  inherited;

end;

procedure TMyDescendent.MethodB(out A: integer);
begin
  inherited;
  Writeln(A);
end;

function TMyDescendent.MethodC: integer;
begin
//  inherited; // Error
//  Result := inherited; // Error
  Result := inherited MethodC; // Ok
end;

procedure Test3;
var
  Instance: TMyClass;
  A: integer;
begin
  Instance := TMyDescendent.Create;
  A := 123;
  Instance.MethodB(A);
  readln;
end;
begin
  Test;
  Test3;
//  Test;
//  Test2;
end.


