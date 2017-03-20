unit HVDMT;

interface

uses
  HVVMT;

function GetDmt(const AClass: TClass): PDmt;

function GetDynamicMethodCount(const AClass: TClass): Integer;

function GetDynamicMethodIndex(const AClass: TClass; const Slot: Integer): Integer;

function GetDynamicMethodProc(const AClass: TClass; const Slot: Integer): Pointer;

function FindDynamicMethod(const AClass: TClass; const DMTIndex: TDMTIndex): Pointer;

implementation

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

end.
