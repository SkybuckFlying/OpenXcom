unit ManufactureInfoState;

interface

uses
  Classes, SysUtils, Math,
  Engine.State, Engine.Game, Engine.Action,
  Mod.Mod, Engine.LocalizedText, Engine.Unicode, Engine.Options,
  Interface.Window, Interface.TextButton, Interface.ToggleTextButton,
  Interface.Text, Interface.ArrowButton,
  Savegame.Base, Savegame.Production, Mod.RuleManufacture,
  Engine.Timer, Menu.ErrorMessageState, Mod.RuleInterface,
  Generics.Collections;

type
  TManufactureInfoState = class(TState)
  private
    FBase: TBase;
    FItem: TRuleManufacture;
    FProduction: TProduction;
    FWindow: TWindow;
    FBtnStop, FBtnOk: TTextButton;
    FTxtTitle, FTxtAvailableEngineer, FTxtAvailableSpace, FTxtMonthlyProfit,
    FTxtAllocatedEngineer, FTxtUnitToProduce, FTxtUnitUp, FTxtUnitDown,
    FTxtEngineerUp, FTxtEngineerDown, FTxtAllocated, FTxtTodo: TText;
    FBtnSell: TToggleTextButton;
    FBtnUnitUp, FBtnUnitDown, FBtnEngineerUp, FBtnEngineerDown: TArrowButton;
    FTimerMoreEngineer, FTimerLessEngineer, FTimerMoreUnit, FTimerLessUnit: TTimer;
    FSurfaceEngineers, FSurfaceUnits: TInteractiveSurface;
    FProducedItemsValue: Integer;

    procedure InitProfitInfo;
    function GetMonthlyNetFunds: Integer;
    procedure SetAssignedEngineer;
    procedure MoreEngineer(Change: Integer);
    procedure LessEngineer(Change: Integer);
    procedure MoreUnit(Change: Integer);
    procedure LessUnit(Change: Integer);
    procedure ExitState;
  public
    constructor Create(AOwner: TComponent; Base: TBase; Item: TRuleManufacture); overload;
    constructor Create(AOwner: TComponent; Base: TBase; Production: TProduction); overload;
    destructor Destroy; override;
    procedure BtnSellClick(Sender: TObject; Action: TAction);
    procedure BtnStopClick(Sender: TObject; Action: TAction);
    procedure BtnOkClick(Sender: TObject; Action: TAction);
    procedure MoreEngineerPress(Sender: TObject; Action: TAction);
    procedure MoreEngineerRelease(Sender: TObject; Action: TAction);
    procedure MoreEngineerClick(Sender: TObject; Action: TAction);
    procedure LessEngineerPress(Sender: TObject; Action: TAction);
    procedure LessEngineerRelease(Sender: TObject; Action: TAction);
    procedure LessEngineerClick(Sender: TObject; Action: TAction);
    procedure MoreUnitPress(Sender: TObject; Action: TAction);
    procedure MoreUnitRelease(Sender: TObject; Action: TAction);
    procedure MoreUnitClick(Sender: TObject; Action: TAction);
    procedure LessUnitPress(Sender: TObject; Action: TAction);
    procedure LessUnitRelease(Sender: TObject; Action: TAction);
    procedure LessUnitClick(Sender: TObject; Action: TAction);
    procedure OnMoreEngineer;
    procedure OnLessEngineer;
    procedure OnMoreUnit;
    procedure OnLessUnit;
    procedure HandleWheelEngineer(Sender: TObject; Action: TAction);
    procedure HandleWheelUnit(Sender: TObject; Action: TAction);
    procedure Think; override;
  end;

implementation

constructor TManufactureInfoState.Create(AOwner: TComponent; Base: TBase; Item: TRuleManufacture);
begin
  FBase := Base;
  FItem := Item;
  FProduction := nil;
  BuildUi;
end;

constructor TManufactureInfoState.Create(AOwner: TComponent; Base: TBase; Production: TProduction);
begin
  FBase := Base;
  FItem := nil;
  FProduction := Production;
  BuildUi;
