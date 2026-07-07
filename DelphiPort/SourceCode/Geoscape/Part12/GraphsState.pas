unit GraphsState;

interface

uses
  System.SysUtils, System.Classes, System.Math,
  Engine.State, Engine.Game, Engine.Mod, Engine.Palette,
  Engine.Surface, Engine.InteractiveSurface, Engine.LocalizedText,
  Savegame.Country, Savegame.Region, Mod.RuleCountry,
  Mod.RuleRegion, Interface.Text, Interface.TextButton,
  Interface.ToggleTextButton, Savegame.GameTime,
  Savegame.SavedGame, Interface.TextList, Engine.Action,
  Engine.Options, Engine.Unicode, Mod.RuleInterface;

type
  TGraphButInfo = class
    Name: TLocalizedText;
    Color: Byte;
    Pushed: Boolean;
    constructor Create(AName: TLocalizedText; AColor: Byte);
  end;

  TGraphsState = class(TState)
  private
    const GRAPH_MAX_BUTTONS = 16;
    FBg: TInteractiveSurface;
    FBtnUfoRegion, FBtnUfoCountry, FBtnXcomRegion, FBtnXcomCountry: TInteractiveSurface;
    FBtnIncome, FBtnFinance, FBtnGeoscape: TInteractiveSurface;
    FTxtTitle, FTxtFactor: TText;
    FTxtMonths, FTxtYears: TTextList;
    FTxtScale: TArray<TText>;
    FBtnRegions, FBtnCountries, FBtnFinances: TArray<TToggleTextButton>;
    FRegionToggles, FCountryToggles: TArray<TGraphButInfo>;
    FFinanceToggles: TArray<Boolean>;
    FBtnRegionTotal, FBtnCountryTotal: TToggleTextButton;
    FAlienRegionLines, FAlienCountryLines: TArray<TSurface>;
    FXcomRegionLines, FXcomCountryLines: TArray<TSurface>;
    FFinanceLines, FIncomeLines: TArray<TSurface>;
    FAlien, FIncome, FCountry, FFinance: Boolean;
    FButRegionsOffset, FButCountriesOffset: Integer;
    procedure ShiftButtons(AAction: TAction);
    procedure ScrollButtons(var Toggles: TArray<TGraphButInfo>;
                           var Buttons: TArray<TToggleTextButton>;
                           var Offset: Integer; Step: Integer);
    procedure UpdateButton(From: TGraphButInfo; ToBtn: TToggleTextButton);
    procedure BtnGeoscapeClick(AAction: TAction);
    procedure BtnUfoRegionClick(AAction: TAction);
    procedure BtnUfoCountryClick(AAction: TAction);
    procedure BtnXcomRegionClick(AAction: TAction);
    procedure BtnXcomCountryClick(AAction: TAction);
    procedure BtnIncomeClick(AAction: TAction);
    procedure BtnFinanceClick(AAction: TAction);
    procedure BtnRegionListClick(AAction: TAction);
    procedure BtnCountryListClick(AAction: TAction);
    procedure BtnFinanceListClick(AAction: TAction);
    procedure ResetScreen;
    procedure UpdateScale(LowerLimit, UpperLimit: Double);
    procedure DrawLines;
    procedure DrawRegionLines;
    procedure DrawCountryLines;
    procedure DrawFinanceLines;
  public
    constructor Create;
    destructor Destroy; override;
  end;

implementation

{ TGraphButInfo }
constructor TGraphButInfo.Create(AName: TLocalizedText; AColor: Byte);
begin
  Name := AName;
  Color := AColor;
  Pushed := False;
end;

{ TGraphsState }

constructor TGraphsState.Create;
var
  i: Integer;
  region: TRegion;
  country: TCountry;
  color: Byte;
  regionTotalColor, countryTotalColor: Byte;
  graphRegionToggles, graphCountryToggles, graphFinanceToggles: string;
  gridColor: Byte;
  months: array[0..11] of string;
  monthIdx: Integer;
  scaleText: TText;
