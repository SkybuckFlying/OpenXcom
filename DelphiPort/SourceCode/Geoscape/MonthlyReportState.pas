unit MonthlyReportState;

interface

uses
  System.SysUtils, System.Classes,
  Engine.State, Engine.Game, Engine.Mod, Engine.LocalizedText,
  Interface.TextButton, Interface.Window, Interface.Text,
  Savegame.SavedGame, Savegame.GameTime, Geoscape.PsiTrainingState,
  Savegame.Region, Savegame.Country, Mod.RuleCountry,
  Geoscape.Globe, Engine.Options, Engine.Unicode,
  Menu.CutsceneState, Savegame.Base, Battlescape.CommendationState,
  Savegame.SoldierDiary, Menu.SaveGameState, Mod.RuleInterface;

type
  TMonthlyReportState = class(TState)
  private
    FBtnOk, FBtnBigOk: TTextButton;
    FWindow: TWindow;
    FTxtTitle, FTxtMonth, FTxtRating: TText;
    FTxtIncome, FTxtMaintenance, FTxtBalance: TText;
    FTxtDesc, FTxtFailure: TText;
    FPsi: Boolean;
    FGameOver: Boolean;
    FRatingTotal, FFundingDiff, FLastMonthsRating: Integer;
    FHappyList, FSadList, FPactList: TStringList;
    FGlobe: TGlobe;
    FSoldiersMedalled: TList;
    procedure BtnOkClick(AAction: TAction);
    function CountryList(const Countries: TStringList; const Singular, Plural: string): string;
    procedure CalculateChanges;
  public
    constructor Create(APsi: Boolean; AGlobe: TGlobe);
    destructor Destroy; override;
    procedure Init; override;
  end;

implementation

{ TMonthlyReportState }

constructor TMonthlyReportState.Create(APsi: Boolean; AGlobe: TGlobe);
var
  difficulty_threshold: Integer;
  rating: string;
  month, year: Integer;
  m: string;
  ss: string;
  satisFactionString: string;
  resetWarning: Boolean;
