program TestPubMethodTable;
 
{$APPTYPE CONSOLE}
 
uses
  Classes,
  SysUtils,
  TypInfo,
  HVVMT in 'HVVMT.pas';

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
 
procedure DumpPublishedMethodsFaster(AClass: TClass);
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
 
type
  {$M+}
  TMyClass = class
  published
    procedure FirstPublished; 
    procedure SecondPublished(A: integer); 
    procedure ThirdPublished(A: integer); stdcall; 
    function FourthPublished(A: TComponent): TComponent; stdcall; 
    procedure FifthPublished(Component: TComponent); stdcall; 
    function SixthPublished(A: string; Two, Three, Four, Five, Six: integer): string; pascal; 
  end;
 
procedure TMyClass.FirstPublished; 
begin 
end;
procedure TMyClass.SecondPublished; 
begin 
end;
procedure TMyClass.ThirdPublished; 
begin 
end;
function TMyClass.FourthPublished;
begin 
  Result := nil;
end;
procedure TMyClass.FifthPublished;
begin
end;
function TMyClass.SixthPublished;
begin 
end;
 
procedure DumpMethod(Method: PPublishedMethod);
begin
  if Assigned(Method) 
  then Writeln(Format('%p=%s', [Method.Address, Method.Name]))
  else Writeln('nil');
end;
 
procedure Test;
begin
  DumpPublishedMethods(TMyClass);
  DumpPublishedMethodsFaster(TMyClass);
  DumpMethod(FindPublishedMethodByName(TMyClass, 'FirstPublished'));
  DumpMethod(FindPublishedMethodByName(TMyClass, 
    FindPublishedMethodName(TMyClass, @TMyClass.SecondPublished)));
  DumpMethod(FindPublishedMethodByAddr(TMyClass, @TMyClass.ThirdPublished));
  DumpMethod(FindPublishedMethodByAddr(TMyClass, 
    FindPublishedMethodAddr(TMyClass, 'FourthPublished')));
  DumpMethod(FindPublishedMethodByAddr(TMyClass, 
    FindPublishedMethodByName(TMyClass, 'FifthPublished').Address));
  DumpMethod(FindPublishedMethodByAddr(TMyClass, @TMyClass.SixthPublished));
  DumpMethod(FindPublishedMethodByName(TMyClass, 'NotThere'));
  DumpMethod(FindPublishedMethodByAddr(TMyClass, nil));
end;

begin
  Test;
  readln;
end.


