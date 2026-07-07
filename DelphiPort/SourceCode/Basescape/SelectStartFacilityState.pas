unit SelectStartFacilityState;

interface

uses
  Classes, SysUtils, Generics.Collections,
  Engine.Game, Engine.Action,
  Engine.LocalizedText, Engine.Options,
  Interface.TextButton, Interface.TextList,
  Mod.Mod, Mod.RuleBaseFacility,
  Savegame.Base, Savegame.BaseFacility,
  BuildFacilitiesState, PlaceStartFacilityState,
  PlaceLiftState, Globe;

type
  TSelectStartFacilityState = class(TBuildFacilitiesState)
  private
    FGlobe: TGlobe;
  public
    constructor Create(AOwner: TComponent; Base: TBase; State: TState; Globe: TGlobe);
    destructor Destroy; override;
    procedure PopulateBuildList; override;
    procedure BtnOkClick(Sender: TObject; Action: TAction); override;
    procedure LstFacilitiesClick(Sender: TObject; Action: TAction); override;
    procedure FacilityBuilt;
  end;

implementation

constructor TSelectStartFacilityState.Create(AOwner: TComponent; Base: TBase; State: TState; Globe: TGlobe);
begin
  inherited Create(AOwner, Base, State);
  FGlobe := Globe;
  FFacilities := FGame.GetMod.GetCustomBaseFacilities; // assumed to return TList<TRuleBaseFacility>
  FBtnOk.SetText(Translate('STR_RESET'));
  FBtnOk.OnMouseClick := BtnOkClick;
  FBtnOk.OnKeyboardPress := nil;
  FLstFacilities.OnMouseClick := LstFacilitiesClick;
  PopulateBuildList;
end;

destructor TSelectStartFacilityState.Destroy;
begin
  inherited;
end;

procedure TSelectStartFacilityState.PopulateBuildList;
var
  Rule: TRuleBaseFacility;
begin
  FLstFacilities.ClearList;
  for Rule in FFacilities do
    FLstFacilities.AddRow([Translate(Rule.GetType)]);
end;

procedure TSelectStartFacilityState.BtnOkClick(Sender: TObject; Action: TAction);
var
  Fac: TBaseFacility;
begin
  for Fac in FBase.GetFacilities do
    Fac.Free;
  FBase.GetFacilities.Clear;
  FGame.PopState;
  FGame.PopState;
  FGame.PushState(TPlaceLiftState.Create(Self, FBase, FGlobe, True));
end;

procedure TSelectStartFacilityState.LstFacilitiesClick(Sender: TObject; Action: TAction);
begin
  FGame.PushState(TPlaceStartFacilityState.Create(Self, FBase, Self, FFacilities[FLstFacilities.GetSelectedRow]));
end;

procedure TSelectStartFacilityState.FacilityBuilt;
begin
  FFacilities.Delete(FLstFacilities.GetSelectedRow);
  if FFacilities.Count = 0 then
  begin
    FGame.PopState;
    FGame.PopState;
  end
  else
    PopulateBuildList;
end;

end.