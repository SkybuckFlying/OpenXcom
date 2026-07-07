unit CraftInfoState;

interface

uses
  Classes, SysUtils, Math,
  Engine.State, Engine.Game, Engine.Action,
  Mod.Mod, Engine.LocalizedText, Engine.Options, Engine.Unicode,
  Interface.TextButton, Interface.Window, Interface.Text, Interface.TextEdit,
  Engine.SurfaceSet, Savegame.Craft, Mod.RuleCraft,
  Savegame.CraftWeapon, Mod.RuleCraftWeapon,
  Savegame.Base, Savegame.SavedGame,
  CraftSoldiersState, CraftWeaponsState, CraftEquipmentState, CraftArmorState;

type
  TCraftInfoState = class(TState)
  private
    FBase: TBase;
    FCraftId: Integer;
    FCraft: TCraft;

    FBtnOk, FBtnW1, FBtnW2, FBtnCrew, FBtnEquip, FBtnArmor: TTextButton;
    FWindow: TWindow;
    FEdtCraft: TTextEdit;
    FTxtDamage, FTxtFuel: TText;
    FTxtW1Name, FTxtW1Ammo, FTxtW2Name, FTxtW2Ammo: TText;
    FSprite, FWeapon1, FWeapon2, FCrew, FEquip: TSurface;

    function FormatTime(Total: Integer): string;
  public
    constructor Create(AOwner: TComponent; Base: TBase; CraftId: Integer);
    destructor Destroy; override;
    procedure Init; override;
    procedure BtnOkClick(Sender: TObject; Action: TAction);
    procedure BtnW1Click(Sender: TObject; Action: TAction);
    procedure BtnW2Click(Sender: TObject; Action: TAction);
    procedure BtnCrewClick(Sender: TObject; Action: TAction);
    procedure BtnEquipClick(Sender: TObject; Action: TAction);
    procedure BtnArmorClick(Sender: TObject; Action: TAction);
    procedure EdtCraftChange(Sender: TObject; Action: TAction);
  end;

implementation

constructor TCraftInfoState.Create(AOwner: TComponent; Base: TBase; CraftId: Integer);
begin
  inherited Create(AOwner);
  FBase := Base;
  FCraftId := CraftId;

  if FGame.GetSavedGame.GetMonthsPassed <> -1 then
    FWindow := TWindow.Create(Self, 320, 200, 0, 0, POPUP_BOTH)
  else
    FWindow := TWindow.Create(Self, 320, 200, 0, 0, POPUP_NONE);
  FBtnOk := TTextButton.Create(64, 24, 128, 168);
  FBtnW1 := TTextButton.Create(24, 32, 14, 48);
  FBtnW2 := TTextButton.Create(24, 32, 282, 48);
  FBtnCrew := TTextButton.Create(64, 16, 14, 96);
  FBtnEquip := TTextButton.Create(64, 16, 14, 120);
  FBtnArmor := TTextButton.Create(64, 16, 14, 144);
  FEdtCraft := TTextEdit.Create(Self, 140, 16, 80, 8);
  FTxtDamage := TText.Create(100, 17, 14, 24);
  FTxtFuel := TText.Create(82, 17, 228, 24);
  FTxtW1Name := TText.Create(95, 16, 46, 48);
  FTxtW1Ammo := TText.Create(75, 24, 46, 64);
  FTxtW2Name := TText.Create(95, 16, 184, 48);
  FTxtW2Ammo := TText.Create(75, 24, 204, 64);
  FSprite := TSurface.Create(32, 40, 144, 52);
  FWeapon1 := TSurface.Create(15, 17, 121, 63);
  FWeapon2 := TSurface.Create(15, 17, 184, 63);
  FCrew := TSurface.Create(220, 18, 85, 96);
  FEquip := TSurface.Create(220, 18, 85, 121);

  SetInterface('craftInfo');
  Add(FWindow, 'window', 'craftInfo');
  Add(FBtnOk, 'button', 'craftInfo');
  Add(FBtnW1, 'button', 'craftInfo');
  Add(FBtnW2, 'button', 'craftInfo');
  Add(FBtnCrew, 'button', 'craftInfo');
  Add(FBtnEquip, 'button', 'craftInfo');
  Add(FBtnArmor, 'button', 'craftInfo');
  Add(FEdtCraft, 'text1', 'craftInfo');
  Add(FTxtDamage, 'text1', 'craftInfo');
  Add(FTxtFuel, 'text1', 'craftInfo');
  Add(FTxtW1Name, 'text2', 'craftInfo');
  Add(FTxtW1Ammo, 'text3', 'craftInfo');
  Add(FTxtW2Name, 'text2', 'craftInfo');
  Add(FTxtW2Ammo, 'text3', 'craftInfo');
  Add(FSprite);
  Add(FWeapon1);
  Add(FWeapon2);
  Add(FCrew);
  Add(FEquip);
  CenterAllSurfaces;

  FWindow.SetBackground(FGame.GetMod.GetSurface('BACK14.SCR'));
  FBtnOk.SetText(Translate('STR_OK'));
  FBtnOk.OnMouseClick := BtnOkClick;
  FBtnOk.OnKeyboardPress := BtnOkClick;
  FBtnW1.SetText('1');
  FBtnW1.OnMouseClick := BtnW1Click;
  FBtnW2.SetText('2');
  FBtnW2.OnMouseClick := BtnW2Click;
  FBtnCrew.SetText(Translate('STR_CREW'));
  FBtnCrew.OnMouseClick := BtnCrewClick;
  FBtnEquip.SetText(Translate('STR_EQUIPMENT_UC'));
  FBtnEquip.OnMouseClick := BtnEquipClick;
  FBtnArmor.SetText(Translate('STR_ARMOR'));
  FBtnArmor.OnMouseClick := BtnArmorClick;
  FEdtCraft.SetBig;
  FEdtCraft.SetAlign(ALIGN_CENTER);
  FEdtCraft.OnChange := EdtCraftChange;
  FTxtW1Name.SetWordWrap(True);
  FTxtW2Name.SetWordWrap(True);
