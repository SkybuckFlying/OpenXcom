unit ManageAlienContainmentState;

interface

uses
  Classes, SysUtils, Generics.Collections,
  Engine.State, Engine.Game, Engine.Action,
  Mod.Mod, Engine.LocalizedText, Engine.Options,
  Interface.TextButton, Interface.Window, Interface.Text, Interface.TextList,
  Savegame.ResearchProject, Savegame.SavedGame, Savegame.Base,
  Savegame.ItemContainer, Mod.RuleItem, Mod.RuleResearch,
  Mod.Armor, Engine.Timer, Menu.ErrorMessageState,
  SellState, Mod.RuleInterface, Menu.OptionsBaseState;

type
  TManageAlienContainmentState = class(TState)
  private
    FBase: TBase;
    FOrigin: TOptionsOrigin;
    FBtnOk, FBtnCancel: TTextButton;
    FWindow: TWindow;
    FTxtTitle, FTxtUsed, FTxtAvailable, FTxtItem,
    FTxtLiveAliens, FTxtDeadAliens, FTxtInterrogatedAliens: TText;
    FLstAliens: TTextList;
    FTimerInc, FTimerDec: TTimer;
    FQtys: TList<Integer>;
    FAliens: TStringList;
    FSel: Integer;
    FAliensSold: Integer;

    function GetQuantity: Integer;
    procedure UpdateStrings;
    procedure IncreaseByValue(Change: Integer);
    procedure DecreaseByValue(Change: Integer);
  public
    constructor Create(AOwner: TComponent; Base: TBase; Origin: TOptionsOrigin);
    destructor Destroy; override;
    procedure Think; override;
    procedure BtnOkClick(Sender: TObject; Action: TAction);
    procedure BtnCancelClick(Sender: TObject; Action: TAction);
    procedure LstItemsLeftArrowPress(Sender: TObject; Action: TAction);
    procedure LstItemsLeftArrowRelease(Sender: TObject; Action: TAction);
    procedure LstItemsLeftArrowClick(Sender: TObject; Action: TAction);
    procedure LstItemsRightArrowPress(Sender: TObject; Action: TAction);
    procedure LstItemsRightArrowRelease(Sender: TObject; Action: TAction);
    procedure LstItemsRightArrowClick(Sender: TObject; Action: TAction);
    procedure LstItemsMousePress(Sender: TObject; Action: TAction);
    procedure Increase;
    procedure Decrease;
  end;

implementation

constructor TManageAlienContainmentState.Create(AOwner: TComponent; Base: TBase; Origin: TOptionsOrigin);
var
  researchList: TStringList;
  items: TStringList;
  i: Integer;
  qty: Integer;
  research: TResearchProject;
  itemName: string;