end;

procedure TManufactureInfoState.BuildUi;
begin
  inherited Create(nil);
  Screen := False;

  FWindow := TWindow.Create(Self, 320, 160, 0, 20, POPUP_BOTH);
  FTxtTitle := TText.Create(320, 17, 0, 30);
  FBtnOk := TTextButton.Create(136, 16, 168, 155);
  FBtnStop := TTextButton.Create(136, 16, 16, 155);
  FBtnSell := TToggleTextButton.Create(60, 16, 244, 61);
  FTxtAvailableEngineer := TText.Create(160, 9, 16, 50);
  FTxtAvailableSpace := TText.Create(160, 9, 16, 60);
  FTxtMonthlyProfit := TText.Create(160, 9, 168, 50);
  FTxtAllocatedEngineer := TText.Create(112, 32, 16, 80);
  FTxtUnitToProduce := TText.Create(112, 48, 168, 64);
  FTxtEngineerUp := TText.Create(90, 9, 40, 118);
  FTxtEngineerDown := TText.Create(90, 9, 40, 138);
  FTxtUnitUp := TText.Create(90, 9, 192, 118);
  FTxtUnitDown := TText.Create(90, 9, 192, 138);
  FBtnEngineerUp := TArrowButton.Create(ARROW_BIG_UP, 13, 14, 132, 114);
  FBtnEngineerDown := TArrowButton.Create(ARROW_BIG_DOWN, 13, 14, 132, 136);
  FBtnUnitUp := TArrowButton.Create(ARROW_BIG_UP, 13, 14, 284, 114);
  FBtnUnitDown := TArrowButton.Create(ARROW_BIG_DOWN, 13, 14, 284, 136);
  FTxtAllocated := TText.Create(40, 16, 128, 88);
  FTxtTodo := TText.Create(40, 16, 280, 88);

  FSurfaceEngineers := TInteractiveSurface.Create(160, 150, 0, 25);
  FSurfaceEngineers.OnMouseClick := HandleWheelEngineer;
  FSurfaceUnits := TInteractiveSurface.Create(160, 150, 160, 25);
  FSurfaceUnits.OnMouseClick := HandleWheelUnit;

  SetInterface('manufactureInfo');
  Add(FSurfaceEngineers);
  Add(FSurfaceUnits);
  Add(FWindow, 'window', 'manufactureInfo');
  Add(FTxtTitle, 'text', 'manufactureInfo');
  Add(FTxtAvailableEngineer, 'text', 'manufactureInfo');
  Add(FTxtAvailableSpace, 'text', 'manufactureInfo');
  Add(FTxtMonthlyProfit, 'text', 'manufactureInfo');
  Add(FTxtAllocatedEngineer, 'text', 'manufactureInfo');
  Add(FTxtAllocated, 'text', 'manufactureInfo');
  Add(FTxtUnitToProduce, 'text', 'manufactureInfo');
  Add(FTxtTodo, 'text', 'manufactureInfo');
  Add(FTxtEngineerUp, 'text', 'manufactureInfo');
  Add(FTxtEngineerDown, 'text', 'manufactureInfo');
  Add(FBtnEngineerUp, 'button1', 'manufactureInfo');
  Add(FBtnEngineerDown, 'button1', 'manufactureInfo');
  Add(FTxtUnitUp, 'text', 'manufactureInfo');
  Add(FTxtUnitDown, 'text', 'manufactureInfo');
  Add(FBtnUnitUp, 'button1', 'manufactureInfo');
  Add(FBtnUnitDown, 'button1', 'manufactureInfo');
  Add(FBtnOk, 'button2', 'manufactureInfo');
  Add(FBtnStop, 'button2', 'manufactureInfo');
  Add(FBtnSell, 'button1', 'manufactureInfo');
  CenterAllSurfaces;

  FWindow.SetBackground(FGame.GetMod.GetSurface('BACK17.SCR'));
  FTxtTitle.SetText(Translate(IfThen(FItem <> nil, FItem.GetName, FProduction.GetRules.GetName)));
  FTxtTitle.SetBig;
  FTxtTitle.SetAlign(ALIGN_CENTER);

  FTxtAllocatedEngineer.SetText(Translate('STR_ENGINEERS__ALLOCATED'));
  FTxtAllocatedEngineer.SetBig;
  FTxtAllocatedEngineer.SetWordWrap(True);
  FTxtAllocatedEngineer.SetVerticalAlign(ALIGN_BOTTOM);
  FTxtAllocated.SetBig;
  FTxtTodo.SetBig;

  FTxtUnitToProduce.SetText(Translate('STR_UNITS_TO_PRODUCE'));
  FTxtUnitToProduce.SetBig;
  FTxtUnitToProduce.SetWordWrap(True);
  FTxtUnitToProduce.SetVerticalAlign(ALIGN_BOTTOM);

  FTxtEngineerUp.SetText(Translate('STR_INCREASE_UC'));
  FTxtEngineerDown.SetText(Translate('STR_DECREASE_UC'));
  FBtnEngineerUp.OnMousePress := MoreEngineerPress;
  FBtnEngineerUp.OnMouseRelease := MoreEngineerRelease;
  FBtnEngineerUp.OnMouseClick := MoreEngineerClick;
  FBtnEngineerDown.OnMousePress := LessEngineerPress;
  FBtnEngineerDown.OnMouseRelease := LessEngineerRelease;
  FBtnEngineerDown.OnMouseClick := LessEngineerClick;

  FBtnUnitUp.OnMousePress := MoreUnitPress;
  FBtnUnitUp.OnMouseRelease := MoreUnitRelease;
  FBtnUnitUp.OnMouseClick := MoreUnitClick;
  FBtnUnitDown.OnMousePress := LessUnitPress;
  FBtnUnitDown.OnMouseRelease := LessUnitRelease;
  FBtnUnitDown.OnMouseClick := LessUnitClick;

  FTxtUnitUp.SetText(Translate('STR_INCREASE_UC'));
  FTxtUnitDown.SetText(Translate('STR_DECREASE_UC'));

  FBtnSell.SetText(Translate('STR_SELL_PRODUCTION'));
  FBtnSell.OnMouseClick := BtnSellClick;

  FBtnOk.SetText(Translate('STR_OK'));
  FBtnOk.OnMouseClick := BtnOkClick;
  FBtnOk.OnKeyboardPress := BtnOkClick;
  FBtnStop.SetText(Translate('STR_STOP_PRODUCTION'));
  FBtnStop.OnMouseClick := BtnStopClick;

  if FItem <> nil then
    FProduction := TProduction.Create(FItem, 1)
  else
    FProduction := FProduction; // already set
  FBase.AddProduction(FProduction);
  FBtnSell.SetPressed(FProduction.GetSellItems);
  InitProfitInfo;
  SetAssignedEngineer;

  FTimerMoreEngineer := TTimer.Create(250);
  FTimerMoreEngineer.OnTimer := OnMoreEngineer;
  FTimerLessEngineer := TTimer.Create(250);
  FTimerLessEngineer.OnTimer := OnLessEngineer;
  FTimerMoreUnit := TTimer.Create(250);
  FTimerMoreUnit.OnTimer := OnMoreUnit;
  FTimerLessUnit := TTimer.Create(250);
  FTimerLessUnit.OnTimer := OnLessUnit;
