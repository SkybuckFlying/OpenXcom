unit ConfirmNewBaseState;

interface

uses
  Engine.State, Engine.Game, Mod.Mod, Engine.LocalizedText,
  Interface.Window, Interface.Text, Interface.TextButton,
  Savegame.SavedGame, Savegame.Region, Mod.RuleRegion,
  Savegame.Base, Basescape.BaseNameState, Menu.ErrorMessageState,
  Engine.Options, Engine.Unicode, Mod.RuleInterface;

type
  TConfirmNewBaseState = class(TState)
  private
    FBase: TBase;
    FGlobe: TGlobe;
    FWindow: TWindow;
    FTxtCost, FTxtArea: TText;
    FBtnOk, FBtnCancel: TTextButton;
    FCost: Integer;
    procedure BtnOkClick(AAction: TAction);
    procedure BtnCancelClick(AAction: TAction);
  public
    constructor Create(ABase: TBase; AGlobe: TGlobe);
    destructor Destroy; override;
  end;

implementation

uses
  System.SysUtils, System.Classes;

{ TConfirmNewBaseState }

constructor TConfirmNewBaseState.Create(ABase: TBase; AGlobe: TGlobe);
var
  i: Integer;
  area: string;
begin
  inherited Create(nil);
  FBase := ABase;
  FGlobe := AGlobe;
  FCost := 0;

  FScreen := False;

  FWindow := TWindow.Create(Self, 224, 72, 16, 64);
  FBtnOk := TTextButton.Create(54, 12, 68, 104);
  FBtnCancel := TTextButton.Create(54, 12, 138, 104);
  FTxtCost := TText.Create(120, 9, 68, 80);
  FTxtArea := TText.Create(120, 9, 68, 90);

  SetInterface('geoscape');

  Add(FWindow, 'genericWindow', 'geoscape');
  Add(FBtnOk, 'genericButton2', 'geoscape');
  Add(FBtnCancel, 'genericButton2', 'geoscape');
  Add(FTxtCost, 'genericText', 'geoscape');
  Add(FTxtArea, 'genericText', 'geoscape');

  CenterAllSurfaces;

  FWindow.SetBackground(Game.Mod.GetSurface('BACK01.SCR'));

  FBtnOk.Text := Tr('STR_OK');
  FBtnOk.OnMouseClick := BtnOkClick;
  FBtnOk.OnKeyboardPress(Options.keyOk, BtnOkClick);

  FBtnCancel.Text := Tr('STR_CANCEL_UC');
  FBtnCancel.OnMouseClick := BtnCancelClick;
  FBtnCancel.OnKeyboardPress(Options.keyCancel, BtnCancelClick);

  area := '';
  for i := 0 to Game.SavedGame.Regions.Count - 1 do
  begin
    if Game.SavedGame.Regions[i].Rules.InsideRegion(FBase.Longitude, FBase.Latitude) then
    begin
      FCost := Game.SavedGame.Regions[i].Rules.BaseCost;
      area := Tr(Game.SavedGame.Regions[i].Rules.TypeName);
      Break;
    end;
  end;

  FTxtCost.Text := Tr('STR_COST_').Arg(Unicode.FormatFunding(FCost));
  FTxtArea.Text := Tr('STR_AREA_').Arg(area);
end;

destructor TConfirmNewBaseState.Destroy;
begin
  inherited;
end;

procedure TConfirmNewBaseState.BtnOkClick(AAction: TAction);
begin
  if Game.SavedGame.Funds >= FCost then
  begin
    Game.SavedGame.Funds := Game.SavedGame.Funds - FCost;
    Game.SavedGame.Bases.Add(FBase);
    Game.PushState(TBaseNameState.Create(FBase, FGlobe, False));
  end
  else
  begin
    Game.PushState(TErrorMessageState.Create(
      Tr('STR_NOT_ENOUGH_MONEY'),
      Palette,
      Game.Mod.Interface('geoscape').GetElement('genericWindow').Color,
      'BACK01.SCR',
      Game.Mod.Interface('geoscape').GetElement('palette').Color
    ));
  end;
end;

procedure TConfirmNewBaseState.BtnCancelClick(AAction: TAction);
begin
  FGlobe.OnMouseOver(nil);
  Game.PopState;
end;

end.