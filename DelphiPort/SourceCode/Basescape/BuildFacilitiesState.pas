unit BuildFacilitiesState;

interface

uses
  Classes, SysUtils, Generics.Collections,
  Engine.State, Engine.Game, Engine.Action,
  Mod.Mod, Engine.LocalizedText, Engine.Options,
  Interface.TextButton, Interface.Window, Interface.Text,
  Interface.TextList, Mod.RuleBaseFacility,
  Savegame.SavedGame, Savegame.Base, PlaceFacilityState;

type
  TBuildFacilitiesState = class(TState)
  protected
    FBase: TBase;
    FState: TState;
    FFacilities: TList<TRuleBaseFacility>;

    FBtnOk: TTextButton;
    FWindow: TWindow;
    FTxtTitle: TText;
    FLstFacilities: TTextList;

    procedure PopulateBuildList; virtual;
  public
    constructor Create(AOwner: TComponent; Base: TBase; State: TState);
    destructor Destroy; override;
    procedure Init; override;
    procedure BtnOkClick(Sender: TObject; Action: TAction); virtual;
    procedure LstFacilitiesClick(Sender: TObject; Action: TAction); virtual;
  end;

implementation

constructor TBuildFacilitiesState.Create(AOwner: TComponent; Base: TBase; State: TState);
begin
  inherited Create(AOwner);
  FBase := Base;
  FState := State;
  Screen := False;

  FWindow := TWindow.Create(Self, 128, 160, 192, 40, POPUP_VERTICAL);
  FBtnOk := TTextButton.Create(112, 16, 200, 176);
  FLstFacilities := TTextList.Create(104, 104, 200, 64);
  FTxtTitle := TText.Create(118, 17, 197, 48);

  SetInterface('selectFacility');
  Add(FWindow, 'window', 'selectFacility');
  Add(FBtnOk, 'button', 'selectFacility');
  Add(FTxtTitle, 'text', 'selectFacility');
  Add(FLstFacilities, 'list', 'selectFacility');
  CenterAllSurfaces;

  FWindow.SetBackground(FGame.GetMod.GetSurface('BACK05.SCR'));
  FBtnOk.SetText(Translate('STR_OK'));
  FBtnOk.OnMouseClick := BtnOkClick;
  FBtnOk.OnKeyboardPress := BtnOkClick;
  FTxtTitle.SetBig;
  FTxtTitle.SetAlign(ALIGN_CENTER);
  FTxtTitle.SetText(Translate('STR_INSTALLATION'));
  FLstFacilities.SetColumns([1], [104]);
  FLstFacilities.SetSelectable(True);
  FLstFacilities.SetBackground(FWindow);
  FLstFacilities.SetMargin(2);
  FLstFacilities.SetWordWrap(True);
  FLstFacilities.SetScrolling(True, 0);
  FLstFacilities.OnMouseClick := LstFacilitiesClick;

  PopulateBuildList;
end;

destructor TBuildFacilitiesState.Destroy;
begin
  FFacilities.Free;
  inherited;
end;

procedure TBuildFacilitiesState.PopulateBuildList;
var
  Facilities: TStringList;
  i: Integer;
  Rule: TRuleBaseFacility;
begin
  FFacilities := TList<TRuleBaseFacility>.Create;
  Facilities := FGame.GetMod.GetBaseFacilitiesList;
  try
    for i := 0 to Facilities.Count - 1 do
    begin
      Rule := FGame.GetMod.GetBaseFacility(Facilities[i]);
      if FGame.GetSavedGame.IsResearched(Rule.GetRequirements) and (not Rule.IsLift) then
        FFacilities.Add(Rule);
    end;
  finally
    Facilities.Free;
  end;

  FLstFacilities.ClearList;
  for Rule in FFacilities do
    FLstFacilities.AddRow([Translate(Rule.GetType)]);
end;

procedure TBuildFacilitiesState.Init;
begin
  FState.Init;
  inherited;
end;

procedure TBuildFacilitiesState.BtnOkClick(Sender: TObject; Action: TAction);
begin
  FGame.PopState;
end;

procedure TBuildFacilitiesState.LstFacilitiesClick(Sender: TObject; Action: TAction);
begin
  FGame.PushState(TPlaceFacilityState.Create(Self, FBase, FFacilities[FLstFacilities.GetSelectedRow]));
end;

end.