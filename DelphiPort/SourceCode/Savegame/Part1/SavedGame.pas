unit SavedGame;

interface

uses
  Classes, SysUtils, Generics.Collections, YAML, GameTime, Country, Base, Region,
  Ufo, Waypoint, MissionSite, AlienBase, AlienStrategy, AlienMission, SavedBattleGame,
  ResearchProject, Soldier, RuleResearch, RuleManufacture, Production, Craft, Target,
  Mod;

type
  TGameDifficulty = (diffBeginner, diffExperienced, diffVeteran, diffGenius, diffSuperhuman);
  TGameEnding = (endNone, endWin, endLose);
  TSaveType = (stDefault, stQuick, stAutoGeoscape, stAutoBattlescape, stIronman, stIronmanEnd);

  TSaveInfo = record
    FileName: string;
    DisplayName: string;
    Timestamp: TDateTime;
    IsoDate: string;
    IsoTime: string;
    Details: string;
    Mods: TArray<string>;
    Reserved: Boolean;
  end;

  TPromotionInfo = record
    TotalCommanders: Integer;
    TotalColonels: Integer;
    TotalCaptains: Integer;
    TotalSergeants: Integer;
  end;

  TSavedGame = class
  private
    FName: string;
    FDifficulty: TGameDifficulty;
    FEnding: TGameEnding;
    FIronman: Boolean;
    FTime: TGameTime;
    FResearchScores: TList<Integer>;
    FFunds: TList<Int64>;
    FMaintenance: TList<Int64>;
    FIncomes: TList<Int64>;
    FExpenditures: TList<Int64>;
    FGlobeLon: Double;
    FGlobeLat: Double;
    FGlobeZoom: Integer;
    FIds: TDictionary<string, Integer>;
    FCountries: TObjectList<TCountry>;
    FRegions: TObjectList<TRegion>;
    FBases: TObjectList<TBase>;
    FUfos: TObjectList<TUfo>;
    FWaypoints: TObjectList<TWaypoint>;
    FMissionSites: TObjectList<TMissionSite>;
    FAlienBases: TObjectList<TAlienBase>;
    FAlienStrategy: TAlienStrategy;
    FActiveMissions: TObjectList<TAlienMission>;
    FDiscoveredResearch: TList<TRuleResearch>;
    FPoppedResearch: TList<TRuleResearch>;
    FDeadSoldiers: TObjectList<TSoldier>;
    FBattleGame: TSavedBattleGame;
    FDebug: Boolean;
    FWarned: Boolean;
    FMonthsPassed: Integer;
    FGraphRegionToggles: string;
    FGraphCountryToggles: string;
    FGraphFinanceToggles: string;
    FSelectedBase: Integer;
    FLastSelectedArmor: string;
    FMissionStatistics: TObjectList<TMissionStatistics>;

    function GetSelectedBase: TBase;
    procedure SetSelectedBase(Index: Integer);
    function GetFunds: Int64;
    procedure SetFunds(Value: Int64);
    procedure ProcessSoldier(Soldier: TSoldier; var Info: TPromotionInfo);
    function InspectSoldiers(const Soldiers, Participants: TArray<TSoldier>; Rank: Integer): TSoldier;
    function GetSoldierScore(Soldier: TSoldier): Integer;
  public
    const AUTOSAVE_GEOSCAPE = '_autogeo_.asav';
    const AUTOSAVE_BATTLESCAPE = '_autobattle_.asav';
    const QUICKSAVE = '_quick_.asav';

    constructor Create;
    destructor Destroy; override;

    class function SanitizeModName(const Name: string): string;
    class function GetList(Lang: TLanguage; AutoQuick: Boolean): TArray<TSaveInfo>;
    class function GetSaveInfo(const FileName: string; Lang: TLanguage): TSaveInfo;

    procedure Load(const Filename: string; Mod: TMod);
    procedure Save(const Filename: string);

    property Name: string read FName write FName;
    property Difficulty: TGameDifficulty read FDifficulty write FDifficulty;
    function DifficultyCoefficient: Integer;
    property Ending: TGameEnding read FEnding write FEnding;
    property Ironman: Boolean read FIronman write FIronman;
    property Time: TGameTime read FTime write SetTime;
    property Funds: Int64 read GetFunds write SetFunds;
    property FundsList: TList<Int64> read FFunds;
    property GlobeLongitude: Double read FGlobeLon write FGlobeLon;
    property GlobeLatitude: Double read FGlobeLat write FGlobeLat;
    property GlobeZoom: Integer read FGlobeZoom write FGlobeZoom;
    property Ids: TDictionary<string, Integer> read FIds;

    function GetId(const Name: string): Integer;
    procedure SetAllIds(const Ids: TDictionary<string, Integer>);

    property Countries: TObjectList<TCountry> read FCountries;
    function CountryFunding: Integer;

    property Regions: TObjectList<TRegion> read FRegions;
    property Bases: TObjectList<TBase> read FBases;
    function BaseMaintenance: Integer;

    procedure MonthlyFunding;

    property Ufos: TObjectList<TUfo> read FUfos;
    property Waypoints: TObjectList<TWaypoint> read FWaypoints;
    property MissionSites: TObjectList<TMissionSite> read FMissionSites;

    property AlienBases: TObjectList<TAlienBase> read FAlienBases;
    property AlienStrategy: TAlienStrategy read FAlienStrategy;

    property ActiveMissions: TObjectList<TAlienMission> read FActiveMissions;
    function FindAlienMission(const Region: string; Objective: TMissionObjective): TAlienMission;

    property SavedBattle: TSavedBattleGame read FBattleGame write SetBattleGame;

    procedure AddFinishedResearchSimple(Research: TRuleResearch);
    procedure AddFinishedResearch(Research: TRuleResearch; Mod: TMod; Base: TBase; Score: Boolean = True);
    function GetAvailableResearchProjects(Mod: TMod; Base: TBase; ConsiderDebug: Boolean = False): TArray<TRuleResearch>;
    procedure GetNewlyAvailableResearchProjects(const Before, After: TArray<TRuleResearch>; var Diff: TArray<TRuleResearch>);

    function GetAvailableProductions(Mod: TMod; Base: TBase): TArray<TRuleManufacture>;
    procedure GetDependableManufacture(Research: TRuleResearch; Mod: TMod; Base: TBase; var Dependables: TArray<TRuleManufacture>);

    function HasUndiscoveredProtectedUnlock(R: TRuleResearch; Mod: TMod): Boolean;
    function IsResearched(const Research: string; ConsiderDebug: Boolean = True): Boolean; overload;
    function IsResearched(const Research: TArray<string>; ConsiderDebug: Boolean = True): Boolean; overload;

    function GetSoldier(Id: Integer): TSoldier;

    function HandlePromotions(Participants: TArray<TSoldier>): Boolean;

    function GetSelectedBase: TBase;
    procedure SetSelectedBase(Index: Integer);

    procedure SetDebugMode;
    property DebugMode: Boolean read FDebug;

    property Maintenances: TList<Int64> read FMaintenance;
    procedure AddResearchScore(Score: Integer);
    property ResearchScores: TList<Integer> read FResearchScores;
    property Incomes: TList<Int64> read FIncomes;
    property Expenditures: TList<Int64> read FExpenditures;

    property Warned: Boolean read FWarned write FWarned;

    function LocateRegion(Lon, Lat: Double): TRegion; overload;
    function LocateRegion(const Target: TTarget): TRegion; overload;

    property MonthsPassed: Integer read FMonthsPassed;
    property GraphRegionToggles: string read FGraphRegionToggles write FGraphRegionToggles;
    property GraphCountryToggles: string read FGraphCountryToggles write FGraphCountryToggles;
    property GraphFinanceToggles: string read FGraphFinanceToggles write FGraphFinanceToggles;

    procedure AddMonth;

    procedure AddPoppedResearch(Research: TRuleResearch);
    function WasResearchPopped(Research: TRuleResearch): Boolean;
    procedure RemovePoppedResearch(Research: TRuleResearch);

    property DeadSoldiers: TObjectList<TSoldier> read FDeadSoldiers;

    property LastSelectedArmor: string read FLastSelectedArmor write FLastSelectedArmor;

    property MissionStatistics: TObjectList<TMissionStatistics> read FMissionStatistics;

    function KillSoldier(Soldier: TSoldier; Cause: TBattleUnitKills = nil): Integer;

    procedure SetTime(const Time: TGameTime);
    procedure SetBattleGame(Battle: TSavedBattleGame);
  end;

