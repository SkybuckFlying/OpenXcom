unit PlaceFacilityState;

interface

uses
  Classes, SysUtils,
  Engine.State, Engine.Game, Engine.Action,
  Mod.Mod, Engine.LocalizedText,
  Interface.TextButton, Interface.Window, Interface.Text,
  BaseView, Savegame.Base, Savegame.BaseFacility,
  Mod.RuleBaseFacility, Savegame.SavedGame,
  Menu.ErrorMessageState, Engine.Options, Engine.Unicode,
  Mod.RuleInterface;

type
  TPlaceFacilityState = class(TState)
  protected
    FBase: TBase;
    FRule: TRuleBaseFacility;
    FView: TBaseView;
    FBtnCancel: TTextButton;
    FWindow: TWindow;
    FTxtFacility, FTxtCost, FNumCost, FTxtTime, FNumTime, FTxtMaintenance, FNumMaintenance: TText;
  public
    constructor Create(AOwner: TComponent; Base: TBase; Rule: TRuleBaseFacility);
    destructor Destroy; override;
    procedure BtnCancelClick(Sender: TObject; Action: TAction); virtual;
    procedure ViewClick(Sender: TObject; Action: TAction); virtual;
  end;

implementation

constructor TPlaceFacilityState.Create(AOwner: TComponent; Base: TBase; Rule: TRuleBaseFacility);
begin
  inherited Create(AOwner);
  FBase := Base;
  FRule := Rule;
  Screen := False;

  FWindow := TWindow.Create(Self, 128, 160, 192, 40);
  FView := TBaseView.Create(192, 192, 0, 8);
  FBtnCancel := TTextButton.Create(112, 16, 200, 176);
  FTxtFacility := TText.Create(110, 9, 202, 50);
  FTxtCost := TText.Create(110, 9, 202, 62);
  FNumCost := TText.Create(110, 17, 202, 70);
  FTxtTime := TText.Create(110, 9, 202, 90);
  FNumTime := TText.Create(110, 17, 202, 98);
  FTxtMaintenance := TText.Create(110, 9, 202, 118);
  FNumMaintenance := TText.Create(110, 17, 202, 126);

  SetInterface('placeFacility');
  Add(FWindow, 'window', 'placeFacility');
  Add(FView, 'baseView', 'basescape');
  Add(FBtnCancel, 'button', 'placeFacility');
  Add(FTxtFacility, 'text', 'placeFacility');
  Add(FTxtCost, 'text', 'placeFacility');
  Add(FNumCost, 'numbers', 'placeFacility');
  Add(FTxtTime, 'text', 'placeFacility');
  Add(FNumTime, 'numbers', 'placeFacility');
  Add(FTxtMaintenance, 'text', 'placeFacility');
  Add(FNumMaintenance, 'numbers', 'placeFacility');
  CenterAllSurfaces;

  FWindow.SetBackground(FGame.GetMod.GetSurface('BACK01.SCR'));
  FView.SetTexture(FGame.GetMod.GetSurfaceSet('BASEBITS.PCK'));
  FView.SetBase(FBase);
  FView.SetSelectable(FRule.GetSize);
  FView.OnMouseClick := ViewClick;
  FBtnCancel.SetText(Translate('STR_CANCEL'));
  FBtnCancel.OnMouseClick := BtnCancelClick;
  FBtnCancel.OnKeyboardPress := BtnCancelClick;
  FTxtFacility.SetText(Translate(FRule.GetType));
  FTxtCost.SetText(Translate('STR_COST_UC'));
  FNumCost.SetBig;
  FNumCost.SetText(Unicode.FormatFunding(FRule.GetBuildCost));
  FTxtTime.SetText(Translate('STR_CONSTRUCTION_TIME_UC'));
  FNumTime.SetBig;
  FNumTime.SetText(Translate('STR_DAY', FRule.GetBuildTime));
  FTxtMaintenance.SetText(Translate('STR_MAINTENANCE_UC'));
  FNumMaintenance.SetBig;
  FNumMaintenance.SetText(Unicode.FormatFunding(FRule.GetMonthlyCost));
end;

destructor TPlaceFacilityState.Destroy;
begin
  inherited;
end;

procedure TPlaceFacilityState.BtnCancelClick(Sender: TObject; Action: TAction);
begin
  FGame.PopState;
end;

procedure TPlaceFacilityState.ViewClick(Sender: TObject; Action: TAction);
var
  Fac: TBaseFacility;
begin
  if not FView.IsPlaceable(FRule) then
    FGame.PushState(TErrorMessageState.Create(Self, Translate('STR_CANNOT_BUILD_HERE'), FPalette,
      FGame.GetMod.GetInterface('placeFacility').GetElement('errorMessage').Color, 'BACK01.SCR',
      FGame.GetMod.GetInterface('placeFacility').GetElement('errorPalette').Color))
  else if FGame.GetSavedGame.GetFunds < FRule.GetBuildCost then
  begin
    FGame.PopState;
    FGame.PushState(TErrorMessageState.Create(Self, Translate('STR_NOT_ENOUGH_MONEY'), FPalette,
      FGame.GetMod.GetInterface('placeFacility').GetElement('errorMessage').Color, 'BACK01.SCR',
      FGame.GetMod.GetInterface('placeFacility').GetElement('errorPalette').Color));
  end
  else
  begin
    Fac := TBaseFacility.Create(FRule, FBase);
    Fac.SetX(FView.GetGridX);
    Fac.SetY(FView.GetGridY);
    Fac.SetBuildTime(FRule.GetBuildTime);
    FBase.GetFacilities.Add(Fac);
    if Options.AllowBuildingQueue then
    begin
      if FView.IsQueuedBuilding(FRule) then Fac.SetBuildTime(MaxInt);
      FView.ReCalcQueuedBuildings;
    end;
    FGame.GetSavedGame.SetFunds(FGame.GetSavedGame.GetFunds - FRule.GetBuildCost);
    FGame.PopState;
  end;
end;

end.