begin
  inherited Create(nil);

  FBg := TInteractiveSurface.Create(320, 200, 0, 0);
  FBg.OnMousePress(BtnUfoRegionClick, SDL_BUTTON_WHEELUP); // placeholder, actually use shift
  FBg.OnMousePress(ShiftButtons, SDL_BUTTON_WHEELUP);
  FBg.OnMousePress(ShiftButtons, SDL_BUTTON_WHEELDOWN);

  FBtnUfoRegion := TInteractiveSurface.Create(32, 24, 96, 0);
  FBtnUfoCountry := TInteractiveSurface.Create(32, 24, 128, 0);
  FBtnXcomRegion := TInteractiveSurface.Create(32, 24, 160, 0);
  FBtnXcomCountry := TInteractiveSurface.Create(32, 24, 192, 0);
  FBtnIncome := TInteractiveSurface.Create(32, 24, 224, 0);
  FBtnFinance := TInteractiveSurface.Create(32, 24, 256, 0);
  FBtnGeoscape := TInteractiveSurface.Create(32, 24, 288, 0);

  FTxtTitle := TText.Create(230, 16, 90, 28);
  FTxtFactor := TText.Create(38, 11, 96, 28);
  FTxtMonths := TTextList.Create(205, 8, 115, 183);
  FTxtYears := TTextList.Create(200, 8, 121, 191);

  SetInterface('graphs');

  Add(FBg);
  Add(FBtnUfoRegion);
  Add(FBtnUfoCountry);
  Add(FBtnXcomRegion);
  Add(FBtnXcomCountry);
  Add(FBtnIncome);
  Add(FBtnFinance);
  Add(FBtnGeoscape);
  Add(FTxtMonths, 'scale', 'graphs');
  Add(FTxtYears, 'scale', 'graphs');
  Add(FTxtTitle, 'text', 'graphs');
  Add(FTxtFactor, 'text', 'graphs');

  for i := 0 to 9 do
  begin
    scaleText := TText.Create(42, 16, 80, 171 - (i * 14));
    FTxtScale := FTxtScale + [scaleText];
    Add(scaleText, 'scale', 'graphs');
  end;

  regionTotalColor := Game.Mod.Interface('graphs').GetElement('regionTotal').Color;
  countryTotalColor := Game.Mod.Interface('graphs').GetElement('countryTotal').Color;

  // Region buttons
  var offset := 0;
  for region in Game.SavedGame.Regions do
  begin
    color := 13 + 8 * (offset mod GRAPH_MAX_BUTTONS);
    FRegionToggles := FRegionToggles + [TGraphButInfo.Create(Tr(region.Rules.TypeName), color)];
    if offset < GRAPH_MAX_BUTTONS then
    begin
      var btn := TToggleTextButton.Create(88, 11, 0, offset * 11);
      btn.Text := Tr(region.Rules.TypeName);
      btn.InvertColor := color;
      btn.OnMousePress := BtnRegionListClick;
      FBtnRegions := FBtnRegions + [btn];
      Add(btn, 'button', 'graphs');
    end;
    FAlienRegionLines := FAlienRegionLines + [TSurface.Create(320, 200, 0, 0)];
    Add(FAlienRegionLines[High(FAlienRegionLines)]);
    FXcomRegionLines := FXcomRegionLines + [TSurface.Create(320, 200, 0, 0)];
    Add(FXcomRegionLines[High(FXcomRegionLines)]);
    Inc(offset);
  end;

  FBtnRegionTotal := TToggleTextButton.Create(88, 11, 0, Min(offset, GRAPH_MAX_BUTTONS) * 11);
  FRegionToggles := FRegionToggles + [TGraphButInfo.Create(Tr('STR_TOTAL_UC'), regionTotalColor)];
  FBtnRegionTotal.OnMousePress := BtnRegionListClick;
  FBtnRegionTotal.InvertColor := regionTotalColor;
  FBtnRegionTotal.Text := Tr('STR_TOTAL_UC');
  FAlienRegionLines := FAlienRegionLines + [TSurface.Create(320, 200, 0, 0)];
  Add(FAlienRegionLines[High(FAlienRegionLines)]);
  FXcomRegionLines := FXcomRegionLines + [TSurface.Create(320, 200, 0, 0)];
  Add(FXcomRegionLines[High(FXcomRegionLines)]);
  Add(FBtnRegionTotal, 'button', 'graphs');

  // Country buttons
  offset := 0;
  for country in Game.SavedGame.Countries do
  begin
    color := 13 + 8 * (offset mod GRAPH_MAX_BUTTONS);
    FCountryToggles := FCountryToggles + [TGraphButInfo.Create(Tr(country.Rules.TypeName), color)];
    if offset < GRAPH_MAX_BUTTONS then
    begin
      var btn := TToggleTextButton.Create(88, 11, 0, offset * 11);
      btn.Text := Tr(country.Rules.TypeName);
      btn.InvertColor := color;
      btn.OnMousePress := BtnCountryListClick;
      FBtnCountries := FBtnCountries + [btn];
      Add(btn, 'button', 'graphs');
    end;
    FAlienCountryLines := FAlienCountryLines + [TSurface.Create(320, 200, 0, 0)];
    Add(FAlienCountryLines[High(FAlienCountryLines)]);
    FXcomCountryLines := FXcomCountryLines + [TSurface.Create(320, 200, 0, 0)];
    Add(FXcomCountryLines[High(FXcomCountryLines)]);
    FIncomeLines := FIncomeLines + [TSurface.Create(320, 200, 0, 0)];
    Add(FIncomeLines[High(FIncomeLines)]);
    Inc(offset);
  end;

  FBtnCountryTotal := TToggleTextButton.Create(88, 11, 0, Min(offset, GRAPH_MAX_BUTTONS) * 11);
  FCountryToggles := FCountryToggles + [TGraphButInfo.Create(Tr('STR_TOTAL_UC'), countryTotalColor)];
  FBtnCountryTotal.OnMousePress := BtnCountryListClick;
  FBtnCountryTotal.InvertColor := countryTotalColor;
  FBtnCountryTotal.Text := Tr('STR_TOTAL_UC');
  FAlienCountryLines := FAlienCountryLines + [TSurface.Create(320, 200, 0, 0)];
  Add(FAlienCountryLines[High(FAlienCountryLines)]);
  FXcomCountryLines := FXcomCountryLines + [TSurface.Create(320, 200, 0, 0)];
  Add(FXcomCountryLines[High(FXcomCountryLines)]);
  FIncomeLines := FIncomeLines + [TSurface.Create(320, 200, 0, 0)];
  Add(FIncomeLines[High(FIncomeLines)]);
  Add(FBtnCountryTotal, 'button', 'graphs');

  // Finance buttons
  for i := 0 to 4 do
  begin
    var btn := TToggleTextButton.Create(88, 11, 0, i * 11);
    btn.InvertColor := 13 + 8 * i;
    btn.OnMousePress := BtnFinanceListClick;
    FBtnFinances := FBtnFinances + [btn];
    Add(btn, 'button', 'graphs');
    FFinanceToggles := FFinanceToggles + [False];
    FFinanceLines := FFinanceLines + [TSurface.Create(320, 200, 0, 0)];
    Add(FFinanceLines[High(FFinanceLines)]);
  end;
  FBtnFinances[0].Text := Tr('STR_INCOME');
  FBtnFinances[1].Text := Tr('STR_EXPENDITURE');
  FBtnFinances[2].Text := Tr('STR_MAINTENANCE');
  FBtnFinances[3].Text := Tr('STR_BALANCE');
  FBtnFinances[4].Text := Tr('STR_SCORE');

  // Load saved toggle states
  graphRegionToggles := Game.SavedGame.GraphRegionToggles;
  graphCountryToggles := Game.SavedGame.GraphCountryToggles;
  graphFinanceToggles := Game.SavedGame.GraphFinanceToggles;
  while graphRegionToggles.Length < Length(FRegionToggles) do graphRegionToggles := graphRegionToggles + '0';
  while graphCountryToggles.Length < Length(FCountryToggles) do graphCountryToggles := graphCountryToggles + '0';
  while graphFinanceToggles.Length < Length(FFinanceToggles) do graphFinanceToggles := graphFinanceToggles + '0';

  for i := 0 to High(FRegionToggles) do
  begin
    FRegionToggles[i].Pushed := graphRegionToggles[i+1] = '1';
    if i = High(FRegionToggles) then
      FBtnRegionTotal.Pressed := FRegionToggles[i].Pushed
    else if i < GRAPH_MAX_BUTTONS then
      FBtnRegions[i].Pressed := FRegionToggles[i].Pushed;
  end;
  for i := 0 to High(FCountryToggles) do
  begin
    FCountryToggles[i].Pushed := graphCountryToggles[i+1] = '1';
    if i = High(FCountryToggles) then
      FBtnCountryTotal.Pressed := FCountryToggles[i].Pushed
    else if i < GRAPH_MAX_BUTTONS then
      FBtnCountries[i].Pressed := FCountryToggles[i].Pushed;
  end;
  for i := 0 to High(FFinanceToggles) do
  begin
    FFinanceToggles[i] := graphFinanceToggles[i+1] = '1';
    FBtnFinances[i].Pressed := FFinanceToggles[i];
  end;

  gridColor := Game.Mod.Interface('graphs').GetElement('graph').Color;
  FBg.DrawRect(125, 49, 188, 127, gridColor);
  for var grid := 0 to 4 do
    for var y := 50 + grid to 163 + grid do
      for var x := 126 + grid to 297 + grid do
      begin
        var col := gridColor + grid + 1;
        if grid = 4 then col := 0;
        FBg.DrawRect(x, y, 16 - grid*2, 13 - grid*2, col);
      end;

  // Month labels
  var monthNames: array[0..11] of string = ('STR_JAN','STR_FEB','STR_MAR','STR_APR','STR_MAY','STR_JUN',
                                            'STR_JUL','STR_AUG','STR_SEP','STR_OCT','STR_NOV','STR_DEC');
  monthIdx := Game.SavedGame.Time.Month;
  FTxtMonths.SetColumns(12, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17);
  FTxtMonths.AddRow(12, [' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ',' ']);
  FTxtYears.SetColumns(6, 34, 34, 34, 34, 34, 34);
  FTxtYears.AddRow(6, [' ',' ',' ',' ',' ',' ']);
  for i := 0 to 11 do
  begin
    if monthIdx > 11 then
    begin
      monthIdx := 0;
      FTxtYears.SetCellText(0, i div 2, IntToStr(Game.SavedGame.Time.Year));
      if i > 2 then
        FTxtYears.SetCellText(0, 0, IntToStr(Game.SavedGame.Time.Year - 1));
    end;
    FTxtMonths.SetCellText(0, i, Tr(monthNames[monthIdx]));
    Inc(monthIdx);
  end;

  for var txt in FTxtScale do
    txt.Align := ALIGN_RIGHT;

  // Background
  if Game.Mod.GetSurface('GRAPH.BDY', False) <> nil then
    Game.Mod.GetSurface('GRAPH.BDY').Blit(FBg)
  else
    Game.Mod.GetSurface('GRAPHS.SPK').Blit(FBg);

  FTxtTitle.Align := ALIGN_CENTER;
  FTxtFactor.Text := Tr('STR_FINANCE_THOUSANDS');

  // Button events
  FBtnUfoRegion.OnMousePress := BtnUfoRegionClick;
  FBtnUfoCountry.OnMousePress := BtnUfoCountryClick;
  FBtnXcomRegion.OnMousePress := BtnXcomRegionClick;
  FBtnXcomCountry.OnMousePress := BtnXcomCountryClick;
  FBtnIncome.OnMousePress := BtnIncomeClick;
  FBtnFinance.OnMousePress := BtnFinanceClick;
  FBtnGeoscape.OnMousePress := BtnGeoscapeClick;
  FBtnGeoscape.OnKeyboardPress(Options.KeyCancel, BtnGeoscapeClick);
  FBtnGeoscape.OnKeyboardPress(Options.KeyGeoGraphs, BtnGeoscapeClick);

  CenterAllSurfaces;

  // Default view
  BtnUfoRegionClick(nil);
