unit NewPossibleManufactureState;

interface

uses
  System.SysUtils, System.Classes,
  Engine.State, Engine.Game, Engine.LocalizedText, Engine.Mod,
  Interface.TextButton, Interface.Window, Interface.Text,
  Interface.TextList, Mod.RuleManufacture,
  Basescape.ManufactureState, Savegame.Base, Engine.Options;

type
  TNewPossibleManufactureState = class(TState)
  private
    FWindow: TWindow;
    FTxtTitle: TText;
    FLstPossibilities: TTextList;
    FBtnManufacture, FBtnOk: TTextButton;
    FBase: TBase;
    procedure BtnOkClick(AAction: TAction);
    procedure BtnManufactureClick(AAction: TAction);
  public
    constructor Create(ABase: TBase; const APossibilities: TList);
  end;

implementation

{ TNewPossibleManufactureState }

constructor TNewPossibleManufactureState.Create(ABase: TBase; const APossibilities: TList);
var
  i: Integer;
  rule: TRuleManufacture;
begin
  inherited Create(nil);
  FBase := ABase;
  FScreen := False;

  FWindow := TWindow.Create(Self, 288, 180, 16, 10);
  FBtnOk := TTextButton.Create(160, 14, 80, 149);
  FBtnManufacture := TTextButton.Create(160, 14, 80, 165);
  FTxtTitle := TText.Create(288, 40, 16, 20);
  FLstPossibilities := TTextList.Create(250, 80, 35, 50);

  SetInterface('geoManufacture');

  Add(FWindow, 'window', 'geoManufacture');
  Add(FBtnOk, 'button', 'geoManufacture');
  Add(FBtnManufacture, 'button', 'geoManufacture');
  Add(FTxtTitle, 'text1', 'geoManufacture');
  Add(FLstPossibilities, 'text2', 'geoManufacture');

  CenterAllSurfaces;

  FWindow.SetBackground(Game.Mod.GetSurface('BACK17.SCR'));

  FBtnOk.Text := Tr('STR_OK');
  FBtnOk.OnMouseClick := BtnOkClick;
  FBtnOk.OnKeyboardPress(Options.KeyCancel, BtnOkClick);

  FBtnManufacture.Text := Tr('STR_ALLOCATE_MANUFACTURE');
  FBtnManufacture.OnMouseClick := BtnManufactureClick;
  FBtnManufacture.OnKeyboardPress(Options.KeyOk, BtnManufactureClick);

  FTxtTitle.Big := True;
  FTxtTitle.Align := ALIGN_CENTER;
  FTxtTitle.Text := Tr('STR_WE_CAN_NOW_PRODUCE');

  FLstPossibilities.SetColumns(1, 250);
  FLstPossibilities.Big := True;
  FLstPossibilities.Align := ALIGN_CENTER;
  FLstPossibilities.Scrolling := True;
  FLstPossibilities.ScrollAmount := 0;

  for i := 0 to APossibilities.Count - 1 do
  begin
    rule := TRuleManufacture(APossibilities[i]);
    FLstPossibilities.AddRow(1, [Tr(rule.Name)]);
  end;
end;

procedure TNewPossibleManufactureState.BtnOkClick(AAction: TAction);
begin
  Game.PopState;
end;

procedure TNewPossibleManufactureState.BtnManufactureClick(AAction: TAction);
begin
  Game.PopState;
  Game.PushState(TManufactureState.Create(FBase));
end;

end.