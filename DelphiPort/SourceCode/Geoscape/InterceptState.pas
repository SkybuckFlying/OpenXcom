unit InterceptState;

interface

uses
  System.SysUtils, System.Classes,
  Engine.State, Engine.Game, Engine.Mod, Engine.LocalizedText,
  Interface.TextButton, Interface.Window, Interface.Text,
  Interface.TextList, Savegame.Base, Savegame.Craft,
  Savegame.SavedGame, Engine.Options, Geoscape.Globe,
  Geoscape.SelectDestinationState, Geoscape.ConfirmDestinationState,
  Basescape.BasescapeState;

type
  TInterceptState = class(TState)
  private
    FGlobe: TGlobe;
    FBase: TBase;
    FTarget: TTarget;
    FBtnCancel, FBtnGotoBase: TTextButton;
    FWindow: TWindow;
    FTxtTitle, FTxtCraft, FTxtStatus, FTxtBase, FTxtWeapons: TText;
    FLstCrafts: TTextList;
    FCrafts: TList;
    procedure BtnCancelClick(AAction: TAction);
    procedure BtnGotoBaseClick(AAction: TAction);
    procedure LstCraftsLeftClick(AAction: TAction);
    procedure LstCraftsRightClick(AAction: TAction);
  public
    constructor Create(AGlobe: TGlobe; ABase: TBase = nil; ATarget: TTarget = nil);
    destructor Destroy; override;
  end;

implementation

{ TInterceptState }

constructor TInterceptState.Create(AGlobe: TGlobe; ABase: TBase; ATarget: TTarget);
var
  row: Integer;
  b: TBase;
  c: TCraft;
  ss: string;
begin
  inherited Create(nil);
  FGlobe := AGlobe;
  FBase := ABase;
  FTarget := ATarget;
  FScreen := False;

  FWindow := TWindow.Create(Self, 320, 140, 0, 30, POPUP_HORIZONTAL);
  FBtnCancel := TTextButton.Create(IfThen(ABase <> nil, 142, 288), 16, 16, 146);
  FBtnGotoBase := TTextButton.Create(142, 16, 162, 146);
  FTxtTitle := TText.Create(300, 17, 10, 46);
  FTxtCraft := TText.Create(86, 9, 14, 70);
  FTxtStatus := TText.Create(70, 9, 100, 70);
  FTxtBase := TText.Create(80, 9, 170, 70);
  FTxtWeapons := TText.Create(80, 17, 238, 62);
  FLstCrafts := TTextList.Create(288, 64, 8, 78);

  SetInterface('intercept');

  Add(FWindow, 'window', 'intercept');
  Add(FBtnCancel, 'button', 'intercept');
  Add(FBtnGotoBase, 'button', 'intercept');
  Add(FTxtTitle, 'text1', 'intercept');
  Add(FTxtCraft, 'text2', 'intercept');
  Add(FTxtStatus, 'text2', 'intercept');
  Add(FTxtBase, 'text2', 'intercept');
  Add(FTxtWeapons, 'text2', 'intercept');
  Add(FLstCrafts, 'list', 'intercept');

  CenterAllSurfaces;

  FWindow.SetBackground(Game.Mod.GetSurface('BACK12.SCR'));

  FBtnCancel.Text := Tr('STR_CANCEL');
  FBtnCancel.OnMouseClick := BtnCancelClick;
  FBtnCancel.OnKeyboardPress(Options.KeyCancel, BtnCancelClick);
  FBtnCancel.OnKeyboardPress(Options.KeyGeoIntercept, BtnCancelClick);

  FBtnGotoBase.Text := Tr('STR_GO_TO_BASE');
  FBtnGotoBase.OnMouseClick := BtnGotoBaseClick;
  FBtnGotoBase.Visible := ABase <> nil;

  FTxtTitle.Align := ALIGN_CENTER;
  FTxtTitle.Big := True;
  FTxtTitle.Text := Tr('STR_LAUNCH_INTERCEPTION');

  FTxtCraft.Text := Tr('STR_CRAFT');
  FTxtStatus.Text := Tr('STR_STATUS');
  FTxtBase.Text := Tr('STR_BASE');
  FTxtWeapons.Text := Tr('STR_WEAPONS_CREW_HWPS');

  FLstCrafts.SetColumns(4, 86, 70, 80, 46);
  FLstCrafts.Selectable := True;
  FLstCrafts.Background := FWindow;
  FLstCrafts.Margin := 6;
  FLstCrafts.OnMouseClick := LstCraftsLeftClick;
  FLstCrafts.OnMouseClick(LstCraftsRightClick, SDL_BUTTON_RIGHT);

  FCrafts := TList.Create;
  row := 0;
  for b in Game.SavedGame.Bases do
  begin
    if (FBase <> nil) and (b <> FBase) then Continue;
    for c in b.Crafts do
    begin
      ss := '';
      if c.NumWeapons > 0 then
        ss := Unicode.TOK_COLOR_FLIP + IntToStr(c.NumWeapons) + Unicode.TOK_COLOR_FLIP
      else
        ss := '0';
      ss := ss + '/';
      if c.NumSoldiers > 0 then
        ss := ss + Unicode.TOK_COLOR_FLIP + IntToStr(c.NumSoldiers) + Unicode.TOK_COLOR_FLIP
      else
        ss := ss + '0';
      ss := ss + '/';
      if c.NumVehicles > 0 then
        ss := ss + Unicode.TOK_COLOR_FLIP + IntToStr(c.NumVehicles) + Unicode.TOK_COLOR_FLIP
      else
        ss := ss + '0';
      FCrafts.Add(c);
      FLstCrafts.AddRow(4, [c.Name(Game.Language), Tr(c.Status), b.Name, ss]);
      if c.Status = 'STR_READY' then
        FLstCrafts.SetCellColor(row, 1, FLstCrafts.SecondaryColor);
      Inc(row);
    end;
  end;
end;

destructor TInterceptState.Destroy;
begin
  FCrafts.Free;
  inherited;
end;

procedure TInterceptState.BtnCancelClick(AAction: TAction);
begin
  Game.PopState;
end;

procedure TInterceptState.BtnGotoBaseClick(AAction: TAction);
begin
  Game.PopState;
  Game.PushState(TBasescapeState.Create(FBase, FGlobe));
end;

procedure TInterceptState.LstCraftsLeftClick(AAction: TAction);
var
  c: TCraft;
begin
  c := TCraft(FCrafts[FLstCrafts.SelectedRow]);
  if (c.Status = 'STR_READY') or ((c.Status = 'STR_OUT') and not c.LowFuel and not c.MissionComplete) or Options.CraftLaunchAlways then
  begin
    Game.PopState;
    if FTarget = nil then
      Game.PushState(TSelectDestinationState.Create(c, FGlobe))
    else
      Game.PushState(TConfirmDestinationState.Create(c, FTarget));
  end;
end;

procedure TInterceptState.LstCraftsRightClick(AAction: TAction);
var
  c: TCraft;
begin
  c := TCraft(FCrafts[FLstCrafts.SelectedRow]);
  if c.Status = 'STR_OUT' then
  begin
    FGlobe.Center(c.Longitude, c.Latitude);
    Game.PopState;
  end;
end;

end.