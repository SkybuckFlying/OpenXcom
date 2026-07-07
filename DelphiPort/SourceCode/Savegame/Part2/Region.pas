unit Region;

interface

uses
  Classes, SysUtils, Generics.Collections, YAML, RuleRegion;

type
  TRegion = class
  private
    FRules: TRuleRegion;
    FActivityXcom: TList<Integer>;
    FActivityAlien: TList<Integer>;
  public
    constructor Create(Rules: TRuleRegion);
    destructor Destroy; override;
    procedure Load(const Node: TYamlNode);
    function Save: TYamlNode;
    property Rules: TRuleRegion read FRules;
    procedure AddActivityXcom(Activity: Integer);
    procedure AddActivityAlien(Activity: Integer);
    property ActivityXcom: TList<Integer> read FActivityXcom;
    property ActivityAlien: TList<Integer> read FActivityAlien;
    procedure NewMonth;
  end;

implementation

constructor TRegion.Create(Rules: TRuleRegion);
begin
  FRules := Rules;
  FActivityXcom := TList<Integer>.Create;
  FActivityAlien := TList<Integer>.Create;
  FActivityAlien.Add(0);
  FActivityXcom.Add(0);
end;

destructor TRegion.Destroy;
begin
  FActivityXcom.Free;
  FActivityAlien.Free;
  inherited;
end;

procedure TRegion.Load(const Node: TYamlNode);
begin
  FActivityXcom.Clear;
  for var v in Node['activityXcom'] do FActivityXcom.Add(v.AsInteger);
  FActivityAlien.Clear;
  for var v in Node['activityAlien'] do FActivityAlien.Add(v.AsInteger);
end;

function TRegion.Save: TYamlNode;
begin
  Result := TYamlNode.Create;
  Result['type'] := FRules.Type;
  Result['activityXcom'] := FActivityXcom.ToArray;
  Result['activityAlien'] := FActivityAlien.ToArray;
end;

procedure TRegion.AddActivityXcom(Activity: Integer);
begin
  FActivityXcom[FActivityXcom.Count - 1] := FActivityXcom.Last + Activity;
end;

procedure TRegion.AddActivityAlien(Activity: Integer);
begin
  FActivityAlien[FActivityAlien.Count - 1] := FActivityAlien.Last + Activity;
end;

procedure TRegion.NewMonth;
begin
  FActivityAlien.Add(0);
  FActivityXcom.Add(0);
  if FActivityAlien.Count > 12 then FActivityAlien.Delete(0);
  if FActivityXcom.Count > 12 then FActivityXcom.Delete(0);
end;

end.