end;

destructor TManufactureInfoState.Destroy;
begin
  FTimerMoreEngineer.Free;
  FTimerLessEngineer.Free;
  FTimerMoreUnit.Free;
  FTimerLessUnit.Free;
  inherited;
end;

procedure TManufactureInfoState.InitProfitInfo;
var
  ItemMap: TDictionary<string, Integer>;
  pair: TPair<string, Integer>;
  sellValue: Integer;
begin
  FProducedItemsValue := 0;
  ItemMap := FProduction.GetRules.GetProducedItems;
  for pair in ItemMap do
  begin
    if FProduction.GetRules.GetCategory = 'STR_CRAFT' then
      sellValue := FGame.GetMod.GetCraft(pair.Key, True).GetSellCost
    else
      sellValue := FGame.GetMod.GetItem(pair.Key, True).GetSellCost;
    FProducedItemsValue := FProducedItemsValue + sellValue * pair.Value;
  end;
end;

function TManufactureInfoState.GetMonthlyNetFunds: Integer;
const
  AVG_HOURS_PER_MONTH = 730; // approximate
var
  saleValue: Integer;
  numEngineers: Integer;
  manHoursPerMonth: Integer;
  itemsPerMonth: Single;
begin
  saleValue := IfThen(FBtnSell.GetPressed, FProducedItemsValue, 0);
  numEngineers := FProduction.GetAssignedEngineers;
  manHoursPerMonth := AVG_HOURS_PER_MONTH * numEngineers;
  if not FProduction.GetInfiniteAmount then
  begin
    manHoursPerMonth := Min(manHoursPerMonth,
      FProduction.GetRules.GetManufactureTime * (FProduction.GetAmountTotal - FProduction.GetAmountProduced));
  end;
  itemsPerMonth := manHoursPerMonth / FProduction.GetRules.GetManufactureTime;
  Result := Round((saleValue - FProduction.GetRules.GetManufactureCost) * itemsPerMonth);
