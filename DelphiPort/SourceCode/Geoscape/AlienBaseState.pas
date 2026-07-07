unit AlienBaseState;

interface

uses
  Engine.State, Engine.Game, Engine.Mod, Engine.LocalizedText,
  Interface.TextButton, Interface.Window, Interface.Text,
  Geoscape.GeoscapeState, Geoscape.Globe, Savegame.SavedGame,
  Savegame.Region, Savegame.Country, Savegame.AlienBase,
  Mod.RuleRegion, Mod.RuleCountry, Engine.Options, Engine.Action;

type
  TAlienBaseState = class(TState)
  private
    FState: TGeoscapeState;
    FBase: TAlienBase;
    FBtnOk: TTextButton;
    FWindow: TWindow;
    FTxtTitle: TText;
    procedure BtnOkClick(AAction: TAction);
  public
    constructor Create(ABase: TAlienBase; AState: TGeoscapeState);
    destructor Destroy; override;
  end;

implementation

uses
  System.SysUtils, System.Classes;

{ TAlienBaseState }

constructor TAlienBaseState.Create(ABase: TAlienBase; AState: TGeoscapeState);
var
  region, country: string;
  location: string;
  i: Integer;
begin
  inherited Create(nil);
  FState := AState;
  FBase := ABase;

  FWindow := TWindow.Create(Self, 320, 200, 0, 0);
  FBtnOk := TTextButton.Create(50, 12, 135, 180);
  FTxtTitle := TText.Create(308, 60, 6, 60);

  SetInterface('alienBase');

  Add(FWindow, 'window', 'alienBase');
  Add(FBtnOk, 'text', 'alienBase');
  Add(FTxtTitle, 'button', 'alienBase');

  CenterAllSurfaces;

  FWindow.SetBackground(Game.Mod.GetSurface('BACK13.SCR'));

  FBtnOk.Text := Tr('STR_OK');
  FBtnOk.OnMouseClick := BtnOkClick;
  FBtnOk.OnKeyboardPress(Options.keyOk, BtnOkClick);
  FBtnOk.OnKeyboardPress(Options.keyCancel, BtnOkClick);

  FTxtTitle.Align := ALIGN_CENTER;
  FTxtTitle.Big := True;
  FTxtTitle.WordWrap := True;

  // Locate country and region
  country := '';
  region := '';
  for i := 0 to Game.SavedGame.Countries.Count - 1 do
  begin
    if Game.SavedGame.Countries[i].Rules.InsideCountry(FBase.Longitude, FBase.Latitude) then
    begin
      country := Tr(Game.SavedGame.Countries[i].Rules.TypeName);
      Break;
    end;
  end;
  for i := 0 to Game.SavedGame.Regions.Count - 1 do
  begin
    if Game.SavedGame.Regions[i].Rules.InsideRegion(FBase.Longitude, FBase.Latitude) then
    begin
      region := Tr(Game.SavedGame.Regions[i].Rules.TypeName);
      Break;
    end;
  end;

  if not country.IsEmpty then
    location := Tr('STR_COUNTRIES_COMMA').Arg(country).Arg(region)
  else if not region.IsEmpty then
    location := region
  else
    location := Tr('STR_UNKNOWN');

  FTxtTitle.Text := Tr('STR_XCOM_AGENTS_HAVE_LOCATED_AN_ALIEN_BASE_IN_REGION').Arg(location);
end;

destructor TAlienBaseState.Destroy;
begin
  // cleanup
  inherited;
end;

procedure TAlienBaseState.BtnOkClick(AAction: TAction);
begin
  FState.TimerReset;
  FState.Globe.Center(FBase.Longitude, FBase.Latitude);
  Game.PopState;
end;

end.