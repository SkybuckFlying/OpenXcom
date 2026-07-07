unit CraftSoldiersState;

interface

uses
  Classes, SysUtils, Generics.Collections,
  Engine.State, Engine.Game, Engine.Action,
  Mod.Mod, Engine.LocalizedText, Engine.Options,
  Interface.ComboBox, Interface.TextButton, Interface.Window,
  Interface.Text, Interface.TextList,
  Savegame.Base, Savegame.Soldier, Savegame.Craft,
  Savegame.SavedGame, SoldierInfoState, Mod.RuleInterface,
  Math;

type
  TGetStatFn = function(Game: TGame; Soldier: TSoldier): Integer;

  TSortFunctor = class
  private
    FGame: TGame;
    FGetStatFn: TGetStatFn;
  public
    constructor Create(Game: TGame; GetStatFn: TGetStatFn);
    function Compare(SoldierA, SoldierB: TSoldier): Boolean;
  end;

  TCraftSoldiersState = class(TState)
  private
    FBase: TBase;
    FCraft: Integer;
    FOtherCraftColor: Byte;
    FOrigSoldierOrder: TList<TSoldier>;

    FBtnOk: TTextButton;
    FWindow: TWindow;
    FTxtTitle, FTxtName, FTxtRank, FTxtCraft, FTxtAvailable, FTxtUsed: TText;
    FCbxSortBy: TComboBox;
    FLstSoldiers: TTextList;
    FSortFunctors: TList<TSortFunctor>;

    procedure InitList;
    procedure MoveSoldierUp(Action: TAction; Row: Integer; Max: Boolean = False);
    procedure MoveSoldierDown(Action: TAction; Row: Integer; Max: Boolean = False);
  public
    constructor Create(AOwner: TComponent; Base: TBase; Craft: Integer);
    destructor Destroy; override;
    procedure Init; override;
    procedure CbxSortByChange(Sender: TObject; Action: TAction);
    procedure BtnOkClick(Sender: TObject; Action: TAction);
    procedure LstItemsLeftArrowClick(Sender: TObject; Action: TAction);
    procedure LstItemsRightArrowClick(Sender: TObject; Action: TAction);
    procedure LstSoldiersClick(Sender: TObject; Action: TAction);
    procedure LstSoldiersMousePress(Sender: TObject; Action: TAction);
  end;

implementation

{ TSortFunctor }
constructor TSortFunctor.Create(Game: TGame; GetStatFn: TGetStatFn);
begin
  FGame := Game;
  FGetStatFn := GetStatFn;
end;

function TSortFunctor.Compare(SoldierA, SoldierB: TSoldier): Boolean;
begin
  Result := FGetStatFn(FGame, SoldierA) < FGetStatFn(FGame, SoldierB);
end;

// Stat functions
function TuStat(Game: TGame; S: TSoldier): Integer; begin Result := S.GetCurrentStats.TU; end;
function StaminaStat(Game: TGame; S: TSoldier): Integer; begin Result := S.GetCurrentStats.Stamina; end;
function HealthStat(Game: TGame; S: TSoldier): Integer; begin Result := S.GetCurrentStats.Health; end;
function BraveryStat(Game: TGame; S: TSoldier): Integer; begin Result := S.GetCurrentStats.Bravery; end;
function ReactionsStat(Game: TGame; S: TSoldier): Integer; begin Result := S.GetCurrentStats.Reactions; end;
function FiringStat(Game: TGame; S: TSoldier): Integer; begin Result := S.GetCurrentStats.Firing; end;
function ThrowingStat(Game: TGame; S: TSoldier): Integer; begin Result := S.GetCurrentStats.Throwing; end;
function StrengthStat(Game: TGame; S: TSoldier): Integer; begin Result := S.GetCurrentStats.Strength; end;
function PsiStrengthStat(Game: TGame; S: TSoldier): Integer;
begin
  if (S.GetCurrentStats.PsiSkill > 0) or
     (Options.PsiStrengthEval and Game.GetSavedGame.IsResearched(Game.GetMod.GetPsiRequirements)) then
    Result := S.GetCurrentStats.PsiStrength
  else
    Result := 0;
end;
function PsiSkillStat(Game: TGame; S: TSoldier): Integer;
begin
  Result := Max(S.GetCurrentStats.PsiSkill, 0);
end;
function MeleeStat(Game: TGame; S: TSoldier): Integer; begin Result := S.GetCurrentStats.Melee; end;
function RankStat(Game: TGame; S: TSoldier): Integer; begin Result := Ord(S.GetRank); end;
function MissionsStat(Game: TGame; S: TSoldier): Integer; begin Result := S.GetMissions; end;
function KillsStat(Game: TGame; S: TSoldier): Integer; begin Result := S.GetKills; end;
function WoundRecoveryStat(Game: TGame; S: TSoldier): Integer; begin Result := S.GetWoundRecovery; end;

