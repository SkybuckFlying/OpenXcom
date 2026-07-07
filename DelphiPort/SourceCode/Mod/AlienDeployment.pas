unit AlienDeployment;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections,
  Yaml, ModUnit, Savegame.WeightedOptions;

type
  // Forward declarations
  TMod = class;

  TItemSet = record
    Items: TArray<string>;
  end;

  TDeploymentData = record
    AlienRank: Integer;
    LowQty, HighQty, DQty, ExtraQty: Integer;
    PercentageOutsideUfo: Integer;
    ItemSets: TArray<TItemSet>;
  end;

  TBriefingData = record
    Palette: Integer;
    TextOffset: Integer;
    Title: string;
    Desc: string;
    Music: string;
    Background: string;
    Cutscene: string;
    ShowCraft: Boolean;
    ShowTarget: Boolean;
    constructor Create;
  end;

  TChronoTrigger = (ctForceLose, ctForceAbort, ctForceWin);
  TEscapeType = (etNone, etExit, etEntry, etEither);

  TAlienDeployment = class
  private
    FType: string;
    FData: TArray<TDeploymentData>;
    FWidth, FLength, FHeight, FCivilians: Integer;
    FTerrains: TArray<string>;
    FMusic: TArray<string>;
    FShade: Integer;
    FNextStage: string;
    FRace: string;
    FScript: string;
    FFinalDestination: Boolean;
    FIsAlienBase: Boolean;
    FWinCutscene: string;
    FLoseCutscene: string;
    FAbortCutscene: string;
    FAlert: string;
    FAlertBackground: string;
    FBriefingData: TBriefingData;
    FMarkerName: string;
    FObjectivePopup: string;
    FObjectiveCompleteText: string;
    FObjectiveFailedText: string;
    FGenMission: TWeightedOptions;
    FMarkerIcon: Integer;
    FDurationMin, FDurationMax: Integer;
    FMinDepth, FMaxDepth: Integer;
    FGenMissionFrequency: Integer;
    FObjectiveType: Integer;
    FObjectivesRequired: Integer;
    FObjectiveCompleteScore: Integer;
    FObjectiveFailedScore: Integer;
    FDespawnPenalty: Integer;
    FPoints: Integer;
    FTurnLimit: Integer;
    FCheatTurn: Integer;
    FChronoTrigger: TChronoTrigger;
    FEscapeType: TEscapeType;
  public
    constructor Create(const AType: string);
    destructor Destroy; override;
    procedure Load(const Node: TYamlNode; ModObj: TMod);
    function GetType: string;
    function GetDeploymentData: TArray<TDeploymentData>;
    procedure GetDimensions(out Width, Length, Height: Integer);
    function GetCivilians: Integer;
    function GetTerrains: TArray<string>;
    function GetShade: Integer;
    function GetNextStage: string;
    function GetRace: string;
    function GetScript: string;
    function IsFinalDestination: Boolean;
    function GetWinCutscene: string;
    function GetLoseCutscene: string;
    function GetAbortCutscene: string;
    function GetAlertMessage: string;
    function GetAlertBackground: string;
    function GetBriefingData: TBriefingData;
    function GetMarkerName: string;
    function GetMarkerIcon: Integer;
    function GetDurationMin: Integer;
    function GetDurationMax: Integer;
    function GetMusic: TArray<string>;
    function GetMinDepth: Integer;
    function GetMaxDepth: Integer;
    function GetObjectiveType: Integer;
    function GetObjectivesRequired: Integer;
    function GetObjectivePopup: string;
    function GetObjectiveCompleteInfo(out Text: string; out Score: Integer): Boolean;
    function GetObjectiveFailedInfo(out Text: string; out Score: Integer): Boolean;
    function GetDespawnPenalty: Integer;
    function GetPoints: Integer;
    function GetTurnLimit: Integer;
    function GetChronoTrigger: TChronoTrigger;
    function GetCheatTurn: Integer;
    function IsAlienBase: Boolean;
    function ChooseGenMissionType: string;
    function GetGenMissionFrequency: Integer;
    function GetEscapeType: TEscapeType;
  end;

implementation

{ TBriefingData }

constructor TBriefingData.Create;
begin
  Palette := 0;
  TextOffset := 0;
  Music := 'GMDEFEND';
  Background := 'BACK16.SCR';
  ShowCraft := True;
  ShowTarget := True;
end;

{ TAlienDeployment }

