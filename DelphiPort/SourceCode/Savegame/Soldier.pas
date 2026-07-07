unit Soldier;

interface

uses
  Classes, SysUtils, Generics.Collections, YAML, Mod, Craft, EquipmentLayoutItem,
  SoldierDeath, SoldierDiary, Armor, RuleSoldier, UnitStats, SavedGame, Language;

type
  TSoldierRank = (RANK_ROOKIE, RANK_SQUADDIE, RANK_SERGEANT, RANK_CAPTAIN, RANK_COLONEL, RANK_COMMANDER);
  TSoldierGender = (GENDER_MALE, GENDER_FEMALE);
  TSoldierLook = (LOOK_BLONDE, LOOK_BROWNHAIR, LOOK_ORIENTAL, LOOK_AFRICAN);

  TSoldier = class
  private
    FId: Integer;
    FName: string;
    FInitialStats: TUnitStats;
    FCurrentStats: TUnitStats;
    FRank: TSoldierRank;
    FCraft: TCraft;
    FGender: TSoldierGender;
    FLook: TSoldierLook;
    FMissions: Integer;
    FKills: Integer;
    FRecovery: Integer;
    FRecentlyPromoted: Boolean;
    FPsiTraining: Boolean;
    FArmor: TArmor;
    FEquipmentLayout: TObjectList<TEquipmentLayoutItem>;
    FDeath: TSoldierDeath;
    FDiary: TSoldierDiary;
    FRules: TRuleSoldier;
    FImprovement: Integer;
    FPsiStrImprovement: Integer;
    FStatString: string;
    procedure CalcStatString(const StatStrings: TArray<TStatString>; PsiStrengthEval: Boolean);
  public
    constructor Create(Rules: TRuleSoldier; Armor: TArmor; Id: Integer = 0);
    destructor Destroy; override;
    procedure Load(const Node: TYamlNode; Mod: TMod; Save: TSavedGame);
    function Save: TYamlNode;
    property Id: Integer read FId;
    property Name: string read FName write FName;
    function GetName(IncludeStatString: Boolean = False; MaxLength: Integer = 20): string;
    property Craft: TCraft read FCraft write FCraft;
    function GetCraftString(Lang: TLanguage): string;
    function GetRankString: string;
    function GetRankSprite: Integer;
    property Rank: TSoldierRank read FRank;
    procedure PromoteRank;
    property Missions: Integer read FMissions;
    property Kills: Integer read FKills;
    property Gender: TSoldierGender read FGender;
    property Look: TSoldierLook read FLook;
    property Rules: TRuleSoldier read FRules;
    procedure AddMissionCount;
    procedure AddKillCount(Count: Integer);
    property InitialStats: TUnitStats read FInitialStats;
    property CurrentStats: TUnitStats read FCurrentStats;
    function IsPromoted: Boolean;
    property Armor: TArmor read FArmor write FArmor;
    property WoundRecovery: Integer read FRecovery write FRecovery;
    procedure Heal;
    property EquipmentLayout: TObjectList<TEquipmentLayoutItem> read FEquipmentLayout;
    procedure TrainPsi;
    procedure TrainPsi1Day;
    property IsInPsiTraining: Boolean read FPsiTraining write FPsiTraining;
    property Improvement: Integer read FImprovement;
    property PsiStrImprovement: Integer read FPsiStrImprovement;
    property Death: TSoldierDeath read FDeath;
    procedure Die(Death: TSoldierDeath);
    property Diary: TSoldierDiary read FDiary;
  end;

implementation

uses
  RNG, Language, Mod, Options, Unicode;

constructor TSoldier.Create(Rules: TRuleSoldier; Armor: TArmor; Id: Integer);
var
  minStats, maxStats: TUnitStats;
  names: TArray<TSoldierNamePool>;
  nationality: Integer;
