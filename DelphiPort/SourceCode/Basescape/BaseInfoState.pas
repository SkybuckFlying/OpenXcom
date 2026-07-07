unit BaseInfoState;

interface

uses
  Classes, SysUtils, Generics.Collections,
  Engine.Game, Engine.Action, Engine.State,
  Engine.LocalizedText, Engine.Options,
  Mod.Mod, Interface.Bar, Interface.TextButton,
  Interface.Text, Interface.TextEdit, Engine.Surface,
  MiniBaseView, Savegame.SavedGame, Savegame.Base,
  MonthlyCostsState, TransfersState, StoresState, BasescapeState;

type
  TBaseInfoState = class(TState)
  private
    FBase: TBase;
    FState: TBasescapeState;

    FBg: TSurface;
    FMini: TMiniBaseView;
    FBtnOk: TTextButton;
    FBtnTransfers: TTextButton;
    FBtnStores: TTextButton;
    FBtnMonthlyCosts: TTextButton;
    FEdtBase: TTextEdit;

    FTxtPersonnel, FTxtSoldiers, FTxtEngineers, FTxtScientists: TText;
    FNumSoldiers, FNumEngineers, FNumScientists: TText;
    FBarSoldiers, FBarEngineers, FBarScientists: TBar;

    FTxtSpace, FTxtQuarters, FTxtStores, FTxtLaboratories, FTxtWorkshops, FTxtContainment, FTxtHangars: TText;
    FNumQuarters, FNumStores, FNumLaboratories, FNumWorkshops, FNumContainment, FNumHangars: TText;
    FBarQuarters, FBarStores, FBarLaboratories, FBarWorkshops, FBarContainment, FBarHangars: TBar;

    FTxtDefense, FTxtShortRange, FTxtLongRange: TText;
    FNumDefense, FNumShortRange, FNumLongRange: TText;
    FBarDefense, FBarShortRange, FBarLongRange: TBar;

    procedure UpdateStats;
    procedure EdtBaseChange(Sender: TObject; Action: TAction);
    procedure MiniClick(Sender: TObject; Action: TAction);
    procedure HandleKeyPress(Sender: TObject; Action: TAction);
    procedure BtnOkClick(Sender: TObject; Action: TAction);
    procedure BtnTransfersClick(Sender: TObject; Action: TAction);
    procedure BtnStoresClick(Sender: TObject; Action: TAction);
    procedure BtnMonthlyCostsClick(Sender: TObject; Action: TAction);
  public
    constructor Create(AOwner: TComponent; Base: TBase; State: TBasescapeState);
    destructor Destroy; override;
    procedure Init; override;
  end;

implementation

uses Math, Engine.Mod;

constructor TBaseInfoState.Create(AOwner: TComponent; Base: TBase; State: TBasescapeState);
var
  ss: TStringStream;
  i: Integer;
