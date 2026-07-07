unit StatString;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections,
  Yaml, UnitStats, StatStringCondition, Engine.Language;

type
  TStatString = class
  private
    FString: string;
    FConditions: TArray<TStatStringCondition>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Load(const Node: TYamlNode);
    function GetConditions: TArray<TStatStringCondition>;
    function GetString: string;
    class function CalcStatString(CurrentStats: TUnitStats; StatStrings: TArray<TStatString>;
      PsiStrengthEval: Boolean; InTraining: Boolean): string; static;
    class function GetCurrentStats(CurrentStats: TUnitStats): TDictionary<string, Integer>; static;
  end;

implementation

{ TStatString }

constructor TStatString.Create;
begin
  inherited Create;
end;

destructor TStatString.Destroy;
begin
  for var cond in FConditions do cond.Free;
  inherited;
end;

procedure TStatString.Load(const Node: TYamlNode);
var
  condNames: array[0..11] of string = ('psiStrength', 'psiSkill', 'bravery', 'strength',
    'firing', 'reactions', 'stamina', 'tu', 'health', 'throwing', 'melee', 'psiTraining');
  i: Integer;
begin
  FString := Node['string'].AsString(FString);
  for i := 0 to High(condNames) do
  begin
    if Node.Has(condNames[i]) then
    begin
      var minVal := 0;
      var maxVal := 255;
      if Node[condNames[i]][0] then
        minVal := Node[condNames[i]][0].AsInteger(minVal);
      if Node[condNames[i]][1] then
        maxVal := Node[condNames[i]][1].AsInteger(maxVal);
      FConditions := FConditions + [TStatStringCondition.Create(condNames[i], minVal, maxVal)];
    end;
  end;
end;

function TStatString.GetConditions: TArray<TStatStringCondition>;
begin
  Result := FConditions;
end;

function TStatString.GetString: string;
begin
  Result := FString;
end;

class function TStatString.CalcStatString(CurrentStats: TUnitStats;
  StatStrings: TArray<TStatString>; PsiStrengthEval: Boolean;
  InTraining: Boolean): string;
var
  statsMap: TDictionary<string, Integer>;
  statStr: string;
begin
  Result := '';
  statsMap := GetCurrentStats(CurrentStats);
  try
    if InTraining then
      statsMap.Add('psiTraining', 1);
    for var rule in StatStrings do
    begin
      var conditionsMet := True;
      for var cond in rule.GetConditions do
      begin
        var val: Integer;
        if statsMap.TryGetValue(cond.GetConditionName, val) then
        begin
          if not cond.IsMet(val, (CurrentStats.PsiSkill > 0) or PsiStrengthEval) then
          begin
            conditionsMet := False;
            Break;
          end;
        end
        else
        begin
          conditionsMet := False;
          Break;
        end;
      end;
      if conditionsMet then
      begin
        Result := Result + rule.GetString;
        if Result.Length > 1 then
          Break;
      end;
    end;
  finally
    statsMap.Free;
  end;
end;

class function TStatString.GetCurrentStats(CurrentStats: TUnitStats): TDictionary<string, Integer>;
begin
  Result := TDictionary<string, Integer>.Create;
  Result.Add('psiStrength', CurrentStats.PsiStrength);
  Result.Add('psiSkill', CurrentStats.PsiSkill);
  Result.Add('bravery', CurrentStats.Bravery);
  Result.Add('strength', CurrentStats.Strength);
  Result.Add('firing', CurrentStats.Firing);
  Result.Add('reactions', CurrentStats.Reactions);
  Result.Add('stamina', CurrentStats.Stamina);
  Result.Add('tu', CurrentStats.TU);
  Result.Add('health', CurrentStats.Health);
  Result.Add('throwing', CurrentStats.Throwing);
  Result.Add('melee', CurrentStats.Melee);
end;

end.