begin
  FRules := Rules;
  FArmor := Armor;
  FId := Id;
  FRank := RANK_ROOKIE;
  FCraft := nil;
  FMissions := 0;
  FKills := 0;
  FRecovery := 0;
  FRecentlyPromoted := False;
  FPsiTraining := False;
  FImprovement := 0;
  FPsiStrImprovement := 0;
  FEquipmentLayout := TObjectList<TEquipmentLayoutItem>.Create;
  FDiary := TSoldierDiary.Create;
  FDeath := nil;
  if Id <> 0 then
  begin
    minStats := Rules.MinStats;
    maxStats := Rules.MaxStats;
    FInitialStats.TU := RNG.Generate(minStats.TU, maxStats.TU);
    FInitialStats.Stamina := RNG.Generate(minStats.Stamina, maxStats.Stamina);
    FInitialStats.Health := RNG.Generate(minStats.Health, maxStats.Health);
    FInitialStats.Bravery := RNG.Generate(minStats.Bravery div 10, maxStats.Bravery div 10) * 10;
    FInitialStats.Reactions := RNG.Generate(minStats.Reactions, maxStats.Reactions);
    FInitialStats.Firing := RNG.Generate(minStats.Firing, maxStats.Firing);
    FInitialStats.Throwing := RNG.Generate(minStats.Throwing, maxStats.Throwing);
    FInitialStats.Strength := RNG.Generate(minStats.Strength, maxStats.Strength);
    FInitialStats.PsiStrength := RNG.Generate(minStats.PsiStrength, maxStats.PsiStrength);
    FInitialStats.Melee := RNG.Generate(minStats.Melee, maxStats.Melee);
    FInitialStats.PsiSkill := minStats.PsiSkill;
    FCurrentStats := FInitialStats;
    names := Rules.Names;
    if Length(names) > 0 then
    begin
      nationality := RNG.Generate(0, High(names));
      FName := names[nationality].GenName(FGender, Rules.FemaleFrequency);
      FLook := names[nationality].GenLook(4); // moddable
    end
    else
    begin
      if RNG.Percent(Rules.FemaleFrequency) then
        FGender := GENDER_FEMALE
      else
        FGender := GENDER_MALE;
      FLook := LOOK_BLONDE;
      if FGender = GENDER_FEMALE then
        FName := 'Jane Doe'
      else
        FName := 'John Doe';
    end;
  end;
end;

destructor TSoldier.Destroy;
begin
  FEquipmentLayout.Free;
  FDiary.Free;
  FDeath.Free;
  inherited;
end;

procedure TSoldier.Load(const Node: TYamlNode; Mod: TMod; Save: TSavedGame);
begin
  FId := Node['id'].AsInteger(FId);
  FName := Node['name'].AsString;
  FInitialStats := Node['initialStats'].As<TUnitStats>;
  FCurrentStats := Node['currentStats'].As<TUnitStats>;
  FRank := TSoldierRank(Node['rank'].AsInteger);
  FGender := TSoldierGender(Node['gender'].AsInteger);
  FLook := TSoldierLook(Node['look'].AsInteger);
  FMissions := Node['missions'].AsInteger(FMissions);
  FKills := Node['kills'].AsInteger(FKills);
  FRecovery := Node['recovery'].AsInteger(FRecovery);
  var armorType := Node['armor'].AsString;
  FArmor := Mod.GetArmor(armorType);
  if FArmor = nil then
    FArmor := Mod.GetArmor(Mod.GetSoldier(Mod.SoldiersList[0]).Armor);
  FPsiTraining := Node['psiTraining'].AsBoolean(FPsiTraining);
  FImprovement := Node['improvement'].AsInteger(FImprovement);
  FPsiStrImprovement := Node['psiStrImprovement'].AsInteger(FPsiStrImprovement);
  if Node['equipmentLayout'] <> nil then
  begin
    for var itemNode in Node['equipmentLayout'] do
    begin
      var item := TEquipmentLayoutItem.Create(itemNode);
      if Mod.GetInventory(item.Slot) <> nil then
        FEquipmentLayout.Add(item)
      else
        item.Free;
    end;
  end;
  if Node['death'] <> nil then
  begin
    FDeath := TSoldierDeath.Create;
    FDeath.Load(Node['death']);
  end;
  if Options.SoldierDiaries and (Node['diary'] <> nil) then
  begin
    FDiary.Free;
    FDiary := TSoldierDiary.Create;
    FDiary.Load(Node['diary'], Mod);
  end;
  CalcStatString(Mod.StatStrings, (Options.PsiStrengthEval and Save.IsResearched(Mod.PsiRequirements)));
