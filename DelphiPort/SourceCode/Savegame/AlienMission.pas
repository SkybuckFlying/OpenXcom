unit AlienMission;

interface

uses
  Classes, SysUtils, Generics.Collections, YAML, RuleAlienMission, AlienBase,
  Base, Game, Globe, Mod, RuleRegion, RuleCountry, UfoTrajectory, SavedGame,
  MissionSite, Ufo, Craft, Region, Country, Waypoint, AlienDeployment;

type
  TAlienMission = class
  private
    FRule: TRuleAlienMission;
    FRegion: string;
    FRace: string;
    FNextWave: Integer;
    FNextUfoCounter: Integer;
    FSpawnCountdown: Integer;
    FLiveUfos: Integer;
    FUniqueID: Integer;
    FMissionSiteZone: Integer;
    FBase: TAlienBase;
    procedure AddScore(Lon, Lat: Double; Game: TSavedGame);
    function SpawnUfo(const Game: TSavedGame; Mod: TMod; Globe: TGlobe; const Wave: TMissionWave; const Trajectory: TUfoTrajectory): TUfo;
    procedure SpawnAlienBase(Engine: TGame; const Area: TMissionArea; Pos: TPointF);
    function GetWaypoint(const Trajectory: TUfoTrajectory; NextWaypoint: Integer; Globe: TGlobe; Region: TRuleRegion): TPointF;
    function GetLandPoint(Globe: TGlobe; Region: TRuleRegion; Zone: Integer): TPointF;
    function SpawnMissionSite(Game: TSavedGame; Deployment: TAlienDeployment; const Area: TMissionArea): TMissionSite;
    procedure LogMissionError(Zone: Integer; Region: TRuleRegion);
  public
    constructor Create(const Rule: TRuleAlienMission);
    destructor Destroy; override;
    procedure Load(const Node: TYamlNode; Game: TSavedGame);
    function Save: TYamlNode;
    property Rules: TRuleAlienMission read FRule;
    property Region: string read FRegion;
    property Race: string read FRace write FRace;
    property WaveCountdown: Integer read FSpawnCountdown write FSpawnCountdown;
    property Id: Integer read FUniqueID write FUniqueID;
    property AlienBase: TAlienBase read FBase write FBase;
    function IsOver: Boolean;
    procedure Think(Engine: TGame; Globe: TGlobe);
    procedure Start(InitialCount: Integer = 0);
    procedure IncreaseLiveUfos; inline;
    procedure DecreaseLiveUfos; inline;
    procedure UfoReachedWaypoint(Ufo: TUfo; Engine: TGame; Globe: TGlobe);
    procedure UfoLifting(Ufo: TUfo; Game: TSavedGame);
    procedure UfoShotDown(Ufo: TUfo);
    procedure SetRegion(const Region: string; Mod: TMod);
    procedure SetMissionSiteZone(Zone: Integer);
  end;

implementation

uses
  RNG, Exception, Logger, Texture, Globe, fmath;

constructor TAlienMission.Create(const Rule: TRuleAlienMission);
begin
  FRule := Rule;
  FNextWave := 0;
  FNextUfoCounter := 0;
  FSpawnCountdown := 0;
  FLiveUfos := 0;
  FUniqueID := 0;
  FMissionSiteZone := -1;
  FBase := nil;
end;

destructor TAlienMission.Destroy;
begin
  inherited;
end;

procedure TAlienMission.Load(const Node: TYamlNode; Game: TSavedGame);
begin
  FRegion := Node['region'].AsString(FRegion);
  FRace := Node['race'].AsString(FRace);
  FNextWave := Node['nextWave'].AsInteger(FNextWave);
  FNextUfoCounter := Node['nextUfoCounter'].AsInteger(FNextUfoCounter);
  FSpawnCountdown := Node['spawnCountdown'].AsInteger(FSpawnCountdown);
  FLiveUfos := Node['liveUfos'].AsInteger(FLiveUfos);
  FUniqueID := Node['uniqueID'].AsInteger(FUniqueID);
  if Node['alienBase'] <> nil then
  begin
    var baseNode := Node['alienBase'];
    var id := baseNode.AsInteger(-1);
    var typ := 'STR_ALIEN_BASE';
    if id = -1 then
    begin
      id := baseNode['id'].AsInteger;
      typ := baseNode['type'].AsString;
    end;
    for var ab in Game.AlienBases do
      if (ab.Id = id) and (ab.Deployment.MarkerName = typ) then
      begin
        FBase := ab;
        Break;
      end;
  end;
  FMissionSiteZone := Node['missionSiteZone'].AsInteger(FMissionSiteZone);