implementation

uses
  Math, RNG, SerializationHelper, RuleSoldier, Armor;

constructor TSavedGame.Create;
begin
  FTime := TGameTime.Create(6, 1, 1, 1999, 12, 0, 0);
  FResearchScores := TList<Integer>.Create;
  FFunds := TList<Int64>.Create;
  FFunds.Add(0);
  FMaintenance := TList<Int64>.Create;
  FMaintenance.Add(0);
  FIncomes := TList<Int64>.Create;
  FIncomes.Add(0);
  FExpenditures := TList<Int64>.Create;
  FExpenditures.Add(0);
  FIds := TDictionary<string, Integer>.Create;
  FCountries := TObjectList<TCountry>.Create;
  FRegions := TObjectList<TRegion>.Create;
  FBases := TObjectList<TBase>.Create;
  FUfos := TObjectList<TUfo>.Create;
  FWaypoints := TObjectList<TWaypoint>.Create;
  FMissionSites := TObjectList<TMissionSite>.Create;
  FAlienBases := TObjectList<TAlienBase>.Create;
  FAlienStrategy := TAlienStrategy.Create;
  FActiveMissions := TObjectList<TAlienMission>.Create;
  FDiscoveredResearch := TList<TRuleResearch>.Create;
  FPoppedResearch := TList<TRuleResearch>.Create;
  FDeadSoldiers := TObjectList<TSoldier>.Create;
  FMissionStatistics := TObjectList<TMissionStatistics>.Create;
  FBattleGame := nil;
  FDifficulty := diffBeginner;
  FEnding := endNone;
  FIronman := False;
  FDebug := False;
  FWarned := False;
  FMonthsPassed := -1;
  FSelectedBase := 0;
  FLastSelectedArmor := 'STR_NONE_UC';
