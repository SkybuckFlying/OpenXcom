unit MissionSite;

interface

uses
  Classes, SysUtils, YAML, Target, RuleAlienMission, AlienDeployment;

type
  TMissionSite = class(TTarget)
  private
    FRules: TRuleAlienMission;
    FDeployment: TAlienDeployment;
    FTexture: Integer;
    FSecondsRemaining: Integer;
    FRace: string;
    FCity: string;
    FInBattlescape: Boolean;
    FDetected: Boolean;
  public
    constructor Create(Rules: TRuleAlienMission; Deployment: TAlienDeployment);
    destructor Destroy; override;
    procedure Load(const Node: TYamlNode);
    function Save: TYamlNode;
    function GetType: string; override;
    property Rules: TRuleAlienMission read FRules;
    property Deployment: TAlienDeployment read FDeployment;
    function GetMarkerName: string; override;
    function GetMarker: Integer; override;
    property SecondsRemaining: Integer read FSecondsRemaining write FSecondsRemaining;
    property AlienRace: string read FRace write FRace;
    property InBattlescape: Boolean read FInBattlescape write FInBattlescape;
    property Texture: Integer read FTexture write FTexture;
    property City: string read FCity write FCity;
    property Detected: Boolean read FDetected write FDetected;
  end;

implementation

constructor TMissionSite.Create(Rules: TRuleAlienMission; Deployment: TAlienDeployment);
begin
  inherited Create;
  FRules := Rules;
  FDeployment := Deployment;
  FTexture := -1;
  FSecondsRemaining := 0;
  FInBattlescape := False;
  FDetected := False;
end;

destructor TMissionSite.Destroy;
begin
  inherited;
end;

procedure TMissionSite.Load(const Node: TYamlNode);
begin
  inherited Load(Node);
  FTexture := Node['texture'].AsInteger(FTexture);
  FSecondsRemaining := Node['secondsRemaining'].AsInteger(FSecondsRemaining);
  FRace := Node['race'].AsString(FRace);
  FInBattlescape := Node['inBattlescape'].AsBoolean(FInBattlescape);
  FDetected := Node['detected'].AsBoolean(FDetected);
end;

function TMissionSite.Save: TYamlNode;
begin
  Result := inherited Save;
  Result['type'] := FRules.Type;
  Result['deployment'] := FDeployment.Type;
  Result['texture'] := FTexture;
  if FSecondsRemaining <> 0 then Result['secondsRemaining'] := FSecondsRemaining;
  Result['race'] := FRace;
  if FInBattlescape then Result['inBattlescape'] := FInBattlescape;
  Result['detected'] := FDetected;
end;

function TMissionSite.GetType: string;
begin
  Result := FDeployment.MarkerName;
end;

function TMissionSite.GetMarkerName: string;
begin
  Result := GetType;
end;

function TMissionSite.GetMarker: Integer;
begin
  if not FDetected then Exit(-1);
  if FDeployment.MarkerIcon = -1 then Exit(5);
  Result := FDeployment.MarkerIcon;
end;

end.