unit CraftArmorState;

interface

uses
  Classes, SysUtils,
  Engine.State, Engine.Game, Engine.Action,
  Mod.Mod, Engine.LocalizedText, Engine.Options,
  Interface.TextButton, Interface.Window, Interface.Text, Interface.TextList,
  Savegame.Base, Savegame.Soldier, Savegame.Craft,
  Mod.Armor, SoldierArmorState, Savegame.SavedGame,
  Savegame.ItemContainer, Mod.RuleInterface, Mod.RuleSoldier;

type
  TCraftArmorState = class(TState)
  private
    FBase: TBase;
    FCraft: Integer;
    FBtnOk: TTextButton;
    FWindow: TWindow;
    FTxtTitle, FTxtName, FTxtCraft, FTxtArmor: TText;
    FLstSoldiers: TTextList;
  public
    constructor Create(AOwner: TComponent; Base: TBase; Craft: Integer);
    destructor Destroy; override;
    procedure Init; override;
    procedure BtnOkClick(Sender: TObject; Action: TAction);
    procedure LstSoldiersClick(Sender: TObject; Action: TAction);
  end;

implementation

constructor TCraftArmorState.Create(AOwner: TComponent; Base: TBase; Craft: Integer);
var
  c: TCraft;
  Soldier: TSoldier;
  row: Integer;
  color: Byte;
  otherColor: Byte;
begin
  inherited Create(AOwner);
  FBase := Base;
  FCraft := Craft;

  FWindow := TWindow.Create(Self, 320, 200, 0, 0);
  FBtnOk := TTextButton.Create(288, 16, 16, 176);
  FTxtTitle := TText.Create(300, 17, 16, 7);
  FTxtName := TText.Create(114, 9, 16, 32);
  FTxtCraft := TText.Create(76, 9, 130, 32);
  FTxtArmor := TText.Create(100, 9, 199, 32);
  FLstSoldiers := TTextList.Create(292, 128, 8, 40);

  SetInterface('craftArmor');
  Add(FWindow, 'window', 'craftArmor');
  Add(FBtnOk, 'button', 'craftArmor');
  Add(FTxtTitle, 'text', 'craftArmor');
  Add(FTxtName, 'text', 'craftArmor');
  Add(FTxtCraft, 'text', 'craftArmor');
  Add(FTxtArmor, 'text', 'craftArmor');
  Add(FLstSoldiers, 'list', 'craftArmor');
  CenterAllSurfaces;

  FWindow.SetBackground(FGame.GetMod.GetSurface('BACK14.SCR'));
  FBtnOk.SetText(Translate('STR_OK'));
  FBtnOk.OnMouseClick := BtnOkClick;
  FBtnOk.OnKeyboardPress := BtnOkClick;
  FTxtTitle.SetBig;
  FTxtTitle.SetText(Translate('STR_SELECT_ARMOR'));
  FTxtName.SetText(Translate('STR_NAME_UC'));
  FTxtCraft.SetText(Translate('STR_CRAFT'));
  FTxtArmor.SetText(Translate('STR_ARMOR'));

  FLstSoldiers.SetColumns([114, 69, 101]);
  FLstSoldiers.SetSelectable(True);
  FLstSoldiers.SetBackground(FWindow);
  FLstSoldiers.SetMargin(8);
  FLstSoldiers.SetScrolling(True, 0);
  FLstSoldiers.OnMousePress := LstSoldiersClick;

  c := FBase.GetCrafts[Craft];
  otherColor := FGame.GetMod.GetInterface('craftArmor').GetElement('otherCraft').Color;
  row := 0;
  for Soldier in FBase.GetSoldiers do
  begin
    FLstSoldiers.AddRow([
      Soldier.GetName(True),
      Soldier.GetCraftString(FGame.GetLanguage),
      Translate(Soldier.GetArmor.GetType)
    ]);
    if Soldier.GetCraft = c then
      color := FLstSoldiers.GetSecondaryColor
    else if Soldier.GetCraft <> nil then
      color := otherColor
    else
      color := FLstSoldiers.GetColor;
    FLstSoldiers.SetRowColor(row, color);
    Inc(row);
  end;
end;

destructor TCraftArmorState.Destroy;
begin
  inherited;
end;

procedure TCraftArmorState.Init;
var
  row: Integer;
begin
  inherited;
  row := 0;
  for Soldier in FBase.GetSoldiers do
  begin
    FLstSoldiers.SetCellText(row, 2, Translate(Soldier.GetArmor.GetType));
    Inc(row);
  end;
end;

procedure TCraftArmorState.BtnOkClick(Sender: TObject; Action: TAction);
begin
  FGame.PopState;
end;

procedure TCraftArmorState.LstSoldiersClick(Sender: TObject; Action: TAction);
var
  s: TSoldier;
  a: TArmor;
  save: TSavedGame;
begin
  s := FBase.GetSoldiers[FLstSoldiers.GetSelectedRow];
  if (s.GetCraft <> nil) and (s.GetCraft.GetStatus = 'STR_OUT') then Exit;

  if Action.GetDetails.button.button = SDL_BUTTON_LEFT then
    FGame.PushState(TSoldierArmorState.Create(Self, FBase, FLstSoldiers.GetSelectedRow))
  else if Action.GetDetails.button.button = SDL_BUTTON_RIGHT then
  begin
    save := FGame.GetSavedGame;
    a := FGame.GetMod.GetArmor(save.GetLastSelectedArmor);
    if (a <> nil) and ((a.GetUnits.IsEmpty) or (a.GetUnits.IndexOf(s.GetRules.GetType) <> -1)) then
    begin
      if save.GetMonthsPassed <> -1 then
      begin
        if FBase.GetStorageItems.GetItem(a.GetStoreItem) > 0 then
        begin
          if s.GetArmor.GetStoreItem <> Armor.NONE then
            FBase.GetStorageItems.AddItem(s.GetArmor.GetStoreItem);
          if a.GetStoreItem <> Armor.NONE then
            FBase.GetStorageItems.RemoveItem(a.GetStoreItem);
          s.SetArmor(a);
          FLstSoldiers.SetCellText(FLstSoldiers.GetSelectedRow, 2, Translate(a.GetType));
        end;
      end
      else
      begin
        s.SetArmor(a);
        FLstSoldiers.SetCellText(FLstSoldiers.GetSelectedRow, 2, Translate(a.GetType));
      end;
    end;
  end;
end;

end.