constructor TAlienDeployment.Create(const AType: string);
begin
  inherited Create;
  FType := AType;
  FWidth := 0; FLength := 0; FHeight := 0;
  FCivilians := 0;
  FShade := -1;
  FFinalDestination := False;
  FIsAlienBase := False;
  FAlert := 'STR_ALIENS_TERRORISE';
  FAlertBackground := 'BACK03.SCR';
  FMarkerName := 'STR_TERROR_SITE';
  FMarkerIcon := -1;
  FDurationMin := 0; FDurationMax := 0;
  FMinDepth := 0; FMaxDepth := 0;
  FGenMissionFrequency := 0;
  FObjectiveType := -1;
  FObjectivesRequired := 0;
  FObjectiveCompleteScore := 0;
  FObjectiveFailedScore := 0;
  FDespawnPenalty := 0;
  FPoints := 0;
  FTurnLimit := 0;
  FCheatTurn := 20;
  FChronoTrigger := ctForceLose;
  FEscapeType := etNone;
end;

destructor TAlienDeployment.Destroy;
begin
  inherited;
end;

procedure TAlienDeployment.Load(const Node: TYamlNode; ModObj: TMod);
var
  i: Integer;
  depthNode, durationNode, briefNode: TYamlNode;
begin
  FType := Node['type'].AsString(FType);
  FData := Node['data'].AsArray<TDeploymentData>(FData);

  FWidth := Node['width'].AsInteger(FWidth);
  FLength := Node['length'].AsInteger(FLength);
  FHeight := Node['height'].AsInteger(FHeight);
  FCivilians := Node['civilians'].AsInteger(FCivilians);
  FTerrains := Node['terrains'].AsArray<string>(FTerrains);
  FShade := Node['shade'].AsInteger(FShade);
  FNextStage := Node['nextStage'].AsString(FNextStage);
  FRace := Node['race'].AsString(FRace);
  FFinalDestination := Node['finalDestination'].AsBoolean(FFinalDestination);
  FWinCutscene := Node['winCutscene'].AsString(FWinCutscene);
  FLoseCutscene := Node['loseCutscene'].AsString(FLoseCutscene);
  FAbortCutscene := Node['abortCutscene'].AsString(FAbortCutscene);
  FScript := Node['script'].AsString(FScript);
  FAlert := Node['alert'].AsString(FAlert);
  FAlertBackground := Node['alertBackground'].AsString(FAlertBackground);
  briefNode := Node['briefing'];
  if not briefNode.IsNull then
    FBriefingData := briefNode.As<TBriefingData>(FBriefingData);
  FMarkerName := Node['markerName'].AsString(FMarkerName);
  if Node.Has('markerIcon') then
    FMarkerIcon := ModObj.GetOffset(Node['markerIcon'].AsInteger(FMarkerIcon), 8);

  depthNode := Node['depth'];
  if not depthNode.IsNull then
  begin
    FMinDepth := depthNode[0].AsInteger(FMinDepth);
    FMaxDepth := depthNode[1].AsInteger(FMaxDepth);
  end;
  durationNode := Node['duration'];
  if not durationNode.IsNull then
  begin
    FDurationMin := durationNode[0].AsInteger(FDurationMin);
    FDurationMax := durationNode[1].AsInteger(FDurationMax);
  end;
  FMusic := Node['music'].AsArray<string>(FMusic);

  FObjectiveType := Node['objectiveType'].AsInteger(FObjectiveType);
  FObjectivesRequired := Node['objectivesRequired'].AsInteger(FObjectivesRequired);
  FObjectivePopup := Node['objectivePopup'].AsString(FObjectivePopup);

  if Node.Has('objectiveComplete') then
  begin
    FObjectiveCompleteText := Node['objectiveComplete'][0].AsString(FObjectiveCompleteText);
    FObjectiveCompleteScore := Node['objectiveComplete'][1].AsInteger(FObjectiveCompleteScore);
  end;
  if Node.Has('objectiveFailed') then
  begin
    FObjectiveFailedText := Node['objectiveFailed'][0].AsString(FObjectiveFailedText);
    FObjectiveFailedScore := Node['objectiveFailed'][1].AsInteger(FObjectiveFailedScore);
  end;

  FDespawnPenalty := Node['despawnPenalty'].AsInteger(FDespawnPenalty);
  FPoints := Node['points'].AsInteger(FPoints);
  FCheatTurn := Node['cheatTurn'].AsInteger(FCheatTurn);
  FTurnLimit := Node['turnLimit'].AsInteger(FTurnLimit);
  FChronoTrigger := TChronoTrigger(Node['chronoTrigger'].AsInteger(Integer(FChronoTrigger)));
  FIsAlienBase := Node['alienBase'].AsBoolean(FIsAlienBase);
  FEscapeType := TEscapeType(Node['escapeType'].AsInteger(Integer(FEscapeType)));

  if Node.Has('genMission') then
    FGenMission.Load(Node['genMission']);
  FGenMissionFrequency := Node['genMissionFreq'].AsInteger(FGenMissionFrequency);