end;

procedure TManufactureInfoState.SetAssignedEngineer;
begin
  FTxtAvailableEngineer.SetText(Translate('STR_ENGINEERS_AVAILABLE_UC').Arg(FBase.GetAvailableEngineers));
  FTxtAvailableSpace.SetText(Translate('STR_WORKSHOP_SPACE_AVAILABLE_UC').Arg(FBase.GetFreeWorkshops));
  FTxtAllocated.SetText('>' + Unicode.TOK_COLOR_FLIP + IntToStr(FProduction.GetAssignedEngineers));
  if FProduction.GetInfiniteAmount then
    FTxtTodo.SetText('>' + Unicode.TOK_COLOR_FLIP + '∞')
  else
    FTxtTodo.SetText('>' + Unicode.TOK_COLOR_FLIP + IntToStr(FProduction.GetAmountTotal));
  FTxtMonthlyProfit.SetText(Translate('STR_MONTHLY_PROFIT').Arg(Unicode.FormatFunding(GetMonthlyNetFunds)));
end;

procedure TManufactureInfoState.MoreEngineer(Change: Integer);
var
  available, space: Integer;
begin
  if Change <= 0 then Exit;
  available := FBase.GetAvailableEngineers;
  space := FBase.GetFreeWorkshops;
  if (available > 0) and (space > 0) then
  begin
    Change := Min(Min(available, space), Change);
    FProduction.SetAssignedEngineers(FProduction.GetAssignedEngineers + Change);
    FBase.SetEngineers(FBase.GetEngineers - Change);
    SetAssignedEngineer;
  end;
end;

procedure TManufactureInfoState.LessEngineer(Change: Integer);
var
  assigned: Integer;
begin
  if Change <= 0 then Exit;
  assigned := FProduction.GetAssignedEngineers;
  if assigned > 0 then
  begin
    Change := Min(assigned, Change);
    FProduction.SetAssignedEngineers(assigned - Change);
    FBase.SetEngineers(FBase.GetEngineers + Change);
    SetAssignedEngineer;
  end;
end;

procedure TManufactureInfoState.MoreUnit(Change: Integer);
var
  units, availableHangars: Integer;