end;

function TAlienMission.Save: TYamlNode;
begin
  Result := TYamlNode.Create;
  Result['type'] := FRule.Type;
  Result['region'] := FRegion;
  Result['race'] := FRace;
  Result['nextWave'] := FNextWave;
  Result['nextUfoCounter'] := FNextUfoCounter;
  Result['spawnCountdown'] := FSpawnCountdown;
  Result['liveUfos'] := FLiveUfos;
  Result['uniqueID'] := FUniqueID;
  if FBase <> nil then
    Result['alienBase'] := FBase.SaveId;
  Result['missionSiteZone'] := FMissionSiteZone;
end;

function TAlienMission.IsOver: Boolean;
begin
  if FRule.Objective = OBJECTIVE_INFILTRATION then
    Exit(False);
  Result := (FNextWave = FRule.WaveCount) and (FLiveUfos = 0);
end;

procedure TAlienMission.Think(Engine: TGame; Globe: TGlobe);
var
  Mod: TMod;
  Game: TSavedGame;
  wave: TMissionWave;
  trajectory: TUfoTrajectory;
  ufo: TUfo;
  areas: TArray<TMissionArea>;
  area: TMissionArea;
  texture: TTexture;
  deployment: TAlienDeployment;
  pos: TPointF;
  region: TRuleRegion;
begin
  Mod := Engine.Mod;
  Game := Engine.SavedGame;
  if FNextWave >= FRule.WaveCount then Exit;
  if FSpawnCountdown > 30 then
  begin
    FSpawnCountdown := FSpawnCountdown - 30;
    Exit;
  end;
  wave := FRule.GetWave(FNextWave);
  trajectory := Mod.GetUfoTrajectory(wave.trajectory);
  ufo := SpawnUfo(Game, Mod, Globe, wave, trajectory);
  if ufo <> nil then
    Game.Ufos.Add(ufo)
  else if (Mod.GetDeployment(wave.ufoType) <> nil) or ((FRule.Objective = OBJECTIVE_SITE) and wave.objective) then
  begin
    var spawnZone := FRule.SpawnZone;
    if spawnZone = -1 then spawnZone := trajectory.GetZone(0);
    areas := Mod.GetRegion(FRegion).GetMissionZones[spawnZone].areas;
    area := areas[FMissionSiteZone];
    if FMissionSiteZone = -1 then
      area := areas[RNG.Generate(0, High(areas))];
    texture := Mod.Globe.GetTexture(area.texture);
    if Mod.GetDeployment(wave.ufoType) <> nil then
      deployment := Mod.GetDeployment(wave.ufoType)
    else
    begin
      if texture = nil then
        raise Exception.Create('Error spawning mission site: ' + FRule.Type);
      deployment := Mod.GetDeployment(texture.GetRandomDeployment);
    end;
    SpawnMissionSite(Game, deployment, area);
  end;

  Inc(FNextUfoCounter);
  if FNextUfoCounter >= wave.ufoCount then
  begin
    FNextUfoCounter := 0;
    Inc(FNextWave);
  end;

  if (FRule.Objective = OBJECTIVE_INFILTRATION) and (FNextWave = FRule.WaveCount) then
  begin
    for var c in Game.Countries do
    begin
      region := Mod.GetRegion(FRegion);
      if (not c.Pact) and (not c.NewPact) and region.InsideRegion(c.Rules.LabelLongitude, c.Rules.LabelLatitude) then
      begin
        c.NewPact := True;
        areas := region.GetMissionZones[FRule.SpawnZone].areas;
        var tries := 0;
        repeat
          area := areas[RNG.Generate(0, High(areas))];
          pos.X := RNG.Generate(Min(area.lonMin, area.lonMax), Max(area.lonMin, area.lonMax));
          pos.Y := RNG.Generate(Min(area.latMin, area.latMax), Max(area.latMin, area.latMax));
          Inc(tries);
        until (Globe.InsideLand(pos.X, pos.Y) and region.InsideRegion(pos.X, pos.Y)) or (tries >= 100);
        SpawnAlienBase(Engine, area, pos);
        Break;
      end;
    end;
    FNextWave := 0;
  end;

  if (FRule.Objective = OBJECTIVE_BASE) and (FNextWave = FRule.WaveCount) then
  begin
    region := Mod.GetRegion(FRegion);
    areas := region.GetMissionZones[FRule.SpawnZone].areas;
    var tries := 0;
    repeat
      area := areas[RNG.Generate(0, High(areas))];
      pos.X := RNG.Generate(Min(area.lonMin, area.lonMax), Max(area.lonMin, area.lonMax));
      pos.Y := RNG.Generate(Min(area.latMin, area.latMax), Max(area.latMin, area.latMax));
      Inc(tries);
    until (Globe.InsideLand(pos.X, pos.Y) and region.InsideRegion(pos.X, pos.Y)) or (tries >= 100);
    SpawnAlienBase(Engine, area, pos);
  end;

  if FNextWave <> FRule.WaveCount then
  begin
    var spawnTimer := FRule.GetWave(FNextWave).spawnTimer div 30;
    FSpawnCountdown := (spawnTimer div 2 + RNG.Generate(0, spawnTimer)) * 30;
  end;