begin
  inherited Create(AOwner);
  FBase := Base;
  FOrigin := Origin;
  FAliensSold := 0;
  FQtys := TList<Integer>.Create;
  FAliens := TStringList.Create;

  researchList := TStringList.Create;
  for research in FBase.GetResearch do
  begin
    itemName := research.GetRules.GetName;
    if FGame.GetMod.GetItem(itemName) <> nil then
      if FGame.GetMod.GetItem(itemName).IsAlien then
        researchList.Add(itemName);
  end;

  FWindow := TWindow.Create(Self, 320, 200, 0, 0);
  FBtnOk := TTextButton.Create(IfThen(Options.StorageLimitsEnforced and (FBase.GetFreeContainment < 0), 288, 148), 16,
    IfThen(Options.StorageLimitsEnforced and (FBase.GetFreeContainment < 0), 16, 8), 176);
  FBtnCancel := TTextButton.Create(148, 16, 164, 176);
  FTxtTitle := TText.Create(310, 17, 5, 8);
  FTxtAvailable := TText.Create(190, 9, 10, 24);
  FTxtUsed := TText.Create(110, 9, 136, 24);
  FTxtItem := TText.Create(120, 9, 10, 41);
  FTxtLiveAliens := TText.Create(54, 18, 153, 32);
  FTxtDeadAliens := TText.Create(54, 18, 207, 32);
  FTxtInterrogatedAliens := TText.Create(54, 18, 261, 32);
  FLstAliens := TTextList.Create(286, 112, 8, 53);

  SetInterface('manageContainment');
  Add(FWindow, 'window', 'manageContainment');
  Add(FBtnOk, 'button', 'manageContainment');
  Add(FBtnCancel, 'button', 'manageContainment');
  Add(FTxtTitle, 'text', 'manageContainment');
  Add(FTxtAvailable, 'text', 'manageContainment');
  Add(FTxtUsed, 'text', 'manageContainment');
  Add(FTxtItem, 'text', 'manageContainment');
  Add(FTxtLiveAliens, 'text', 'manageContainment');
  Add(FTxtDeadAliens, 'text', 'manageContainment');
  Add(FTxtInterrogatedAliens, 'text', 'manageContainment');
  Add(FLstAliens, 'list', 'manageContainment');
  CenterAllSurfaces;

  FWindow.SetBackground(FGame.GetMod.GetSurface(IfThen(Origin = OPT_BATTLESCAPE, 'BACK01.SCR', 'BACK05.SCR')));
  FBtnOk.SetText(Translate('STR_REMOVE_SELECTED'));
  FBtnOk.OnMouseClick := BtnOkClick;
  FBtnOk.OnKeyboardPress := BtnOkClick;
  FBtnCancel.SetText(Translate('STR_CANCEL'));
  FBtnCancel.OnMouseClick := BtnCancelClick;
  FBtnCancel.OnKeyboardPress := BtnCancelClick;

  if Options.StorageLimitsEnforced and (FBase.GetFreeContainment < 0) then
  begin
    FBtnCancel.Visible := False;
    FBtnOk.Visible := False;
  end;

  FTxtTitle.SetBig;
  FTxtTitle.SetAlign(ALIGN_CENTER);
  FTxtTitle.SetText(Translate('STR_MANAGE_CONTAINMENT'));
  FTxtItem.SetText(Translate('STR_ALIEN'));
  FTxtLiveAliens.SetText(Translate('STR_LIVE_ALIENS'));
  FTxtLiveAliens.SetWordWrap(True);
  FTxtLiveAliens.SetVerticalAlign(ALIGN_BOTTOM);
  FTxtDeadAliens.SetText(Translate('STR_DEAD_ALIENS'));
  FTxtDeadAliens.SetWordWrap(True);
  FTxtDeadAliens.SetVerticalAlign(ALIGN_BOTTOM);
  FTxtInterrogatedAliens.SetText(Translate('STR_UNDER_INTERROGATION'));
  FTxtInterrogatedAliens.SetWordWrap(True);
  FTxtInterrogatedAliens.SetVerticalAlign(ALIGN_BOTTOM);

  FTxtAvailable.SetText(Translate('STR_SPACE_AVAILABLE').Arg(FBase.GetFreeContainment));
  FTxtUsed.SetText(Translate('STR_SPACE_USED').Arg(FBase.GetUsedContainment));

  FLstAliens.SetArrowColumn(184, ARROW_HORIZONTAL);
  FLstAliens.SetColumns([160, 64, 46, 46]);
  FLstAliens.SetSelectable(True);
  FLstAliens.SetBackground(FWindow);
  FLstAliens.SetMargin(2);
  FLstAliens.OnLeftArrowPress := LstItemsLeftArrowPress;
  FLstAliens.OnLeftArrowRelease := LstItemsLeftArrowRelease;
  FLstAliens.OnLeftArrowClick := LstItemsLeftArrowClick;
  FLstAliens.OnRightArrowPress := LstItemsRightArrowPress;
  FLstAliens.OnRightArrowRelease := LstItemsRightArrowRelease;
  FLstAliens.OnRightArrowClick := LstItemsRightArrowClick;
  FLstAliens.OnMousePress := LstItemsMousePress;

  items := FGame.GetMod.GetItemsList;
  for i := 0 to items.Count - 1 do
  begin
    qty := FBase.GetStorageItems.GetItem(items[i]);
    if (qty > 0) and FGame.GetMod.GetItem(items[i], True).IsAlien then
    begin
      FQtys.Add(0);
      FAliens.Add(items[i]);
      // check if in research list
      if researchList.IndexOf(items[i]) <> -1 then
      begin
        FLstAliens.AddRow([Translate(items[i]), IntToStr(qty), '0', '1']);
        researchList.Delete(researchList.IndexOf(items[i]));
      end
      else
        FLstAliens.AddRow([Translate(items[i]), IntToStr(qty), '0', '0']);
    end;
  end;

  // remaining research items not in storage (interrogation ongoing)
  for i := 0 to researchList.Count - 1 do
  begin
    FAliens.Add(researchList[i]);
    FQtys.Add(0);
    FLstAliens.AddRow([Translate(researchList[i]), '0', '0', '1']);
    FLstAliens.SetRowColor(FAliens.Count - 1, FLstAliens.GetSecondaryColor);
  end;

  FTimerInc := TTimer.Create(250);
  FTimerInc.OnTimer := Increase;
  FTimerDec := TTimer.Create(250);
  FTimerDec.OnTimer := Decrease;
