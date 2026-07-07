unit Ufo;

interface

uses
  Classes, SysUtils, YAML, MovingTarget, Mod, RuleUfo, AlienMission,
  UfoTrajectory, SavedGame, Target, Craft, Language;

type
  TUfoStatus = (usFlying, usLanded, usCrashed, usDestroyed);

  TUfo = class(TMovingTarget)
  private
    FRules: TRuleUfo;
    FCrashId: Integer;
    FLandId: Integer;
    FDamage: Integer;
    FDirection: string;
    FAltitude: string;
    FStatus: TUfoStatus;
    FSecondsRemaining: Integer;
    FInBattlescape: Boolean;
    FShotDownByCraftId: TCraftId;
    FMission: TAlienMission;
    FTrajectory: TUfoTrajectory;
    FTrajectoryPoint: Integer;
    FDetected: Boolean;
    FHyperDetected: Boolean;
    FProcessedIntercept: Boolean;
    FShootingAt: Integer;
    FHitFrame: Integer;
    FFireCountdown: Integer;
    FEscapeCountdown: Integer;
    procedure CalculateSpeed; override;
  public
    constructor Create(Rules: TRuleUfo);
    destructor Destroy; override;
    procedure Load(const Node: TYamlNode; Mod: TMod; Game: TSavedGame);
    function Save(NewBattle: Boolean): TYamlNode;
    function GetType: string; override;
    property Rules: TRuleUfo read FRules write FRules;
    function GetDefaultName(Lang: TLanguage): string; override;
    function GetMarkerName: string; override;
    function GetMarkerId: Integer; override;
    function GetMarker: Integer; override;
    property Damage: Integer read FDamage write FDamage;
    property Detected: Boolean read FDetected write FDetected;
    property SecondsRemaining: Integer read FSecondsRemaining write FSecondsRemaining;
    property Direction: string read FDirection;
    property Altitude: string read FAltitude write FAltitude;
    property Status: TUfoStatus read FStatus write FStatus;
    function IsCrashed: Boolean;
    function IsDestroyed: Boolean;
    procedure Think;
    property InBattlescape: Boolean read FInBattlescape write FInBattlescape;
    function GetAlienRace: string;
    procedure SetShotDownByCraftId(const CraftId: TCraftId);
    function GetShotDownByCraftId: TCraftId;
    function GetVisibility: Integer;
    function GetMissionType: string;
    procedure SetMissionInfo(Mission: TAlienMission; Trajectory: TUfoTrajectory);
    property HyperDetected: Boolean read FHyperDetected write FHyperDetected;
    property TrajectoryPoint: Integer read FTrajectoryPoint write FTrajectoryPoint;
    property Trajectory: TUfoTrajectory read FTrajectory;
    property Mission: TAlienMission read FMission;
    procedure SetDestination(Dest: TTarget); override;
    property ShootingAt: Integer read FShootingAt write FShootingAt;
    property LandId: Integer read FLandId write FLandId;
    property CrashId: Integer read FCrashId write FCrashId;
    property HitFrame: Integer read FHitFrame write FHitFrame;
    property FireCountdown: Integer read FFireCountdown write FFireCountdown;
    property EscapeCountdown: Integer read FEscapeCountdown write FEscapeCountdown;
    property InterceptionProcessed: Boolean read FProcessedIntercept write FProcessedIntercept;
  end;

implementation

uses
  Math, Logger;

constructor TUfo.Create(Rules: TRuleUfo);
begin
  inherited Create;
  FRules := Rules;
  FCrashId := 0;
  FLandId := 0;
  FDamage := 0;
  FDirection := 'STR_NORTH';
  FAltitude := 'STR_HIGH_UC';
  FStatus := usFlying;
  FSecondsRemaining := 0;
  FInBattlescape := False;
  FMission := nil;
  FTrajectory := nil;
  FTrajectoryPoint := 0;
  FDetected := False;
  FHyperDetected := False;
  FProcessedIntercept := False;
  FShootingAt := 0;
  FHitFrame := 0;
  FFireCountdown := 0;
  FEscapeCountdown := 0;
end;

destructor TUfo.Destroy;
begin
  if FMission <> nil then
    FMission.DecreaseLiveUfos;
  inherited;