end;

procedure TAlienMission.Start(InitialCount: Integer);
begin
  FNextWave := 0;
  FNextUfoCounter := 0;
  FLiveUfos := 0;
  if InitialCount = 0 then
  begin
    var spawnTimer := FRule.GetWave(0).spawnTimer div 30;
    FSpawnCountdown := (spawnTimer div 2 + RNG.Generate(0, spawnTimer)) * 30;
  end
  else
    FSpawnCountdown := InitialCount;
end;

procedure TAlienMission.IncreaseLiveUfos;
begin
  Inc(FLiveUfos);
end;

procedure TAlienMission.DecreaseLiveUfos;
begin
  Dec(FLiveUfos);
end;

function TAlienMission.SpawnUfo(const Game: TSavedGame; Mod: TMod; Globe: TGlobe; const Wave: TMissionWave; const Trajectory: TUfoTrajectory): TUfo;
var
  ufoRule: TRuleUfo;
  regionRules: TRuleRegion;
  found: TBase;
  pos: TPointF;
  wp: TWaypoint;
begin
  ufoRule := Mod.GetUfo(Wave.ufoType);
  if FRule.Objective = OBJECTIVE_RETALIATION then
  begin
    regionRules := Mod.GetRegion(FRegion);
    for var b in Game.Bases do
      if regionRules.InsideRegion(b.Longitude, b.Latitude) and b.RetaliationTarget then
      begin
        var battleshipRule := Mod.GetUfo(FRule.SpawnUfo);
        var assaultTrajectory := Mod.GetUfoTrajectory('RETALIATION_ASSAULT_RUN');
        Result := TUfo.Create(battleshipRule);
        Result.SetMissionInfo(Self, assaultTrajectory);
        if Trajectory.GetAltitude(0) = 'STR_GROUND' then
          pos := GetLandPoint(Globe, regionRules, Trajectory.GetZone(0))
        else
          pos := regionRules.GetRandomPoint(Trajectory.GetZone(0));
        Result.Altitude := assaultTrajectory.GetAltitude(0);
        Result.Speed := assaultTrajectory.ApplySpeedPercentage(0, battleshipRule.MaxSpeed);
        Result.Longitude := pos.X;
        Result.Latitude := pos.Y;
        wp := TWaypoint.Create;
        wp.Longitude := b.Longitude;
        wp.Latitude := b.Latitude;
        Result.SetDestination(wp);
        Exit;
      end;
  end
  else if FRule.Objective = OBJECTIVE_SUPPLY then
  begin
    if (ufoRule = nil) or (Wave.objective and (FBase = nil)) then Exit(nil);
    Result := TUfo.Create(ufoRule);
    Result.SetMissionInfo(Self, Trajectory);
    regionRules := Mod.GetRegion(FRegion);
    if Trajectory.GetAltitude(0) = 'STR_GROUND' then
      pos := GetLandPoint(Globe, regionRules, Trajectory.GetZone(0))
    else
      pos := regionRules.GetRandomPoint(Trajectory.GetZone(0));
    Result.Altitude := Trajectory.GetAltitude(0);
    Result.Speed := Trajectory.ApplySpeedPercentage(0, ufoRule.MaxSpeed);
    Result.Longitude := pos.X;
    Result.Latitude := pos.Y;
    wp := TWaypoint.Create;
    if Trajectory.GetAltitude(1) = 'STR_GROUND' then
    begin
      if Wave.objective then
      begin
        pos.X := FBase.Longitude;
        pos.Y := FBase.Latitude;
      end
      else
        pos := GetLandPoint(Globe, regionRules, Trajectory.GetZone(1));
    end
    else
      pos := regionRules.GetRandomPoint(Trajectory.GetZone(1));
    wp.Longitude := pos.X;
    wp.Latitude := pos.Y;
    Result.SetDestination(wp);
    Exit;
  end;
  if ufoRule = nil then Exit(nil);
  Result := TUfo.Create(ufoRule);
  Result.SetMissionInfo(Self, Trajectory);
  regionRules := Mod.GetRegion(FRegion);
  pos := GetWaypoint(Trajectory, 0, Globe, regionRules);
  Result.Altitude := Trajectory.GetAltitude(0);
  if Trajectory.GetAltitude(0) = 'STR_GROUND' then
    Result.SecondsRemaining := Trajectory.GroundTimer * 5;
  Result.Speed := Trajectory.ApplySpeedPercentage(0, ufoRule.MaxSpeed);
  Result.Longitude := pos.X;
  Result.Latitude := pos.Y;
  wp := TWaypoint.Create;
  pos := GetWaypoint(Trajectory, 1, Globe, regionRules);
  wp.Longitude := pos.X;
  wp.Latitude := pos.Y;
  Result.SetDestination(wp);