constructor TCraftSoldiersState.Create(AOwner: TComponent; Base: TBase; Craft: Integer);
var
  sortOptions: TStringList;
  procedure PushSortOption(const Id: string; Fn: TGetStatFn);
  begin
    sortOptions.Add(Translate(Id));
    FSortFunctors.Add(TSortFunctor.Create(FGame, Fn));
  end;
begin
  inherited Create(AOwner);
  FBase := Base;
  FCraft := Craft;
  FOrigSoldierOrder := TList<TSoldier>.Create;
  FOrigSoldierOrder.AddRange(FBase.GetSoldiers.ToArray);

  FWindow := TWindow.Create(Self, 320, 200, 0, 0);
  FBtnOk := TTextButton.Create(148, 16, 164, 176);
  FTxtTitle := TText.Create(300, 17, 16, 7);
  FTxtName := TText.Create(114, 9, 16, 32);
  FTxtRank := TText.Create(102, 9, 122, 32);
  FTxtCraft := TText.Create(84, 9, 224, 32);
  FTxtAvailable := TText.Create(110, 9, 16, 24);
  FTxtUsed := TText.Create(110, 9, 122, 24);
  FCbxSortBy := TComboBox.Create(Self, 148, 16, 8, 176, True);
  FLstSoldiers := TTextList.Create(288, 128, 8, 40);

  SetInterface('craftSoldiers');
  Add(FWindow, 'window', 'craftSoldiers');
  Add(FBtnOk, 'button', 'craftSoldiers');
  Add(FTxtTitle, 'text', 'craftSoldiers');
  Add(FTxtName, 'text', 'craftSoldiers');
  Add(FTxtRank, 'text', 'craftSoldiers');
  Add(FTxtCraft, 'text', 'craftSoldiers');
  Add(FTxtAvailable, 'text', 'craftSoldiers');
  Add(FTxtUsed, 'text', 'craftSoldiers');
  Add(FLstSoldiers, 'list', 'craftSoldiers');
  Add(FCbxSortBy, 'button', 'craftSoldiers');

  FOtherCraftColor := FGame.GetMod.GetInterface('craftSoldiers').GetElement('otherCraft').Color;
  CenterAllSurfaces;

  FWindow.SetBackground(FGame.GetMod.GetSurface('BACK02.SCR'));
  FBtnOk.SetText(Translate('STR_OK'));
  FBtnOk.OnMouseClick := BtnOkClick;
  FBtnOk.OnKeyboardPress := BtnOkClick;

  FTxtTitle.SetBig;
  FTxtTitle.SetText(Translate('STR_SELECT_SQUAD_FOR_CRAFT').Arg(
    FBase.GetCrafts[FCraft].GetName(FGame.GetLanguage)));
  FTxtName.SetText(Translate('STR_NAME_UC'));
  FTxtRank.SetText(Translate('STR_RANK'));
  FTxtCraft.SetText(Translate('STR_CRAFT'));

  sortOptions := TStringList.Create;
  try
    sortOptions.Add(Translate('STR_ORIGINAL_ORDER'));
    FSortFunctors := TList<TSortFunctor>.Create;
    FSortFunctors.Add(nil);

    PushSortOption('STR_RANK', RankStat);
    PushSortOption('STR_MISSIONS2', MissionsStat);
    PushSortOption('STR_KILLS2', KillsStat);
    PushSortOption('STR_WOUND_RECOVERY2', WoundRecoveryStat);
    PushSortOption('STR_TIME_UNITS', TuStat);
    PushSortOption('STR_STAMINA', StaminaStat);
    PushSortOption('STR_HEALTH', HealthStat);
    PushSortOption('STR_BRAVERY', BraveryStat);
    PushSortOption('STR_REACTIONS', ReactionsStat);
    PushSortOption('STR_FIRING_ACCURACY', FiringStat);
    PushSortOption('STR_THROWING_ACCURACY', ThrowingStat);
    PushSortOption('STR_STRENGTH', StrengthStat);

    // Psi options only if researched or has skill
    if Options.PsiStrengthEval and FGame.GetSavedGame.IsResearched(FGame.GetMod.GetPsiRequirements) then
      PushSortOption('STR_PSIONIC_STRENGTH', PsiStrengthStat);
    if FBase.GetSoldiers.Exists( function(S: TSoldier): Boolean begin Result := S.GetCurrentStats.PsiSkill > 0; end) then
      PushSortOption('STR_PSIONIC_SKILL', PsiSkillStat);

    PushSortOption('STR_MELEE_ACCURACY', MeleeStat);

    FCbxSortBy.SetOptions(sortOptions);
    FCbxSortBy.SetSelected(0);
    FCbxSortBy.OnChange := CbxSortByChange;
    FCbxSortBy.SetText(Translate('STR_SORT_BY'));

    FLstSoldiers.SetArrowColumn(192, ARROW_VERTICAL);
    FLstSoldiers.SetColumns([106, 102, 72]);
    FLstSoldiers.SetSelectable(True);
    FLstSoldiers.SetBackground(FWindow);
    FLstSoldiers.SetMargin(8);
    FLstSoldiers.OnLeftArrowClick := LstItemsLeftArrowClick;
    FLstSoldiers.OnRightArrowClick := LstItemsRightArrowClick;
    FLstSoldiers.OnMouseClick := LstSoldiersClick;
    FLstSoldiers.OnMousePress := LstSoldiersMousePress;
  finally
    sortOptions.Free;
  end;
