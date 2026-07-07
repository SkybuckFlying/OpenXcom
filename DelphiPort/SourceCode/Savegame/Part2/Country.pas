unit Country;

interface

uses
  Classes, SysUtils, Generics.Collections, YAML, RuleCountry, RNG;

type
  TCountry = class
  private
    FRules: TRuleCountry;
    FPact: Boolean;
    FNewPact: Boolean;
    FFunding: TList<Integer>;
    FActivityXcom: TList<Integer>;
    FActivityAlien: TList<Integer>;
    FSatisfaction: Integer;
  public
    constructor Create(Rules: TRuleCountry; Gen: Boolean = True);
    destructor Destroy; override;
    procedure Load(const Node: TYamlNode);
    function Save: TYamlNode;
    property Rules: TRuleCountry read FRules;
    property Funding: TList<Integer> read FFunding;
    procedure SetFunding(Value: Integer);
    function Satisfaction: Integer;
    procedure AddActivityXcom(Activity: Integer);
    procedure AddActivityAlien(Activity: Integer);
    property ActivityXcom: TList<Integer> read FActivityXcom;
    property ActivityAlien: TList<Integer> read FActivityAlien;
    procedure NewMonth(XcomTotal, AlienTotal, PactScore: Integer);
    property NewPact: Boolean read FNewPact write FNewPact;
    property Pact: Boolean read FPact write FPact;
  end;

implementation

constructor TCountry.Create(Rules: TRuleCountry; Gen: Boolean);
begin
  FRules := Rules;
  FPact := False;
  FNewPact := False;
  FFunding := TList<Integer>.Create;
  FActivityXcom := TList<Integer>.Create;
  FActivityAlien := TList<Integer>.Create;
  FSatisfaction := 2;
  if Gen then
    FFunding.Add(Rules.GenerateFunding);
  FActivityAlien.Add(0);
  FActivityXcom.Add(0);
end;

destructor TCountry.Destroy;
begin
  FFunding.Free;
  FActivityXcom.Free;
  FActivityAlien.Free;
  inherited;
end;

procedure TCountry.Load(const Node: TYamlNode);
begin
  FFunding.Clear;
  for var v in Node['funding'] do FFunding.Add(v.AsInteger);
  FActivityXcom.Clear;
  for var v in Node['activityXcom'] do FActivityXcom.Add(v.AsInteger);
  FActivityAlien.Clear;
  for var v in Node['activityAlien'] do FActivityAlien.Add(v.AsInteger);
  FPact := Node['pact'].AsBoolean(FPact);
  FNewPact := Node['newPact'].AsBoolean(FNewPact);
end;

function TCountry.Save: TYamlNode;
begin
  Result := TYamlNode.Create;
  Result['type'] := FRules.Type;
  Result['funding'] := FFunding.ToArray;
  Result['activityXcom'] := FActivityXcom.ToArray;
  Result['activityAlien'] := FActivityAlien.ToArray;
  if FPact then Result['pact'] := FPact;
  if FNewPact then Result['newPact'] := FNewPact;
end;

procedure TCountry.SetFunding(Value: Integer);
begin
  FFunding[FFunding.Count - 1] := Value;
end;

function TCountry.Satisfaction: Integer;
begin
  if FPact then Result := 0 else Result := FSatisfaction;
end;

procedure TCountry.AddActivityXcom(Activity: Integer);
begin
  FActivityXcom[FActivityXcom.Count - 1] := FActivityXcom.Last + Activity;
end;

procedure TCountry.AddActivityAlien(Activity: Integer);
begin
  FActivityAlien[FActivityAlien.Count - 1] := FActivityAlien.Last + Activity;
end;

procedure TCountry.NewMonth(XcomTotal, AlienTotal, PactScore: Integer);
var
  funding, oldFunding, newFunding, good, bad: Integer;
begin
  FSatisfaction := 2;
  funding := FFunding.Last;
  good := (XcomTotal div 10) + FActivityXcom.Last;
  bad := (AlienTotal div 20) + FActivityAlien.Last;
  oldFunding := funding div 1000;
  newFunding := (oldFunding * RNG.Generate(5, 20) div 100) * 1000;
  if bad <= good + 30 then
  begin
    if good > bad + 30 then
    begin
      if RNG.Generate(0, good) > bad then
      begin
        var cap := FRules.FundingCap * 1000;
        if funding + newFunding > cap then
          newFunding := cap - funding;
        if newFunding > 0 then
          FSatisfaction := 3;
      end;
    end;
  end
  else
  begin
    if RNG.Generate(0, bad) > good then
    begin
      if newFunding > 0 then
      begin
        newFunding := -newFunding;
        if funding + newFunding < 0 then
          newFunding := -funding;
        if newFunding < 0 then
          FSatisfaction := 1;
      end;
    end;
  end;
  if FNewPact and not FPact then
  begin
    FNewPact := False;
    FPact := True;
    AddActivityAlien(PactScore);
  end;
  if FPact then
    FFunding.Add(0)
  else if FSatisfaction <> 2 then
    FFunding.Add(funding + newFunding)
  else
    FFunding.Add(funding);
  FActivityAlien.Add(0);
  FActivityXcom.Add(0);
  if FActivityAlien.Count > 12 then FActivityAlien.Delete(0);
  if FActivityXcom.Count > 12 then FActivityXcom.Delete(0);
  if FFunding.Count > 12 then FFunding.Delete(0);
end;

end.