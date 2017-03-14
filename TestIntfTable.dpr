program TestIntfTable;

{$APPTYPE CONSOLE}

uses
  Classes,
  SysUtils,
  TypInfo,
  ComObj;

procedure DumpInterfaces(AClass: TClass);
var
  i: Integer;
  InterfaceTable: PInterfaceTable;
  InterfaceEntry: PInterfaceEntry;
begin
  while Assigned(AClass) do
  begin
    InterfaceTable := AClass.GetInterfaceTable;
    if Assigned(InterfaceTable) then
    begin
      Writeln('Implemented interfaces in ', AClass.ClassName);
      for i := 0 to InterfaceTable.EntryCount - 1 do
      begin
        InterfaceEntry := @InterfaceTable.Entries[i];
        Writeln(Format('%d. GUID = %s', //
          [i, GUIDToString(InterfaceEntry.IID)]));
      end;
    end;
    AClass := AClass.ClassParent;
  end;
  Writeln;
end;

begin
  DumpInterfaces(TComponent);
  DumpInterfaces(TComObject);
  DumpInterfaces(TComObjectFactory);
  Readln;

  (* Expected output:

Implemented interfaces in TComponent
0. GUID = {E28B1858-EC86-4559-8FCD-6B4F824151ED }
1. GUID = { 00000000-0000-0000-C000-000000000046 }

Implemented interfaces in TComObject 0. GUID = { DF0B3D60-548F-101B-8E65-08002B2BD119 }
1. GUID = { 00000000-0000-0000-C000-000000000046 }

Implemented interfaces in TComObjectFactory 0. GUID = { B196B28F-BAB4-101A-B69C-00AA00341D07 }
1. GUID = { 00000001-0000-0000-C000-000000000046 }
2. GUID = { 00000000-0000-0000-C000-000000000046 }

  *)

end.