end;

destructor TGraphsState.Destroy;
var
  graphRegionToggles, graphCountryToggles, graphFinanceToggles: string;
  i: Integer;
begin
  for i := 0 to High(FRegionToggles) do
  begin
    graphRegionToggles := graphRegionToggles + IfThen(FRegionToggles[i].Pushed, '1', '0');
    FRegionToggles[i].Free;
  end;
  for i := 0 to High(FCountryToggles) do
  begin
    graphCountryToggles := graphCountryToggles + IfThen(FCountryToggles[i].Pushed, '1', '0');
    FCountryToggles[i].Free;
  end;
  for i := 0 to High(FFinanceToggles) do
    graphFinanceToggles := graphFinanceToggles + IfThen(FFinanceToggles[i], '1', '0');
  Game.SavedGame.GraphRegionToggles := graphRegionToggles;
  Game.SavedGame.GraphCountryToggles := graphCountryToggles;
  Game.SavedGame.GraphFinanceToggles := graphFinanceToggles;
  inherited;
end;

procedure TGraphsState.ShiftButtons(AAction: TAction);
begin
  if FFinance then Exit;
  if FCountry then
  begin
    if Length(FCountryToggles) <= GRAPH_MAX_BUTTONS then Exit;
    if AAction.Details.button.button = SDL_BUTTON_WHEELUP then
      ScrollButtons(FCountryToggles, FBtnCountries, FButCountriesOffset, -1)
    else if AAction.Details.button.button = SDL_BUTTON_WHEELDOWN then
      ScrollButtons(FCountryToggles, FBtnCountries, FButCountriesOffset, 1);
  end
  else
  begin
    if Length(FRegionToggles) <= GRAPH_MAX_BUTTONS then Exit;
    if AAction.Details.button.button = SDL_BUTTON_WHEELUP then
      ScrollButtons(FRegionToggles, FBtnRegions, FButRegionsOffset, -1)
    else if AAction.Details.button.button = SDL_BUTTON_WHEELDOWN then
      ScrollButtons(FRegionToggles, FBtnRegions, FButRegionsOffset, 1);
  end;