end;

procedure TAlienMission.UfoReachedWaypoint(Ufo: TUfo; Engine: TGame; Globe: TGlobe);
var
  Mod: TMod;
  Game: TSavedGame;
  curWaypoint, nextWaypoint: Integer;
  trajectory: TUfoTrajectory;
  waveNumber: Integer;
  wave: TMissionWave;
  regionRules: TRuleRegion;
  pos: TPointF;
  wp: TWaypoint;
  area: TMissionArea;
  texture: TTexture;
  deployment: TAlienDeployment;
  missionSite: TMissionSite;
  followers: TArray<TCraft>;
begin
  Mod := Engine.Mod;
  Game := Engine.SavedGame;
  curWaypoint := Ufo.TrajectoryPoint;
  nextWaypoint := curWaypoint + 1;
  trajectory := Ufo.Trajectory;
  waveNumber := FNextWave - 1;
  if waveNumber < 0 then waveNumber := FRule.WaveCount - 1;
  wave := FRule.GetWave(waveNumber);
  if nextWaypoint >= trajectory.WaypointCount then
  begin
    Ufo.Detected := False;
    Ufo.Status := usDestroyed;
    Exit;
  end;
  Ufo.Altitude := trajectory.GetAltitude(nextWaypoint);
  Ufo.TrajectoryPoint := nextWaypoint;
  regionRules := Mod.GetRegion(FRegion);
  pos := GetWaypoint(trajectory, nextWaypoint, Globe, regionRules);
  wp := TWaypoint.Create;
  wp.Longitude := pos.X;
  wp.Latitude := pos.Y;
  Ufo.SetDestination(wp);
  if Ufo.Altitude <> 'STR_GROUND' then
  begin
    if Ufo.LandId <> 0 then Ufo.LandId := 0;
    Ufo.Speed := trajectory.ApplySpeedPercentage(nextWaypoint, Ufo.Rules.MaxSpeed);
  end
  else
  begin
    if (FMissionSiteZone <> -1) and wave.objective and (trajectory.GetZone(curWaypoint) = FRule.SpawnZone) then
    begin
      AddScore(Ufo.Longitude, Ufo.Latitude, Game);
      Ufo.Status := usDestroyed;
      area := regionRules.GetMissionZones[trajectory.GetZone(curWaypoint)].areas[FMissionSiteZone];
      texture := Mod.Globe.GetTexture(area.texture);
      if Mod.GetDeployment(FRule.SiteType) <> nil then
        deployment := Mod.GetDeployment(FRule.SiteType)
      else
      begin
        if texture = nil then
          raise Exception.Create('Error spawning mission site: ' + FRule.Type);
        deployment := Mod.GetDeployment(texture.GetRandomDeployment);
      end;
      missionSite := SpawnMissionSite(Game, deployment, area);
      if missionSite <> nil then
      begin
        followers := Ufo.GetCraftFollowers;
        for var c in followers do
          if c.NumSoldiers <> 0 then
            c.SetDestination(missionSite);
      end;
    end
    else if trajectory.ID = 'RETALIATION_ASSAULT_RUN' then
    begin
      Ufo.Detected := False;
      for var b in Game.Bases do
        if (Abs(b.Longitude - Ufo.Longitude) < 1e-12) and (Abs(b.Latitude - Ufo.Latitude) < 1e-12) then
        begin
          Ufo.SetDestination(b);
          Break;
        end;
    end
    else
    begin
      if Globe.InsideLand(Ufo.Longitude, Ufo.Latitude) then
      begin
        Ufo.SecondsRemaining := trajectory.GroundTimer * 5;
        if Ufo.Detected and (Ufo.LandId = 0) then
          Ufo.LandId := Engine.SavedGame.GetId('STR_LANDING_SITE');
      end
      else
        Ufo.SecondsRemaining := 5;
    end;
  end;
