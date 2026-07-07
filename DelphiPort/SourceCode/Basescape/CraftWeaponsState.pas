unit CraftWeaponsState;

interface

uses
  Classes, SysUtils, Generics.Collections,
  Engine.State, Engine.Game, Engine.Action,
  Mod.Mod, Engine.LocalizedText, Engine.Options,
  Interface.TextButton, Interface.Window, Interface.Text, Interface.TextList,
  Savegame.Craft, Savegame.CraftWeapon, Mod.RuleCraftWeapon,
  Savegame.ItemContainer, Savegame.Base;

type
  TCraftWeaponsState = class(TState)
  private
    FBase: TBase;
    FCraft, FWeapon: Integer;
    FBtnCancel: TTextButton;
    FWindow: TWindow;
    FTxtTitle, FTxtArmament, FTxtQuantity, FTxtAmmunition: TText;
    FLstWeapons: TTextList;
    FWeapons: TList<TRuleCraftWeapon>;
  public
    constructor Create(AOwner: TComponent; Base: TBase; Craft, Weapon: Integer);
    destructor Destroy; override;
    procedure BtnCancelClick(Sender: TObject; Action: TAction);
    procedure LstWeaponsClick(Sender: TObject; Action: TAction);
  end;

implementation

constructor TCraftWeaponsState.Create(AOwner: TComponent; Base: TBase; Craft, Weapon: Integer);
var
  Weapons: TStringList;
  w: TRuleCraftWeapon;
  ss: TStringStream;
begin
  inherited Create(AOwner);
  FBase := Base;
  FCraft := Craft;
  FWeapon := Weapon;
  Screen := False;

  FWindow := TWindow.Create(Self, 220, 160, 50, 20, POPUP_BOTH);
  FBtnCancel := TTextButton.Create(140, 16, 90, 156);
  FTxtTitle := TText.Create(208, 17, 56, 28);
  FTxtArmament := TText.Create(76, 9, 66, 52);
  FTxtQuantity := TText.Create(50, 9, 140, 52);
  FTxtAmmunition := TText.Create(68, 17, 200, 44);
  FLstWeapons := TTextList.Create(188, 80, 58, 68);

  SetInterface('craftWeapons');
  Add(FWindow, 'window', 'craftWeapons');
  Add(FBtnCancel, 'button', 'craftWeapons');
  Add(FTxtTitle, 'text', 'craftWeapons');
  Add(FTxtArmament, 'text', 'craftWeapons');
  Add(FTxtQuantity, 'text', 'craftWeapons');
  Add(FTxtAmmunition, 'text', 'craftWeapons');
  Add(FLstWeapons, 'list', 'craftWeapons');
  CenterAllSurfaces;

  FWindow.SetBackground(FGame.GetMod.GetSurface('BACK14.SCR'));
  FBtnCancel.SetText(Translate('STR_CANCEL_UC'));
  FBtnCancel.OnMouseClick := BtnCancelClick;
  FBtnCancel.OnKeyboardPress := BtnCancelClick;
  FTxtTitle.SetBig;
  FTxtTitle.SetAlign(ALIGN_CENTER);
  FTxtTitle.SetText(Translate('STR_SELECT_ARMAMENT'));
  FTxtArmament.SetText(Translate('STR_ARMAMENT'));
  FTxtQuantity.SetText(Translate('STR_QUANTITY_UC'));
  FTxtAmmunition.SetText(Translate('STR_AMMUNITION_AVAILABLE'));
  FTxtAmmunition.SetWordWrap(True);
  FTxtAmmunition.SetVerticalAlign(ALIGN_BOTTOM);
  FLstWeapons.SetColumns([94, 50, 36]);
  FLstWeapons.SetSelectable(True);
  FLstWeapons.SetBackground(FWindow);
  FLstWeapons.SetMargin(8);

  FWeapons := TList<TRuleCraftWeapon>.Create;
  FLstWeapons.AddRow([Translate('STR_NONE_UC')]);
  FWeapons.Add(nil);

  Weapons := FGame.GetMod.GetCraftWeaponsList;
  try
    for w in Weapons do
    begin
      if FBase.GetStorageItems.GetItem(w.GetLauncherItem) > 0 then
      begin
        FWeapons.Add(w);
        ss := TStringStream.Create;
        try
          ss.WriteString(IntToStr(FBase.GetStorageItems.GetItem(w.GetLauncherItem)));
          FTxtAmmunition.SetText(ss.DataString);
        finally
          ss.Free;
        end;
        FLstWeapons.AddRow([Translate(w.GetType),
          IntToStr(FBase.GetStorageItems.GetItem(w.GetLauncherItem)),
          IfThen(w.GetClipItem <> '', IntToStr(FBase.GetStorageItems.GetItem(w.GetClipItem)), Translate('STR_NOT_AVAILABLE'))]);
      end;
    end;
  finally
    Weapons.Free;
  end;
  FLstWeapons.OnMouseClick := LstWeaponsClick;
end;

destructor TCraftWeaponsState.Destroy;
begin
  FWeapons.Free;
  inherited;
end;

procedure TCraftWeaponsState.BtnCancelClick(Sender: TObject; Action: TAction);
begin
  FGame.PopState;
end;

procedure TCraftWeaponsState.LstWeaponsClick(Sender: TObject; Action: TAction);
var
  current: TCraftWeapon;
  sel: TRuleCraftWeapon;
begin
  current := FBase.GetCrafts[FCraft].GetWeapons[FWeapon];
  if current <> nil then
  begin
    FBase.GetStorageItems.AddItem(current.GetRules.GetLauncherItem);
    FBase.GetStorageItems.AddItem(current.GetRules.GetClipItem, current.GetClipsLoaded(FGame.GetMod));
    current.Free;
    FBase.GetCrafts[FCraft].GetWeapons[FWeapon] := nil;
  end;

  sel := FWeapons[FLstWeapons.GetSelectedRow];
  if sel <> nil then
  begin
    current := TCraftWeapon.Create(sel, 0);
    current.SetRearming(True);
    FBase.GetStorageItems.RemoveItem(sel.GetLauncherItem);
    FBase.GetCrafts[FCraft].GetWeapons[FWeapon] := current;
    if FBase.GetCrafts[FCraft].GetStatus = 'STR_READY' then
      FBase.GetCrafts[FCraft].SetStatus('STR_REARMING');
  end;
  FGame.PopState;
end;

end.