end;

procedure TGraphsState.ScrollButtons(var Toggles: TArray<TGraphButInfo>;
                                     var Buttons: TArray<TToggleTextButton>;
                                     var Offset: Integer; Step: Integer);
var
  i: Integer;
begin
  if (Offset + Step < 0) or (Offset + Step + GRAPH_MAX_BUTTONS > Length(Toggles)) then Exit;
  Offset := Offset + Step;
  for i := 0 to GRAPH_MAX_BUTTONS - 1 do
    if i < Length(Buttons) then
      UpdateButton(Toggles[Offset + i], Buttons[i]);
end;

procedure TGraphsState.UpdateButton(From: TGraphButInfo; ToBtn: TToggleTextButton);
begin
  ToBtn.Text := From.Name;
  ToBtn.InvertColor := From.Color;
  ToBtn.Pressed := From.Pushed;
end;

procedure TGraphsState.ResetScreen;
var
  i: Integer;
begin
  for i := 0 to High(FAlienRegionLines) do FAlienRegionLines[i].Visible := False;
  for i := 0 to High(FAlienCountryLines) do FAlienCountryLines[i].Visible := False;
  for i := 0 to High(FXcomRegionLines) do FXcomRegionLines[i].Visible := False;
  for i := 0 to High(FXcomCountryLines) do FXcomCountryLines[i].Visible := False;
  for i := 0 to High(FIncomeLines) do FIncomeLines[i].Visible := False;
  for i := 0 to High(FFinanceLines) do FFinanceLines[i].Visible := False;
  for i := 0 to High(FBtnRegions) do FBtnRegions[i].Visible := False;
  for i := 0 to High(FBtnCountries) do FBtnCountries[i].Visible := False;
  for i := 0 to High(FBtnFinances) do FBtnFinances[i].Visible := False;
  FBtnRegionTotal.Visible := False;
  FBtnCountryTotal.Visible := False;
  FTxtFactor.Visible := False;
end;

procedure TGraphsState.UpdateScale(LowerLimit, UpperLimit: Double);
var
  increment: Double;
  i: Integer;
begin
  increment := (UpperLimit - LowerLimit) / 9;
  if increment < 10 then increment := 10;
  var textVal := LowerLimit;
  for i := 0 to 9 do
  begin
    FTxtScale[i].Text := Unicode.FormatNumber(Round(textVal));
    textVal := textVal + increment;
  end;
end;

procedure TGraphsState.DrawLines;
begin
  if not FCountry and not FFinance then
    DrawRegionLines
  else if not FFinance then
    DrawCountryLines
  else
    DrawFinanceLines;