end;

destructor TSavedGame.Destroy;
begin
  FTime.Free;
  FResearchScores.Free;
  FFunds.Free;
  FMaintenance.Free;
  FIncomes.Free;
  FExpenditures.Free;
  FIds.Free;
  FCountries.Free;
  FRegions.Free;
  FBases.Free;
  FUfos.Free;
  FWaypoints.Free;
  FMissionSites.Free;
  FAlienBases.Free;
  FAlienStrategy.Free;
  FActiveMissions.Free;
  FDiscoveredResearch.Free;
  FPoppedResearch.Free;
  FDeadSoldiers.Free;
  FMissionStatistics.Free;
  FBattleGame.Free;
  inherited;
end;

class function TSavedGame.SanitizeModName(const Name: string): string;
var
  p: Integer;
begin
  p := Pos(' ver: ', Name);
  if p > 0 then
    Result := Copy(Name, 1, p - 1)
  else
    Result := Name;
end;

class function TSavedGame.GetList(Lang: TLanguage; AutoQuick: Boolean): TArray<TSaveInfo>;
begin
  // Placeholder: implement file scanning
  SetLength(Result, 0);
end;

class function TSavedGame.GetSaveInfo(const FileName: string; Lang: TLanguage): TSaveInfo;
begin
  // Placeholder
end;

procedure TSavedGame.Load(const Filename: string; Mod: TMod);
begin
  // Placeholder: YAML load
end;

procedure TSavedGame.Save(const Filename: string);
begin
  // Placeholder: YAML save
end;

function TSavedGame.DifficultyCoefficient: Integer;
begin
  Result := TMod.DIFFICULTY_COEFFICIENT[Ord(FDifficulty)];
end;

function TSavedGame.GetFunds: Int64;
begin
  Result := FFunds.Last;
end;

procedure TSavedGame.SetFunds(Value: Int64);
var
  diff: Int64;
begin
  diff := Value - FFunds.Last;
  if diff > 0 then
    FIncomes.Last := FIncomes.Last + diff
  else
    FExpenditures.Last := FExpenditures.Last - diff;
  FFunds.Last := Value;
end;

function TSavedGame.GetId(const Name: string): Integer;
begin
  if not FIds.TryGetValue(Name, Result) then
  begin
    Result := 1;
    FIds.Add(Name, Result + 1);
  end
  else
  begin
    Inc(Result);
    FIds[Name] := Result;
  end;
end;

procedure TSavedGame.SetAllIds(const Ids: TDictionary<string, Integer>);
var
  pair: TPair<string, Integer>;
begin
  FIds.Clear;
  for pair in Ids do
    FIds.Add(pair.Key, pair.Value);
end;

function TSavedGame.CountryFunding: Integer;
var
  c: TCountry;
begin
  Result := 0;
  for c in FCountries do
    Result := Result + c.Funding.Last;