begin
  if Change <= 0 then Exit;
  if (FProduction.GetRules.GetCategory = 'STR_CRAFT') and
     (FBase.GetAvailableHangars - FBase.GetUsedHangars <= 0) then
  begin
    FTimerMoreUnit.Stop;
    FGame.PushState(TErrorMessageState.Create(Self,
      Translate('STR_NO_FREE_HANGARS_FOR_CRAFT_PRODUCTION'),
      FPalette,
      FGame.GetMod.GetInterface('basescape').GetElement('errorMessage').Color,
      'BACK17.SCR',
      FGame.GetMod.GetInterface('basescape').GetElement('errorPalette').Color));
    Exit;
  end;
  units := FProduction.GetAmountTotal;
  Change := Min(MaxInt - units, Change);
  if FProduction.GetRules.GetCategory = 'STR_CRAFT' then
    Change := Min(FBase.GetAvailableHangars - FBase.GetUsedHangars, Change);
  FProduction.SetAmountTotal(units + Change);
  SetAssignedEngineer;
end;

procedure TManufactureInfoState.LessUnit(Change: Integer);
var
  units: Integer;
begin
  if Change <= 0 then Exit;
  units := FProduction.GetAmountTotal;
  Change := Min(units - (FProduction.GetAmountProduced + 1), Change);
  FProduction.SetAmountTotal(units - Change);
  SetAssignedEngineer;
end;

procedure TManufactureInfoState.ExitState;
begin
  FGame.PopState;
  if FItem <> nil then
    FGame.PopState;
end;

// Event handlers
procedure TManufactureInfoState.BtnSellClick(Sender: TObject; Action: TAction);
begin
  SetAssignedEngineer;
end;

procedure TManufactureInfoState.BtnStopClick(Sender: TObject; Action: TAction);
begin
  FBase.RemoveProduction(FProduction);
  ExitState;
end;

procedure TManufactureInfoState.BtnOkClick(Sender: TObject; Action: TAction);
begin
  if FItem <> nil then
    FProduction.StartItem(FBase, FGame.GetSavedGame, FGame.GetMod);
  FProduction.SetSellItems(FBtnSell.GetPressed);
  ExitState;
end;

procedure TManufactureInfoState.MoreEngineerPress(Sender: TObject; Action: TAction);
begin
  if Action.GetDetails.button.button = SDL_BUTTON_LEFT then FTimerMoreEngineer.Start;
end;

procedure TManufactureInfoState.MoreEngineerRelease(Sender: TObject; Action: TAction);
begin
  if Action.GetDetails.button.button = SDL_BUTTON_LEFT then
  begin
    FTimerMoreEngineer.SetInterval(250);
    FTimerMoreEngineer.Stop;
  end;
end;

procedure TManufactureInfoState.MoreEngineerClick(Sender: TObject; Action: TAction);
begin
  if Action.GetDetails.button.button = SDL_BUTTON_RIGHT then MoreEngineer(MaxInt);
  if Action.GetDetails.button.button = SDL_BUTTON_LEFT then MoreEngineer(1);
end;

procedure TManufactureInfoState.LessEngineerPress(Sender: TObject; Action: TAction);
begin
  if Action.GetDetails.button.button = SDL_BUTTON_LEFT then FTimerLessEngineer.Start;
end;

procedure TManufactureInfoState.LessEngineerRelease(Sender: TObject; Action: TAction);
begin
  if Action.GetDetails.button.button = SDL_BUTTON_LEFT then
  begin
    FTimerLessEngineer.SetInterval(250);
    FTimerLessEngineer.Stop;
  end;
end;

procedure TManufactureInfoState.LessEngineerClick(Sender: TObject; Action: TAction);
begin
  if Action.GetDetails.button.button = SDL_BUTTON_RIGHT then LessEngineer(MaxInt);
  if Action.GetDetails.button.button = SDL_BUTTON_LEFT then LessEngineer(1);
end;

procedure TManufactureInfoState.MoreUnitPress(Sender: TObject; Action: TAction);
begin
  if (Action.GetDetails.button.button = SDL_BUTTON_LEFT) and (FProduction.GetAmountTotal < MaxInt) then
    FTimerMoreUnit.Start;