end;

procedure TUfo.Load(const Node: TYamlNode; Mod: TMod; Game: TSavedGame);
begin
  inherited Load(Node);
  // Load UFO specific data
end;

function TUfo.Save(NewBattle: Boolean): TYamlNode;
begin
  Result := inherited Save;
  // Save UFO data
end;

function TUfo.GetType: string;
begin
  Result := 'STR_UFO';
end;

function TUfo.GetDefaultName(Lang: TLanguage): string;
begin
  case FStatus of
    usLanded: Result := Lang.GetString('STR_LANDING_SITE_') + IntToStr(FLandId);
    usCrashed: Result := Lang.GetString('STR_CRASH_SITE_') + IntToStr(FCrashId);
    else Result := Lang.GetString('STR_UFO_') + IntToStr(FId);
  end;
end;

function TUfo.GetMarkerName: string;
begin
  case FStatus of
    usLanded: Result := 'STR_LANDING_SITE_';
    usCrashed: Result := 'STR_CRASH_SITE_';
    else Result := 'STR_UFO_';
  end;
end;

function TUfo.GetMarkerId: Integer;
begin
  case FStatus of
    usLanded: Result := FLandId;
    usCrashed: Result := FCrashId;
    else Result := FId;
  end;
end;

function TUfo.GetMarker: Integer;
begin
  if not FDetected then Exit(-1);
  case FStatus of
    usLanded: Result := FRules.LandMarker;
    usCrashed: Result := FRules.CrashMarker;
    else Result := FRules.Marker;
  end;
  if Result = -1 then
    Result := 2;
end;

function TUfo.IsCrashed: Boolean;
begin
  Result := FDamage > FRules.MaxDamage div 2;
end;

function TUfo.IsDestroyed: Boolean;
begin
  Result := FDamage >= FRules.MaxDamage;
end;

procedure TUfo.CalculateSpeed;
begin
  inherited CalculateSpeed;
  // Set direction based on speed components
end;

procedure TUfo.Think;
begin
  case FStatus of
    usFlying:
    begin
      Move;
      if ReachedDestination then
        SetSpeed(0);
    end;
    usLanded:
      FSecondsRemaining := FSecondsRemaining - 5;
    usCrashed:
      if not FDetected then FDetected := True;
    usDestroyed: ; // do nothing
  end;
end;

function TUfo.GetAlienRace: string;
begin
  if FMission <> nil then
    Result := FMission.Race
  else
    Result := '';
end;

procedure TUfo.SetShotDownByCraftId(const CraftId: TCraftId);
begin
  FShotDownByCraftId := CraftId;
end;

function TUfo.GetShotDownByCraftId: TCraftId;
begin
  Result := FShotDownByCraftId;
end;

function TUfo.GetVisibility: Integer;
var
  size: Integer;
begin
  if FRules.Size = 'STR_VERY_SMALL' then size := -30
  else if FRules.Size = 'STR_SMALL' then size := -15
  else if FRules.Size = 'STR_MEDIUM_UC' then size := 0
  else if FRules.Size = 'STR_LARGE' then size := 15
  else if FRules.Size = 'STR_VERY_LARGE' then size := 30
  else size := 0;

  if FAltitude = 'STR_GROUND' then
    Result := -30
  else if FAltitude = 'STR_VERY_LOW' then
    Result := size - 20
  else if FAltitude = 'STR_LOW_UC' then
    Result := size - 10
  else if FAltitude = 'STR_HIGH_UC' then
    Result := size
  else // STR_VERY_HIGH
    Result := size - 10;
end;

function TUfo.GetMissionType: string;
begin
  if FMission <> nil then
    Result := FMission.Rules.Type
  else
    Result := '';
end;

procedure TUfo.SetMissionInfo(Mission: TAlienMission; Trajectory: TUfoTrajectory);
begin
  FMission := Mission;
  if FMission <> nil then
    FMission.IncreaseLiveUfos;
  FTrajectory := Trajectory;
  FTrajectoryPoint := 0;
end;

procedure TUfo.SetDestination(Dest: TTarget);
begin
  // Delete old waypoint if any
  inherited SetDestination(Dest);
end;

end.