end;

function TSavedGame.BaseMaintenance: Integer;
var
  b: TBase;
begin
  Result := 0;
  for b in FBases do
    Result := Result + b.MonthlyMaintenance;
end;

procedure TSavedGame.MonthlyFunding;
begin
  SetFunds(GetFunds + CountryFunding - BaseMaintenance);
  FFunds.Add(GetFunds);
  FMaintenance.Add(BaseMaintenance);
  FIncomes.Add(CountryFunding);
  FExpenditures.Add(BaseMaintenance);
  FResearchScores.Add(0);
  while FIncomes.Count > 12 do FIncomes.Delete(0);
  while FExpenditures.Count > 12 do FExpenditures.Delete(0);
  while FResearchScores.Count > 12 do FResearchScores.Delete(0);
  while FFunds.Count > 12 do FFunds.Delete(0);
  while FMaintenance.Count > 12 do FMaintenance.Delete(0);
end;

function TSavedGame.FindAlienMission(const Region: string; Objective: TMissionObjective): TAlienMission;
var
  m: TAlienMission;
begin
  for m in FActiveMissions do
    if (m.Region = Region) and (m.Rules.Objective = Objective) then
      Exit(m);
  Result := nil;
end;

procedure TSavedGame.AddFinishedResearchSimple(Research: TRuleResearch);
begin
  if not FDiscoveredResearch.Contains(Research) then
    FDiscoveredResearch.Add(Research);
end;

procedure TSavedGame.AddFinishedResearch(Research: TRuleResearch; Mod: TMod; Base: TBase; Score: Boolean);
var
  queue: TList<TRuleResearch>;
  i: Integer;
  current: TRuleResearch;
  hasUndiscovered: Boolean;
  available: TArray<TRuleResearch>;
  j: Integer;
begin
  queue := TList<TRuleResearch>.Create;
  try
    queue.Add(Research);
    i := 0;
    while i < queue.Count do
    begin
      current := queue[i];
      hasUndiscovered := HasUndiscoveredProtectedUnlock(current, Mod);
      if not IsResearched(current.Name, False) then
      begin
        FDiscoveredResearch.Add(current);
        if not hasUndiscovered and IsResearched(current.GetOneFree, False) then
          RemovePoppedResearch(current);
        if Score then
          AddResearchScore(current.Points);
      end
      else
      begin
        if not hasUndiscovered then
        begin
          Inc(i);
          Continue;
        end;
      end;

      available := GetAvailableResearchProjects(Mod, Base, False);
      for j := 0 to High(available) do
      begin
        if available[j].Cost = 0 then
        begin
          if not queue.Contains(available[j]) then
          begin
            if available[j].Requirements = [] then
              queue.Add(available[j])
            else
            begin
              for var unlock in current.Unlocked do
                if available[j].Name = unlock then
                begin
                  queue.Add(available[j]);
                  Break;
                end;
            end;
          end;
        end;
      end;
      Inc(i);
    end;
  finally
    queue.Free;
  end;
end;

function TSavedGame.GetAvailableResearchProjects(Mod: TMod; Base: TBase; ConsiderDebug: Boolean): TArray<TRuleResearch>;
var
  unlocked: TList<TRuleResearch>;
  research: TRuleResearch;
  i: Integer;
begin
  unlocked := TList<TRuleResearch>.Create;
  try
    for var r in FDiscoveredResearch do
      for var u in r.Unlocked do
        unlocked.Add(Mod.GetResearch(u));

    Result := [];
    for var name in Mod.ResearchList do
    begin
      research := Mod.GetResearch(name);
      if ConsiderDebug and FDebug then
        // allowed
      else if not unlocked.Contains(research) then
      begin
        if not IsResearched(research.Dependencies, ConsiderDebug) then
          Continue;
      end;

      if not IsResearched(research.Requirements, ConsiderDebug) then
        Continue;

      if IsResearched(research.Name, False) then
      begin
        if not IsResearched(research.GetOneFree, False) then
          // keep
        else if not HasUndiscoveredProtectedUnlock(research, Mod) then
          Continue;
      end;

      if Base <> nil then
      begin
        if Base.ResearchProjects.Find(function(p: TResearchProject): Boolean begin Result := p.Rules = research; end) <> nil then
          Continue;
        if research.NeedItem and (Base.StorageItems.GetItem(research.Name) = 0) then
          Continue;
      end
      else
      begin
        if research.NeedItem and (research.Cost = 0) then
          Continue;
      end;

      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := research;
    end;
  finally
    unlocked.Free;
  end;
