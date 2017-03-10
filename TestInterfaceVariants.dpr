program TestInterfaceVariants;

{$APPTYPE CONSOLE}

uses Variants, SysUtils;


procedure Dump(const V: Variant);
begin
  with TVarData(V) do
    writeln(Format('%.4x:%.8x:%.8x:%.8x', [RawData[0], RawData[1], RawData[2], RawData[3]]));
end;

const
  NilInterface: IUnknown  = nil;
  NilDispatch : IDispatch = nil;
var
  V: Variant;
begin
  V := Unassigned;
  Dump(V);

  V := OleVariant(IUnknown(Unassigned));
  Dump(V);

  V := NilInterface;
  Dump(V);

  V := NilDispatch;
  Dump(V);

//  V := IUnknown(nil);  // [Error] Invalid typecast
//  Dump(V);

  readln;
{
0000:00000000:00000000:00000000
000D:00000000:00000000:00000000
000D:00000000:00000000:00000000
0009:00000000:00000000:00000000
}
end.

