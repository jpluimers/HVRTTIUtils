program TestPolyPub;

{$APPTYPE CONSOLE}

uses
  Classes,
  SysUtils,
  TypInfo,
  Contnrs;

type
{$M+}
  TParent = class
  published
    procedure Polymorphic(const S: string);
  end;

  TChild = class
  published
    procedure Polymorphic(const S: string);
  end;

  TOther = class
  published
    procedure Polymorphic(const S: string);
  end;

procedure TParent.Polymorphic(const S: string);
begin
  Writeln('TParent.Polymorphic: ', S);
end;

procedure TChild.Polymorphic(const S: string);
begin
  Writeln('TChild.Polymorphic: ', S);
end;

procedure TOther.Polymorphic(const S: string);
begin
  Writeln('TOther.Polymorphic: ', S);
end;

function BuildList: TObjectList;
begin
  Result := TObjectList.Create;
  Result.Add(TParent.Create);
  Result.Add(TChild.Create);
  Result.Add(TOther.Create);
end;

type
  TPolymorphic = procedure(Self: TObject; const S: string);

procedure CallList(List: TObjectList);
var
  i: Integer;
  Instance: TObject;
  Polymorphic: procedure(Self: TObject; const S: string);
begin
  for i := 0 to List.Count - 1 do
  begin
    Instance := List[i];
    // Separate assign-and-call
    Polymorphic := Instance.MethodAddress('Polymorphic');
    if Assigned(Polymorphic) then
    begin
      Polymorphic(Instance, IntToStr(i));
      // Alternative syntax:
      TPolymorphic(Instance.MethodAddress('Polymorphic'))(Instance, IntToStr(i));
    end;
  end;
end;

begin
  CallList(BuildList);
  Readln;

  { Expected output:

TParent.Polymorphic: 0
TParent.Polymorphic: 0
TChild.Polymorphic: 1
TChild.Polymorphic: 1
TOther.Polymorphic: 2
TOther.Polymorphic: 2
  }
end.