end;

procedure TGraphsState.DrawRegionLines;
var
  upperLimit, lowerLimit: Integer;
  totals: array[0..11] of Integer;
  entry, iter: Integer;
  region: TRegion;
  range: Double;
  units: Double;
  y, x, reduction: Integer;
  newLineVector: TArray<Integer>;
  color: Byte;
begin
  upperLimit := 0; lowerLimit := 0;
  FillChar(totals, SizeOf(totals), 0);

  for entry := 0 to Game.SavedGame.FundsList.Count - 1 do
  begin
    var total := 0;
    for iter := 0 to Game.SavedGame.Regions.Count - 1 do
    begin
      region := Game.SavedGame.Regions[iter];
      if FAlien then
        total := total + region.ActivityAlien[entry]
      else
        total := total + region.ActivityXcom[entry];
      if FAlien then
      begin
        if (region.ActivityAlien[entry] > upperLimit) and FRegionToggles[iter].Pushed then
          upperLimit := region.ActivityAlien[entry];
        if (region.ActivityAlien[entry] < lowerLimit) and FRegionToggles[iter].Pushed then
          lowerLimit := region.ActivityAlien[entry];
      end
      else
      begin
        if (region.ActivityXcom[entry] > upperLimit) and FRegionToggles[iter].Pushed then
          upperLimit := region.ActivityXcom[entry];
        if (region.ActivityXcom[entry] < lowerLimit) and FRegionToggles[iter].Pushed then
          lowerLimit := region.ActivityXcom[entry];
      end;
    end;
    if FRegionToggles[High(FRegionToggles)].Pushed then
    begin
      if total > upperLimit then upperLimit := total;
      if total < lowerLimit then lowerLimit := total;
    end;
  end;

  range := upperLimit - lowerLimit;
  var low := lowerLimit;
  var check := 10;
  while range > check * 9 do check := check * 2;
  lowerLimit := 0;
  upperLimit := check * 9;
  if low < 0 then
    while low < lowerLimit do
    begin
      Dec(lowerLimit, check);
      Dec(upperLimit, check);
    end;
  range := upperLimit - lowerLimit;
  units := range / 126;

  for iter := 0 to Game.SavedGame.Regions.Count - 1 do
  begin
    region := Game.SavedGame.Regions[iter];
    FAlienRegionLines[iter].Clear;
    FXcomRegionLines[iter].Clear;
    SetLength(newLineVector, 0);
    for entry := 0 to 11 do
    begin
      x := 312 - entry * 17;
      y := 175 - Round(-lowerLimit / units);
      reduction := 0;
      if FAlien then
      begin
        if entry < region.ActivityAlien.Count then
        begin
          reduction := region.ActivityAlien[region.ActivityAlien.Count - (1 + entry)] div Round(units);
          y := y - reduction;
          totals[entry] := totals[entry] + region.ActivityAlien[region.ActivityAlien.Count - (1 + entry)];
        end;
      end
      else
      begin
        if entry < region.ActivityXcom.Count then
        begin
          reduction := region.ActivityXcom[region.ActivityXcom.Count - (1 + entry)] div Round(units);
          y := y - reduction;
          totals[entry] := totals[entry] + region.ActivityXcom[region.ActivityXcom.Count - (1 + entry)];
        end;
      end;
      if y > 175 then y := 175;
      newLineVector := newLineVector + [y];
      if Length(newLineVector) > 1 then
      begin
        if FAlien then
          FAlienRegionLines[iter].DrawLine(x, y, x + 17, newLineVector[Length(newLineVector)-2],
                                           FRegionToggles[iter].Color + 4)
        else
          FXcomRegionLines[iter].DrawLine(x, y, x + 17, newLineVector[Length(newLineVector)-2],
                                           FRegionToggles[iter].Color + 4);
      end;
    end;
    if FAlien then
      FAlienRegionLines[iter].Visible := FRegionToggles[iter].Pushed
    else
      FXcomRegionLines[iter].Visible := FRegionToggles[iter].Pushed;
  end;

  // Total line
  if FAlien then FAlienRegionLines[High(FAlienRegionLines)].Clear
  else FXcomRegionLines[High(FXcomRegionLines)].Clear;
  color := Game.Mod.Interface('graphs').GetElement('regionTotal').Color2;
  SetLength(newLineVector, 0);
  for entry := 0 to 11 do
  begin
    x := 312 - entry * 17;
    y := 175 - Round(-lowerLimit / units);
    reduction := totals[entry] div Round(units);
    y := y - reduction;
    newLineVector := newLineVector + [y];
    if Length(newLineVector) > 1 then
    begin
      if FAlien then
        FAlienRegionLines[High(FAlienRegionLines)].DrawLine(x, y, x + 17, newLineVector[Length(newLineVector)-2], color)
      else
        FXcomRegionLines[High(FXcomRegionLines)].DrawLine(x, y, x + 17, newLineVector[Length(newLineVector)-2], color);
    end;
  end;
  if FAlien then
    FAlienRegionLines[High(FAlienRegionLines)].Visible := FRegionToggles[High(FRegionToggles)].Pushed
  else
    FXcomRegionLines[High(FXcomRegionLines)].Visible := FRegionToggles[High(FRegionToggles)].Pushed;

  UpdateScale(lowerLimit, upperLimit);
  FTxtFactor.Visible := False;