end;

procedure TAlienMission.UfoLifting(Ufo: TUfo; Game: TSavedGame);
begin
  case Ufo.Status of
    usLanded:
    begin
      if (FRule.Points > 0) and (FRule.Objective <> OBJECTIVE_BASE) then
        AddScore(Ufo.Longitude, Ufo.Latitude, Game);
      Ufo.Altitude := 'STR_VERY_LOW';
      Ufo.Speed := Ufo.Trajectory.ApplySpeedPercentage(Ufo.TrajectoryPoint, Ufo.Rules.MaxSpeed);
    end;
    usCrashed:
    begin
      Ufo.Detected := False;
      Ufo.Status := usDestroyed;
    end;
  end;
end;

procedure TAlienMission.UfoShotDown(Ufo: TUfo);
begin
  if (FNextWave <> FRule.WaveCount) then
    FSpawnCountdown := FSpawnCountdown + 30 * (RNG.Generate(0, 400) + 48);
end;

procedure TAlienMission.AddScore(Lon, Lat: Double; Game: TSavedGame);
begin
  if FRule.Objective = OBJECTIVE_INFILTRATION then Exit;
  for var r in Game.Regions do
    if r.Rules.InsideRegion(Lon, Lat) then
    begin
      r.AddActivityAlien(FRule.Points);
      Break;
    end;
  for var c in Game.Countries do
    if c.Rules.InsideCountry(Lon, Lat) then
    begin
      c.AddActivityAlien(FRule.Points);
      Break;
    end;
end;

procedure TAlienMission.SpawnAlienBase(Engine: TGame; const Area: TMissionArea; Pos: TPointF);
var
  Game: TSavedGame;
  Mod: TMod;
  deployment: TAlienDeployment;
  texture: TTexture;
  ab: TAlienBase;
begin
  Game := Engine.SavedGame;
  Mod := Engine.Mod;
  texture := Mod.Globe.GetTexture(Area.texture);
  if Mod.GetDeployment(FRule.SiteType) <> nil then
    deployment := Mod.GetDeployment(FRule.SiteType)
  else if (texture <> nil) and (texture.Deployments.Count > 0) then
    deployment := Mod.GetDeployment(texture.GetRandomDeployment)
  else
    deployment := Mod.GetDeployment('STR_ALIEN_BASE_ASSAULT');
  ab := TAlienBase.Create(deployment);
  ab.AlienRace := FRace;
  ab.Id := Game.GetId(deployment.MarkerName);
  ab.Longitude := Pos.X;
  ab.Latitude := Pos.Y;
  Game.AlienBases.Add(ab);
  AddScore(ab.Longitude, ab.Latitude, Game);
