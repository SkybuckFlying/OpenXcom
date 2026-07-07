unit CraftsState;

interface

uses
  Classes, SysUtils,
  Engine.State, Engine.Game, Engine.Action,
  Mod.Mod, Engine.LocalizedText, Engine.Options,
  Interface.TextButton, Interface.Window, Interface.Text, Interface.TextList,
  Savegame.Craft, Mod.RuleCraft, Savegame.Base,
  Menu.ErrorMessageState, CraftInfoState, SellState,
  Savegame.SavedGame, Mod.RuleInterface;

type
  TCraftsState = class(TState)
  private
    FBase: TBase;
    FBtnOk: TTextButton;
    FWindow: TWindow;
    FTxtTitle, FTxtBase, FTxtName, FTxtStatus, FTxtWeapon, FTxtCrew, FTxtHwp: TText;
    FLstCrafts: TTextList;
  public
    constructor Create(AOwner: TComponent; Base: TBase);
    destructor Destroy; override;
    procedure Init; override;
    procedure BtnOkClick(Sender: TObject; Action: TAction);
    procedure LstCraftsClick(Sender: TObject; Action: TAction);
  end;

implementation

constructor TCraftsState.Create(AOwner: TComponent; Base: TBase);
begin
  inherited Create(AOwner);
  FBase := Base;

  FWindow := TWindow.Create(Self, 320, 200, 0, 0);
  FBtnOk := TTextButton.Create(288, 16, 16, 176);
  FTxtTitle := TText.Create(298, 17, 16, 8);
  FTxtBase := TText.Create(298, 17, 16, 24);
  FTxtName := TText.Create(94, 9, 16, 40);
  FTxtStatus := TText.Create(50, 9, 110, 40);
  FTxtWeapon := TText.Create(50, 17, 160, 40);
  FTxtCrew := TText.Create(58, 9, 210, 40);
  FTxtHwp := TText.Create(46, 9, 268, 40);
  FLstCrafts := TTextList.Create(288, 118, 8, 58);

  SetInterface('craftSelect');
  Add(FWindow, 'window', 'craftSelect');
  Add(FBtnOk, 'button', 'craftSelect');
  Add(FTxtTitle, 'text', 'craftSelect');
  Add(FTxtBase, 'text', 'craftSelect');
  Add(FTxtName, 'text', 'craftSelect');
  Add(FTxtStatus, 'text', 'craftSelect');
  Add(FTxtWeapon, 'text', 'craftSelect');
  Add(FTxtCrew, 'text', 'craftSelect');
  Add(FTxtHwp, 'text', 'craftSelect');
  Add(FLstCrafts, 'list', 'craftSelect');
  CenterAllSurfaces;

  FWindow.SetBackground(FGame.GetMod.GetSurface('BACK14.SCR'));
  FBtnOk.SetText(Translate('STR_OK'));
  FBtnOk.OnMouseClick := BtnOkClick;
  FBtnOk.OnKeyboardPress := BtnOkClick;
  FTxtTitle.SetBig;
  FTxtTitle.SetText(Translate('STR_INTERCEPTION_CRAFT'));
  FTxtBase.SetBig;
  FTxtBase.SetText(Translate('STR_BASE_').Arg(FBase.GetName));
  FTxtName.SetText(Translate('STR_NAME_UC'));
  FTxtStatus.SetText(Translate('STR_STATUS'));
  FTxtWeapon.SetText(Translate('STR_WEAPON_SYSTEMS'));
  FTxtWeapon.SetWordWrap(True);
  FTxtCrew.SetText(Translate('STR_CREW'));
  FTxtHwp.SetText(Translate('STR_HWPS'));
  FLstCrafts.SetColumns([94, 68, 44, 46, 28]);
  FLstCrafts.SetSelectable(True);
  FLstCrafts.SetBackground(FWindow);
  FLstCrafts.SetMargin(8);
  FLstCrafts.OnMouseClick := LstCraftsClick;
end;

destructor TCraftsState.Destroy;
begin
  inherited;
end;

procedure TCraftsState.Init;
var
  craft: TCraft;
begin
  inherited;
  FLstCrafts.ClearList;
  for craft in FBase.GetCrafts do
    FLstCrafts.AddRow([
      craft.GetName(FGame.GetLanguage),
      Translate(craft.GetStatus),
      IntToStr(craft.GetNumWeapons) + '/' + IntToStr(craft.GetRules.GetWeapons),
      IntToStr(craft.GetNumSoldiers),
      IntToStr(craft.GetNumVehicles)
    ]);
end;

procedure TCraftsState.BtnOkClick(Sender: TObject; Action: TAction);
begin
  FGame.PopState;
  if (FGame.GetSavedGame.GetMonthsPassed > -1) and Options.StorageLimitsEnforced and FBase.StoresOverfull then
  begin
    FGame.PushState(TSellState.Create(Self, FBase));
    FGame.PushState(TErrorMessageState.Create(Self,
      Translate('STR_STORAGE_EXCEEDED').Arg(FBase.GetName),
      FPalette,
      FGame.GetMod.GetInterface('craftSelect').GetElement('errorMessage').Color,
      'BACK01.SCR',
      FGame.GetMod.GetInterface('craftSelect').GetElement('errorPalette').Color));
  end;
end;

procedure TCraftsState.LstCraftsClick(Sender: TObject; Action: TAction);
begin
  if FBase.GetCrafts[FLstCrafts.GetSelectedRow].GetStatus <> 'STR_OUT' then
    FGame.PushState(TCraftInfoState.Create(Self, FBase, FLstCrafts.GetSelectedRow));
end;

end.