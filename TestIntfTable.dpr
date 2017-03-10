program TestIntfTable;
 
{$APPTYPE CONSOLE}
 
uses
  Classes,
  SysUtils,
  TypInfo,
  ComObj;

procedure DumpInterfaces(AClass: TClass);
var
  i : integer;
  InterfaceTable: PInterfaceTable;
  InterfaceEntry: PInterfaceEntry;
begin
  while Assigned(AClass) do
  begin
    InterfaceTable := AClass.GetInterfaceTable;
    if Assigned(InterfaceTable) then
    begin
      writeln('Implemented interfaces in ', AClass.ClassName);
      for i := 0 to InterfaceTable.EntryCount-1 do
      begin
        InterfaceEntry := @InterfaceTable.Entries[i];
        writeln(Format('%d. GUID = %s', 
                       [i, GUIDToString(InterfaceEntry.IID)]));
      end;
    end;  
    AClass := AClass.ClassParent;
  end;
  writeln;
end;
 
begin
  DumpInterfaces(TComponent);
  DumpInterfaces(TComObject);
  DumpInterfaces(TComObjectFactory);
  readln;
end.
