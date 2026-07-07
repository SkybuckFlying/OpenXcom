unit PlaceLiftState;

interface

uses
  Classes, SysUtils,
  Engine.State, Engine.Game, Engine.Action,
  Mod.Mod, Engine.LocalizedText,
  Interface.Text,
  BaseView, Savegame.Base, Savegame.BaseFacility,
  Mod.RuleBaseFacility, BasescapeState,
  SelectStartFacilityState, Savegame.SavedGame,
  Globe;

type
  TPlaceLiftState = class(TState)
  private
    FBase: TBase;
    FGlobe: TGlobe;
    FView: TBaseView;
    FTxtTitle: TText;
    FFirst: Boolean;
    FLift: TRuleBaseFacility;
  public
    constructor Create(AOwner: TComponent; Base: TBase; Globe: TGlobe; First: Boolean);
    destructor Destroy; override;
    procedure ViewClick(Sender: TObject; Action: TAction);
  end;

implementation

constructor TPlaceLiftState.Create(AOwner: TComponent; Base: TBase; Globe: TGlobe; First: Boolean);
var
  i: Integer;
begin
  inherited Create(AOwner);
  FBase := Base;
  FGlobe := Globe;
  FFirst := First;

  FView := TBaseView.Create(192, 192, 0, 8);
  FTxtTitle := TText.Create(320, 9, 0, 0);

  SetInterface('placeFacility');
  Add(FView, 'baseView', 'basescape');
  Add(FTxtTitle, 'text', 'placeFacility');
  CenterAllSurfaces;

  FView.SetTexture(FGame.GetMod.GetSurfaceSet('BASEBITS.PCK'));
  FView.SetBase(FBase);
  for i := 0 to FGame.GetMod.GetBaseFacilitiesList.Count - 1 do
  begin
    if FGame.GetMod.GetBaseFacility(FGame.GetMod.GetBaseFacilitiesList[i]).IsLift then
    begin
      FLift := FGame.GetMod.GetBaseFacility(FGame.GetMod.GetBaseFacilitiesList[i]);
      Break;
    end;
  end;
  FView.SetSelectable(FLift.GetSize);
  FView.OnMouseClick := ViewClick;
  FTxtTitle.SetText(Translate('STR_SELECT_POSITION_FOR_ACCESS_LIFT'));
end;

destructor TPlaceLiftState.Destroy;
begin
  inherited;
end;

procedure TPlaceLiftState.ViewClick(Sender: TObject; Action: TAction);
var
  Fac: TBaseFacility;
  bState: TBasescapeState;
begin
  Fac := TBaseFacility.Create(FLift, FBase);
  Fac.SetX(FView.GetGridX);
  Fac.SetY(FView.GetGridY);
  FBase.GetFacilities.Add(Fac);
  FGame.PopState;
  bState := TBasescapeState.Create(Self, FBase, FGlobe);
  FGame.GetSavedGame.SetSelectedBase(FGame.GetSavedGame.GetBases.Count - 1);
  FGame.PushState(bState);
  if FFirst then
    FGame.PushState(TSelectStartFacilityState.Create(Self, FBase, bState, FGlobe));
end;

end.