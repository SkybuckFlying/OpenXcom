unit ManufactureStartState;

interface

uses
  Classes, SysUtils,
  Engine.State, Engine.Game, Engine.Action,
  Mod.Mod, Engine.LocalizedText, Engine.Options, Engine.Unicode,
  Interface.Window, Interface.TextButton, Interface.Text, Interface.TextList,
  Savegame.Base, Savegame.ItemContainer, Mod.RuleManufacture,
  Savegame.SavedGame, ManufactureInfoState, Menu.ErrorMessageState,
  Mod.RuleInterface;

type
  TManufactureStartState = class(TState)
  private
    FBase: TBase;
    FItem: TRuleManufacture;
    FWindow: TWindow;
    FBtnCancel, FBtnStart: TTextButton;
    FTxtTitle, FTxtManHour, FTxtCost, FTxtWorkSpace,
    FTxtRequiredItemsTitle, FTxtItemNameColumn, FTxtUnitRequiredColumn,
    FTxtUnitAvailableColumn: TText;
    FLstRequiredItems: TTextList;
  public
    constructor Create(AOwner: TComponent; Base: TBase; Item: TRuleManufacture);
    destructor Destroy; override;
    procedure BtnCancelClick(Sender: TObject; Action: TAction);
    procedure BtnStartClick(Sender: TObject; Action: TAction);
  end;

implementation

constructor TManufactureStartState.Create(AOwner: TComponent; Base: TBase; Item: TRuleManufacture);
var
  requiredItems: TDictionary<string, Integer>;
  pair: TPair<string, Integer>;
  row: Integer;
  availableWorkspace: Integer;
  productionPossible: Boolean;
  s1, s2: string;