begin
  inherited Create(AOwner);
  FBase := Base;
  FState := State;

  FBg := TSurface.Create(320, 200, 0, 0);
  FMini := TMiniBaseView.Create(128, 16, 182, 8);
  FBtnOk := TTextButton.Create(30, 14, 10, 180);
  FBtnTransfers := TTextButton.Create(80, 14, 46, 180);
  FBtnStores := TTextButton.Create(80, 14, 132, 180);
  FBtnMonthlyCosts := TTextButton.Create(92, 14, 218, 180);
  FEdtBase := TTextEdit.Create(Self, 127, 16, 8, 8);

  FTxtPersonnel := TText.Create(300, 9, 8, 30);
  FTxtSoldiers := TText.Create(114, 9, 8, 41);
  FNumSoldiers := TText.Create(40, 9, 126, 41);
  FBarSoldiers := TBar.Create(150, 5, 166, 43);
  FTxtEngineers := TText.Create(114, 9, 8, 51);
  FNumEngineers := TText.Create(40, 9, 126, 51);
  FBarEngineers := TBar.Create(150, 5, 166, 53);
  FTxtScientists := TText.Create(114, 9, 8, 61);
  FNumScientists := TText.Create(40, 9, 126, 61);
  FBarScientists := TBar.Create(150, 5, 166, 63);

  FTxtSpace := TText.Create(300, 9, 8, 72);
  FTxtQuarters := TText.Create(114, 9, 8, 83);
  FNumQuarters := TText.Create(40, 9, 126, 83);
  FBarQuarters := TBar.Create(150, 5, 166, 85);
  FTxtStores := TText.Create(114, 9, 8, 93);
  FNumStores := TText.Create(40, 9, 126, 93);
  FBarStores := TBar.Create(150, 5, 166, 95);
  FTxtLaboratories := TText.Create(114, 9, 8, 103);
  FNumLaboratories := TText.Create(40, 9, 126, 103);
  FBarLaboratories := TBar.Create(150, 5, 166, 105);
  FTxtWorkshops := TText.Create(114, 9, 8, 113);
  FNumWorkshops := TText.Create(40, 9, 126, 113);
  FBarWorkshops := TBar.Create(150, 5, 166, 115);
  if Options.StorageLimitsEnforced then
  begin
    FTxtContainment := TText.Create(114, 9, 8, 123);
    FNumContainment := TText.Create(40, 9, 126, 123);
    FBarContainment := TBar.Create(150, 5, 166, 125);
  end;
  FTxtHangars := TText.Create(114, 9, 8, IfThen(Options.StorageLimitsEnforced, 133, 123));
  FNumHangars := TText.Create(40, 9, 126, IfThen(Options.StorageLimitsEnforced, 133, 123));
  FBarHangars := TBar.Create(150, 5, 166, IfThen(Options.StorageLimitsEnforced, 135, 125));

  FTxtDefense := TText.Create(114, 9, 8, IfThen(Options.StorageLimitsEnforced, 147, 138));
  FNumDefense := TText.Create(40, 9, 126, IfThen(Options.StorageLimitsEnforced, 147, 138));
  FBarDefense := TBar.Create(150, 5, 166, IfThen(Options.StorageLimitsEnforced, 149, 140));
  FTxtShortRange := TText.Create(114, 9, 8, IfThen(Options.StorageLimitsEnforced, 157, 153));
  FNumShortRange := TText.Create(40, 9, 126, IfThen(Options.StorageLimitsEnforced, 157, 153));
  FBarShortRange := TBar.Create(150, 5, 166, IfThen(Options.StorageLimitsEnforced, 159, 155));
  FTxtLongRange := TText.Create(114, 9, 8, IfThen(Options.StorageLimitsEnforced, 167, 163));
  FNumLongRange := TText.Create(40, 9, 126, IfThen(Options.StorageLimitsEnforced, 167, 163));
  FBarLongRange := TBar.Create(150, 5, 166, IfThen(Options.StorageLimitsEnforced, 169, 165));

  SetInterface('baseInfo');
  Add(FBg);
  Add(FMini, 'miniBase', 'basescape');
  Add(FBtnOk, 'button', 'baseInfo');
  Add(FBtnTransfers, 'button', 'baseInfo');
  Add(FBtnStores, 'button', 'baseInfo');
  Add(FBtnMonthlyCosts, 'button', 'baseInfo');
  Add(FEdtBase, 'text1', 'baseInfo');
  Add(FTxtPersonnel, 'text1', 'baseInfo');
  Add(FTxtSoldiers, 'text2', 'baseInfo');
  Add(FNumSoldiers, 'numbers', 'baseInfo');
  Add(FBarSoldiers, 'personnelBars', 'baseInfo');
  Add(FTxtEngineers, 'text2', 'baseInfo');
  Add(FNumEngineers, 'numbers', 'baseInfo');
  Add(FBarEngineers, 'personnelBars', 'baseInfo');
  Add(FTxtScientists, 'text2', 'baseInfo');
  Add(FNumScientists, 'numbers', 'baseInfo');
  Add(FBarScientists, 'personnelBars', 'baseInfo');
  Add(FTxtSpace, 'text1', 'baseInfo');
  Add(FTxtQuarters, 'text2', 'baseInfo');
  Add(FNumQuarters, 'numbers', 'baseInfo');
  Add(FBarQuarters, 'facilityBars', 'baseInfo');
  Add(FTxtStores, 'text2', 'baseInfo');
  Add(FNumStores, 'numbers', 'baseInfo');
  Add(FBarStores, 'facilityBars', 'baseInfo');
  Add(FTxtLaboratories, 'text2', 'baseInfo');
  Add(FNumLaboratories, 'numbers', 'baseInfo');
  Add(FBarLaboratories, 'facilityBars', 'baseInfo');
  Add(FTxtWorkshops, 'text2', 'baseInfo');
  Add(FNumWorkshops, 'numbers', 'baseInfo');
  Add(FBarWorkshops, 'facilityBars', 'baseInfo');
  if Options.StorageLimitsEnforced then
  begin
    Add(FTxtContainment, 'text2', 'baseInfo');
    Add(FNumContainment, 'numbers', 'baseInfo');
    Add(FBarContainment, 'facilityBars', 'baseInfo');
  end;
  Add(FTxtHangars, 'text2', 'baseInfo');
  Add(FNumHangars, 'numbers', 'baseInfo');
  Add(FBarHangars, 'facilityBars', 'baseInfo');
  Add(FTxtDefense, 'text2', 'baseInfo');
  Add(FNumDefense, 'numbers', 'baseInfo');
  Add(FBarDefense, 'defenceBar', 'baseInfo');
  Add(FTxtShortRange, 'text2', 'baseInfo');
  Add(FNumShortRange, 'numbers', 'baseInfo');
  Add(FBarShortRange, 'detectionBars', 'baseInfo');
  Add(FTxtLongRange, 'text2', 'baseInfo');
  Add(FNumLongRange, 'numbers', 'baseInfo');
  Add(FBarLongRange, 'detectionBars', 'baseInfo');

  CenterAllSurfaces;

  ss := TStringStream.Create;
  try
    if Options.StorageLimitsEnforced then
      ss.WriteString('ALT');
    ss.WriteString('BACK07.SCR');
    FGame.GetMod.GetSurface(ss.DataString).Blit(FBg);
  finally
    ss.Free;
  end;

  FMini.SetTexture(FGame.GetMod.GetSurfaceSet('BASEBITS.PCK'));
  FMini.SetBases(FGame.GetSavedGame.GetBases);
  for i := 0 to FGame.GetSavedGame.GetBases.Count - 1 do
    if FGame.GetSavedGame.GetBases[i] = FBase then
    begin
      FMini.SetSelectedBase(i);
      Break;
    end;
  FMini.OnMouseClick := MiniClick;
  FMini.OnKeyboardPress := HandleKeyPress;

  FBtnOk.SetText(Translate('STR_OK'));
  FBtnOk.OnMouseClick := BtnOkClick;
  FBtnOk.OnKeyboardPress := BtnOkClick;
  FBtnTransfers.SetText(Translate('STR_TRANSFERS_UC'));
  FBtnTransfers.OnMouseClick := BtnTransfersClick;
  FBtnStores.SetText(Translate('STR_STORES_UC'));
  FBtnStores.OnMouseClick := BtnStoresClick;
  FBtnMonthlyCosts.SetText(Translate('STR_MONTHLY_COSTS'));
  FBtnMonthlyCosts.OnMouseClick := BtnMonthlyCostsClick;

  FEdtBase.SetBig;
  FEdtBase.OnChange := EdtBaseChange;

  FTxtPersonnel.SetText(Translate('STR_PERSONNEL_AVAILABLE_PERSONNEL_TOTAL'));
  FTxtSoldiers.SetText(Translate('STR_SOLDIERS'));
  FBarSoldiers.SetScale(1.0);
  FTxtEngineers.SetText(Translate('STR_ENGINEERS'));
  FBarEngineers.SetScale(1.0);
  FTxtScientists.SetText(Translate('STR_SCIENTISTS'));
  FBarScientists.SetScale(1.0);
  FTxtSpace.SetText(Translate('STR_SPACE_USED_SPACE_AVAILABLE'));
  FTxtQuarters.SetText(Translate('STR_LIVING_QUARTERS_PLURAL'));
  FBarQuarters.SetScale(0.5);
  FTxtStores.SetText(Translate('STR_STORES'));
  FBarStores.SetScale(0.5);
  FTxtLaboratories.SetText(Translate('STR_LABORATORIES'));
  FBarLaboratories.SetScale(0.5);
  FTxtWorkshops.SetText(Translate('STR_WORK_SHOPS'));
  FBarWorkshops.SetScale(0.5);
  if Options.StorageLimitsEnforced then
  begin
    FTxtContainment.SetText(Translate('STR_ALIEN_CONTAINMENT'));
    FBarContainment.SetScale(0.5);
  end;
  FTxtHangars.SetText(Translate('STR_HANGARS'));
  FBarHangars.SetScale(18.0);
  FTxtDefense.SetText(Translate('STR_DEFENSE_STRENGTH'));
  FBarDefense.SetScale(0.125);
  FTxtShortRange.SetText(Translate('STR_SHORT_RANGE_DETECTION'));
  FBarShortRange.SetScale(25.0);
  FTxtLongRange.SetText(Translate('STR_LONG_RANGE_DETECTION'));
  FBarLongRange.SetScale(25.0);