end;

procedure TGraphsState.DrawCountryLines;
var
  upperLimit, lowerLimit: Integer;
  totals: array[0..11] of Integer;
  entry, iter: Integer;
  country: TCountry;
  range: Double;
  units: Double;
  y, x, reduction: Integer;
  newLineVector: TArray<Integer>;
  color: Byte;
begin
  upperLimit := 0; lowerLimit := 0;
  FillChar(totals, SizeOf(totals), 0);

  for entry := 0 to Game.SavedGame.FundsList.Count - 1 do
  begin
    var total := 0;
    for iter := 0 to Game.SavedGame.Countries.Count - 1 do
    begin
      country := Game.SavedGame.Countries[iter];
      if FAlien then
        total := total + country.ActivityAlien[entry]
      else if FIncome then
        total := total + country.Funding[entry] div 1000
      else
        total := total + country.ActivityXcom[entry];
      if FAlien then
      begin
        if (country.ActivityAlien[entry] > upperLimit) and FCountryToggles[iter].Pushed then
          upperLimit := country.ActivityAlien[entry];
        if (country.ActivityAlien[entry] < lowerLimit) and FCountryToggles[iter].Pushed then
          lowerLimit := country.ActivityAlien[entry];
      end
      else if FIncome then
      begin
        if (country.Funding[entry] div 1000 > upperLimit) and FCountryToggles[iter].Pushed then
          upperLimit := country.Funding[entry] div 1000;
        if (country.Funding[entry] div 1000 < lowerLimit) and FCountryToggles[iter].Pushed then
          lowerLimit := country.Funding[entry] div 1000;
      end
      else
      begin
        if (country.ActivityXcom[entry] > upperLimit) and FCountryToggles[iter].Pushed then
          upperLimit := country.ActivityXcom[entry];
        if (country.ActivityXcom[entry] < lowerLimit) and FCountryToggles[iter].Pushed then
          lowerLimit := country.ActivityXcom[entry];
      end;
    end;
    if FCountryToggles[High(FCountryToggles)].Pushed then
    begin
      if total > upperLimit then upperLimit := total;
      if total < lowerLimit then lowerLimit := total;
    end;
  end;

  range := upperLimit - lowerLimit;
  var low := lowerLimit;
  var check := IfThen(FIncome, 50, 10);
  while range > check * 9 do check := check * 2;
  lowerLimit := 0;
  upperLimit := check * 9;
  if low < 0 then
    while low < lowerLimit do
    begin
      Dec(lowerLimit, check);
      Dec(upperLimit, check);
    end;
  range := upperLimit - lowerLimit;
  units := range / 126;

  for iter := 0 to Game.SavedGame.Countries.Count - 1 do
  begin
    country := Game.SavedGame.Countries[iter];
    FAlienCountryLines[iter].Clear;
    FXcomCountryLines[iter].Clear;
    FIncomeLines[iter].Clear;
    SetLength(newLineVector, 0);
    for entry := 0 to 11 do
    begin
      x := 312 - entry * 17;
      y := 175 - Round(-lowerLimit / units);
      reduction := 0;
      if FAlien then
      begin
        if entry < country.ActivityAlien.Count then
          reduction := country.ActivityAlien[country.ActivityAlien.Count - (1 + entry)] div Round(units);
      end
      else if FIncome then
      begin
        if entry < country.Funding.Count then
          reduction := (country.Funding[country.Funding.Count - (1 + entry)] div 1000) div Round(units);
      end
      else
      begin
        if entry < country.ActivityXcom.Count then
          reduction := country.ActivityXcom[country.ActivityXcom.Count - (1 + entry)] div Round(units);
      end;
      y := y - reduction;
      if y > 175 then y := 175;
      newLineVector := newLineVector + [y];
      if Length(newLineVector) > 1 then
      begin
        if FAlien then
          FAlienCountryLines[iter].DrawLine(x, y, x + 17, newLineVector[Length(newLineVector)-2],
                                            FCountryToggles[iter].Color + 4)
        else if FIncome then
          FIncomeLines[iter].DrawLine(x, y, x + 17, newLineVector[Length(newLineVector)-2],
                                      FCountryToggles[iter].Color + 4)
        else
          FXcomCountryLines[iter].DrawLine(x, y, x + 17, newLineVector[Length(newLineVector)-2],
                                           FCountryToggles[iter].Color + 4);
      end;
      // accumulate totals
      if FAlien then
        totals[entry] := totals[entry] + country.ActivityAlien[country.ActivityAlien.Count - (1 + entry)]
      else if FIncome then
        totals[entry] := totals[entry] + country.Funding[country.Funding.Count - (1 + entry)] div 1000
      else
        totals[entry] := totals[entry] + country.ActivityXcom[country.ActivityXcom.Count - (1 + entry)];
    end;
    if FAlien then
      FAlienCountryLines[iter].Visible := FCountryToggles[iter].Pushed
    else if FIncome then
      FIncomeLines[iter].Visible := FCountryToggles[iter].Pushed
    else
      FXcomCountryLines[iter].Visible := FCountryToggles[iter].Pushed;
  end;

  // Total line
  if FAlien then FAlienCountryLines[High(FAlienCountryLines)].Clear
  else if FIncome then FIncomeLines[High(FIncomeLines)].Clear
  else FXcomCountryLines[High(FXcomCountryLines)].Clear;
  color := Game.Mod.Interface('graphs').GetElement('countryTotal').Color2;
  SetLength(newLineVector, 0);
  for entry := 0 to 11 do
  begin
    x := 312 - entry * 17;
    y := 175 - Round(-lowerLimit / units);
    reduction := totals[entry] div Round(units);
    y := y - reduction;
    newLineVector := newLineVector + [y];
    if Length(newLineVector) > 1 then
    begin
      if FAlien then
        FAlienCountryLines[High(FAlienCountryLines)].DrawLine(x, y, x + 17, newLineVector[Length(newLineVector)-2], color)
      else if FIncome then
        FIncomeLines[High(FIncomeLines)].DrawLine(x, y, x + 17, newLineVector[Length(newLineVector)-2], color)
      else
        FXcomCountryLines[High(FXcomCountryLines)].DrawLine(x, y, x + 17, newLineVector[Length(newLineVector)-2], color);
    end;
  end;
  if FAlien then
    FAlienCountryLines[High(FAlienCountryLines)].Visible := FCountryToggles[High(FCountryToggles)].Pushed
  else if FIncome then
    FIncomeLines[High(FIncomeLines)].Visible := FCountryToggles[High(FCountryToggles)].Pushed
  else
    FXcomCountryLines[High(FXcomCountryLines)].Visible := FCountryToggles[High(FCountryToggles)].Pushed;

  UpdateScale(lowerLimit, upperLimit);
  FTxtFactor.Visible := FIncome;
