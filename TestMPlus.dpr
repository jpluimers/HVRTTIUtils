program TestMPlus;
{$APPTYPE CONSOLE}

uses
  Classes,
  SysUtils,
  TypInfo;

type
  {$M-}
  TMMinus = class
    DefField: TObject;
    property DefProp: TObject read DefField write DefField;
    procedure DefMethod;
  published
    PubField: TObject;
    property PubProp: TObject read PubField write PubField;
    procedure PubMethod;
  end;
  {$M+}
  TMPlus = class
    DefField: TObject;
    property DefProp: TObject read DefField write DefField;
    procedure DefMethod;
  published
    PubField: TObject;
    property PubProp: TObject read PubField write PubField;
    procedure PubMethod;
  end;
 
procedure TMMinus.DefMethod; begin end;
procedure TMMinus.PubMethod; begin end;
procedure TMPlus.DefMethod; begin end;
procedure TMPlus.PubMethod; begin end;
 
procedure DumpMClass(AClass: TClass);
begin
  Writeln(Format('Testing %s:', [AClass.Classname]));
  Writeln(Format('DefField=%p', [AClass.Create.FieldAddress('DefField')]));
  Writeln(Format('DefProp=%p', [TypInfo.GetPropInfo(AClass, 'DefProp')]));
  Writeln(Format('DefMethod=%p', [AClass.MethodAddress('DefMethod')]));
  Writeln(Format('PubField=%p', [AClass.Create.FieldAddress('PubField')]));
  Writeln(Format('PubProp=%p', [TypInfo.GetPropInfo(AClass, 'PubProp')]));
  Writeln(Format('PubMethod=%p', [AClass.MethodAddress('PubMethod')]));
  Writeln;
end;

begin
  DumpMClass(TMMinus);
  DumpMClass(TMPlus);
  readln;
end.
