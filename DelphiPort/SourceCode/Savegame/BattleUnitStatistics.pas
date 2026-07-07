unit BattleUnitStatistics;

interface

uses
  Classes, SysUtils, Generics.Collections, YAML, BattleUnit, Language;

type
  TBattleUnitKills = class
  private
    FName: string;
    FType: string;
    FRank: string;
    FRace: string;
    FWeapon: string;
    FWeaponAmmo: string;
    FFaction: TUnitFaction;
    FStatus: TUnitStatus;
    FMission: Integer;
    FTurn: Integer;
    FId: Integer;
    FSide: TUnitSide;
    FBodypart: TUnitBodyPart;
  public
    constructor Create; overload;
    constructor Create(const Node: TYamlNode); overload;
    destructor Destroy; override;
    procedure Load(const Node: TYamlNode);
    function Save: TYamlNode;
    function MakeTurnUnique: Integer;
    function HostileTurn: Boolean;
    procedure SetTurn(UnitTurn: Integer; UnitFaction: TUnitFaction);
    function GetKillStatusString: string;
    function GetUnitStatusString: string;
    function GetUnitFactionString: string;
    function GetUnitSideString: string;
    function GetUnitBodyPartString: string;
    function GetUnitName(Lang: TLanguage): string;
    procedure SetUnitStats(Unit: TBattleUnit);
    property Name: string read FName;
    property &Type: string read FType;
    property Rank: string read FRank;
    property Race: string read FRace;
    property Weapon: string read FWeapon;
    property WeaponAmmo: string read FWeaponAmmo;
    property Faction: TUnitFaction read FFaction;
    property Status: TUnitStatus read FStatus;
    property Mission: Integer read FMission;
    property Turn: Integer read FTurn;
    property Id: Integer read FId;
    property Side: TUnitSide read FSide;
    property Bodypart: TUnitBodyPart read FBodypart;
  end;

  TBattleUnitStatistics = class
  private
    FWasUnconcious: Boolean;
    FShotAtCounter: Integer;
    FHitCounter: Integer;
    FShotByFriendlyCounter: Integer;
    FShotFriendlyCounter: Integer;
    FLoneSurvivor: Boolean;
    FIronMan: Boolean;
    FLongDistanceHitCounter: Integer;
    FLowAccuracyHitCounter: Integer;
    FShotsFiredCounter: Integer;
    FShotsLandedCounter: Integer;
    FKills: TObjectList<TBattleUnitKills>;
    FDaysWounded: Integer;
    FKIA: Boolean;
    FNikeCross: Boolean;
    FMercyCross: Boolean;
    FWoundsHealed: Integer;
    FDelta: TUnitStats;
    FAppliedStimulant: Integer;
    FAppliedPainKill: Integer;
    FRevivedSoldier: Integer;
    FRevivedHostile: Integer;
    FRevivedNeutral: Integer;
    FMIA: Boolean;
    FMartyr: Integer;
    FSlaveKills: Integer;
  public
    constructor Create; overload;
    constructor Create(const Node: TYamlNode); overload;
    destructor Destroy; override;
    procedure Load(const Node: TYamlNode);
    function Save: TYamlNode;
    function DuplicateEntry(Status: TUnitStatus; Id: Integer): Boolean;
    function HasFriendlyFired: Boolean;
    property WasUnconcious: Boolean read FWasUnconcious;
    property ShotAtCounter: Integer read FShotAtCounter;
    property HitCounter: Integer read FHitCounter;
    property ShotByFriendlyCounter: Integer read FShotByFriendlyCounter;
    property ShotFriendlyCounter: Integer read FShotFriendlyCounter;
    property LoneSurvivor: Boolean read FLoneSurvivor;
    property IronMan: Boolean read FIronMan;
    property LongDistanceHitCounter: Integer read FLongDistanceHitCounter;
    property LowAccuracyHitCounter: Integer read FLowAccuracyHitCounter;
    property ShotsFiredCounter: Integer read FShotsFiredCounter;
    property ShotsLandedCounter: Integer read FShotsLandedCounter;
    property Kills: TObjectList<TBattleUnitKills> read FKills;
    property DaysWounded: Integer read FDaysWounded;
    property KIA: Boolean read FKIA;
    property NikeCross: Boolean read FNikeCross;
    property MercyCross: Boolean read FMercyCross;
    property WoundsHealed: Integer read FWoundsHealed;
    property Delta: TUnitStats read FDelta;
    property AppliedStimulant: Integer read FAppliedStimulant;
    property AppliedPainKill: Integer read FAppliedPainKill;
    property RevivedSoldier: Integer read FRevivedSoldier;
    property RevivedHostile: Integer read FRevivedHostile;
    property RevivedNeutral: Integer read FRevivedNeutral;
    property MIA: Boolean read FMIA;
    property Martyr: Integer read FMartyr;
    property SlaveKills: Integer read FSlaveKills;
  end;