end;

procedure TGraphsState.DrawFinanceLines;
var
  upperLimit, lowerLimit: Integer;
  incomeTotals, balanceTotals, expendTotals, maintTotals: array[0..11] of Int64;
  scoreTotals: array[0..11] of Integer;
  entry: Integer;
  range: Double;
  units: Double;
  y, x, reduction: Integer;
  newLineVector: TArray<Integer>;
begin
  upperLimit := 0; lowerLimit := 0;
  FillChar(incomeTotals, SizeOf(incomeTotals), 0);
  FillChar(balanceTotals, SizeOf(balanceTotals), 0);
  FillChar(expendTotals, SizeOf(expendTotals), 0);
  FillChar(maintTotals, SizeOf(maintTotals), 0);
  FillChar(scoreTotals, SizeOf(scoreTotals), 0);

  for entry := 0 to Game.SavedGame.FundsList.Count - 1 do
  begin
    var inv := Game.SavedGame.FundsList.Count - (1 + entry);
    maintTotals[entry] := Game.SavedGame.Maintenances[inv] div 1000;
    balanceTotals[entry] := Game.SavedGame.FundsList[inv] div 1000;
    scoreTotals[entry] := Game.SavedGame.ResearchScores[inv];
    for var region in Game.SavedGame.Regions do
      scoreTotals[entry] := scoreTotals[entry] + region.ActivityXcom[inv] - region.ActivityAlien[inv];

    if FFinanceToggles[2] then
    begin
      if maintTotals[entry] > upperLimit then upperLimit := maintTotals[entry];
      if maintTotals[entry] < lowerLimit then lowerLimit := maintTotals[entry];
    end;
    if FFinanceToggles[3] then
    begin
      if balanceTotals[entry] > upperLimit then upperLimit := balanceTotals[entry];
      if balanceTotals[entry] < lowerLimit then lowerLimit := balanceTotals[entry];
    end;
    if FFinanceToggles[4] then
    begin
      if scoreTotals[entry] > upperLimit then upperLimit := scoreTotals[entry];
      if scoreTotals[entry] < lowerLimit then lowerLimit := scoreTotals[entry];
    end;
  end;

  for entry := 0 to Game.SavedGame.Expenditures.Count - 1 do
  begin
    var inv := Game.SavedGame.Expenditures.Count - (entry + 1);
    expendTotals[entry] := Game.SavedGame.Expenditures[inv] div 1000;
    incomeTotals[entry] := Game.SavedGame.Incomes[inv] div 1000;
    if FFinanceToggles[0] and (incomeTotals[entry] > upperLimit) then upperLimit := incomeTotals[entry];
    if FFinanceToggles[1] and (expendTotals[entry] > upperLimit) then upperLimit := expendTotals[entry];
  end;

  range := upperLimit - lowerLimit;
  var low := lowerLimit;
  var check := 250;
  while range > check * 9 do check := check * 2;
  lowerLimit := 0;
  upperLimit := check * 9;
  if low < 0 then
    while low < lowerLimit do
    begin
      Dec(lowerLimit, check);
      Dec(upperLimit, check);
    end;

  for var btn := 0 to 4 do
  begin
    FFinanceLines[btn].Visible := FFinanceToggles[btn];
    FFinanceLines[btn].Clear;
  end;

  range := upperLimit - lowerLimit;
  units := range / 126;

  for var btn := 0 to 4 do
  begin
    SetLength(newLineVector, 0);
    for entry := 0 to 11 do
    begin
      x := 312 - entry * 17;
      y := 175 - Round(-lowerLimit / units);
      reduction := 0;
      case btn of
        0: reduction := incomeTotals[entry] div Round(units);
        1: reduction := expendTotals[entry] div Round(units);
        2: reduction := maintTotals[entry] div Round(units);
        3: reduction := balanceTotals[entry] div Round(units);
        4: reduction := scoreTotals[entry] div Round(units);
      end;
      y := y - reduction;
      newLineVector := newLineVector + [y];
      var offset := (btn mod 2) * 8;
      if Length(newLineVector) > 1 then
        FFinanceLines[btn].DrawLine(x, y, x + 17, newLineVector[Length(newLineVector)-2],
                                    Palette.BlockOffset(btn div 2 + 1) + offset);
    end;
  end;

  UpdateScale(lowerLimit, upperLimit);
  FTxtFactor.Visible := True;
