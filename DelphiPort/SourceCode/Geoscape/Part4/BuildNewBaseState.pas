unit BuildNewBaseState;

interface

uses
  Engine.State, Engine.Game, Engine.Action, Mod.Mod,
  Engine.LocalizedText, Engine.Surface, Engine.Timer, Engine.Screen,
  Interface.Window, Geoscape.Globe, Interface.Text,
  Interface.TextButton, Savegame.Base, Savegame.Craft,
  Basescape.BaseNameState, Geoscape.ConfirmNewBaseState,
  Engine.Options, Menu.ErrorMessageState, Mod.RuleInterface;

type
  TBuildNewBaseState = class(TState)
  private
    FBase: TBase;
    FGlobe: TGlobe;
    FFirst: Boolean;
    FOldShowRadar: Boolean;
    FOldLat, FOldLon: Double;
    FMouseX, FMouseY: Integer;
    FBtnRotateLeft, FBtnRotateRight, FBtnRotateUp, FBtnRotateDown: TInteractiveSurface;
    FBtnZoomIn, FBtnZoomOut: TInteractiveSurface;
    FWindow: TWindow;
    FBtnCancel: TTextButton;
    FTxtTitle: TText;
    FHoverTimer: TTimer;
    procedure GlobeClick(AAction: TAction);
    procedure GlobeHover(AAction: TAction);
    procedure HoverRedraw;
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
  public
    constructor Create(ABase: TBase; AGlobe: TGlobe; AFirst: Boolean);
    destructor Destroy; override;
    procedure Init; override;
    procedure Think; override;
    procedure Handle(AAction: TAction); override;
    procedure Resize(var dX, dY: Integer); override;
  end;

implementation

uses
  System.SysUtils, System.Math, System.Types;

{ TBuildNewBaseState }

constructor TBuildNewBaseState.Create(ABase: TBase; AGlobe: TGlobe; AFirst: Boolean);
var
  dx, dy: Integer;