begin
  inherited Create(nil);
  FPsi := APsi;
  FGameOver := False;
  FRatingTotal := 0;
  FFundingDiff := 0;
  FLastMonthsRating := 0;
  FGlobe := AGlobe;
  FHappyList := TStringList.Create;
  FSadList := TStringList.Create;
  FPactList := TStringList.Create;
  FSoldiersMedalled := TList.Create;

  FWindow := TWindow.Create(Self, 320, 200, 0, 0);
  FBtnOk := TTextButton.Create(50, 12, 135, 180);
  FBtnBigOk := TTextButton.Create(120, 18, 100, 174);
  FTxtTitle := TText.Create(300, 17, 16, 8);
  FTxtMonth := TText.Create(130, 9, 16, 24);
  FTxtRating := TText.Create(160, 9, 146, 24);
  FTxtIncome := TText.Create(300, 9, 16, 32);
  FTxtMaintenance := TText.Create(130, 9, 16, 40);
  FTxtBalance := TText.Create(160, 9, 146, 40);
  FTxtDesc := TText.Create(280, 132, 16, 48);
  FTxtFailure := TText.Create(290, 160, 15, 10);

  SetInterface('monthlyReport');

  Add(FWindow, 'window', 'monthlyReport');
  Add(FBtnOk, 'button', 'monthlyReport');
  Add(FBtnBigOk, 'button', 'monthlyReport');
  Add(FTxtTitle, 'text1', 'monthlyReport');
  Add(FTxtMonth, 'text1', 'monthlyReport');
  Add(FTxtRating, 'text1', 'monthlyReport');
  Add(FTxtIncome, 'text1', 'monthlyReport');
  Add(FTxtMaintenance, 'text1', 'monthlyReport');
  Add(FTxtBalance, 'text1', 'monthlyReport');
  Add(FTxtDesc, 'text2', 'monthlyReport');
  Add(FTxtFailure, 'text2', 'monthlyReport');

  CenterAllSurfaces;

  FWindow.SetBackground(Game.Mod.GetSurface('BACK13.SCR'));

  FBtnOk.Text := Tr('STR_OK');
  FBtnOk.OnMouseClick := BtnOkClick;
  FBtnOk.OnKeyboardPress(Options.KeyOk, BtnOkClick);
  FBtnOk.OnKeyboardPress(Options.KeyCancel, BtnOkClick);

  FBtnBigOk.Text := Tr('STR_OK');
  FBtnBigOk.OnMouseClick := BtnOkClick;
  FBtnBigOk.OnKeyboardPress(Options.KeyOk, BtnOkClick);
  FBtnBigOk.OnKeyboardPress(Options.KeyCancel, BtnOkClick);
  FBtnBigOk.Visible := False;

  FTxtTitle.Big := True;
  FTxtTitle.Text := Tr('STR_XCOM_PROJECT_MONTHLY_REPORT');

  FTxtFailure.Big := True;
  FTxtFailure.Align := ALIGN_CENTER;
  FTxtFailure.VerticalAlign := ALIGN_MIDDLE;
  FTxtFailure.WordWrap := True;
  FTxtFailure.Text := Tr('STR_YOU_HAVE_FAILED');
  FTxtFailure.Visible := False;

  CalculateChanges;

  month := Game.SavedGame.Time.Month - 1;
  year := Game.SavedGame.Time.Year;
  if month = 0 then
  begin
    month := 12;
    Dec(year);
  end;
  case month of
    1: m := 'STR_JAN';
    2: m := 'STR_FEB';
    3: m := 'STR_MAR';
    4: m := 'STR_APR';
    5: m := 'STR_MAY';
    6: m := 'STR_JUN';
    7: m := 'STR_JUL';
    8: m := 'STR_AUG';
    9: m := 'STR_SEP';
    10: m := 'STR_OCT';
    11: m := 'STR_NOV';
    12: m := 'STR_DEC';
  end;
  FTxtMonth.Text := Tr('STR_MONTH').Arg(Tr(m)).Arg(year);

  difficulty_threshold := Game.Mod.DefeatScore + 100 * Game.SavedGame.DifficultyCoefficient;
  rating := Tr('STR_RATING_TERRIBLE');
  if FRatingTotal > difficulty_threshold - 300 then rating := Tr('STR_RATING_POOR');
  if FRatingTotal > difficulty_threshold then rating := Tr('STR_RATING_OK');
  if FRatingTotal > 0 then rating := Tr('STR_RATING_GOOD');
  if FRatingTotal > 500 then rating := Tr('STR_RATING_EXCELLENT');
  FTxtRating.Text := Tr('STR_MONTHLY_RATING').Arg(FRatingTotal).Arg(rating);

  ss := Tr('STR_INCOME') + '> ' + Unicode.TOK_COLOR_FLIP + Unicode.FormatFunding(Game.SavedGame.CountryFunding);
  ss := ss + ' (';
  if FFundingDiff > 0 then ss := ss + '+';
  ss := ss + Unicode.FormatFunding(FFundingDiff) + ')';
  FTxtIncome.Text := ss;

  FTxtMaintenance.Text := Tr('STR_MAINTENANCE') + '> ' + Unicode.TOK_COLOR_FLIP + Unicode.FormatFunding(Game.SavedGame.BaseMaintenance);
  FTxtBalance.Text := Tr('STR_BALANCE') + '> ' + Unicode.TOK_COLOR_FLIP + Unicode.FormatFunding(Game.SavedGame.Funds);

  FTxtDesc.WordWrap := True;

  // Satisfaction
  satisFactionString := Tr('STR_COUNCIL_IS_DISSATISFIED');
  resetWarning := True;
  if FRatingTotal > difficulty_threshold then
    satisFactionString := Tr('STR_COUNCIL_IS_GENERALLY_SATISFIED');
  if FRatingTotal > 500 then
    satisFactionString := Tr('STR_COUNCIL_IS_VERY_PLEASED');
  if (FLastMonthsRating <= difficulty_threshold) and (FRatingTotal <= difficulty_threshold) then
  begin
    satisFactionString := Tr('STR_YOU_HAVE_NOT_SUCCEEDED');
    FPactList.Clear;
    FHappyList.Clear;
    FSadList.Clear;
    FGameOver := True;
  end;

  ss := satisFactionString;

  if not FGameOver then
  begin
    if Game.SavedGame.Funds <= Game.Mod.DefeatFunds then
    begin
      if Game.SavedGame.Warned then
      begin
        ss := Tr('STR_YOU_HAVE_NOT_SUCCEEDED');
        FPactList.Clear;
        FHappyList.Clear;
        FSadList.Clear;
        FGameOver := True;
      end
      else
      begin
        ss := ss + #13#10#13#10 + Tr('STR_COUNCIL_REDUCE_DEBTS');
        Game.SavedGame.Warned := True;
        resetWarning := False;
      end;
    end;
  end;
  if resetWarning and Game.SavedGame.Warned then
    Game.SavedGame.Warned := False;

  ss := ss + CountryList(FHappyList, 'STR_COUNTRY_IS_PARTICULARLY_PLEASED', 'STR_COUNTRIES_ARE_PARTICULARLY_HAPPY');
  ss := ss + CountryList(FSadList, 'STR_COUNTRY_IS_UNHAPPY_WITH_YOUR_ABILITY', 'STR_COUNTRIES_ARE_UNHAPPY_WITH_YOUR_ABILITY');
  ss := ss + CountryList(FPactList, 'STR_COUNTRY_HAS_SIGNED_A_SECRET_PACT', 'STR_COUNTRIES_HAVE_SIGNED_A_SECRET_PACT');

  FTxtDesc.Text := ss;
end;

destructor TMonthlyReportState.Destroy;
begin
  FHappyList.Free;
  FSadList.Free;
  FPactList.Free;
  FSoldiersMedalled.Free;
  inherited;
end;

procedure TMonthlyReportState.Init;
begin
  inherited;
  if FGameOver then
    Game.SavedGame.Ending := END_LOSE;
end;

procedure TMonthlyReportState.BtnOkClick(AAction: TAction);
var
  b: TBase;
  soldier: TSoldier;