implementation

constructor TBattleUnitKills.Create;
begin
  FFaction := FACTION_HOSTILE;
  FStatus := STATUS_IGNORE_ME;
  FMission := 0;
  FTurn := 0;
  FId := 0;
  FSide := SIDE_FRONT;
  FBodypart := BODYPART_HEAD;
end;

constructor TBattleUnitKills.Create(const Node: TYamlNode);
begin
  Create;
  Load(Node);
end;

destructor TBattleUnitKills.Destroy;
begin
  inherited;
end;

procedure TBattleUnitKills.Load(const Node: TYamlNode);
begin
  if Node['name'] <> nil then FName := Node['name'].AsString;
  FType := Node['type'].AsString(FType);
  FRank := Node['rank'].AsString(FRank);
  FRace := Node['race'].AsString(FRace);
  FWeapon := Node['weapon'].AsString(FWeapon);
  FWeaponAmmo := Node['weaponAmmo'].AsString(FWeaponAmmo);
  FStatus := TUnitStatus(Node['status'].AsInteger);
  FFaction := TUnitFaction(Node['faction'].AsInteger);
  FMission := Node['mission'].AsInteger(FMission);
  FTurn := Node['turn'].AsInteger(FTurn);
  FSide := TUnitSide(Node['side'].AsInteger);
  FBodypart := TUnitBodyPart(Node['bodypart'].AsInteger);
  FId := Node['id'].AsInteger(FId);
end;

function TBattleUnitKills.Save: TYamlNode;
begin
  Result := TYamlNode.Create;
  if FName <> '' then Result['name'] := FName;
  if FType <> '' then Result['type'] := FType;
  Result['rank'] := FRank;
  Result['race'] := FRace;
  Result['weapon'] := FWeapon;
  Result['weaponAmmo'] := FWeaponAmmo;
  Result['status'] := Ord(FStatus);
  Result['faction'] := Ord(FFaction);
  Result['mission'] := FMission;
  Result['turn'] := FTurn;
  Result['side'] := Ord(FSide);
  Result['bodypart'] := Ord(FBodypart);
  Result['id'] := FId;
end;

function TBattleUnitKills.MakeTurnUnique: Integer;
begin
  Result := FTurn + FMission * 300;
end;

function TBattleUnitKills.HostileTurn: Boolean;
begin
  Result := ((FTurn - 1) mod 3 = 0);
end;

procedure TBattleUnitKills.SetTurn(UnitTurn: Integer; UnitFaction: TUnitFaction);
begin
  FTurn := UnitTurn * 3 + Ord(UnitFaction);
end;

function TBattleUnitKills.GetKillStatusString: string;
begin
  case FStatus of
    STATUS_DEAD: Result := 'STR_KILLED';
    STATUS_UNCONSCIOUS: Result := 'STR_STUNNED';
    STATUS_PANICKING: Result := 'STR_PANICKED';
    STATUS_TURNING: Result := 'STR_MINDCONTROLLED';
  else Result := 'status error';
  end;
end;

// ... other helper methods

procedure TBattleUnitKills.SetUnitStats(Unit: TBattleUnit);
begin
  // Implementation
end;

constructor TBattleUnitStatistics.Create;
begin
  FKills := TObjectList<TBattleUnitKills>.Create;
  FWasUnconcious := False;
  FShotAtCounter := 0;
  FHitCounter := 0;
  FShotByFriendlyCounter := 0;
  FShotFriendlyCounter := 0;
  FLoneSurvivor := False;
  FIronMan := False;
  FLongDistanceHitCounter := 0;
  FLowAccuracyHitCounter := 0;
  FShotsFiredCounter := 0;
  FShotsLandedCounter := 0;
  FDaysWounded := 0;
  FKIA := False;
  FNikeCross := False;
  FMercyCross := False;
  FWoundsHealed := 0;
  FAppliedStimulant := 0;
  FAppliedPainKill := 0;
  FRevivedSoldier := 0;
  FRevivedHostile := 0;
  FRevivedNeutral := 0;
  FMIA := False;
  FMartyr := 0;
  FSlaveKills := 0;
end;

constructor TBattleUnitStatistics.Create(const Node: TYamlNode);
begin
  Create;
  Load(Node);
end;

destructor TBattleUnitStatistics.Destroy;
begin
  FKills.Free;
  inherited;
end;