end;

procedure TManufactureInfoState.MoreUnitRelease(Sender: TObject; Action: TAction);
begin
  if Action.GetDetails.button.button = SDL_BUTTON_LEFT then
  begin
    FTimerMoreUnit.SetInterval(250);
    FTimerMoreUnit.Stop;
  end;
end;

procedure TManufactureInfoState.MoreUnitClick(Sender: TObject; Action: TAction);
begin
  if FProduction.GetInfiniteAmount then Exit;
  if Action.GetDetails.button.button = SDL_BUTTON_RIGHT then
  begin
    if FProduction.GetRules.GetCategory = 'STR_CRAFT' then
      MoreUnit(MaxInt)
    else
    begin
      FProduction.SetInfiniteAmount(True);
      SetAssignedEngineer;
    end;
  end
  else if Action.GetDetails.button.button = SDL_BUTTON_LEFT then
    MoreUnit(1);
end;

procedure TManufactureInfoState.LessUnitPress(Sender: TObject; Action: TAction);
begin
  if Action.GetDetails.button.button = SDL_BUTTON_LEFT then FTimerLessUnit.Start;
end;

procedure TManufactureInfoState.LessUnitRelease(Sender: TObject; Action: TAction);
begin
  if Action.GetDetails.button.button = SDL_BUTTON_LEFT then
  begin
    FTimerLessUnit.SetInterval(250);
    FTimerLessUnit.Stop;
  end;
end;

procedure TManufactureInfoState.LessUnitClick(Sender: TObject; Action: TAction);
begin
  if (Action.GetDetails.button.button = SDL_BUTTON_RIGHT) or
     (Action.GetDetails.button.button = SDL_BUTTON_LEFT) then
  begin
    FProduction.SetInfiniteAmount(False);
    if (Action.GetDetails.button.button = SDL_BUTTON_RIGHT) or
       (FProduction.GetAmountTotal <= FProduction.GetAmountProduced) then
    begin
      FProduction.SetAmountTotal(FProduction.GetAmountProduced + 1);
      SetAssignedEngineer;
    end;
    if Action.GetDetails.button.button = SDL_BUTTON_LEFT then LessUnit(1);
  end;
end;

procedure TManufactureInfoState.OnMoreEngineer;
begin
  FTimerMoreEngineer.SetInterval(50);
  MoreEngineer(1);
end;

procedure TManufactureInfoState.OnLessEngineer;
begin
  FTimerLessEngineer.SetInterval(50);
  LessEngineer(1);
end;

procedure TManufactureInfoState.OnMoreUnit;
begin
  FTimerMoreUnit.SetInterval(50);
  MoreUnit(1);
end;

procedure TManufactureInfoState.OnLessUnit;
begin
  FTimerLessUnit.SetInterval(50);
  LessUnit(1);
end;

procedure TManufactureInfoState.HandleWheelEngineer(Sender: TObject; Action: TAction);
begin
  if Action.GetDetails.button.button = SDL_BUTTON_WHEELUP then
    MoreEngineer(Options.ChangeValueByMouseWheel)
  else if Action.GetDetails.button.button = SDL_BUTTON_WHEELDOWN then
    LessEngineer(Options.ChangeValueByMouseWheel);
end;

procedure TManufactureInfoState.HandleWheelUnit(Sender: TObject; Action: TAction);
begin
  if Action.GetDetails.button.button = SDL_BUTTON_WHEELUP then
    MoreUnit(Options.ChangeValueByMouseWheel)
  else if Action.GetDetails.button.button = SDL_BUTTON_WHEELDOWN then
    LessUnit(Options.ChangeValueByMouseWheel);
end;

procedure TManufactureInfoState.Think;
begin
  inherited;
  FTimerMoreEngineer.Think(Self, 0);
  FTimerLessEngineer.Think(Self, 0);
  FTimerMoreUnit.Think(Self, 0);
  FTimerLessUnit.Think(Self, 0);
end;

end.