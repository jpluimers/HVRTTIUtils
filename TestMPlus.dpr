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

procedure TMMinus.DefMethod;
begin
end;

procedure TMMinus.PubMethod;
begin
end;

procedure TMPlus.DefMethod;
begin
end;

procedure TMPlus.PubMethod;
begin
end;

procedure DumpMClass(AClass: TClass);
begin
  Writeln(Format('Testing %s:', [AClass.ClassName]));
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
  Readln;

  { Expected output like (all nil values must be nil, all non nil values must be non-nil):

Testing TMMinus:
DefField=00000000
DefProp=00000000
DefMethod=00000000
PubField=01E09D60
PubProp=004CE06F
PubMethod=004CE284

Testing TMPlus:
DefField=01E09D74
DefProp=004CE226
DefMethod=004CE288
PubField=01E09D90
PubProp=004CE248
PubMethod=004CE28C
  }
end.
