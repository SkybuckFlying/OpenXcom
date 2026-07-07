unit MissionDetectedState;

interface

uses
  System.SysUtils, Engine.State, Engine.Game, Engine.Mod,
  Engine.LocalizedText, Interface.TextButton, Interface.Window,
  Interface.Text, Geoscape.GeoscapeState, Geoscape.Globe,
  Savegame.MissionSite, Engine.Options, Geoscape.InterceptState,
  Mod.AlienDeployment;

type
  TMissionDetectedState = class(TState)
  private
    FMission: TMissionSite;
    FState: TGeoscapeState;
    FBtnIntercept, FBtnCenter, FBtnCancel: TTextButton;
    FWindow: TWindow;
    FTxtTitle, FTxtCity: TText;
    procedure BtnInterceptClick(AAction: TAction);
    procedure BtnCenterClick(AAction: TAction);
    procedure BtnCancelClick(AAction: TAction);
  public
    constructor Create(AMission: TMissionSite; AState: TGeoscapeState);
    destructor Destroy; override;
  end;

implementation

{ TMissionDetectedState }

constructor TMissionDetectedState.Create(AMission: TMissionSite; AState: TGeoscapeState);
begin
  inherited Create(nil);
  FMission := AMission;
  FState := AState;
  FScreen := False;

  FWindow := TWindow.Create(Self, 256, 200, 0, 0, POPUP_BOTH);
  FBtnIntercept := TTextButton.Create(200, 16, 28, 130);
  FBtnCenter := TTextButton.Create(200, 16, 28, 150);
  FBtnCancel := TTextButton.Create(200, 16, 28, 170);
  FTxtTitle := TText.Create(246, 32, 5, 48);
  FTxtCity := TText.Create(246, 17, 5, 80);

  SetInterface('terrorSite');

  Add(FWindow, 'window', 'terrorSite');
  Add(FBtnIntercept, 'button', 'terrorSite');
  Add(FBtnCenter, 'button', 'terrorSite');
  Add(FBtnCancel, 'button', 'terrorSite');
  Add(FTxtTitle, 'text', 'terrorSite');
  Add(FTxtCity, 'text', 'terrorSite');

  CenterAllSurfaces;

  FWindow.SetBackground(Game.Mod.GetSurface(FMission.Deployment.AlertBackground));

  FBtnIntercept.Text := Tr('STR_INTERCEPT');
  FBtnIntercept.OnMouseClick := BtnInterceptClick;

  FBtnCenter.Text := Tr('STR_CENTER_ON_SITE_TIME_5_SECONDS');
  FBtnCenter.OnMouseClick := BtnCenterClick;

  FBtnCancel.Text := Tr('STR_CANCEL_UC');
  FBtnCancel.OnMouseClick := BtnCancelClick;
  FBtnCancel.OnKeyboardPress(Options.KeyCancel, BtnCancelClick);

  FTxtTitle.Big := True;
  FTxtTitle.Align := ALIGN_CENTER;
  FTxtTitle.WordWrap := True;
  FTxtTitle.Text := Tr(FMission.Deployment.AlertMessage);

  FTxtCity.Big := True;
  FTxtCity.Align := ALIGN_CENTER;
  FTxtCity.Text := Tr(FMission.City);
end;

destructor TMissionDetectedState.Destroy;
begin
  inherited;
end;

procedure TMissionDetectedState.BtnInterceptClick(AAction: TAction);
begin
  FState.TimerReset;
  FState.Globe.Center(FMission.Longitude, FMission.Latitude);
  Game.PushState(TInterceptState.Create(FState.Globe, nil, FMission));
end;

procedure TMissionDetectedState.BtnCenterClick(AAction: TAction);
begin
  FState.TimerReset;
  FState.Globe.Center(FMission.Longitude, FMission.Latitude);
  Game.PopState;
end;

procedure TMissionDetectedState.BtnCancelClick(AAction: TAction);
begin
  Game.PopState;
end;

end.