end;

destructor TBaseInfoState.Destroy;
begin
  inherited;
end;

procedure TBaseInfoState.Init;
begin
  inherited;
  UpdateStats;
end;

procedure TBaseInfoState.UpdateStats;
var
  ss: TStringStream;
begin
  FEdtBase.SetText(FBase.GetName);

  FNumSoldiers.SetText(Format('%d:%d', [FBase.GetAvailableSoldiers, FBase.GetTotalSoldiers]));
  FBarSoldiers.SetMax(FBase.GetTotalSoldiers);
  FBarSoldiers.SetValue(FBase.GetAvailableSoldiers);

  FNumEngineers.SetText(Format('%d:%d', [FBase.GetAvailableEngineers, FBase.GetTotalEngineers]));
  FBarEngineers.SetMax(FBase.GetTotalEngineers);
  FBarEngineers.SetValue(FBase.GetAvailableEngineers);

  FNumScientists.SetText(Format('%d:%d', [FBase.GetAvailableScientists, FBase.GetTotalScientists]));
  FBarScientists.SetMax(FBase.GetTotalScientists);
  FBarScientists.SetValue(FBase.GetAvailableScientists);

  FNumQuarters.SetText(Format('%d:%d', [FBase.GetUsedQuarters, FBase.GetAvailableQuarters]));
  FBarQuarters.SetMax(FBase.GetAvailableQuarters);
  FBarQuarters.SetValue(FBase.GetUsedQuarters);

  FNumStores.SetText(Format('%d:%d', [Floor(FBase.GetUsedStores + 0.05), FBase.GetAvailableStores]));
  FBarStores.SetMax(FBase.GetAvailableStores);
  FBarStores.SetValue(Floor(FBase.GetUsedStores + 0.05));

  FNumLaboratories.SetText(Format('%d:%d', [FBase.GetUsedLaboratories, FBase.GetAvailableLaboratories]));
  FBarLaboratories.SetMax(FBase.GetAvailableLaboratories);
  FBarLaboratories.SetValue(FBase.GetUsedLaboratories);

  FNumWorkshops.SetText(Format('%d:%d', [FBase.GetUsedWorkshops, FBase.GetAvailableWorkshops]));
  FBarWorkshops.SetMax(FBase.GetAvailableWorkshops);
  FBarWorkshops.SetValue(FBase.GetUsedWorkshops);

  if Options.StorageLimitsEnforced then
  begin
    FNumContainment.SetText(Format('%d:%d', [FBase.GetUsedContainment, FBase.GetAvailableContainment]));
    FBarContainment.SetMax(FBase.GetAvailableContainment);
    FBarContainment.SetValue(FBase.GetUsedContainment);
  end;

  FNumHangars.SetText(Format('%d:%d', [FBase.GetUsedHangars, FBase.GetAvailableHangars]));
  FBarHangars.SetMax(FBase.GetAvailableHangars);
  FBarHangars.SetValue(FBase.GetUsedHangars);

  FNumDefense.SetText(IntToStr(FBase.GetDefenseValue));
  FBarDefense.SetMax(FBase.GetDefenseValue);
  FBarDefense.SetValue(FBase.GetDefenseValue);

  FNumShortRange.SetText(IntToStr(FBase.GetShortRangeDetection));
  FBarShortRange.SetMax(FBase.GetShortRangeDetection);
  FBarShortRange.SetValue(FBase.GetShortRangeDetection);

  FNumLongRange.SetText(IntToStr(FBase.GetLongRangeDetection));
  FBarLongRange.SetMax(FBase.GetLongRangeDetection);
  FBarLongRange.SetValue(FBase.GetLongRangeDetection);
