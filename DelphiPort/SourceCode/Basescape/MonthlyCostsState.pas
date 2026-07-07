unit MonthlyCostsState;

interface

uses
  Classes, SysUtils,
  Engine.State, Engine.Game, Engine.Action,
  Mod.Mod, Engine.LocalizedText, Engine.Options, Engine.Unicode,
  Interface.TextButton, Interface.Window, Interface.Text, Interface.TextList,
  Savegame.Base, Savegame.SavedGame, Mod.RuleCraft, Mod.RuleSoldier;

type
  TMonthlyCostsState = class(TState)
  private
    FBase: TBase;
    FBtnOk: TTextButton;
    FWindow: TWindow;
    FTxtTitle, FTxtCost, FTxtQuantity, FTxtTotal,
    FTxtRental, FTxtSalaries, FTxtIncome, FTxtMaintenance: TText;
    FLstCrafts, FLstSalaries, FLstMaintenance, FLstTotal: TTextList;
  public
    constructor Create(AOwner: TComponent; Base: TBase);
    destructor Destroy; override;
    procedure BtnOkClick(Sender: TObject; Action: TAction);
  end;

implementation

constructor TMonthlyCostsState.Create(AOwner: TComponent; Base: TBase);
var
  crafts: TStringList;
  soldiers: TStringList;
  craft: TRuleCraft;
  soldier: TRuleSoldier;
  i: Integer;
