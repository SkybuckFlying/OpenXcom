unit PlaceStartFacilityState;

interface

uses
  Classes, SysUtils,
  Engine.Game, Engine.Action,
  Engine.LocalizedText,
  Interface.Text,
  BaseView, Savegame.Base, Savegame.BaseFacility,
  Mod.RuleBaseFacility, Menu.ErrorMessageState,
  SelectStartFacilityState, Mod.Mod, Mod.RuleInterface;

type
  TPlaceStartFacilityState = class(TPlaceFacilityState)
  private
    FSelect: TSelectStartFacilityState;
  public
    constructor Create(AOwner: TComponent; Base: TBase; Select: TSelectStartFacilityState; Rule: TRuleBaseFacility);
    destructor Destroy; override;
    procedure ViewClick(Sender: TObject; Action: TAction); override;
  end;

implementation

constructor TPlaceStartFacilityState.Create(AOwner: TComponent; Base: TBase; Select: TSelectStartFacilityState; Rule: TRuleBaseFacility);
begin
  inherited Create(AOwner, Base, Rule);
  FSelect := Select;
  FView.OnMouseClick := ViewClick;
  FNumCost.SetText(Translate('STR_NONE'));
  FNumTime.SetText(Translate('STR_NONE'));
end;

destructor TPlaceStartFacilityState.Destroy;
begin
  inherited;
end;

procedure TPlaceStartFacilityState.ViewClick(Sender: TObject; Action: TAction);
var
  Fac: TBaseFacility;
begin
  if not FView.IsPlaceable(FRule) then
  begin
    FGame.PopState;
    FGame.PushState(TErrorMessageState.Create(Self, Translate('STR_CANNOT_BUILD_HERE'), FPalette,
      FGame.GetMod.GetInterface('basescape').GetElement('errorMessage').Color, 'BACK01.SCR',
      FGame.GetMod.GetInterface('basescape').GetElement('errorPalette').Color));
  end
  else
  begin
    Fac := TBaseFacility.Create(FRule, FBase);
    Fac.SetX(FView.GetGridX);
    Fac.SetY(FView.GetGridY);
    FBase.GetFacilities.Add(Fac);
    FGame.PopState;
    FSelect.FacilityBuilt;
  end;
end;

end.