end;

destructor TManageAlienContainmentState.Destroy;
begin
  FQtys.Free;
  FAliens.Free;
  FTimerInc.Free;
  FTimerDec.Free;
  inherited;
end;

procedure TManageAlienContainmentState.Think;
begin
  inherited;
  FTimerInc.Think(Self, 0);
  FTimerDec.Think(Self, 0);
end;

procedure TManageAlienContainmentState.BtnOkClick(Sender: TObject; Action: TAction);
var
  i: Integer;
begin
  for i := 0 to FQtys.Count - 1 do
    if FQtys[i] > 0 then
    begin
      FBase.GetStorageItems.RemoveItem(FAliens[i], FQtys[i]);
      if Options.CanSellLiveAliens then
        FGame.GetSavedGame.SetFunds(FGame.GetSavedGame.GetFunds + FGame.GetMod.GetItem(FAliens[i], True).GetSellCost * FQtys[i])
      else
        FBase.GetStorageItems.AddItem(
          FGame.GetMod.GetArmor(
            FGame.GetMod.GetUnit(FAliens[i], True).GetArmor, True
          ).GetCorpseGeoscape, FQtys[i]
        );
    end;
  FGame.PopState;

  if Options.StorageLimitsEnforced and FBase.StoresOverfull then
  begin
    FGame.PushState(TSellState.Create(Self, FBase, FOrigin));
    FGame.PushState(TErrorMessageState.Create(Self,
      Translate('STR_STORAGE_EXCEEDED').Arg(FBase.GetName),
      FPalette,
      FGame.GetMod.GetInterface('manageContainment').GetElement('errorMessage').Color,
      IfThen(FOrigin = OPT_BATTLESCAPE, 'BACK01.SCR', 'BACK13.SCR'),
      FGame.GetMod.GetInterface('manageContainment').GetElement('errorPalette').Color));
  end;
end;

procedure TManageAlienContainmentState.BtnCancelClick(Sender: TObject; Action: TAction);
begin
  FGame.PopState;
end;

procedure TManageAlienContainmentState.LstItemsLeftArrowPress(Sender: TObject; Action: TAction);
begin
  FSel := FLstAliens.GetSelectedRow;
  if (Action.GetDetails.button.button = SDL_BUTTON_LEFT) and (not FTimerDec.IsRunning) then
    FTimerDec.Start;
end;

procedure TManageAlienContainmentState.LstItemsLeftArrowRelease(Sender: TObject; Action: TAction);
begin
  if Action.GetDetails.button.button = SDL_BUTTON_LEFT then
    FTimerDec.Stop;
end;

procedure TManageAlienContainmentState.LstItemsLeftArrowClick(Sender: TObject; Action: TAction);
begin
  if Action.GetDetails.button.button = SDL_BUTTON_RIGHT then
    DecreaseByValue(MaxInt)
  else if Action.GetDetails.button.button = SDL_BUTTON_LEFT then
  begin
    DecreaseByValue(1);
    FTimerInc.SetInterval(250);
    FTimerDec.SetInterval(250);
  end;
end;

procedure TManageAlienContainmentState.LstItemsRightArrowPress(Sender: TObject; Action: TAction);
begin
  FSel := FLstAliens.GetSelectedRow;
  if (Action.GetDetails.button.button = SDL_BUTTON_LEFT) and (not FTimerInc.IsRunning) then
    FTimerInc.Start;