end;

function TSoldier.Save: TYamlNode;
begin
  Result := TYamlNode.Create;
  Result['type'] := FRules.Type;
  Result['id'] := FId;
  Result['name'] := FName;
  Result['initialStats'] := FInitialStats.ToYaml;
  Result['currentStats'] := FCurrentStats.ToYaml;
  Result['rank'] := Ord(FRank);
  if FCraft <> nil then
    Result['craft'] := FCraft.SaveId;
  Result['gender'] := Ord(FGender);
  Result['look'] := Ord(FLook);
  Result['missions'] := FMissions;
  Result['kills'] := FKills;
  if FRecovery > 0 then Result['recovery'] := FRecovery;
  Result['armor'] := FArmor.Type;
  if FPsiTraining then Result['psiTraining'] := FPsiTraining;
  Result['improvement'] := FImprovement;
  Result['psiStrImprovement'] := FPsiStrImprovement;
  if FEquipmentLayout.Count > 0 then
    for var item in FEquipmentLayout do
      Result['equipmentLayout'].Add(item.Save);
  if FDeath <> nil then Result['death'] := FDeath.Save;
  if Options.SoldierDiaries and ((FDiary.MissionIdList.Count > 0) or (FDiary.SoldierCommendations.Count > 0) or (FDiary.MonthsService > 0)) then
    Result['diary'] := FDiary.Save;
end;

function TSoldier.GetName(IncludeStatString: Boolean; MaxLength: Integer): string;
var
  uName: string;
begin
  if IncludeStatString and (FStatString <> '') then
  begin
    uName := Unicode.Utf8ToUtf32(FName);
    if Length(uName) + Length(FStatString) > MaxLength then
      Result := Unicode.Utf32ToUtf8(Copy(uName, 1, MaxLength - Length(FStatString))) + '/' + FStatString
    else
      Result := FName + '/' + FStatString;
  end
  else
    Result := FName;
end;

function TSoldier.GetCraftString(Lang: TLanguage): string;
begin
  if FRecovery > 0 then
    Result := Lang.GetString('STR_WOUNDED')
  else if FCraft = nil then
    Result := Lang.GetString('STR_NONE_UC')
  else
    Result := FCraft.GetName(Lang);
end;

function TSoldier.GetRankString: string;
begin
  case FRank of
    RANK_ROOKIE: Result := 'STR_ROOKIE';
    RANK_SQUADDIE: Result := 'STR_SQUADDIE';
    RANK_SERGEANT: Result := 'STR_SERGEANT';
    RANK_CAPTAIN: Result := 'STR_CAPTAIN';
    RANK_COLONEL: Result := 'STR_COLONEL';
    RANK_COMMANDER: Result := 'STR_COMMANDER';
  else Result := '';
  end;
end;

function TSoldier.GetRankSprite: Integer;
begin
  Result := 42 + Ord(FRank);
end;

procedure TSoldier.PromoteRank;
begin
  FRank := TSoldierRank(Ord(FRank) + 1);
  if FRank > RANK_SQUADDIE then
    FRecentlyPromoted := True;
end;

procedure TSoldier.AddMissionCount;
begin
  Inc(FMissions);
end;

procedure TSoldier.AddKillCount(Count: Integer);
begin
  Inc(FKills, Count);
end;

function TSoldier.IsPromoted: Boolean;
begin
  Result := FRecentlyPromoted;
  FRecentlyPromoted := False;
