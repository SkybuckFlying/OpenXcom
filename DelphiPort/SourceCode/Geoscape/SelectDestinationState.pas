unit SelectDestinationState;

interface

uses
  System.SysUtils, System.Math,
  Engine.State, Engine.Game, Engine.Screen, Engine.Action,
  Engine.Mod, Engine.LocalizedText, Engine.Surface,
  Interface.Window, Geoscape.Globe, Interface.Text,
  Interface.TextButton, Savegame.Waypoint,
  Geoscape.MultipleTargetsState, Savegame.SavedGame,
  Savegame.Craft, Mod.RuleCraft, Geoscape.ConfirmCydoniaState,
  Engine.Options;

type
  TSelectDestinationState = class(TState)
  private
    FCraft: TCraft;
    FGlobe: TGlobe;
    FBtnRotateLeft, FBtnRotateRight, FBtnRotateUp, FBtnRotateDown: TInteractiveSurface;
    FBtnZoomIn, FBtnZoomOut: TInteractiveSurface;
    FWindow: TWindow;
    FTxtTitle: TText;
    FBtnCancel, FBtnCydonia: TTextButton;
    procedure GlobeClick(AAction: TAction);
    procedure BtnRotateLeftPress(AAction: TAction);
    procedure BtnRotateLeftRelease(AAction: TAction);
    procedure BtnRotateRightPress(AAction: TAction);
    procedure BtnRotateRightRelease(AAction: TAction);
    procedure BtnRotateUpPress(AAction: TAction);
    procedure BtnRotateUpRelease(AAction: TAction);
    procedure BtnRotateDownPress(AAction: TAction);
    procedure BtnRotateDownRelease(AAction: TAction);
    procedure BtnZoomInLeftClick(AAction: TAction);
    procedure BtnZoomInRightClick(AAction: TAction);
    procedure BtnZoomOutLeftClick(AAction: TAction);
    procedure BtnZoomOutRightClick(AAction: TAction);
    procedure BtnCancelClick(AAction: TAction);
    procedure BtnCydoniaClick(AAction: TAction);
  public
    constructor Create(ACraft: TCraft; AGlobe: TGlobe);
    destructor Destroy; override;
    procedure Init; override;
    procedure Think; override;
    procedure Handle(AAction: TAction); override;
    procedure Resize(var dX, dY: Integer); override;
  end;

implementation

{ TSelectDestinationState }

constructor TSelectDestinationState.Create(ACraft: TCraft; AGlobe: TGlobe);
var
  dx, dy: Integer;