end;

function TAlienDeployment.GetType: string;
begin
  Result := FType;
end;

function TAlienDeployment.GetDeploymentData: TArray<TDeploymentData>;
begin
  Result := FData;
end;

procedure TAlienDeployment.GetDimensions(out Width, Length, Height: Integer);
begin
  Width := FWidth;
  Length := FLength;
  Height := FHeight;
end;

function TAlienDeployment.GetCivilians: Integer;
begin
  Result := FCivilians;
end;

function TAlienDeployment.GetTerrains: TArray<string>;
begin
  Result := FTerrains;
end;

function TAlienDeployment.GetShade: Integer;
begin
  Result := FShade;
end;

function TAlienDeployment.GetNextStage: string;
begin
  Result := FNextStage;
end;

function TAlienDeployment.GetRace: string;
begin
  Result := FRace;
end;

function TAlienDeployment.GetScript: string;
begin
  Result := FScript;
end;

function TAlienDeployment.IsFinalDestination: Boolean;
begin
  Result := FFinalDestination;
end;

function TAlienDeployment.GetWinCutscene: string;
begin
  Result := FWinCutscene;
end;

function TAlienDeployment.GetLoseCutscene: string;
begin
  Result := FLoseCutscene;
end;

function TAlienDeployment.GetAbortCutscene: string;
begin
  Result := FAbortCutscene;
end;

function TAlienDeployment.GetAlertMessage: string;
begin
  Result := FAlert;
end;

function TAlienDeployment.GetAlertBackground: string;
begin
  Result := FAlertBackground;
end;

function TAlienDeployment.GetBriefingData: TBriefingData;
begin
  Result := FBriefingData;
end;

function TAlienDeployment.GetMarkerName: string;
begin
  Result := FMarkerName;
end;

function TAlienDeployment.GetMarkerIcon: Integer;
begin
  Result := FMarkerIcon;
end;

function TAlienDeployment.GetDurationMin: Integer;
begin
  Result := FDurationMin;
end;

function TAlienDeployment.GetDurationMax: Integer;
begin
  Result := FDurationMax;
end;

function TAlienDeployment.GetMusic: TArray<string>;
begin
  Result := FMusic;
end;

function TAlienDeployment.GetMinDepth: Integer;
begin
  Result := FMinDepth;
end;

function TAlienDeployment.GetMaxDepth: Integer;
begin
  Result := FMaxDepth;
end;

function TAlienDeployment.GetObjectiveType: Integer;
begin
  Result := FObjectiveType;
end;

function TAlienDeployment.GetObjectivesRequired: Integer;
begin
  Result := FObjectivesRequired;
end;

function TAlienDeployment.GetObjectivePopup: string;
begin
  Result := FObjectivePopup;
end;

function TAlienDeployment.GetObjectiveCompleteInfo(out Text: string; out Score: Integer): Boolean;
begin
  Text := FObjectiveCompleteText;
  Score := FObjectiveCompleteScore;
  Result := not Text.IsEmpty;
end;

function TAlienDeployment.GetObjectiveFailedInfo(out Text: string; out Score: Integer): Boolean;
begin
  Text := FObjectiveFailedText;
  Score := FObjectiveFailedScore;
  Result := not Text.IsEmpty;
end;

function TAlienDeployment.GetDespawnPenalty: Integer;
begin
  Result := FDespawnPenalty;
end;

function TAlienDeployment.GetPoints: Integer;
begin
  Result := FPoints;
end;

function TAlienDeployment.GetTurnLimit: Integer;
begin
  Result := FTurnLimit;
end;

function TAlienDeployment.GetChronoTrigger: TChronoTrigger;
begin
  Result := FChronoTrigger;
end;

function TAlienDeployment.GetCheatTurn: Integer;
begin
  Result := FCheatTurn;
end;

function TAlienDeployment.IsAlienBase: Boolean;
begin
  Result := FIsAlienBase;
end;

function TAlienDeployment.ChooseGenMissionType: string;
begin
  Result := FGenMission.Choose;
end;

function TAlienDeployment.GetGenMissionFrequency: Integer;
begin
  Result := FGenMissionFrequency;
end;

function TAlienDeployment.GetEscapeType: TEscapeType;
begin
  Result := FEscapeType;
end;

end.