end;

procedure TSoldier.Heal;
begin
  Dec(FRecovery);
end;

procedure TSoldier.TrainPsi;
var
  skillCap, strengthCap: Integer;
begin
  skillCap := FRules.StatCaps.PsiSkill;
  strengthCap := FRules.StatCaps.PsiStrength;
  FImprovement := 0;
  FPsiStrImprovement := 0;
  if FCurrentStats.PsiSkill < FRules.MinStats.PsiSkill then
    FCurrentStats.PsiSkill := FRules.MinStats.PsiSkill
  else if FCurrentStats.PsiSkill <= FRules.MaxStats.PsiSkill then
  begin
    var max := FRules.MaxStats.PsiSkill + FRules.MaxStats.PsiSkill div 2;
    FImprovement := RNG.Generate(FRules.MaxStats.PsiSkill, max);
  end
  else
  begin
    if FCurrentStats.PsiSkill <= skillCap div 2 then
      FImprovement := RNG.Generate(5, 12)
    else if FCurrentStats.PsiSkill < skillCap then
      FImprovement := RNG.Generate(1, 3);
    if Options.AllowPsiStrengthImprovement then
    begin
      if FCurrentStats.PsiStrength <= strengthCap div 2 then
        FPsiStrImprovement := RNG.Generate(5, 12)
      else if FCurrentStats.PsiStrength < strengthCap then
        FPsiStrImprovement := RNG.Generate(1, 3);
    end;
  end;
  FCurrentStats.PsiSkill := FCurrentStats.PsiSkill + FImprovement;
  FCurrentStats.PsiStrength := FCurrentStats.PsiStrength + FPsiStrImprovement;
  if FCurrentStats.PsiSkill > skillCap then FCurrentStats.PsiSkill := skillCap;
  if FCurrentStats.PsiStrength > strengthCap then FCurrentStats.PsiStrength := strengthCap;
end;

procedure TSoldier.TrainPsi1Day;
begin
  if not FPsiTraining then
  begin
    FImprovement := 0;
    Exit;
  end;
  if FCurrentStats.PsiSkill > 0 then
  begin
    if (8 * 100 >= FCurrentStats.PsiSkill * RNG.Generate(1, 100)) and (FCurrentStats.PsiSkill < FRules.StatCaps.PsiSkill) then
    begin
      Inc(FImprovement);
      Inc(FCurrentStats.PsiSkill);
    end;
    if Options.AllowPsiStrengthImprovement then
    begin
      if (8 * 100 >= FCurrentStats.PsiStrength * RNG.Generate(1, 100)) and (FCurrentStats.PsiStrength < FRules.StatCaps.PsiStrength) then
      begin
        Inc(FPsiStrImprovement);
        Inc(FCurrentStats.PsiStrength);
      end;
    end;
  end
  else if FCurrentStats.PsiSkill < FRules.MinStats.PsiSkill then
  begin
    Inc(FCurrentStats.PsiSkill);
    if FCurrentStats.PsiSkill = FRules.MinStats.PsiSkill then
    begin
      FImprovement := FRules.MaxStats.PsiSkill + RNG.Generate(0, FRules.MaxStats.PsiSkill div 2);
      FCurrentStats.PsiSkill := FImprovement;
    end;
  end
  else
    FCurrentStats.PsiSkill := FCurrentStats.PsiSkill - RNG.Generate(30, 60);
end;

procedure TSoldier.Die(Death: TSoldierDeath);
begin
  FDeath.Free;
  FDeath := Death;
  FCraft := nil;
  FPsiTraining := False;
  FRecentlyPromoted := False;
  FRecovery := 0;
  FEquipmentLayout.Clear;
end;

procedure TSoldier.CalcStatString(const StatStrings: TArray<TStatString>; PsiStrengthEval: Boolean);
begin
  FStatString := TStatString.CalcStatString(FCurrentStats, StatStrings, PsiStrengthEval, FPsiTraining);
end;

end.