begin
  inherited Create(AOwner);
  FBase := Base;
  FItem := Item;
  Screen := False;

  FWindow := TWindow.Create(Self, 320, 160, 0, 20);
  FBtnCancel := TTextButton.Create(136, 16, 16, 155);
  FTxtTitle := TText.Create(320, 17, 0, 30);
  FTxtManHour := TText.Create(290, 9, 16, 50);
  FTxtCost := TText.Create(290, 9, 16, 60);
  FTxtWorkSpace := TText.Create(290, 9, 16, 70);
  FTxtRequiredItemsTitle := TText.Create(290, 9, 16, 84);
  FTxtItemNameColumn := TText.Create(60, 16, 30, 92);
  FTxtUnitRequiredColumn := TText.Create(60, 16, 155, 92);
  FTxtUnitAvailableColumn := TText.Create(60, 16, 230, 92);
  FLstRequiredItems := TTextList.Create(270, 40, 30, 108);
  FBtnStart := TTextButton.Create(136, 16, 168, 155);

  SetInterface('allocateManufacture');
  Add(FWindow, 'window', 'allocateManufacture');
  Add(FTxtTitle, 'text', 'allocateManufacture');
  Add(FTxtManHour, 'text', 'allocateManufacture');
  Add(FTxtCost, 'text', 'allocateManufacture');
  Add(FTxtWorkSpace, 'text', 'allocateManufacture');
  Add(FBtnCancel, 'button', 'allocateManufacture');
  Add(FTxtRequiredItemsTitle, 'text', 'allocateManufacture');
  Add(FTxtItemNameColumn, 'text', 'allocateManufacture');
  Add(FTxtUnitRequiredColumn, 'text', 'allocateManufacture');
  Add(FTxtUnitAvailableColumn, 'text', 'allocateManufacture');
  Add(FLstRequiredItems, 'list', 'allocateManufacture');
  Add(FBtnStart, 'button', 'allocateManufacture');
  CenterAllSurfaces;

  FWindow.SetBackground(FGame.GetMod.GetSurface('BACK17.SCR'));
  FTxtTitle.SetText(Translate(FItem.GetName));
  FTxtTitle.SetBig;
  FTxtTitle.SetAlign(ALIGN_CENTER);
  FTxtManHour.SetText(Translate('STR_ENGINEER_HOURS_TO_PRODUCE_ONE_UNIT').Arg(FItem.GetManufactureTime));
  FTxtCost.SetText(Translate('STR_COST_PER_UNIT_').Arg(Unicode.FormatFunding(FItem.GetManufactureCost)));
  FTxtWorkSpace.SetText(Translate('STR_WORK_SPACE_REQUIRED').Arg(FItem.GetRequiredSpace));
  FBtnCancel.SetText(Translate('STR_CANCEL_UC'));
  FBtnCancel.OnMouseClick := BtnCancelClick;
  FBtnCancel.OnKeyboardPress := BtnCancelClick;

  requiredItems := FItem.GetRequiredItems;
  availableWorkspace := FBase.GetFreeWorkshops;
  productionPossible := FItem.HaveEnoughMoneyForOneMoreUnit(FGame.GetSavedGame.GetFunds) and (availableWorkspace > 0);

  FTxtRequiredItemsTitle.SetText(Translate('STR_SPECIAL_MATERIALS_REQUIRED'));
  FTxtRequiredItemsTitle.SetAlign(ALIGN_CENTER);
  FTxtItemNameColumn.SetText(Translate('STR_ITEM_REQUIRED'));
  FTxtItemNameColumn.SetWordWrap(True);
  FTxtUnitRequiredColumn.SetText(Translate('STR_UNITS_REQUIRED'));
  FTxtUnitRequiredColumn.SetWordWrap(True);
  FTxtUnitAvailableColumn.SetText(Translate('STR_UNITS_AVAILABLE'));
  FTxtUnitAvailableColumn.SetWordWrap(True);

  FLstRequiredItems.SetColumns([140, 75, 55]);
  FLstRequiredItems.SetBackground(FWindow);

  row := 0;
  for pair in requiredItems do
  begin
    s1 := IntToStr(pair.Value);
    if FGame.GetMod.GetItem(pair.Key) <> nil then
    begin
      s2 := IntToStr(FBase.GetStorageItems.GetItem(pair.Key));
      productionPossible := productionPossible and (FBase.GetStorageItems.GetItem(pair.Key) >= pair.Value);
    end
    else if FGame.GetMod.GetCraft(pair.Key) <> nil then
    begin
      s2 := IntToStr(FBase.GetCraftCount(pair.Key));
      productionPossible := productionPossible and (FBase.GetCraftCount(pair.Key) >= pair.Value);
    end
    else
      s2 := '0';
    FLstRequiredItems.AddRow([Translate(pair.Key), s1, s2]);
    FLstRequiredItems.SetCellColor(row, 1, FLstRequiredItems.GetSecondaryColor);
    FLstRequiredItems.SetCellColor(row, 2, FLstRequiredItems.GetSecondaryColor);
    Inc(row);
  end;

  FTxtRequiredItemsTitle.Visible := not requiredItems.IsEmpty;
  FTxtItemNameColumn.Visible := not requiredItems.IsEmpty;
  FTxtUnitRequiredColumn.Visible := not requiredItems.IsEmpty;
  FTxtUnitAvailableColumn.Visible := not requiredItems.IsEmpty;
  FLstRequiredItems.Visible := not requiredItems.IsEmpty;

  FBtnStart.SetText(Translate('STR_START_PRODUCTION'));
  FBtnStart.OnMouseClick := BtnStartClick;
  FBtnStart.OnKeyboardPress := BtnStartClick;
  FBtnStart.Visible := productionPossible;
end;

destructor TManufactureStartState.Destroy;
begin
  inherited;
end;

procedure TManufactureStartState.BtnCancelClick(Sender: TObject; Action: TAction);
begin
  FGame.PopState;
end;

procedure TManufactureStartState.BtnStartClick(Sender: TObject; Action: TAction);
begin
  if (FItem.GetCategory = 'STR_CRAFT') and (FBase.GetAvailableHangars - FBase.GetUsedHangars <= 0) then
    FGame.PushState(TErrorMessageState.Create(Self,
      Translate('STR_NO_FREE_HANGARS_FOR_CRAFT_PRODUCTION'),
      FPalette,
      FGame.GetMod.GetInterface('basescape').GetElement('errorMessage').Color,
      'BACK17.SCR',
      FGame.GetMod.GetInterface('basescape').GetElement('errorPalette').Color))
  else if FItem.GetRequiredSpace > FBase.GetFreeWorkshops then
    FGame.PushState(TErrorMessageState.Create(Self,
      Translate('STR_NOT_ENOUGH_WORK_SPACE'),
      FPalette,
      FGame.GetMod.GetInterface('basescape').GetElement('errorMessage').Color,
      'BACK17.SCR',
      FGame.GetMod.GetInterface('basescape').GetElement('errorPalette').Color))
  else
    FGame.PushState(TManufactureInfoState.Create(Self, FBase, FItem));
end;

end.