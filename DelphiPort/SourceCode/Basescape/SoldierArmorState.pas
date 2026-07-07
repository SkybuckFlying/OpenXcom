unit SoldierArmorState;

interface

uses
  Classes, SysUtils, Generics.Collections,
  Engine.State, Engine.Game, Engine.Action,
  Mod.Mod, Engine.LocalizedText, Engine.Options,
  Interface.TextButton, Interface.Window, Interface.Text, Interface.TextList,
  Mod.Armor, Savegame.SavedGame, Savegame.Soldier, Savegame.Base,
  Savegame.ItemContainer, Mod.RuleSoldier;

type
  TSoldierArmorState = class(TState)
  private
    FBase: TBase;
    FSoldier: Integer;
    FBtnCancel: TTextButton;
    FWindow: TWindow;
    FTxtTitle, FTxtType, FTxtQuantity: TText;
    FLstArmor: TTextList;
    FArmors: TList<TArmor>;
  public
    constructor Create(AOwner: TComponent; Base: TBase; Soldier: Integer);
    destructor Destroy; override;
    procedure BtnCancelClick(Sender: TObject; Action: TAction);
    procedure LstArmorClick(Sender: TObject; Action: TAction);
  end;

implementation

constructor TSoldierArmorState.Create(AOwner: TComponent; Base: TBase; Soldier: Integer);
var
  armors: TStringList;
  a: TArmor;
  s: TSoldier;
begin
  inherited Create(AOwner);
  FBase := Base;
  FSoldier := Soldier;
  Screen := False;

  FWindow := TWindow.Create(Self, 192, 160, 64, 20, POPUP_BOTH);
  FBtnCancel := TTextButton.Create(140, 16, 90, 156);
  FTxtTitle := TText.Create(182, 16, 69, 28);
  FTxtType := TText.Create(90, 9, 80, 52);
  FTxtQuantity := TText.Create(70, 9, 190, 52);
  FLstArmor := TTextList.Create(160, 80, 73, 68);

  SetInterface('soldierArmor');
  Add(FWindow, 'window', 'soldierArmor');
  Add(FBtnCancel, 'button', 'soldierArmor');
  Add(FTxtTitle, 'text', 'soldierArmor');
  Add(FTxtType, 'text', 'soldierArmor');
  Add(FTxtQuantity, 'text', 'soldierArmor');
  Add(FLstArmor, 'list', 'soldierArmor');
  CenterAllSurfaces;

  FWindow.SetBackground(FGame.GetMod.GetSurface('BACK14.SCR'));
  FBtnCancel.SetText(Translate('STR_CANCEL_UC'));
  FBtnCancel.OnMouseClick := BtnCancelClick;
  FBtnCancel.OnKeyboardPress := BtnCancelClick;

  s := FBase.GetSoldiers[Soldier];
  FTxtTitle.SetAlign(ALIGN_CENTER);
  FTxtTitle.SetText(Translate('STR_SELECT_ARMOR_FOR_SOLDIER').Arg(s.GetName));
  FTxtType.SetText(Translate('STR_TYPE'));
  FTxtQuantity.SetText(Translate('STR_QUANTITY_UC'));

  FLstArmor.SetColumns([132, 21]);
  FLstArmor.SetSelectable(True);
  FLstArmor.SetBackground(FWindow);
  FLstArmor.SetMargin(8);

  FArmors := TList<TArmor>.Create;
  armors := FGame.GetMod.GetArmorsList;
  for a in armors do
  begin
    if not a.GetUnits.IsEmpty then
      if a.GetUnits.IndexOf(s.GetRules.GetType) = -1 then
        Continue;
    if FBase.GetStorageItems.GetItem(a.GetStoreItem) > 0 then
    begin
      FArmors.Add(a);
      FLstArmor.AddRow([
        Translate(a.GetType),
        IfThen(FGame.GetSavedGame.GetMonthsPassed > -1, IntToStr(FBase.GetStorageItems.GetItem(a.GetStoreItem)), '-')
      ]);
    end
    else if a.GetStoreItem = Armor.NONE then
    begin
      FArmors.Add(a);
      FLstArmor.AddRow([Translate(a.GetType)]);
    end;
  end;
  FLstArmor.OnMouseClick := LstArmorClick;
end;

destructor TSoldierArmorState.Destroy;
begin
  FArmors.Free;
  inherited;
end;

procedure TSoldierArmorState.BtnCancelClick(Sender: TObject; Action: TAction);
begin
  FGame.PopState;
end;

procedure TSoldierArmorState.LstArmorClick(Sender: TObject; Action: TAction);
var
  soldier: TSoldier;
  armor: TArmor;
begin
  soldier := FBase.GetSoldiers[FSoldier];
  armor := FArmors[FLstArmor.GetSelectedRow];
  if FGame.GetSavedGame.GetMonthsPassed <> -1 then
  begin
    if soldier.GetArmor.GetStoreItem <> Armor.NONE then
      FBase.GetStorageItems.AddItem(soldier.GetArmor.GetStoreItem);
    if armor.GetStoreItem <> Armor.NONE then
      FBase.GetStorageItems.RemoveItem(armor.GetStoreItem);
  end;
  soldier.SetArmor(armor);
  FGame.GetSavedGame.SetLastSelectedArmor(armor.GetType);
  FGame.PopState;
end;

end.