end;

procedure TBaseInfoState.EdtBaseChange(Sender: TObject; Action: TAction);
begin
  FBase.SetName(FEdtBase.GetText);
end;

procedure TBaseInfoState.MiniClick(Sender: TObject; Action: TAction);
var
  baseIdx: Integer;
begin
  baseIdx := FMini.GetHoveredBase;
  if baseIdx < FGame.GetSavedGame.GetBases.Count then
  begin
    FMini.SetSelectedBase(baseIdx);
    FBase := FGame.GetSavedGame.GetBases[baseIdx];
    FState.SetBase(FBase);
    Init;
  end;
end;

procedure TBaseInfoState.HandleKeyPress(Sender: TObject; Action: TAction);
var
  key: Integer;
  i: Integer;
  baseKeys: array[0..7] of Integer;
begin
  if Action.GetDetails.typ = SDL_KEYDOWN then
  begin
    baseKeys[0] := Options.KeyBaseSelect1;
    baseKeys[1] := Options.KeyBaseSelect2;
    baseKeys[2] := Options.KeyBaseSelect3;
    baseKeys[3] := Options.KeyBaseSelect4;
    baseKeys[4] := Options.KeyBaseSelect5;
    baseKeys[5] := Options.KeyBaseSelect6;
    baseKeys[6] := Options.KeyBaseSelect7;
    baseKeys[7] := Options.KeyBaseSelect8;
    key := Action.GetDetails.key.keysym.sym;
    for i := 0 to FGame.GetSavedGame.GetBases.Count - 1 do
    begin
      if key = baseKeys[i] then
      begin
        FMini.SetSelectedBase(i);
        FBase := FGame.GetSavedGame.GetBases[i];
        FState.SetBase(FBase);
        Init;
        Break;
      end;
    end;
  end;
end;

procedure TBaseInfoState.BtnOkClick(Sender: TObject; Action: TAction);
begin
  FGame.PopState;
end;

procedure TBaseInfoState.BtnTransfersClick(Sender: TObject; Action: TAction);
begin
  FGame.PushState(TTransfersState.Create(Self, FBase));
end;

procedure TBaseInfoState.BtnStoresClick(Sender: TObject; Action: TAction);
begin
  FGame.PushState(TStoresState.Create(Self, FBase));
end;

procedure TBaseInfoState.BtnMonthlyCostsClick(Sender: TObject; Action: TAction);
begin
  FGame.PushState(TMonthlyCostsState.Create(Self, FBase));
end;

end.