begin
  if not FGameOver then
  begin
    Game.PopState;

    // Award medals
    for b in Game.SavedGame.Bases do
      for soldier in b.Soldiers do
      begin
        soldier.Diary.AddMonthlyService;
        if soldier.Diary.ManageCommendations(Game.Mod, Game.SavedGame.MissionStatistics) then
          FSoldiersMedalled.Add(soldier);
      end;
    if FSoldiersMedalled.Count > 0 then
      Game.PushState(TCommendationState.Create(FSoldiersMedalled));

    if FPsi then
      Game.PushState(TPsiTrainingState.Create);

    // Autosave
    if Game.SavedGame.IsIronman then
      Game.PushState(TSaveGameState.Create(OPT_GEOSCAPE, SAVE_IRONMAN, Palette))
    else if Options.Autosave then
      Game.PushState(TSaveGameState.Create(OPT_GEOSCAPE, SAVE_AUTO_GEOSCAPE, Palette));
  end
  else
  begin
    if FTxtFailure.Visible then
    begin
      Game.PushState(TCutsceneState.Create(CutsceneState.LOSE_GAME));
      if Game.SavedGame.IsIronman then
        Game.PushState(TSaveGameState.Create(OPT_GEOSCAPE, SAVE_IRONMAN, Palette));
    end
    else
    begin
      FWindow.Color := Game.Mod.Interface('monthlyReport').GetElement('window').Color2;
      FTxtTitle.Visible := False;
      FTxtMonth.Visible := False;
      FTxtRating.Visible := False;
      FTxtIncome.Visible := False;
      FTxtMaintenance.Visible := False;
      FTxtBalance.Visible := False;
      FTxtDesc.Visible := False;
      FBtnOk.Visible := False;
      FBtnBigOk.Visible := True;
      FTxtFailure.Visible := True;
      Game.Mod.PlayMusic('GMLOSE');
    end;
  end;
end;

function TMonthlyReportState.CountryList(const Countries: TStringList; const Singular, Plural: string): string;
var
  list: TLocalizedText;
  i: Integer;
begin
  if Countries.Count = 0 then Exit('');
  Result := #13#10#13#10;
  if Countries.Count = 1 then
    Result := Result + Tr(Singular).Arg(Tr(Countries[0]))
  else
  begin
    list := Tr(Countries[0]);
    for i := 1 to Countries.Count - 2 do
      list := Tr('STR_COUNTRIES_COMMA').Arg(list).Arg(Tr(Countries[i]));
    list := Tr('STR_COUNTRIES_AND').Arg(list).Arg(Tr(Countries[Countries.Count - 1]));
    Result := Result + Tr(Plural).Arg(list);
  end;
end;

procedure TMonthlyReportState.CalculateChanges;
var
  monthOffset, lastMonthOffset: Integer;
  xcomSubTotal, xcomTotal, alienTotal: Integer;
  region: TRegion;
  country: TCountry;
  infiltration: TRuleAlienMission;
  pactScore: Integer;
begin
  FLastMonthsRating := 0;
  xcomSubTotal := 0;
  xcomTotal := 0;
  alienTotal := 0;
  monthOffset := Game.SavedGame.FundsList.Count - 2;
  lastMonthOffset := Game.SavedGame.FundsList.Count - 3;
  if lastMonthOffset < 0 then lastMonthOffset := lastMonthOffset + 2;

  for region in Game.SavedGame.Regions do
  begin
    region.NewMonth;
    if region.ActivityXcom.Count > 2 then
      FLastMonthsRating := FLastMonthsRating + region.ActivityXcom[lastMonthOffset] - region.ActivityAlien[lastMonthOffset];
    xcomSubTotal := xcomSubTotal + region.ActivityXcom[monthOffset];
    alienTotal := alienTotal + region.ActivityAlien[monthOffset];
  end;

  // Council leniency after first month
  if Game.SavedGame.MonthsPassed > 1 then
    Game.SavedGame.ResearchScores[monthOffset] := Game.SavedGame.ResearchScores[monthOffset] + 400;

  xcomTotal := Game.SavedGame.ResearchScores[monthOffset] + xcomSubTotal;
  if Game.SavedGame.ResearchScores.Count > 2 then
    FLastMonthsRating := FLastMonthsRating + Game.SavedGame.ResearchScores[lastMonthOffset];

  infiltration := Game.Mod.GetRandomMission(OBJECTIVE_INFILTRATION, Game.SavedGame.MonthsPassed);
  pactScore := 0;
  if Assigned(infiltration) then
    pactScore := infiltration.Points;

  for country in Game.SavedGame.Countries do
  begin
    if country.NewPact then
      FPactList.Add(country.Rules.TypeName);
    country.NewMonth(xcomTotal, alienTotal, pactScore);
    FFundingDiff := FFundingDiff + (country.Funding[country.Funding.Count - 1] - country.Funding[country.Funding.Count - 2]);
    case country.Satisfaction of
      1: FSadList.Add(country.Rules.TypeName);
      3: FHappyList.Add(country.Rules.TypeName);
    end;
  end;

  FRatingTotal := xcomTotal - alienTotal;
end;

end.