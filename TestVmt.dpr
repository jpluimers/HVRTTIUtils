program TestVmt;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  HVVMT in 'HVVMT.pas';

function GetVmt(const Instance: TObject): PVmt; overload;
begin
  Result := HVVMT.GetVmt(Instance.ClassType);
end;

type
  TMyClass = class
    function SafeCallException(ExceptObject: TObject; ExceptAddr: Pointer): HResult; override;
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    procedure Dispatch(var Message); override;
    procedure DefaultHandler(var Message); override;
    class function NewInstance: TObject; override;
    procedure FreeInstance; override;
    destructor Destroy; override;
    procedure MethodA(var A: Integer); virtual;
    procedure MethodB(out A: Integer); virtual; abstract;
    function MethodC: Integer; virtual;
    procedure Method; virtual;
  end;

  TMyDescendent = class(TMyClass)
    procedure MethodA(var A: Integer); override;
    procedure MethodB(out A: Integer); override;
    function MethodC: Integer; override;
    procedure Method; override;
  end;

function MyMethodOffset: Integer;
asm
  MOV EAX, VMTOFFSET TMyClass.Method
end;

function MyMethodIndex: Integer;
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
  Writeln(ClassName, '.AfterConstruction');
end;

procedure TMyClass.BeforeDestruction;
begin
  Writeln(ClassName, '.BeforeDestruction');
  inherited;
end;

procedure TMyClass.DefaultHandler(var Message);
begin
  inherited;
  Writeln(ClassName, '.DefaultHandler');
end;

destructor TMyClass.Destroy;
begin
  Writeln(ClassName, '.Destroy');
  inherited;
end;

procedure TMyClass.Dispatch(var Message);
begin
  inherited;
  Writeln(ClassName, '.Dispatch');
end;

procedure TMyClass.FreeInstance;
begin
  Writeln(ClassName, '.FreeInstance');
  inherited;
end;

class function TMyClass.NewInstance: TObject;
begin
  Result := inherited NewInstance;
  Writeln(ClassName, '.NewInstance');
end;

function TMyClass.SafeCallException(ExceptObject: TObject; ExceptAddr: Pointer): HResult;
begin
  Result := inherited SafeCallException(ExceptObject, ExceptAddr);
  Writeln(ClassName, '.SafeCallException');
end;

procedure TMyClass.Method;
begin
  Writeln(ClassName, '.Method');
end;

procedure TMyClass.MethodA(var A: Integer);
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
  Writeln('SelfPtr = ', Vmt.SelfPtr.ClassName);
  Writeln('Parent = ', Vmt.Parent^.ClassName);
  Writeln(Vmt.ClassName^);
  Vmt^.SafeCallException(Instance, nil, nil);
  Vmt^.AfterConstruction(Instance);
  Vmt^.BeforeDestruction(Instance);
  Msg := 0;
  Vmt^.Dispatch(Instance, Msg);
  Vmt^.DefaultHandler(Instance, Msg);
  Instance2 := Vmt^.NewInstance(TMyClass) as TMyClass;
  Instance.Destroy;
  Vmt^.Destroy(Instance2, 1);
  Readln;
end;

procedure Test2;
var
  Instance: TMyClass;
begin
  Instance := TMyClass.Create;
  Writeln('VMT offset of Method: ', MyMethodOffset);
  Writeln('VMT Index of Method: ', MyMethodIndex);
  CallMyMethod(Instance);
  Readln;
end;
{$WARNINGS ON}
{ procedure TMyClass.MethodB(out A: Integer);
  begin
  A := 42;
  end; }

function TMyClass.MethodC: Integer;
begin
  Result := 43;
end;

{ TMyDescendent }

procedure TMyDescendent.Method;
begin
  inherited;

end;

procedure TMyDescendent.MethodA(var A: Integer);
begin
  inherited;

end;

procedure TMyDescendent.MethodB(out A: Integer);
begin
  inherited;
  Writeln(A);
end;

function TMyDescendent.MethodC: Integer;
begin
  // inherited; // Error
  // Result := inherited; // Error
  Result := inherited MethodC; // Ok
end;

procedure Test3;
var
  Instance: TMyClass;
  A: Integer;
begin
  Instance := TMyDescendent.Create;
  A := 123;
  Instance.MethodB(A);
  Readln;
end;

begin
  Test;
  Test3;

  // Test;
  // Test2;

  { Expected output:

TMyClass.NewInstance
TMyClass.AfterConstruction
Calling virtual methods explicitly through an obtained VMT pointer (playing the compiler):
SelfPtr = TMyClass
Parent = TObject
TMyClass
TMyClass.SafeCallException
TMyClass.AfterConstruction
TMyClass.BeforeDestruction
TMyClass.DefaultHandler
TMyClass.Dispatch
TMyClass.DefaultHandler
TMyClass.NewInstance
TMyClass.BeforeDestruction
TMyClass.Destroy
TMyClass.FreeInstance
TMyClass.BeforeDestruction
TMyClass.Destroy
TMyClass.FreeInstance
  }
end.