end;

destructor TCraftInfoState.Destroy;
begin
  inherited;
end;

procedure TCraftInfoState.Init;
var
  Texture: TSurfaceSet;
  Frame: TSurface;
  w1, w2: TCraftWeapon;
  i, x: Integer;
  ss: TStringStream;
begin
  inherited;
  FCraft := FBase.GetCrafts[FCraftId];

  FEdtCraft.SetText(FCraft.GetName(FGame.GetLanguage));
  FSprite.Clear;
  Texture := FGame.GetMod.GetSurfaceSet('BASEBITS.PCK');
  Texture.GetFrame(FCraft.GetRules.GetSprite + 33).SetX(0);
  Texture.GetFrame(FCraft.GetRules.GetSprite + 33).SetY(0);
  Texture.GetFrame(FCraft.GetRules.GetSprite + 33).Blit(FSprite);

  FTxtDamage.SetText(Translate('STR_DAMAGE_UC_').Arg(Unicode.FormatPercentage(FCraft.GetDamagePercentage)) +
    IfThen(FCraft.GetStatus = 'STR_REPAIRS' and (FCraft.GetDamage > 0),
    FormatTime(Ceil(FCraft.GetDamage / FCraft.GetRules.GetRepairRate)), ''));
  FTxtFuel.SetText(Translate('STR_FUEL').Arg(Unicode.FormatPercentage(FCraft.GetFuelPercentage)) +
    IfThen(FCraft.GetStatus = 'STR_REFUELLING' and (FCraft.GetRules.GetMaxFuel - FCraft.GetFuel > 0),
    FormatTime(Ceil((FCraft.GetRules.GetMaxFuel - FCraft.GetFuel) / FCraft.GetRules.GetRefuelRate / 2.0)), ''));

  if FCraft.GetRules.GetSoldiers > 0 then
  begin
    FCrew.Clear;
    FEquip.Clear;
    Frame := Texture.GetFrame(38);
    Frame.SetY(0);
    for i := 0 to FCraft.GetNumSoldiers - 1 do
    begin
      Frame.SetX(i * 10);
      Frame.Blit(FCrew);
    end;
    Frame := Texture.GetFrame(40);
    Frame.SetY(0);
    x := 0;
    for i := 0 to FCraft.GetNumVehicles - 1 do
    begin
      Frame.SetX(x);
      Frame.Blit(FEquip);
      Inc(x, 10);
    end;
    Frame := Texture.GetFrame(39);
    for i := 0 to FCraft.GetNumEquipment - 1 do
    begin
      if (i mod 4) = 0 then
      begin
        Frame.SetX(x);
        Frame.Blit(FEquip);
        Inc(x, 10);
      end;
    end;
  end
  else
  begin
    FCrew.Visible := False;
    FEquip.Visible := False;
    FBtnCrew.Visible := False;
    FBtnEquip.Visible := False;
    FBtnArmor.Visible := False;
  end;

  if FCraft.GetRules.GetWeapons > 0 then
  begin
    w1 := FCraft.GetWeapons[0];
    FWeapon1.Clear;
    if w1 <> nil then
    begin
      Frame := Texture.GetFrame(w1.GetRules.GetSprite + 48);
      Frame.SetX(0);
      Frame.SetY(0);
      Frame.Blit(FWeapon1);
      FTxtW1Name.SetText(Unicode.TOK_COLOR_FLIP + Translate(w1.GetRules.GetType));
      FTxtW1Ammo.SetText(Translate('STR_AMMO_').Arg(w1.GetAmmo) + #10 + Unicode.TOK_COLOR_FLIP +
        Translate('STR_MAX').Arg(w1.GetRules.GetAmmoMax) +
        IfThen(FCraft.GetStatus = 'STR_REARMING' and (w1.GetAmmo < w1.GetRules.GetAmmoMax),
        FormatTime(Ceil((w1.GetRules.GetAmmoMax - w1.GetAmmo) / w1.GetRules.GetRearmRate)), ''));
    end
    else
    begin
      FTxtW1Name.SetText('');
      FTxtW1Ammo.SetText('');
    end;
  end
  else
  begin
    FWeapon1.Visible := False;
    FBtnW1.Visible := False;
    FTxtW1Name.Visible := False;
    FTxtW1Ammo.Visible := False;
  end;

  if FCraft.GetRules.GetWeapons > 1 then
  begin
    w2 := FCraft.GetWeapons[1];
    FWeapon2.Clear;
    if w2 <> nil then
    begin
      Frame := Texture.GetFrame(w2.GetRules.GetSprite + 48);
      Frame.SetX(0);
      Frame.SetY(0);
      Frame.Blit(FWeapon2);
      FTxtW2Name.SetText(Unicode.TOK_COLOR_FLIP + Translate(w2.GetRules.GetType));
      FTxtW2Ammo.SetText(Translate('STR_AMMO_').Arg(w2.GetAmmo) + #10 + Unicode.TOK_COLOR_FLIP +
        Translate('STR_MAX').Arg(w2.GetRules.GetAmmoMax) +
        IfThen(FCraft.GetStatus = 'STR_REARMING' and (w2.GetAmmo < w2.GetRules.GetAmmoMax),
        FormatTime(Ceil((w2.GetRules.GetAmmoMax - w2.GetAmmo) / w2.GetRules.GetRearmRate)), ''));
    end
    else
    begin
      FTxtW2Name.SetText('');
      FTxtW2Ammo.SetText('');
    end;
  end
  else
  begin
    FWeapon2.Visible := False;
    FBtnW2.Visible := False;
    FTxtW2Name.Visible := False;
    FTxtW2Ammo.Visible := False;
  end;