end;

destructor TCraftSoldiersState.Destroy;
begin
  FOrigSoldierOrder.Free;
  FSortFunctors.Free;
  inherited;
end;

procedure TCraftSoldiersState.CbxSortByChange(Sender: TObject; Action: TAction);
var
  idx: Integer;
  comp: TSortFunctor;
  Soldier: TSoldier;
  it: TList<TSoldier>.TEnumerator;
begin
  idx := FCbxSortBy.GetSelected;
  if idx = -1 then Exit;

  comp := FSortFunctors[idx];
  if comp <> nil then
    FBase.GetSoldiers.Sort( TComparer<TSoldier>.Construct( comp.Compare ) )
  else
  begin
    // restore original order
    for Soldier in FOrigSoldierOrder do
    begin
      if FBase.GetSoldiers.Contains(Soldier) then
      begin
        FBase.GetSoldiers.Remove(Soldier);
        FBase.GetSoldiers.Add(Soldier);
      end;
    end;
  end;
  InitList;
end;

procedure TCraftSoldiersState.BtnOkClick(Sender: TObject; Action: TAction);
begin
  FGame.PopState;
end;

procedure TCraftSoldiersState.InitList;
var
  row: Integer;
  c: TCraft;
  Soldier: TSoldier;
  color: Byte;
begin
  c := FBase.GetCrafts[FCraft];
  FLstSoldiers.ClearList;
  row := 0;
  for Soldier in FBase.GetSoldiers do
  begin
    FLstSoldiers.AddRow([Soldier.GetName(True, 19), Translate(Soldier.GetRankString), Soldier.GetCraftString(FGame.GetLanguage)]);
    if Soldier.GetCraft = c then
      color := FLstSoldiers.GetSecondaryColor
    else if Soldier.GetCraft <> nil then
      color := FOtherCraftColor
    else
      color := FLstSoldiers.GetColor;
    FLstSoldiers.SetRowColor(row, color);
    Inc(row);
  end;
  FLstSoldiers.Draw;
  FTxtAvailable.SetText(Translate('STR_SPACE_AVAILABLE').Arg(c.GetSpaceAvailable));
  FTxtUsed.SetText(Translate('STR_SPACE_USED').Arg(c.GetSpaceUsed));
end;

procedure TCraftSoldiersState.Init;
begin
  inherited;
  InitList;
end;

procedure TCraftSoldiersState.LstItemsLeftArrowClick(Sender: TObject; Action: TAction);
var
  row: Integer;
begin
  row := FLstSoldiers.GetSelectedRow;
  if row > 0 then
  begin
    if Action.GetDetails.button.button = SDL_BUTTON_LEFT then
      MoveSoldierUp(Action, row)
    else if Action.GetDetails.button.button = SDL_BUTTON_RIGHT then
      MoveSoldierUp(Action, row, True);
  end;
  FCbxSortBy.SetText(Translate('STR_SORT_BY'));
  FCbxSortBy.SetSelected(-1);
end;

procedure TCraftSoldiersState.MoveSoldierUp(Action: TAction; Row: Integer; Max: Boolean);
var
  s: TSoldier;
begin
  s := FBase.GetSoldiers[Row];
  if Max then
  begin
    FBase.GetSoldiers.Delete(Row);
    FBase.GetSoldiers.Insert(0, s);
  end
  else
  begin
    FBase.GetSoldiers[Row] := FBase.GetSoldiers[Row-1];
    FBase.GetSoldiers[Row-1] := s;
    if Row <> FLstSoldiers.GetScroll then
      SDL_WarpMouse(Action.GetLeftBlackBand + Action.GetXMouse, Action.GetTopBlackBand + Action.GetYMouse - 8 * Trunc(Action.GetYScale))
    else
      FLstSoldiers.ScrollUp(False);
  end;
  InitList;
