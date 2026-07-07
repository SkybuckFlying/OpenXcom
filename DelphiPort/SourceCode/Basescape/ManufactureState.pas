unit ManufactureState;

interface

uses
  Classes, SysUtils,
  Engine.State, Engine.Game, Engine.Action,
  Mod.Mod, Engine.LocalizedText, Engine.Unicode, Engine.Options,
  Interface.TextButton, Interface.Window, Interface.Text, Interface.TextList,
  Savegame.Base, Savegame.SavedGame, Mod.RuleManufacture,
  Savegame.Production, NewManufactureListState, ManufactureInfoState;

type
  TManufactureState = class(TState)
  private
    FBase: TBase;
    FBtnNew, FBtnOk: TTextButton;
    FWindow: TWindow;
    FTxtTitle, FTxtAvailable, FTxtAllocated, FTxtSpace, FTxtFunds,
    FTxtItem, FTxtEngineers, FTxtProduced, FTxtCost, FTxtTimeLeft: TText;
    FLstManufacture: TTextList;

    procedure FillProductionList;
    procedure LstManufactureClick(Sender: TObject; Action: TAction);
  public
    constructor Create(AOwner: TComponent; Base: TBase);
    destructor Destroy; override;
    procedure Init; override;
    procedure BtnOkClick(Sender: TObject; Action: TAction);
    procedure BtnNewProductionClick(Sender: TObject; Action: TAction);
  end;

implementation

constructor TManufactureState.Create(AOwner: TComponent; Base: TBase);
begin
  inherited Create(AOwner);
  FBase := Base;

  FWindow := TWindow.Create(Self, 320, 200, 0, 0);
  FBtnNew := TTextButton.Create(148, 16, 8, 176);
  FBtnOk := TTextButton.Create(148, 16, 164, 176);
  FTxtTitle := TText.Create(310, 17, 5, 8);
  FTxtAvailable := TText.Create(150, 9, 8, 24);
  FTxtAllocated := TText.Create(150, 9, 160, 24);
  FTxtSpace := TText.Create(150, 9, 8, 34);
  FTxtFunds := TText.Create(150, 9, 160, 34);
  FTxtItem := TText.Create(80, 9, 10, 52);
  FTxtEngineers := TText.Create(56, 18, 112, 44);
  FTxtProduced := TText.Create(56, 18, 168, 44);
  FTxtCost := TText.Create(44, 27, 222, 44);
  FTxtTimeLeft := TText.Create(60, 27, 260, 44);
  FLstManufacture := TTextList.Create(288, 88, 8, 80);

  SetInterface('manufactureMenu');
  Add(FWindow, 'window', 'manufactureMenu');
  Add(FBtnNew, 'button', 'manufactureMenu');
  Add(FBtnOk, 'button', 'manufactureMenu');
  Add(FTxtTitle, 'text1', 'manufactureMenu');
  Add(FTxtAvailable, 'text1', 'manufactureMenu');
  Add(FTxtAllocated, 'text1', 'manufactureMenu');
  Add(FTxtSpace, 'text1', 'manufactureMenu');
  Add(FTxtFunds, 'text1', 'manufactureMenu');
  Add(FTxtItem, 'text2', 'manufactureMenu');
  Add(FTxtEngineers, 'text2', 'manufactureMenu');
  Add(FTxtProduced, 'text2', 'manufactureMenu');
  Add(FTxtCost, 'text2', 'manufactureMenu');
  Add(FTxtTimeLeft, 'text2', 'manufactureMenu');
  Add(FLstManufacture, 'list', 'manufactureMenu');
  CenterAllSurfaces;

  FWindow.SetBackground(FGame.GetMod.GetSurface('BACK17.SCR'));
  FBtnNew.SetText(Translate('STR_NEW_PRODUCTION'));
  FBtnNew.OnMouseClick := BtnNewProductionClick;
  FBtnOk.SetText(Translate('STR_OK'));
  FBtnOk.OnMouseClick := BtnOkClick;
  FBtnOk.OnKeyboardPress := BtnOkClick;

  FTxtTitle.SetBig;
  FTxtTitle.SetAlign(ALIGN_CENTER);
  FTxtTitle.SetText(Translate('STR_CURRENT_PRODUCTION'));
  FTxtItem.SetText(Translate('STR_ITEM'));
  FTxtEngineers.SetText(Translate('STR_ENGINEERS__ALLOCATED'));
  FTxtEngineers.SetWordWrap(True);
  FTxtProduced.SetText(Translate('STR_UNITS_PRODUCED'));
  FTxtProduced.SetWordWrap(True);
  FTxtCost.SetText(Translate('STR_COST__PER__UNIT'));
  FTxtCost.SetWordWrap(True);
  FTxtTimeLeft.SetText(Translate('STR_DAYS_HOURS_LEFT'));
  FTxtTimeLeft.SetWordWrap(True);

  FLstManufacture.SetColumns([115, 15, 52, 56, 48]);
  FLstManufacture.SetAlign(ALIGN_RIGHT);
  FLstManufacture.SetAlign(ALIGN_LEFT, 0);
  FLstManufacture.SetSelectable(True);
  FLstManufacture.SetBackground(FWindow);
  FLstManufacture.SetMargin(2);
  FLstManufacture.SetWordWrap(True);
  FLstManufacture.OnMouseClick := LstManufactureClick;
  FillProductionList;
