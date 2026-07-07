{----------------------------------------------------------------------------}
{ Unit: UfopaediaSelectState                                                 }
{ State showing a list of articles for a section.                            }
{----------------------------------------------------------------------------}
unit UfopaediaSelectState;

interface

uses
  Classes, SysUtils,
  Engine.State, Engine.Game, Engine.Action, Engine.Options, Engine.LocalizedText,
  Interface.Window, Interface.Text, Interface.TextButton, Interface.TextList,
  Mod.Mod, Mod.ArticleDefinition, Ufopaedia;

type
  TUfopaediaSelectState = class(TState)
  private
    FSection: string;
    FWindow: TWindow;
    FTxtTitle: TText;
    FBtnOk: TTextButton;
    FLstSelection: TTextList;
    FArticleList: TArticleDefinitionList;
    procedure BtnOkClick(Action: TAction);
    procedure LstSelectionClick(Action: TAction);
    procedure LoadSelectionList;
  public
    constructor Create(const section: string);
    destructor Destroy; override;
    procedure Init; override;
  end;

implementation

{ TUfopaediaSelectState }

constructor TUfopaediaSelectState.Create(const section: string);
begin
  inherited Create;
  FSection := section;
  FScreen := False;

  FWindow := TWindow.Create(Self, 256, 180, 32, 10, POPUP_NONE);
  FTxtTitle := TText.Create(224, 17, 48, 26);
  FBtnOk := TTextButton.Create(224, 16, 48, 166);
  FLstSelection := TTextList.Create(224, 104, 40, 50);

  SetInterface('ufopaedia');

  Add(FWindow, 'window', 'ufopaedia');
  Add(FTxtTitle, 'text', 'ufopaedia');
  Add(FBtnOk, 'button2', 'ufopaedia');
  Add(FLstSelection, 'list', 'ufopaedia');

  CenterAllSurfaces;

  FWindow.Background := Game.Mod.GetSurface('BACK01.SCR');

  FTxtTitle.Big := True;
  FTxtTitle.Align := ALIGN_CENTER;
  FTxtTitle.Text := tr('STR_SELECT_ITEM');

  FBtnOk.Text := tr('STR_OK');
  FBtnOk.OnMouseClick := BtnOkClick;
  FBtnOk.OnKeyboardPress := BtnOkClick;
  FBtnOk.KeyboardPressKey := Options.KeyCancel;

  FLstSelection.Columns := [206];
  FLstSelection.Selectable := True;
  FLstSelection.Background := FWindow;
  FLstSelection.Margin := 18;
  FLstSelection.Align := ALIGN_CENTER;
  FLstSelection.OnMouseClick := LstSelectionClick;

  LoadSelectionList;
end;

destructor TUfopaediaSelectState.Destroy;
begin
  FWindow.Free;
  FTxtTitle.Free;
  FBtnOk.Free;
  FLstSelection.Free;
  FArticleList.Free;
  inherited;
end;

procedure TUfopaediaSelectState.Init;
begin
  inherited;
end;

procedure TUfopaediaSelectState.BtnOkClick(Action: TAction);
begin
  Game.PopState;
end;

procedure TUfopaediaSelectState.LstSelectionClick(Action: TAction);
begin
  TUfopaedia.OpenArticle(Game, FArticleList[FLstSelection.SelectedRow]);
end;

procedure TUfopaediaSelectState.LoadSelectionList;
var
  a: TArticleDefinition;
begin
  FArticleList := TArticleDefinitionList.Create;
  TUfopaedia.List(Game.SavedGame, Game.Mod, FSection, FArticleList);
  for a in FArticleList do
    FLstSelection.AddRow([tr(a.Title)]);
end;

end.