end;

procedure TCraftSoldiersState.LstItemsRightArrowClick(Sender: TObject; Action: TAction);
var
  row: Integer;
begin
  row := FLstSoldiers.GetSelectedRow;
  if row < FBase.GetSoldiers.Count - 1 then
  begin
    if Action.GetDetails.button.button = SDL_BUTTON_LEFT then
      MoveSoldierDown(Action, row)
    else if Action.GetDetails.button.button = SDL_BUTTON_RIGHT then
      MoveSoldierDown(Action, row, True);
  end;
  FCbxSortBy.SetText(Translate('STR_SORT_BY'));
  FCbxSortBy.SetSelected(-1);
end;

procedure TCraftSoldiersState.MoveSoldierDown(Action: TAction; Row: Integer; Max: Boolean);
var
  s: TSoldier;
begin
  s := FBase.GetSoldiers[Row];
  if Max then
  begin
    FBase.GetSoldiers.Delete(Row);
    FBase.GetSoldiers.Add(s);
  end
  else
  begin
    FBase.GetSoldiers[Row] := FBase.GetSoldiers[Row+1];
    FBase.GetSoldiers[Row+1] := s;
    if Row <> FLstSoldiers.GetVisibleRows - 1 + FLstSoldiers.GetScroll then
      SDL_WarpMouse(Action.GetLeftBlackBand + Action.GetXMouse, Action.GetTopBlackBand + Action.GetYMouse + 8 * Trunc(Action.GetYScale))
    else
      FLstSoldiers.ScrollDown(False);
  end;
  InitList;
end;

procedure TCraftSoldiersState.LstSoldiersClick(Sender: TObject; Action: TAction);
var
  row: Integer;
  c: TCraft;
  s: TSoldier;
  color: Byte;
begin
  if (Action.GetAbsoluteXMouse >= FLstSoldiers.GetArrowsLeftEdge) and
     (Action.GetAbsoluteXMouse < FLstSoldiers.GetArrowsRightEdge) then
    Exit;

  row := FLstSoldiers.GetSelectedRow;
  if Action.GetDetails.button.button = SDL_BUTTON_LEFT then
  begin
    c := FBase.GetCrafts[FCraft];
    s := FBase.GetSoldiers[row];
    if s.GetCraft = c then
    begin
      s.SetCraft(nil);
      FLstSoldiers.SetCellText(row, 2, Translate('STR_NONE_UC'));
      color := FLstSoldiers.GetColor;
    end
    else if (s.GetCraft <> nil) and (s.GetCraft.GetStatus = 'STR_OUT') then
      color := FOtherCraftColor
    else if (c.GetSpaceAvailable > 0) and (s.GetWoundRecovery = 0) then
    begin
      s.SetCraft(c);
      FLstSoldiers.SetCellText(row, 2, c.GetName(FGame.GetLanguage));
      color := FLstSoldiers.GetSecondaryColor;
    end
    else
      Exit;
    FLstSoldiers.SetRowColor(row, color);
    FTxtAvailable.SetText(Translate('STR_SPACE_AVAILABLE').Arg(c.GetSpaceAvailable));
    FTxtUsed.SetText(Translate('STR_SPACE_USED').Arg(c.GetSpaceUsed));
  end
  else if Action.GetDetails.button.button = SDL_BUTTON_RIGHT then
    FGame.PushState(TSoldierInfoState.Create(Self, FBase, row));
end;

procedure TCraftSoldiersState.LstSoldiersMousePress(Sender: TObject; Action: TAction);
var
  row: Integer;
begin
  if Options.ChangeValueByMouseWheel = 0 then Exit;
  row := FLstSoldiers.GetSelectedRow;
  if (Action.GetDetails.button.button = SDL_BUTTON_WHEELUP) and (row > 0) and
     (Action.GetAbsoluteXMouse >= FLstSoldiers.GetArrowsLeftEdge) and
     (Action.GetAbsoluteXMouse <= FLstSoldiers.GetArrowsRightEdge) then
    MoveSoldierUp(Action, row)
  else if (Action.GetDetails.button.button = SDL_BUTTON_WHEELDOWN) and (row < FBase.GetSoldiers.Count - 1) and
     (Action.GetAbsoluteXMouse >= FLstSoldiers.GetArrowsLeftEdge) and
     (Action.GetAbsoluteXMouse <= FLstSoldiers.GetArrowsRightEdge) then
    MoveSoldierDown(Action, row);
end;

end.