end;

function TCraftInfoState.FormatTime(Total: Integer): string;
var
  days, hours: Integer;
begin
  days := Total div 24;
  hours := Total mod 24;
  Result := #10'(';
  if days > 0 then
    Result := Result + Translate('STR_DAY', days) + '/';
  if hours > 0 then
    Result := Result + Translate('STR_HOUR', hours);
  Result := Result + ')';
end;

procedure TCraftInfoState.BtnOkClick(Sender: TObject; Action: TAction);
begin
  FGame.PopState;
end;

procedure TCraftInfoState.BtnW1Click(Sender: TObject; Action: TAction);
begin
  FGame.PushState(TCraftWeaponsState.Create(Self, FBase, FCraftId, 0));
end;

procedure TCraftInfoState.BtnW2Click(Sender: TObject; Action: TAction);
begin
  FGame.PushState(TCraftWeaponsState.Create(Self, FBase, FCraftId, 1));
end;

procedure TCraftInfoState.BtnCrewClick(Sender: TObject; Action: TAction);
begin
  FGame.PushState(TCraftSoldiersState.Create(Self, FBase, FCraftId));
end;

procedure TCraftInfoState.BtnEquipClick(Sender: TObject; Action: TAction);
begin
  FGame.PushState(TCraftEquipmentState.Create(Self, FBase, FCraftId));
end;

procedure TCraftInfoState.BtnArmorClick(Sender: TObject; Action: TAction);
begin
  FGame.PushState(TCraftArmorState.Create(Self, FBase, FCraftId));
end;

procedure TCraftInfoState.EdtCraftChange(Sender: TObject; Action: TAction);
begin
  if FEdtCraft.GetText = FCraft.GetDefaultName(FGame.GetLanguage) then
    FCraft.SetName('')
  else
    FCraft.SetName(FEdtCraft.GetText);
  if (Action.GetDetails.key.keysym.sym = SDLK_RETURN) or
     (Action.GetDetails.key.keysym.sym = SDLK_KP_ENTER) then
    FEdtCraft.SetText(FCraft.GetName(FGame.GetLanguage));
end;

end.