end;

destructor TManufactureState.Destroy;
begin
  inherited;
end;

procedure TManufactureState.Init;
begin
  inherited;
  FillProductionList;
end;

procedure TManufactureState.BtnOkClick(Sender: TObject; Action: TAction);
begin
  FGame.PopState;
end;

procedure TManufactureState.BtnNewProductionClick(Sender: TObject; Action: TAction);
begin
  FGame.PushState(TNewManufactureListState.Create(Self, FBase));
end;

procedure TManufactureState.FillProductionList;
var
  prod: TProduction;
  s1, s2, s3, s4: string;
  timeLeft, hoursLeft, daysLeft: Integer;
begin
  FLstManufacture.ClearList;
  for prod in FBase.GetProductions do
  begin
    s1 := IntToStr(prod.GetAssignedEngineers);
    if prod.GetInfiniteAmount then
      s2 := IntToStr(prod.GetAmountProduced) + '/∞'
    else
      s2 := IntToStr(prod.GetAmountProduced) + '/' + IntToStr(prod.GetAmountTotal);
    if prod.GetSellItems then s2 := s2 + ' $';
    s3 := Unicode.FormatFunding(prod.GetRules.GetManufactureCost);
    if prod.GetInfiniteAmount then
      s4 := '∞'
    else if prod.GetAssignedEngineers > 0 then
    begin
      timeLeft := prod.GetAmountTotal * prod.GetRules.GetManufactureTime - prod.GetTimeSpent;
      hoursLeft := (timeLeft + prod.GetAssignedEngineers - 1) div prod.GetAssignedEngineers;
      daysLeft := hoursLeft div 24;
      hoursLeft := hoursLeft mod 24;
      s4 := IntToStr(daysLeft) + '/' + IntToStr(hoursLeft);
    end
    else
      s4 := '-';
    FLstManufacture.AddRow([Translate(prod.GetRules.GetName), s1, s2, s3, s4]);
  end;
  FTxtAvailable.SetText(Translate('STR_ENGINEERS_AVAILABLE').Arg(FBase.GetAvailableEngineers));
  FTxtAllocated.SetText(Translate('STR_ENGINEERS_ALLOCATED').Arg(FBase.GetAllocatedEngineers));
  FTxtSpace.SetText(Translate('STR_WORKSHOP_SPACE_AVAILABLE').Arg(FBase.GetFreeWorkshops));
  FTxtFunds.SetText(Translate('STR_CURRENT_FUNDS').Arg(Unicode.FormatFunding(FGame.GetSavedGame.GetFunds)));
end;

procedure TManufactureState.LstManufactureClick(Sender: TObject; Action: TAction);
begin
  FGame.PushState(TManufactureInfoState.Create(Self, FBase, FBase.GetProductions[FLstManufacture.GetSelectedRow]));
end;

end.