begin
  inherited Create(nil);
  FBase := ABase;
  FGlobe := AGlobe;
  FFirst := AFirst;
  FOldLat := 0;
  FOldLon := 0;
  FMouseX := 0;
  FMouseY := 0;

  dx := Game.Screen.DX;
  dy := Game.Screen.DY;
  FScreen := False;

  FOldShowRadar := Options.GlobeRadarLines;
  if not FOldShowRadar then
    Options.GlobeRadarLines := True;

  FBtnRotateLeft := TInteractiveSurface.Create(12, 10, 259 + dx * 2, 176 + dy);
  FBtnRotateRight := TInteractiveSurface.Create(12, 10, 283 + dx * 2, 176 + dy);
  FBtnRotateUp := TInteractiveSurface.Create(13, 12, 271 + dx * 2, 162 + dy);
  FBtnRotateDown := TInteractiveSurface.Create(13, 12, 271 + dx * 2, 187 + dy);
  FBtnZoomIn := TInteractiveSurface.Create(23, 23, 295 + dx * 2, 156 + dy);
  FBtnZoomOut := TInteractiveSurface.Create(13, 17, 300 + dx * 2, 182 + dy);

  FWindow := TWindow.Create(Self, 256, 28, 0, 0);
  FWindow.X := dx;
  FWindow.DY := 0;
  FBtnCancel := TTextButton.Create(54, 12, 186 + dx, 8);
  FTxtTitle := TText.Create(180, 16, 8 + dx, 6);

  FHoverTimer := TTimer.Create(50);
  FHoverTimer.OnTimer := HoverRedraw;
  FHoverTimer.Start;

  SetInterface('geoscape');

  Add(FBtnRotateLeft);
  Add(FBtnRotateRight);
  Add(FBtnRotateUp);
  Add(FBtnRotateDown);
  Add(FBtnZoomIn);
  Add(FBtnZoomOut);

  Add(FWindow, 'genericWindow', 'geoscape');
  Add(FBtnCancel, 'genericButton2', 'geoscape');
  Add(FTxtTitle, 'genericText', 'geoscape');

  // Set up objects
  FGlobe.OnMouseClick := GlobeClick;

  FBtnRotateLeft.OnMousePress := BtnRotateLeftPress;
  FBtnRotateLeft.OnMouseRelease := BtnRotateLeftRelease;
  FBtnRotateLeft.OnKeyboardPress(Options.keyGeoLeft, BtnRotateLeftPress);
  FBtnRotateLeft.OnKeyboardRelease(Options.keyGeoLeft, BtnRotateLeftRelease);

  FBtnRotateRight.OnMousePress := BtnRotateRightPress;
  FBtnRotateRight.OnMouseRelease := BtnRotateRightRelease;
  FBtnRotateRight.OnKeyboardPress(Options.keyGeoRight, BtnRotateRightPress);
  FBtnRotateRight.OnKeyboardRelease(Options.keyGeoRight, BtnRotateRightRelease);

  FBtnRotateUp.OnMousePress := BtnRotateUpPress;
  FBtnRotateUp.OnMouseRelease := BtnRotateUpRelease;
  FBtnRotateUp.OnKeyboardPress(Options.keyGeoUp, BtnRotateUpPress);
  FBtnRotateUp.OnKeyboardRelease(Options.keyGeoUp, BtnRotateUpRelease);

  FBtnRotateDown.OnMousePress := BtnRotateDownPress;
  FBtnRotateDown.OnMouseRelease := BtnRotateDownRelease;
  FBtnRotateDown.OnKeyboardPress(Options.keyGeoDown, BtnRotateDownPress);
  FBtnRotateDown.OnKeyboardRelease(Options.keyGeoDown, BtnRotateDownRelease);

  FBtnZoomIn.OnMouseClick(BtnZoomInLeftClick, SDL_BUTTON_LEFT);
  FBtnZoomIn.OnMouseClick(BtnZoomInRightClick, SDL_BUTTON_RIGHT);
  FBtnZoomIn.OnKeyboardPress(Options.keyGeoZoomIn, BtnZoomInLeftClick);

  FBtnZoomOut.OnMouseClick(BtnZoomOutLeftClick, SDL_BUTTON_LEFT);
  FBtnZoomOut.OnMouseClick(BtnZoomOutRightClick, SDL_BUTTON_RIGHT);
  FBtnZoomOut.OnKeyboardPress(Options.keyGeoZoomOut, BtnZoomOutLeftClick);

  // dirty hacks to get rotate buttons to work in "classic" style
  FBtnRotateLeft.SetListButton;
  FBtnRotateRight.SetListButton;
  FBtnRotateUp.SetListButton;
  FBtnRotateDown.SetListButton;

  FWindow.SetBackground(Game.Mod.GetSurface('BACK01.SCR'));

  FBtnCancel.Text := Tr('STR_CANCEL_UC');
  FBtnCancel.OnMouseClick := BtnCancelClick;
  FBtnCancel.OnKeyboardPress(Options.keyCancel, BtnCancelClick);

  FTxtTitle.Text := Tr('STR_SELECT_SITE_FOR_NEW_BASE');
  FTxtTitle.VerticalAlign := ALIGN_MIDDLE;
  FTxtTitle.WordWrap := True;

  if FFirst then
    FBtnCancel.Visible := False;
end;

destructor TBuildNewBaseState.Destroy;
begin
  if Options.GlobeRadarLines <> FOldShowRadar then
    Options.GlobeRadarLines := False;
  FHoverTimer.Free;
  inherited;
end;

procedure TBuildNewBaseState.Init;
begin
  inherited;
  FGlobe.OnMouseOver := GlobeHover;
  FGlobe.RotateStop;
  FGlobe.SetNewBaseHover(True);
end;

procedure TBuildNewBaseState.Think;
begin
  inherited;
  FGlobe.Think;
  FHoverTimer.Think(Self, 0);
end;

procedure TBuildNewBaseState.Handle(AAction: TAction);
begin
  inherited;
  FGlobe.Handle(AAction, Self);
end;

procedure TBuildNewBaseState.GlobeHover(AAction: TAction);
begin
  FMouseX := Floor(AAction.AbsoluteXMouse);
  FMouseY := Floor(AAction.AbsoluteYMouse);
  if not FHoverTimer.IsRunning then
    FHoverTimer.Start;
end;

procedure TBuildNewBaseState.HoverRedraw;
var
  lon, lat: Double;
