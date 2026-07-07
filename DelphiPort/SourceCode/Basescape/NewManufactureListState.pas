unit NewManufactureListState;

interface

uses
  Classes, SysUtils, Generics.Collections,
  Engine.State, Engine.Game, Engine.Action,
  Mod.Mod, Engine.LocalizedText, Engine.Options,
  Interface.Window, Interface.TextButton, Interface.Text, Interface.TextList,
  Interface.ComboBox,
  Savegame.Base, Savegame.SavedGame, Mod.RuleManufacture,
  ManufactureStartState;

type
  TNewManufactureListState = class(TState)
  private
    FBase: TBase;
    FBtnOk: TTextButton;
    FWindow: TWindow;
    FTxtTitle, FTxtItem, FTxtCategory: TText;
    FLstManufacture: TTextList;
    FCbxCategory: TComboBox;
    FPossibleProductions: TList<TRuleManufacture>;
    FCatStrings: TStringList;
    FDisplayedStrings: TStringList;

    procedure FillProductionList;
    procedure CbxCategoryChange(Sender: TObject; Action: TAction);
  public
    constructor Create(AOwner: TComponent; Base: TBase);
    destructor Destroy; override;
    procedure Init; override;
    procedure BtnOkClick(Sender: TObject; Action: TAction);
    procedure LstProdClick(Sender: TObject; Action: TAction);
  end;

implementation

constructor TNewManufactureListState.Create(AOwner: TComponent; Base: TBase);
var
  i: Integer;
  rule: TRuleManufacture;
begin
  inherited Create(AOwner);
  FBase := Base;
  Screen := False;

  FWindow := TWindow.Create(Self, 320, 156, 0, 22, POPUP_BOTH);
  FBtnOk := TTextButton.Create(304, 16, 8, 154);
  FTxtTitle := TText.Create(320, 17, 0, 30);
  FTxtItem := TText.Create(156, 9, 10, 62);
  FTxtCategory := TText.Create(130, 9, 166, 62);
  FLstManufacture := TTextList.Create(288, 80, 8, 70);
  FCbxCategory := TComboBox.Create(Self, 146, 16, 166, 46);

  SetInterface('selectNewManufacture');
  Add(FWindow, 'window', 'selectNewManufacture');
  Add(FBtnOk, 'button', 'selectNewManufacture');
  Add(FTxtTitle, 'text', 'selectNewManufacture');
  Add(FTxtItem, 'text', 'selectNewManufacture');
  Add(FTxtCategory, 'text', 'selectNewManufacture');
  Add(FLstManufacture, 'list', 'selectNewManufacture');
  Add(FCbxCategory, 'catBox', 'selectNewManufacture');
  CenterAllSurfaces;

  FWindow.SetBackground(FGame.GetMod.GetSurface('BACK17.SCR'));
  FTxtTitle.SetText(Translate('STR_PRODUCTION_ITEMS'));
  FTxtTitle.SetBig;
  FTxtTitle.SetAlign(ALIGN_CENTER);
  FTxtItem.SetText(Translate('STR_ITEM'));
  FTxtCategory.SetText(Translate('STR_CATEGORY'));

  FLstManufacture.SetColumns([156, 130]);
  FLstManufacture.SetSelectable(True);
  FLstManufacture.SetBackground(FWindow);
  FLstManufacture.SetMargin(2);
  FLstManufacture.OnMouseClick := LstProdClick;

  FBtnOk.SetText(Translate('STR_OK'));
  FBtnOk.OnMouseClick := BtnOkClick;
  FBtnOk.OnKeyboardPress := BtnOkClick;

  FPossibleProductions := TList<TRuleManufacture>.Create;
  FGame.GetSavedGame.GetAvailableProductions(FPossibleProductions, FGame.GetMod, FBase);

  FCatStrings := TStringList.Create;
  FCatStrings.Add('STR_ALL_ITEMS');
  for rule in FPossibleProductions do
    if FCatStrings.IndexOf(rule.GetCategory) = -1 then
      FCatStrings.Add(rule.GetCategory);

  FCbxCategory.SetOptions(FCatStrings, True);
  FCbxCategory.OnChange := CbxCategoryChange;
end;

destructor TNewManufactureListState.Destroy;
begin
  FPossibleProductions.Free;
  FCatStrings.Free;
  FDisplayedStrings.Free;
  inherited;
end;

procedure TNewManufactureListState.Init;
begin
  inherited;
  FillProductionList;
end;

procedure TNewManufactureListState.BtnOkClick(Sender: TObject; Action: TAction);
begin
  FGame.PopState;
end;

procedure TNewManufactureListState.LstProdClick(Sender: TObject; Action: TAction);
var
  rule: TRuleManufacture;
  name: string;
begin
  name := FDisplayedStrings[FLstManufacture.GetSelectedRow];
  for rule in FPossibleProductions do
    if rule.GetName = name then
    begin
      FGame.PushState(TManufactureStartState.Create(Self, FBase, rule));
      Break;
    end;
end;

procedure TNewManufactureListState.CbxCategoryChange(Sender: TObject; Action: TAction);
begin
  FillProductionList;
end;

procedure TNewManufactureListState.FillProductionList;
var
  rule: TRuleManufacture;
  cat: string;
begin
  FLstManufacture.ClearList;
  FDisplayedStrings := TStringList.Create;
  FGame.GetSavedGame.GetAvailableProductions(FPossibleProductions, FGame.GetMod, FBase);
  cat := FCatStrings[FCbxCategory.GetSelected];
  for rule in FPossibleProductions do
  begin
    if (rule.GetCategory = cat) or (cat = 'STR_ALL_ITEMS') then
    begin
      FLstManufacture.AddRow([Translate(rule.GetName), Translate(rule.GetCategory)]);
      FDisplayedStrings.Add(rule.GetName);
    end;
  end;
end;

end.