end;

procedure TSavedGame.GetNewlyAvailableResearchProjects(const Before, After: TArray<TRuleResearch>; var Diff: TArray<TRuleResearch>);
var
  i, j: Integer;
  found: Boolean;
begin
  Diff := [];
  for i := 0 to High(After) do
  begin
    found := False;
    for j := 0 to High(Before) do
      if After[i] = Before[j] then
      begin
        found := True;
        Break;
      end;
    if not found then
    begin
      SetLength(Diff, Length(Diff) + 1);
      Diff[High(Diff)] := After[i];
    end;
  end;
end;

function TSavedGame.GetAvailableProductions(Mod: TMod; Base: TBase): TArray<TRuleManufacture>;
begin
  // Placeholder
end;

procedure TSavedGame.GetDependableManufacture(Research: TRuleResearch; Mod: TMod; Base: TBase; var Dependables: TArray<TRuleManufacture>);
begin
  // Placeholder
end;

function TSavedGame.HasUndiscoveredProtectedUnlock(R: TRuleResearch; Mod: TMod): Boolean;
var
  unlock: TRuleResearch;
begin
  for var u in R.Unlocked do
  begin
    unlock := Mod.GetResearch(u);
    if unlock.Requirements <> [] then
      if not IsResearched(unlock.Name, False) then
        Exit(True);
  end;
  Result := False;
end;

function TSavedGame.IsResearched(const Research: string; ConsiderDebug: Boolean): Boolean;
begin
  if ConsiderDebug and FDebug then Exit(True);
  for var r in FDiscoveredResearch do
    if r.Name = Research then Exit(True);
  Result := False;
end;

function TSavedGame.IsResearched(const Research: TArray<string>; ConsiderDebug: Boolean): Boolean;
begin
  if ConsiderDebug and FDebug then Exit(True);
  for var s in Research do
    if not IsResearched(s, False) then
      Exit(False);
  Result := True;
end;

function TSavedGame.GetSoldier(Id: Integer): TSoldier;
var
  b: TBase;
  s: TSoldier;
begin
  for b in FBases do
    for s in b.Soldiers do
      if s.Id = Id then Exit(s);
  for s in FDeadSoldiers do
    if s.Id = Id then Exit(s);
  Result := nil;
end;

function TSavedGame.GetSelectedBase: TBase;
begin
  if (FSelectedBase >= 0) and (FSelectedBase < FBases.Count) then
    Result := FBases[FSelectedBase]
  else if FBases.Count > 0 then
    Result := FBases[0]
  else
    Result := nil;
end;

procedure TSavedGame.SetSelectedBase(Index: Integer);
begin
  FSelectedBase := Index;
end;

procedure TSavedGame.SetDebugMode;
begin
  FDebug := not FDebug;
end;

procedure TSavedGame.AddResearchScore(Score: Integer);
begin
  FResearchScores.Last := FResearchScores.Last + Score;
end;

function TSavedGame.LocateRegion(Lon, Lat: Double): TRegion;
var
  r: TRegion;
begin
  for r in FRegions do
    if r.Rules.InsideRegion(Lon, Lat) then Exit(r);
  Result := nil;
end;

function TSavedGame.LocateRegion(const Target: TTarget): TRegion;
begin
  Result := LocateRegion(Target.Longitude, Target.Latitude);
end;

procedure TSavedGame.AddMonth;
begin
  Inc(FMonthsPassed);
end;

procedure TSavedGame.AddPoppedResearch(Research: TRuleResearch);
begin
  if not FPoppedResearch.Contains(Research) then
    FPoppedResearch.Add(Research);
end;

function TSavedGame.WasResearchPopped(Research: TRuleResearch): Boolean;
begin
  Result := FPoppedResearch.Contains(Research);
end;

procedure TSavedGame.RemovePoppedResearch(Research: TRuleResearch);
begin
  FPoppedResearch.Remove(Research);
end;

function TSavedGame.KillSoldier(Soldier: TSoldier; Cause: TBattleUnitKills = nil): Integer;
var
  b: TBase;
  i: Integer;
begin
  for b in FBases do
  begin
    for i := 0 to b.Soldiers.Count - 1 do
      if b.Soldiers[i] = Soldier then
      begin
        Soldier.Die(TSoldierDeath.Create(FTime, Cause));
        FDeadSoldiers.Add(Soldier);
        b.Soldiers.Delete(i);
        Exit(i);
      end;
  end;
  Result := -1;
