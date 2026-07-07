unit ResearchRequiredState;

interface

uses
  System.SysUtils,
  Engine.State, Engine.Game, Engine.LocalizedText, Engine.Mod,
  Interface.TextButton, Interface.Window, Interface.Text,
  Mod.RuleItem, Engine.Options;

type
  TResearchRequiredState = class(TState)
  private
    FWindow: TWindow;
    FTxtTitle: TText;
    FBtnOk: TTextButton;
    procedure BtnOkClick(AAction: TAction);
  public
    constructor Create(AItem: TRuleItem);
  end;

implementation

{ TResearchRequiredState }

constructor TResearchRequiredState.Create(AItem: TRuleItem);
var
  weapon, clip: string;
begin
  inherited Create(nil);
  FScreen := False;

  weapon := AItem.TypeName;
  clip := AItem.CompatibleAmmo[0];

  FWindow := TWindow.Create(Self, 288, 180, 16, 10);
  FBtnOk := TTextButton.Create(160, 18, 80, 150);
  FTxtTitle := TText.Create(288, 80, 16, 50);

  SetInterface('geoResearchRequired');

  Add(FWindow, 'window', 'geoResearchRequired');
  Add(FBtnOk, 'button', 'geoResearchRequired');
  Add(FTxtTitle, 'text1', 'geoResearchRequired');

  CenterAllSurfaces;

  FWindow.SetBackground(Game.Mod.GetSurface('BACK05.SCR'));

  FBtnOk.Text := Tr('STR_OK');
  FBtnOk.OnMouseClick := BtnOkClick;
  FBtnOk.OnKeyboardPress(Options.KeyCancel, BtnOkClick);
  FBtnOk.OnKeyboardPress(Options.KeyOk, BtnOkClick);

  FTxtTitle.Big := True;
  FTxtTitle.Align := ALIGN_CENTER;
  FTxtTitle.VerticalAlign := ALIGN_MIDDLE;
  FTxtTitle.Text := Tr('STR_YOU_NEED_TO_RESEARCH_ITEM_TO_PRODUCE_ITEM')
                    .Arg(Tr(clip))
                    .Arg(Tr(weapon));
end;

procedure TResearchRequiredState.BtnOkClick(AAction: TAction);
begin
  Game.PopState;
end;

end.