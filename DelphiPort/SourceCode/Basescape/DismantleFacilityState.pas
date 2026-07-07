unit DismantleFacilityState;

interface

uses
  Classes, SysUtils,
  Engine.State, Engine.Game, Engine.Action,
  Mod.Mod, Engine.LocalizedText, Engine.Options,
  Interface.TextButton, Interface.Window, Interface.Text,
  Savegame.Base, Savegame.BaseFacility, BaseView,
  Mod.RuleBaseFacility, Savegame.SavedGame;

type
  TDismantleFacilityState = class(TState)
  private
    FBase: TBase;
    FView: TBaseView;
    FFac: TBaseFacility;

    FBtnOk, FBtnCancel: TTextButton;
    FWindow: TWindow;
    FTxtTitle, FTxtFacility: TText;
  public
    constructor Create(AOwner: TComponent; Base: TBase; View: TBaseView; Fac: TBaseFacility);
    destructor Destroy; override;
    procedure BtnOkClick(Sender: TObject; Action: TAction);
    procedure BtnCancelClick(Sender: TObject; Action: TAction);
  end;

implementation

constructor TDismantleFacilityState.Create(AOwner: TComponent; Base: TBase; View: TBaseView; Fac: TBaseFacility);
begin
  inherited Create(AOwner);
  FBase := Base;
  FView := View;
  FFac := Fac;
  Screen := False;

  FWindow := TWindow.Create(Self, 152, 80, 20, 60);
  FBtnOk := TTextButton.Create(44, 16, 36, 115);
  FBtnCancel := TTextButton.Create(44, 16, 112, 115);
  FTxtTitle := TText.Create(142, 9, 25, 75);
  FTxtFacility := TText.Create(142, 9, 25, 85);

  SetInterface('dismantleFacility');
  Add(FWindow, 'window', 'dismantleFacility');
  Add(FBtnOk, 'button', 'dismantleFacility');
  Add(FBtnCancel, 'button', 'dismantleFacility');
  Add(FTxtTitle, 'text', 'dismantleFacility');
  Add(FTxtFacility, 'text', 'dismantleFacility');
  CenterAllSurfaces;

  FWindow.SetBackground(FGame.GetMod.GetSurface('BACK13.SCR'));
  FBtnOk.SetText(Translate('STR_OK'));
  FBtnOk.OnMouseClick := BtnOkClick;
  FBtnOk.OnKeyboardPress := BtnOkClick;
  FBtnCancel.SetText(Translate('STR_CANCEL_UC'));
  FBtnCancel.OnMouseClick := BtnCancelClick;
  FBtnCancel.OnKeyboardPress := BtnCancelClick;
  FTxtTitle.SetAlign(ALIGN_CENTER);
  FTxtTitle.SetText(Translate('STR_DISMANTLE'));
  FTxtFacility.SetAlign(ALIGN_CENTER);
  FTxtFacility.SetText(Translate(FFac.GetRules.GetType));
end;

destructor TDismantleFacilityState.Destroy;
begin
  inherited;
end;

procedure TDismantleFacilityState.BtnOkClick(Sender: TObject; Action: TAction);
var
  i: Integer;
begin
  if not FFac.GetRules.IsLift then
  begin
    if FFac.GetBuildTime > FFac.GetRules.GetBuildTime then
      FGame.GetSavedGame.SetFunds(FGame.GetSavedGame.GetFunds + FFac.GetRules.GetBuildCost);

    for i := 0 to FBase.GetFacilities.Count - 1 do
      if FBase.GetFacilities[i] = FFac then
      begin
        FBase.GetFacilities.Delete(i);
        FView.ResetSelectedFacility;
        FFac.Free;
        if Options.AllowBuildingQueue then FView.ReCalcQueuedBuildings;
        Break;
      end;
  end
  else
  begin
    for i := 0 to FGame.GetSavedGame.GetBases.Count - 1 do
      if FGame.GetSavedGame.GetBases[i] = FBase then
      begin
        FGame.GetSavedGame.GetBases.Delete(i);
        FBase.Free;
        Break;
      end;
  end;
  FGame.PopState;
end;

procedure TDismantleFacilityState.BtnCancelClick(Sender: TObject; Action: TAction);
begin
  FGame.PopState;
end;

end.