end;

procedure TAlienMission.SetRegion(const Region: string; Mod: TMod);
var
  r: TRuleRegion;
begin
  r := Mod.GetRegion(Region);
  if r.MissionRegion <> '' then
    FRegion := r.MissionRegion
  else
    FRegion := Region;
end;

function TAlienMission.GetWaypoint(const Trajectory: TUfoTrajectory; NextWaypoint: Integer; Globe: TGlobe; Region: TRuleRegion): TPointF;
var
  waveNumber: Integer;
  zone: Integer;
  area: TMissionArea;
begin
  waveNumber := FNextWave - 1;
  if waveNumber < 0 then waveNumber := FRule.WaveCount - 1;
  zone := Trajectory.GetZone(NextWaypoint);
  if zone >= Region.MissionZones.Count then
    LogMissionError(zone, Region);
  if (FMissionSiteZone <> -1) and FRule.GetWave(waveNumber).objective and (zone = FRule.SpawnZone) then
  begin
    area := Region.MissionZones[FRule.SpawnZone].areas[FMissionSiteZone];
    Result.X := area.lonMin;
    Result.Y := area.latMin;
    Exit;
  end;
  if (Trajectory.WaypointCount > NextWaypoint + 1) and (Trajectory.GetAltitude(NextWaypoint + 1) = 'STR_GROUND') then
    Result := GetLandPoint(Globe, Region, zone)
  else
    Result := Region.GetRandomPoint(zone);
end;

function TAlienMission.GetLandPoint(Globe: TGlobe; Region: TRuleRegion; Zone: Integer): TPointF;
var
  tries: Integer;
begin
  if (Zone >= Region.MissionZones.Count) or (Region.MissionZones[Zone].areas.Count = 0) then
    LogMissionError(Zone, Region);
  if Region.MissionZones[Zone].areas[0].isPoint then
    Result := Region.GetRandomPoint(Zone)
  else
  begin
    tries := 0;
    repeat
      Result := Region.GetRandomPoint(Zone);
      Inc(tries);
    until (Globe.InsideLand(Result.X, Result.Y) and Region.InsideRegion(Result.X, Result.Y)) or (tries >= 100);
    if tries = 100 then
      Logger.Log(LOG_DEBUG, 'Region: ' + Region.Type + ' Longitude: ' + FloatToStr(Result.X) + ' Latitude: ' + FloatToStr(Result.Y) + ' invalid zone: ' + IntToStr(Zone) + ' ufo forced to land on water!');
  end;
end;

function TAlienMission.SpawnMissionSite(Game: TSavedGame; Deployment: TAlienDeployment; const Area: TMissionArea): TMissionSite;
begin
  if Deployment = nil then Exit(nil);
  Result := TMissionSite.Create(FRule, Deployment);
  Result.Longitude := RNG.Generate(Area.lonMin, Area.lonMax);
  Result.Latitude := RNG.Generate(Area.latMin, Area.latMax);
  Result.Id := Game.GetId(Deployment.MarkerName);
  Result.SecondsRemaining := RNG.Generate(Deployment.DurationMin, Deployment.DurationMax) * 3600;
  Result.AlienRace := FRace;
  Result.Texture := Area.texture;
  Result.City := Area.name;
  Game.MissionSites.Add(Result);
end;

procedure TAlienMission.LogMissionError(Zone: Integer; Region: TRuleRegion);
begin
  if Region.MissionZones.Count > 0 then
    raise Exception.Create('Error determining waypoint for mission type: ' + FRule.Type + ' in region: ' + Region.Type + ', zone ' + IntToStr(Zone) + ' invalid (max ' + IntToStr(Region.MissionZones.Count - 1) + ')')
  else
    raise Exception.Create('Error determining waypoint for mission type: ' + FRule.Type + ' in region: ' + Region.Type + ', no zones defined');
end;

procedure TAlienMission.SetMissionSiteZone(Zone: Integer);
begin
  FMissionSiteZone := Zone;
end;

end.