begin
  FGlobe.CartToPolar(FMouseX, FMouseY, lon, lat);
  if (lon = lon) and (lat = lat) then // check for NaN
  begin
    FGlobe.SetNewBaseHoverPos(lon, lat);
    FGlobe.SetNewBaseHover(True);
  end;
  if Options.GlobeRadarLines and not (SameValue(FOldLat, lat, 1e-9) and SameValue(FOldLon, lon, 1e-9)) then
  begin
    FOldLat := lat;
    FOldLon := lon;
    FGlobe.Invalidate;
  end;
end;

procedure TBuildNewBaseState.GlobeClick(AAction: TAction);
var
  lon, lat: Double;
  mouseX, mouseY: Integer;
begin
  mouseX := Floor(AAction.AbsoluteXMouse);
  mouseY := Floor(AAction.AbsoluteYMouse);
  FGlobe.CartToPolar(mouseX, mouseY, lon, lat);

  // Ignore window clicks
  if mouseY < 28 then Exit;

  if AAction.Details.button.button = SDL_BUTTON_LEFT then
  begin
    if FGlobe.InsideLand(lon, lat) then
    begin
      FBase.Longitude := lon;
      FBase.Latitude := lat;
      // Update all craft positions
      for var craft in FBase.Crafts do
      begin
        craft.Longitude := lon;
        craft.Latitude := lat;
      end;
      if FFirst then
        Game.PushState(TBaseNameState.Create(FBase, FGlobe, FFirst))
      else
        Game.PushState(TConfirmNewBaseState.Create(FBase, FGlobe));
    end
    else
    begin
      Game.PushState(TErrorMessageState.Create(
        Tr('STR_XCOM_BASE_CANNOT_BE_BUILT'),
        Palette,
        Game.Mod.Interface('geoscape').GetElement('genericWindow').Color,
        'BACK01.SCR',
        Game.Mod.Interface('geoscape').GetElement('palette').Color
      ));
    end;
  end;
end;

procedure TBuildNewBaseState.BtnRotateLeftPress(AAction: TAction);
begin
  FGlobe.RotateLeft;
end;

procedure TBuildNewBaseState.BtnRotateLeftRelease(AAction: TAction);
begin
  FGlobe.RotateStopLon;
end;

procedure TBuildNewBaseState.BtnRotateRightPress(AAction: TAction);
begin
  FGlobe.RotateRight;
end;

procedure TBuildNewBaseState.BtnRotateRightRelease(AAction: TAction);
begin
  FGlobe.RotateStopLon;
end;

procedure TBuildNewBaseState.BtnRotateUpPress(AAction: TAction);
begin
  FGlobe.RotateUp;
end;

procedure TBuildNewBaseState.BtnRotateUpRelease(AAction: TAction);
begin
  FGlobe.RotateStopLat;
end;

procedure TBuildNewBaseState.BtnRotateDownPress(AAction: TAction);
begin
  FGlobe.RotateDown;
end;

procedure TBuildNewBaseState.BtnRotateDownRelease(AAction: TAction);
begin
  FGlobe.RotateStopLat;
end;

procedure TBuildNewBaseState.BtnZoomInLeftClick(AAction: TAction);
begin
  FGlobe.ZoomIn;
end;

procedure TBuildNewBaseState.BtnZoomInRightClick(AAction: TAction);
begin
  FGlobe.ZoomMax;
end;

procedure TBuildNewBaseState.BtnZoomOutLeftClick(AAction: TAction);
begin
  FGlobe.ZoomOut;
end;

procedure TBuildNewBaseState.BtnZoomOutRightClick(AAction: TAction);
begin
  FGlobe.ZoomMin;
end;

procedure TBuildNewBaseState.BtnCancelClick(AAction: TAction);
begin
  FBase.Free;
  Game.PopState;
end;

procedure TBuildNewBaseState.Resize(var dX, dY: Integer);
var
  surf: TSurface;
begin
  for surf in FSurfaces do
  begin
    surf.X := surf.X + dX div 2;
    if (surf <> FWindow) and (surf <> FBtnCancel) and (surf <> FTxtTitle) then
      surf.Y := surf.Y + dY div 2;
  end;
end;

end.