end;

procedure TGraphsState.BtnGeoscapeClick(AAction: TAction);
begin
  Game.PopState;
end;

procedure TGraphsState.BtnUfoRegionClick(AAction: TAction);
begin
  FAlien := True; FIncome := False; FCountry := False; FFinance := False;
  ResetScreen;
  DrawLines;
  for var btn in FBtnRegions do btn.Visible := True;
  FBtnRegionTotal.Visible := True;
  FTxtTitle.Big := True;
  FTxtTitle.Text := Tr('STR_UFO_ACTIVITY_IN_AREAS');
end;

procedure TGraphsState.BtnUfoCountryClick(AAction: TAction);
begin
  FAlien := True; FIncome := False; FCountry := True; FFinance := False;
  ResetScreen;
  DrawLines;
  for var btn in FBtnCountries do btn.Visible := True;
  FBtnCountryTotal.Visible := True;
  FTxtTitle.Big := True;
  FTxtTitle.Text := Tr('STR_UFO_ACTIVITY_IN_COUNTRIES');
end;

procedure TGraphsState.BtnXcomRegionClick(AAction: TAction);
begin
  FAlien := False; FIncome := False; FCountry := False; FFinance := False;
  ResetScreen;
  DrawLines;
  for var btn in FBtnRegions do btn.Visible := True;
  FBtnRegionTotal.Visible := True;
  FTxtTitle.Big := True;
  FTxtTitle.Text := Tr('STR_XCOM_ACTIVITY_IN_AREAS');
end;

procedure TGraphsState.BtnXcomCountryClick(AAction: TAction);
begin
  FAlien := False; FIncome := False; FCountry := True; FFinance := False;
  ResetScreen;
  DrawLines;
  for var btn in FBtnCountries do btn.Visible := True;
  FBtnCountryTotal.Visible := True;
  FTxtTitle.Big := True;
  FTxtTitle.Text := Tr('STR_XCOM_ACTIVITY_IN_COUNTRIES');
end;

procedure TGraphsState.BtnIncomeClick(AAction: TAction);
begin
  FAlien := False; FIncome := True; FCountry := True; FFinance := False;
  ResetScreen;
  DrawLines;
  FTxtFactor.Visible := True;
  for var btn in FBtnCountries do btn.Visible := True;
  FBtnCountryTotal.Visible := True;
  FTxtTitle.Big := True;
  FTxtTitle.Text := Tr('STR_INCOME');
end;

procedure TGraphsState.BtnFinanceClick(AAction: TAction);
begin
  FAlien := False; FIncome := False; FCountry := False; FFinance := True;
  ResetScreen;
  DrawLines;
  for var btn in FBtnFinances do btn.Visible := True;
  FTxtTitle.Big := True;
  FTxtTitle.Text := Tr('STR_FINANCE');
end;

procedure TGraphsState.BtnRegionListClick(AAction: TAction);
var
  number: Integer;
  btn: TToggleTextButton;
begin
  btn := AAction.Sender as TToggleTextButton;
  if btn = FBtnRegionTotal then
    number := High(FRegionToggles)
  else
  begin
    for var i := 0 to High(FBtnRegions) do
      if btn = FBtnRegions[i] then
      begin
        number := i + FButRegionsOffset;
        Break;
      end;
  end;
  FRegionToggles[number].Pushed := btn.Pressed;
  DrawLines;
end;

procedure TGraphsState.BtnCountryListClick(AAction: TAction);
var
  number: Integer;
  btn: TToggleTextButton;
begin
  btn := AAction.Sender as TToggleTextButton;
  if btn = FBtnCountryTotal then
    number := High(FCountryToggles)
  else
  begin
    for var i := 0 to High(FBtnCountries) do
      if btn = FBtnCountries[i] then
      begin
        number := i + FButCountriesOffset;
        Break;
      end;
  end;
  FCountryToggles[number].Pushed := btn.Pressed;
  DrawLines;
end;

procedure TGraphsState.BtnFinanceListClick(AAction: TAction);
var
  number: Integer;
  btn: TToggleTextButton;
begin
  btn := AAction.Sender as TToggleTextButton;
  for var i := 0 to High(FBtnFinances) do
    if btn = FBtnFinances[i] then
    begin
      number := i;
      Break;
    end;
  FFinanceToggles[number] := btn.Pressed;
  FFinanceLines[number].Visible := btn.Pressed;
  DrawLines;
end;

end.