end;

procedure TSavedGame.SetTime(const Time: TGameTime);
begin
  FTime.Free;
  FTime := TGameTime.Create(Time.Weekday, Time.Day, Time.Month, Time.Year,
                            Time.Hour, Time.Minute, Time.Second);
end;

procedure TSavedGame.SetBattleGame(Battle: TSavedBattleGame);
begin
  FBattleGame.Free;
  FBattleGame := Battle;
end;

function TSavedGame.HandlePromotions(Participants: TArray<TSoldier>): Boolean;
var
  allSoldiers: TArray<TSoldier>;
  info: TPromotionInfo;
  total: Integer;
  highest: TSoldier;
begin
  SetLength(allSoldiers, 0);
  for var b in FBases do
  begin
    for var s in b.Soldiers do
    begin
      SetLength(allSoldiers, Length(allSoldiers) + 1);
      allSoldiers[High(allSoldiers)] := s;
      ProcessSoldier(s, info);
    end;
    for var t in b.Transfers do
      if t.Soldier <> nil then
      begin
        SetLength(allSoldiers, Length(allSoldiers) + 1);
        allSoldiers[High(allSoldiers)] := t.Soldier;
        ProcessSoldier(t.Soldier, info);
      end;
  end;
  total := Length(allSoldiers);
  Result := False;

  if info.TotalCommanders = 0 then
  begin
    if total >= 30 then
    begin
      highest := InspectSoldiers(allSoldiers, Participants, Ord(RANK_COLONEL));
      if highest <> nil then
      begin
        highest.PromoteRank;
        Inc(info.TotalCommanders);
        Dec(info.TotalColonels);
        Result := True;
      end;
    end;
  end;

  while (total div 23) > info.TotalColonels do
  begin
    highest := InspectSoldiers(allSoldiers, Participants, Ord(RANK_CAPTAIN));
    if highest = nil then Break;
    highest.PromoteRank;
    Inc(info.TotalColonels);
    Dec(info.TotalCaptains);
    Result := True;
  end;

  while (total div 11) > info.TotalCaptains do
  begin
    highest := InspectSoldiers(allSoldiers, Participants, Ord(RANK_SERGEANT));
    if highest = nil then Break;
    highest.PromoteRank;
    Inc(info.TotalCaptains);
    Dec(info.TotalSergeants);
    Result := True;
  end;

  while (total div 5) > info.TotalSergeants do
  begin
    highest := InspectSoldiers(allSoldiers, Participants, Ord(RANK_SQUADDIE));
    if highest = nil then Break;
    highest.PromoteRank;
    Inc(info.TotalSergeants);
    Result := True;
  end;
end;

procedure TSavedGame.ProcessSoldier(Soldier: TSoldier; var Info: TPromotionInfo);
begin
  case Soldier.Rank of
    RANK_COMMANDER: Inc(Info.TotalCommanders);
    RANK_COLONEL: Inc(Info.TotalColonels);
    RANK_CAPTAIN: Inc(Info.TotalCaptains);
    RANK_SERGEANT: Inc(Info.TotalSergeants);
  end;
end;

function TSavedGame.InspectSoldiers(const Soldiers, Participants: TArray<TSoldier>; Rank: Integer): TSoldier;
var
  s: TSoldier;
  score, best: Integer;
begin
  Result := nil;
  best := -1;
  for s in Soldiers do
    if Ord(s.Rank) = Rank then
    begin
      score := GetSoldierScore(s);
      if (score > best) and ((not Options.FieldPromotions) or (Participants.Contains(s))) then
      begin
        best := score;
        Result := s;
      end;
    end;
end;

function TSavedGame.GetSoldierScore(Soldier: TSoldier): Integer;
var
  stats: TUnitStats;
begin
  stats := Soldier.CurrentStats;
  Result := 2*stats.Health + 2*stats.Stamina + 4*stats.Reactions + 4*stats.Bravery +
            3*(stats.TU + 2*stats.Firing) +
            stats.Melee + stats.Throwing + stats.Strength;
  if stats.PsiSkill > 0 then
    Result := Result + stats.PsiStrength + 2*stats.PsiSkill;
  Result := Result + 10 * (Soldier.Missions + Soldier.Kills);
end;

end.