end;

procedure TManageAlienContainmentState.LstItemsRightArrowRelease(Sender: TObject; Action: TAction);
begin
  if Action.GetDetails.button.button = SDL_BUTTON_LEFT then
    FTimerInc.Stop;
end;

procedure TManageAlienContainmentState.LstItemsRightArrowClick(Sender: TObject; Action: TAction);
begin
  if Action.GetDetails.button.button = SDL_BUTTON_RIGHT then
    IncreaseByValue(MaxInt)
  else if Action.GetDetails.button.button = SDL_BUTTON_LEFT then
  begin
    IncreaseByValue(1);
    FTimerInc.SetInterval(250);
    FTimerDec.SetInterval(250);
  end;
end;

procedure TManageAlienContainmentState.LstItemsMousePress(Sender: TObject; Action: TAction);
begin
  FSel := FLstAliens.GetSelectedRow;
  if Action.GetDetails.button.button = SDL_BUTTON_WHEELUP then
  begin
    FTimerInc.Stop;
    FTimerDec.Stop;
    if (Action.GetAbsoluteXMouse >= FLstAliens.GetArrowsLeftEdge) and
       (Action.GetAbsoluteXMouse <= FLstAliens.GetArrowsRightEdge) then
      IncreaseByValue(Options.ChangeValueByMouseWheel);
  end
  else if Action.GetDetails.button.button = SDL_BUTTON_WHEELDOWN then
  begin
    FTimerInc.Stop;
    FTimerDec.Stop;
    if (Action.GetAbsoluteXMouse >= FLstAliens.GetArrowsLeftEdge) and
       (Action.GetAbsoluteXMouse <= FLstAliens.GetArrowsRightEdge) then
      DecreaseByValue(Options.ChangeValueByMouseWheel);
  end;
end;

function TManageAlienContainmentState.GetQuantity: Integer;
begin
  Result := FBase.GetStorageItems.GetItem(FAliens[FSel]);
end;

procedure TManageAlienContainmentState.Increase;
begin
  FTimerDec.SetInterval(50);
  FTimerInc.SetInterval(50);
  IncreaseByValue(1);
end;

procedure TManageAlienContainmentState.IncreaseByValue(Change: Integer);
var
  qty: Integer;
begin
  qty := GetQuantity - FQtys[FSel];
  if (Change <= 0) or (qty <= 0) then Exit;
  Change := Min(qty, Change);
  FQtys[FSel] := FQtys[FSel] + Change;
  FAliensSold := FAliensSold + Change;
  UpdateStrings;
end;

procedure TManageAlienContainmentState.Decrease;
begin
  FTimerInc.SetInterval(50);
  FTimerDec.SetInterval(50);
  DecreaseByValue(1);
end;

procedure TManageAlienContainmentState.DecreaseByValue(Change: Integer);
begin
  if (Change <= 0) or (FQtys[FSel] <= 0) then Exit;
  Change := Min(FQtys[FSel], Change);
  FQtys[FSel] := FQtys[FSel] - Change;
  FAliensSold := FAliensSold - Change;
  UpdateStrings;
end;

procedure TManageAlienContainmentState.UpdateStrings;
var
  qty, aliens, spaces: Integer;
begin
  qty := GetQuantity - FQtys[FSel];
  FLstAliens.SetRowColor(FSel, IfThen(qty = 0, FLstAliens.GetSecondaryColor, FLstAliens.GetColor));
  FLstAliens.SetCellText(FSel, 1, IntToStr(qty));
  FLstAliens.SetCellText(FSel, 2, IntToStr(FQtys[FSel]));

  aliens := FBase.GetUsedContainment - FAliensSold;
  spaces := FBase.GetAvailableContainment - aliens;
  if Options.StorageLimitsEnforced then
    FBtnOk.Visible := (spaces >= 0);
  FTxtAvailable.SetText(Translate('STR_SPACE_AVAILABLE').Arg(spaces));
  FTxtUsed.SetText(Translate('STR_SPACE_USED').Arg(aliens));
end;

end.