begin
  inherited Create(nil);
  FCraft := ACraft;
  FGlobe := AGlobe;
  dx := Game.Screen.DX;
  dy := Game.Screen.DY;
  FScreen := False;

  FBtnRotateLeft := TInteractiveSurface.Create(12, 10, 259 + dx * 2, 176 + dy);
  FBtnRotateRight := TInteractiveSurface.Create(12, 10, 283 + dx * 2, 176 + dy);
  FBtnRotateUp := TInteractiveSurface.Create(13, 12, 271 + dx * 2, 162 + dy);
  FBtnRotateDown := TInteractiveSurface.Create(13, 12, 271 + dx * 2, 187 + dy);
  FBtnZoomIn := TInteractiveSurface.Create(23, 23, 295 + dx * 2, 156 + dy);
  FBtnZoomOut := TInteractiveSurface.Create(13, 17, 300 + dx * 2, 182 + dy);

  FWindow := TWindow.Create(Self, 256, 28, 0, 0);
  FWindow.X := dx;
  FWindow.DY := 0;
  FBtnCancel := TTextButton.Create(60, 12, 110 + dx, 8);
  FBtnCydonia := TTextButton.Create(60, 12, 180 + dx, 8);
  FTxtTitle := TText.Create(100, 16, 10 + dx, 6);

  SetInterface('geoscape');

  Add(FBtnRotateLeft);
  Add(FBtnRotateRight);
  Add(FBtnRotateUp);
  Add(FBtnRotateDown);
  Add(FBtnZoomIn);
  Add(FBtnZoomOut);

  Add(FWindow, 'genericWindow', 'geoscape');
  Add(FBtnCancel, 'genericButton1', 'geoscape');
  Add(FBtnCydonia, 'genericButton1', 'geoscape');
  Add(FTxtTitle, 'genericText', 'geoscape');

  FGlobe.OnMouseClick := GlobeClick;

  FBtnRotateLeft.OnMousePress := BtnRotateLeftPress;
  FBtnRotateLeft.OnMouseRelease := BtnRotateLeftRelease;
  FBtnRotateLeft.OnKeyboardPress(Options.KeyGeoLeft, BtnRotateLeftPress);
  FBtnRotateLeft.OnKeyboardRelease(Options.KeyGeoLeft, BtnRotateLeftRelease);

  FBtnRotateRight.OnMousePress := BtnRotateRightPress;
  FBtnRotateRight.OnMouseRelease := BtnRotateRightRelease;
  FBtnRotateRight.OnKeyboardPress(Options.KeyGeoRight, BtnRotateRightPress);
  FBtnRotateRight.OnKeyboardRelease(Options.KeyGeoRight, BtnRotateRightRelease);

  FBtnRotateUp.OnMousePress := BtnRotateUpPress;
  FBtnRotateUp.OnMouseRelease := BtnRotateUpRelease;
  FBtnRotateUp.OnKeyboardPress(Options.KeyGeoUp, BtnRotateUpPress);
  FBtnRotateUp.OnKeyboardRelease(Options.KeyGeoUp, BtnRotateUpRelease);

  FBtnRotateDown.OnMousePress := BtnRotateDownPress;
  FBtnRotateDown.OnMouseRelease := BtnRotateDownRelease;
  FBtnRotateDown.OnKeyboardPress(Options.KeyGeoDown, BtnRotateDownPress);
  FBtnRotateDown.OnKeyboardRelease(Options.KeyGeoDown, BtnRotateDownRelease);

  FBtnZoomIn.OnMouseClick(BtnZoomInLeftClick, SDL_BUTTON_LEFT);
  FBtnZoomIn.OnMouseClick(BtnZoomInRightClick, SDL_BUTTON_RIGHT);
  FBtnZoomIn.OnKeyboardPress(Options.KeyGeoZoomIn, BtnZoomInLeftClick);

  FBtnZoomOut.OnMouseClick(BtnZoomOutLeftClick, SDL_BUTTON_LEFT);
  FBtnZoomOut.OnMouseClick(BtnZoomOutRightClick, SDL_BUTTON_RIGHT);
  FBtnZoomOut.OnKeyboardPress(Options.KeyGeoZoomOut, BtnZoomOutLeftClick);

  FBtnRotateLeft.SetListButton;
  FBtnRotateRight.SetListButton;
  FBtnRotateUp.SetListButton;
  FBtnRotateDown.SetListButton;

  FWindow.SetBackground(Game.Mod.GetSurface('BACK01.SCR'));

  FBtnCancel.Text := Tr('STR_CANCEL_UC');
  FBtnCancel.OnMouseClick := BtnCancelClick;
  FBtnCancel.OnKeyboardPress(Options.KeyCancel, BtnCancelClick);

  FTxtTitle.Text := Tr('STR_SELECT_DESTINATION');
  FTxtTitle.VerticalAlign := ALIGN_MIDDLE;
  FTxtTitle.WordWrap := True;

  if not FCraft.Rules.IsSpacecraft or not Game.SavedGame.IsResearched(Game.Mod.FinalResearch) then
    FBtnCydonia.Visible := False
  else
  begin
    FBtnCydonia.Text := Tr('STR_CYDONIA');
    FBtnCydonia.OnMouseClick := BtnCydoniaClick;
  end;

  if FCraft.Status <> 'STR_OUT' then
  begin
    FGlobe.SetCraftRange(FCraft.Longitude, FCraft.Latitude, FCraft.BaseRange);
    FGlobe.Invalidate;
  end;