procedure TBattleUnitStatistics.Load(const Node: TYamlNode);
begin
  FWasUnconcious := Node['wasUnconcious'].AsBoolean(FWasUnconcious);
  if Node['kills'] <> nil then
  begin
    for var killNode in Node['kills'] do
      FKills.Add(TBattleUnitKills.Create(killNode));
  end;
  FShotAtCounter := Node['shotAtCounter'].AsInteger(FShotAtCounter);
  FHitCounter := Node['hitCounter'].AsInteger(FHitCounter);
  FShotByFriendlyCounter := Node['shotByFriendlyCounter'].AsInteger(FShotByFriendlyCounter);
  FShotFriendlyCounter := Node['shotFriendlyCounter'].AsInteger(FShotFriendlyCounter);
  FLoneSurvivor := Node['loneSurvivor'].AsBoolean(FLoneSurvivor);
  FIronMan := Node['ironMan'].AsBoolean(FIronMan);
  FLongDistanceHitCounter := Node['longDistanceHitCounter'].AsInteger(FLongDistanceHitCounter);
  FLowAccuracyHitCounter := Node['lowAccuracyHitCounter'].AsInteger(FLowAccuracyHitCounter);
  FShotsFiredCounter := Node['shotsFiredCounter'].AsInteger(FShotsFiredCounter);
  FShotsLandedCounter := Node['shotsLandedCounter'].AsInteger(FShotsLandedCounter);
  FNikeCross := Node['nikeCross'].AsBoolean(FNikeCross);
  FMercyCross := Node['mercyCross'].AsBoolean(FMercyCross);
  FWoundsHealed := Node['woundsHealed'].AsInteger(FWoundsHealed);
  FAppliedStimulant := Node['appliedStimulant'].AsInteger(FAppliedStimulant);
  FAppliedPainKill := Node['appliedPainKill'].AsInteger(FAppliedPainKill);
  FRevivedSoldier := Node['revivedSoldier'].AsInteger(FRevivedSoldier);
  FRevivedHostile := Node['revivedHostile'].AsInteger(FRevivedHostile);
  FRevivedNeutral := Node['revivedNeutral'].AsInteger(FRevivedNeutral);
  FMartyr := Node['martyr'].AsInteger(FMartyr);
  FSlaveKills := Node['slaveKills'].AsInteger(FSlaveKills);
end;

function TBattleUnitStatistics.Save: TYamlNode;
begin
  Result := TYamlNode.Create;
  Result['wasUnconcious'] := FWasUnconcious;
  if FKills.Count > 0 then
    for var kill in FKills do
      Result['kills'].Add(kill.Save);
  if FShotAtCounter <> 0 then Result['shotAtCounter'] := FShotAtCounter;
  if FHitCounter <> 0 then Result['hitCounter'] := FHitCounter;
  if FShotByFriendlyCounter <> 0 then Result['shotByFriendlyCounter'] := FShotByFriendlyCounter;
  if FShotFriendlyCounter <> 0 then Result['shotFriendlyCounter'] := FShotFriendlyCounter;
  if FLoneSurvivor then Result['loneSurvivor'] := FLoneSurvivor;
  if FIronMan then Result['ironMan'] := FIronMan;
  if FLongDistanceHitCounter <> 0 then Result['longDistanceHitCounter'] := FLongDistanceHitCounter;
  if FLowAccuracyHitCounter <> 0 then Result['lowAccuracyHitCounter'] := FLowAccuracyHitCounter;
  if FShotsFiredCounter <> 0 then Result['shotsFiredCounter'] := FShotsFiredCounter;
  if FShotsLandedCounter <> 0 then Result['shotsLandedCounter'] := FShotsLandedCounter;
  if FNikeCross then Result['nikeCross'] := FNikeCross;
  if FMercyCross then Result['mercyCross'] := FMercyCross;
  if FWoundsHealed <> 0 then Result['woundsHealed'] := FWoundsHealed;
  if FAppliedStimulant <> 0 then Result['appliedStimulant'] := FAppliedStimulant;
  if FAppliedPainKill <> 0 then Result['appliedPainKill'] := FAppliedPainKill;
  if FRevivedSoldier <> 0 then Result['revivedSoldier'] := FRevivedSoldier;
  if FRevivedHostile <> 0 then Result['revivedHostile'] := FRevivedHostile;
  if FRevivedNeutral <> 0 then Result['revivedNeutral'] := FRevivedNeutral;
  if FMartyr <> 0 then Result['martyr'] := FMartyr;
  if FSlaveKills <> 0 then Result['slaveKills'] := FSlaveKills;
end;

function TBattleUnitStatistics.DuplicateEntry(Status: TUnitStatus; Id: Integer): Boolean;
begin
  for var kill in FKills do
    if (kill.Id = Id) and (kill.Status = Status) then
      Exit(True);
  Result := False;
end;

function TBattleUnitStatistics.HasFriendlyFired: Boolean;
begin
  for var kill in FKills do
    if kill.Faction = FACTION_PLAYER then
      Exit(True);
  Result := False;
end;

end.