unit MiniMapState;

interface

uses
  Classes, SysUtils,
  Engine.State,
  Engine.Game,
  Engine.Surface,
  Engine.Timer,
  Engine.Action,
  Engine.Screen,
  Engine.Options,
  Interface.BattlescapeButton,
  Interface.Text,
  Savegame.SavedBattleGame,
  Battlescape.Camera,
  Battlescape.MiniMapView;

type
  TMiniMapState = class(TState)
  private
    FBg: TSurface;
    FMiniMapView: TMiniMapView;
    FBtnLvlUp: TBattlescapeButton;
    FBtnLvlDwn: TBattlescapeButton;
    FBtnOk: TBattlescapeButton;
    FTxtLevel: TText;
    FTimerAnimate: TTimer;
    procedure Animate;
    procedure BtnOkClick(Action: TAction);
    procedure BtnLevelUpClick(Action: TAction);
    procedure BtnLevelDownClick(Action: TAction);
  public
    constructor Create(Camera: TCamera; BattleGame: TSavedBattleGame);
    destructor Destroy; override;
    procedure Handle(Action: TAction); override;
    procedure Think; override;
  end;

implementation

uses
  Engine.Mod,
  Engine.LocalizedText,
  Engine.Palette,
  Engine.Action;

{ TMiniMapState }

constructor TMiniMapState.Create(Camera: TCamera; BattleGame: TSavedBattleGame);
begin
  inherited Create;

  if Options.MaximizeInfoScreens then
  begin
    Options.BaseXResolution := Screen.ORIGINAL_WIDTH;
    Options.BaseYResolution := Screen.ORIGINAL_HEIGHT;
    FGame.Screen.ResetDisplay(False);
  end;

  FBg := TSurface.Create(320, 200);
  FMiniMapView := TMiniMapView.Create(221, 148, 48, 16, FGame, Camera, BattleGame);
  FBtnLvlUp := TBattlescapeButton.Create(18, 20, 24, 62);
  FBtnLvlDwn := TBattlescapeButton.Create(18, 20, 24, 88);
  FBtnOk := TBattlescapeButton.Create(32, 32, 275, 145);
  FTxtLevel := TText.Create(28, 16, 281, 75);

  BattleGame.SetPaletteByDepth(Self);

  Add(FBg);
  FGame.Mod.Surface['SCANBORD.PCK'].Blit(FBg);
  Add(FMiniMapView);
  Add(FBtnLvlUp, 'buttonUp', 'minimap', FBg);
  Add(FBtnLvlDwn, 'buttonDown', 'minimap', FBg);
  Add(FBtnOk, 'buttonOK', 'minimap', FBg);
  Add(FTxtLevel, 'textLevel', 'minimap', FBg);

  CenterAllSurfaces;

  if FGame.Screen.DY > 50 then
    FBg.DrawRect(46, 14, 223, 151, Palette.BlockOffset(15)+15);

  FBtnLvlUp.OnMouseClick := BtnLevelUpClick;
  FBtnLvlDwn.OnMouseClick := BtnLevelDownClick;
  FBtnOk.OnMouseClick := BtnOkClick;
  FBtnOk.OnKeyboardPress(Options.KeyCancel, BtnOkClick);
  FBtnOk.OnKeyboardPress(Options.KeyBattleMap, BtnOkClick);

  FTxtLevel.Big := True;
  FTxtLevel.HighContrast := True;
  FTxtLevel.Text := Format(Tr('STR_LEVEL_SHORT'), [Camera.ViewLevel]);

  FTimerAnimate := TTimer.Create(125);
  FTimerAnimate.OnTimer := Animate;
  FTimerAnimate.Start;

  FMiniMapView.Draw;
end;

destructor TMiniMapState.Destroy;
begin
  FTimerAnimate.Free;
  inherited;
end;

procedure TMiniMapState.Handle(Action: TAction);
begin
  inherited;
  if (Action.Details.Type_ = SDL_MOUSEBUTTONDOWN) then
  begin
    if Action.Details.Button.Button = SDL_BUTTON_WHEELUP then
      BtnLevelUpClick(Action)
    else if Action.Details.Button.Button = SDL_BUTTON_WHEELDOWN then
      BtnLevelDownClick(Action);
  end;
end;

procedure TMiniMapState.BtnOkClick(Action: TAction);
begin
  if Options.MaximizeInfoScreens then
  begin
    Screen.UpdateScale(Options.BattlescapeScale, Options.BaseXBattlescape, Options.BaseYBattlescape, True);
    FGame.Screen.ResetDisplay(False);
  end;
  FGame.PopState;
end;

procedure TMiniMapState.BtnLevelUpClick(Action: TAction);
begin
  FTxtLevel.Text := Format(Tr('STR_LEVEL_SHORT'), [FMiniMapView.Up]);
end;

procedure TMiniMapState.BtnLevelDownClick(Action: TAction);
begin
  FTxtLevel.Text := Format(Tr('STR_LEVEL_SHORT'), [FMiniMapView.Down]);
end;

procedure TMiniMapState.Animate;
begin
  FMiniMapView.Animate;
end;

procedure TMiniMapState.Think;
begin
  inherited;
  FTimerAnimate.Think(Self, nil);
end;

end.