end;

destructor TSelectDestinationState.Destroy;
begin
  FGlobe.SetCraftRange(0, 0, 0);
  inherited;
end;

procedure TSelectDestinationState.Init;
begin
  inherited;
  FGlobe.RotateStop;
end;

procedure TSelectDestinationState.Think;
begin
  inherited;
  FGlobe.Think;
end;

procedure TSelectDestinationState.Handle(AAction: TAction);
begin
  inherited;
  FGlobe.Handle(AAction, Self);
end;

procedure TSelectDestinationState.GlobeClick(AAction: TAction);
var
  lon, lat: Double;
  mouseX, mouseY: Integer;
  v: TList;
  w: TWaypoint;
begin
  mouseX := Floor(AAction.AbsoluteXMouse);
  mouseY := Floor(AAction.AbsoluteYMouse);
  FGlobe.CartToPolar(mouseX, mouseY, lon, lat);

  if mouseY < 28 then Exit;

  if AAction.Details.button.button = SDL_BUTTON_LEFT then
  begin
    v := FGlobe.GetTargets(mouseX, mouseY, True);
    try
      if v.Count = 0 then
      begin
        w := TWaypoint.Create;
        w.Longitude := lon;
        w.Latitude := lat;
        v.Add(w);
      end;
      Game.PushState(TMultipleTargetsState.Create(v, FCraft, nil));
    except
      v.Free;
      raise;
    end;
  end;
end;

procedure TSelectDestinationState.BtnRotateLeftPress(AAction: TAction);
begin
  FGlobe.RotateLeft;
end;

procedure TSelectDestinationState.BtnRotateLeftRelease(AAction: TAction);
begin
  FGlobe.RotateStopLon;
end;

procedure TSelectDestinationState.BtnRotateRightPress(AAction: TAction);
begin
  FGlobe.RotateRight;
end;

procedure TSelectDestinationState.BtnRotateRightRelease(AAction: TAction);
begin
  FGlobe.RotateStopLon;
end;

procedure TSelectDestinationState.BtnRotateUpPress(AAction: TAction);
begin
  FGlobe.RotateUp;
end;

procedure TSelectDestinationState.BtnRotateUpRelease(AAction: TAction);
begin
  FGlobe.RotateStopLat;
end;

procedure TSelectDestinationState.BtnRotateDownPress(AAction: TAction);
begin
  FGlobe.RotateDown;
end;

procedure TSelectDestinationState.BtnRotateDownRelease(AAction: TAction);
begin
  FGlobe.RotateStopLat;
end;

procedure TSelectDestinationState.BtnZoomInLeftClick(AAction: TAction);
begin
  FGlobe.ZoomIn;
end;

procedure TSelectDestinationState.BtnZoomInRightClick(AAction: TAction);
begin
  FGlobe.ZoomMax;
end;

procedure TSelectDestinationState.BtnZoomOutLeftClick(AAction: TAction);
begin
  FGlobe.ZoomOut;
end;

procedure TSelectDestinationState.BtnZoomOutRightClick(AAction: TAction);
begin
  FGlobe.ZoomMin;
end;

procedure TSelectDestinationState.BtnCancelClick(AAction: TAction);
begin
  Game.PopState;
end;

procedure TSelectDestinationState.BtnCydoniaClick(AAction: TAction);
begin
  if (FCraft.NumSoldiers > 0) or (FCraft.NumVehicles > 0) then
    Game.PushState(TConfirmCydoniaState.Create(FCraft));
end;

procedure TSelectDestinationState.Resize(var dX, dY: Integer);
begin
  for var surf in FSurfaces do
  begin
    surf.X := surf.X + dX div 2;
    if (surf <> FWindow) and (surf <> FBtnCancel) and (surf <> FTxtTitle) and (surf <> FBtnCydonia) then
      surf.Y := surf.Y + dY div 2;
  end;
end;

end.