begin
  inherited Create(AOwner);
  FBase := Base;

  FWindow := TWindow.Create(Self, 320, 200, 0, 0);
  FBtnOk := TTextButton.Create(300, 20, 10, 170);
  FTxtTitle := TText.Create(310, 17, 5, 12);
  FTxtCost := TText.Create(80, 9, 115, 32);
  FTxtQuantity := TText.Create(55, 9, 195, 32);
  FTxtTotal := TText.Create(60, 9, 249, 32);
  FTxtRental := TText.Create(150, 9, 10, 40);
  FTxtSalaries := TText.Create(150, 9, 10, 80);
  FTxtIncome := TText.Create(150, 9, 10, 146);
  FTxtMaintenance := TText.Create(150, 9, 10, 154);
  FLstCrafts := TTextList.Create(288, 32, 10, 48);
  FLstSalaries := TTextList.Create(288, 40, 10, 88);
  FLstMaintenance := TTextList.Create(300, 9, 10, 128);
  FLstTotal := TTextList.Create(100, 9, 205, 150);

  SetInterface('costsInfo');
  Add(FWindow, 'window', 'costsInfo');
  Add(FBtnOk, 'button', 'costsInfo');
  Add(FTxtTitle, 'text1', 'costsInfo');
  Add(FTxtCost, 'text1', 'costsInfo');
  Add(FTxtQuantity, 'text1', 'costsInfo');
  Add(FTxtTotal, 'text1', 'costsInfo');
  Add(FTxtRental, 'text1', 'costsInfo');
  Add(FLstCrafts, 'list', 'costsInfo');
  Add(FTxtSalaries, 'text1', 'costsInfo');
  Add(FLstSalaries, 'list', 'costsInfo');
  Add(FLstMaintenance, 'text1', 'costsInfo');
  Add(FTxtIncome, 'list', 'costsInfo');
  Add(FTxtMaintenance, 'list', 'costsInfo');
  Add(FLstTotal, 'text2', 'costsInfo');
  CenterAllSurfaces;

  FWindow.SetBackground(FGame.GetMod.GetSurface('BACK13.SCR'));
  FBtnOk.SetText(Translate('STR_OK'));
  FBtnOk.OnMouseClick := BtnOkClick;
  FBtnOk.OnKeyboardPress := BtnOkClick;

  FTxtTitle.SetBig;
  FTxtTitle.SetAlign(ALIGN_CENTER);
  FTxtTitle.SetText(Translate('STR_MONTHLY_COSTS'));
  FTxtCost.SetText(Translate('STR_COST_PER_UNIT'));
  FTxtQuantity.SetText(Translate('STR_QUANTITY'));
  FTxtTotal.SetText(Translate('STR_TOTAL'));
  FTxtRental.SetText(Translate('STR_CRAFT_RENTAL'));
  FTxtSalaries.SetText(Translate('STR_SALARIES'));

  FTxtIncome.SetText(Translate('STR_INCOME') + '=' + Unicode.FormatFunding(FGame.GetSavedGame.GetCountryFunding));
  FTxtMaintenance.SetText(Translate('STR_MAINTENANCE') + '=' + Unicode.FormatFunding(FGame.GetSavedGame.GetBaseMaintenance));

  FLstCrafts.SetColumns([125, 70, 44, 50]);
  FLstCrafts.SetDot(True);
  crafts := FGame.GetMod.GetCraftsList;
  for i := 0 to crafts.Count - 1 do
  begin
    craft := FGame.GetMod.GetCraft(crafts[i]);
    if (craft.GetRentCost <> 0) and FGame.GetSavedGame.IsResearched(craft.GetRequirements) then
      FLstCrafts.AddRow([
        Translate(crafts[i]),
        Unicode.FormatFunding(craft.GetRentCost),
        IntToStr(FBase.GetCraftCount(crafts[i])),
        Unicode.FormatFunding(FBase.GetCraftCount(crafts[i]) * craft.GetRentCost)
      ]);
  end;

  FLstSalaries.SetColumns([125, 70, 44, 50]);
  FLstSalaries.SetDot(True);
  soldiers := FGame.GetMod.GetSoldiersList;
  for i := 0 to soldiers.Count - 1 do
  begin
    soldier := FGame.GetMod.GetSoldier(soldiers[i]);
    if (soldier.GetSalaryCost <> 0) and FGame.GetSavedGame.IsResearched(soldier.GetRequirements) then
    begin
      if soldiers.Count = 1 then
        FLstSalaries.AddRow([
          Translate('STR_SOLDIERS'),
          Unicode.FormatFunding(soldier.GetSalaryCost),
          IntToStr(FBase.GetSoldierCount(soldiers[i])),
          Unicode.FormatFunding(FBase.GetSoldierCount(soldiers[i]) * soldier.GetSalaryCost)
        ])
      else
        FLstSalaries.AddRow([
          Translate(soldiers[i]),
          Unicode.FormatFunding(soldier.GetSalaryCost),
          IntToStr(FBase.GetSoldierCount(soldiers[i])),
          Unicode.FormatFunding(FBase.GetSoldierCount(soldiers[i]) * soldier.GetSalaryCost)
        ]);
    end;
  end;
  FLstSalaries.AddRow([
    Translate('STR_ENGINEERS'),
    Unicode.FormatFunding(FGame.GetMod.GetEngineerCost),
    IntToStr(FBase.GetTotalEngineers),
    Unicode.FormatFunding(FBase.GetTotalEngineers * FGame.GetMod.GetEngineerCost)
  ]);
  FLstSalaries.AddRow([
    Translate('STR_SCIENTISTS'),
    Unicode.FormatFunding(FGame.GetMod.GetScientistCost),
    IntToStr(FBase.GetTotalScientists),
    Unicode.FormatFunding(FBase.GetTotalScientists * FGame.GetMod.GetScientistCost)
  ]);

  FLstMaintenance.SetColumns([239, 60]);
  FLstMaintenance.SetDot(True);
  FLstMaintenance.AddRow([
    Translate('STR_BASE_MAINTENANCE'),
    Unicode.TOK_COLOR_FLIP + Unicode.FormatFunding(FBase.GetFacilityMaintenance)
  ]);

  FLstTotal.SetColumns([44, 55]);
  FLstTotal.SetDot(True);
  FLstTotal.AddRow([
    Translate('STR_TOTAL'),
    Unicode.FormatFunding(FBase.GetMonthlyMaintenace)
  ]);
end;

destructor TMonthlyCostsState.Destroy;
begin
  inherited;
end;

procedure TMonthlyCostsState.BtnOkClick(Sender: TObject; Action: TAction);
begin
  FGame.PopState;
end;

end.