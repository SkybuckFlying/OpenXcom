unit TargetInfoState;

interface

uses
  System.SysUtils,
  Engine.State, Engine.Game, Engine.Mod, Engine.LocalizedText,
  Interface.TextButton, Interface.Window, Interface.Text,
  Interface.TextEdit, Savegame.MovingTarget, Engine.Options,
  Geoscape.InterceptState, Engine.Action;

type
  TTargetInfoState = class(TState)
  private
    FTarget: TTarget;
    FGlobe: TGlobe;
    FBtnIntercept, FBtnOk: TTextButton;
    FWindow: TWindow;
    FEdtTitle: TTextEdit;
    FTxtTargetted, FTxtFollowers: TText;
    procedure BtnInterceptClick(AAction: TAction);
    procedure BtnOkClick(AAction: TAction);
    procedure EdtTitleChange(AAction: TAction);
  public
    constructor Create(ATarget: TTarget; AGlobe: TGlobe);
    destructor Destroy; override;
  end;

implementation

{ TTargetInfoState }

constructor TTargetInfoState.Create(ATarget: TTarget; AGlobe: TGlobe);
var
  ss: string;
  i: Integer;
begin
  inherited Create(nil);
  FTarget := ATarget;
  FGlobe := AGlobe;
  FScreen := False;

  FWindow := TWindow.Create(Self, 192, 120, 32, 40, POPUP_BOTH);
  FBtnIntercept := TTextButton.Create(160, 12, 48, 124);
  FBtnOk := TTextButton.Create(160, 12, 48, 140);
  FEdtTitle := TTextEdit.Create(Self, 182, 32, 37, 46);
  FTxtTargetted := TText.Create(182, 9, 37, 78);
  FTxtFollowers := TText.Create(182, 40, 37, 88);

  SetInterface('targetInfo');

  Add(FWindow, 'window', 'targetInfo');
  Add(FBtnIntercept, 'button', 'targetInfo');
  Add(FBtnOk, 'button', 'targetInfo');
  Add(FEdtTitle, 'text2', 'targetInfo');
  Add(FTxtTargetted, 'text1', 'targetInfo');
  Add(FTxtFollowers, 'text1', 'targetInfo');

  CenterAllSurfaces;

  FWindow.SetBackground(Game.Mod.GetSurface('BACK01.SCR'));

  FBtnIntercept.Text := Tr('STR_INTERCEPT');
  FBtnIntercept.OnMouseClick := BtnInterceptClick;

  FBtnOk.Text := Tr('STR_OK');
  FBtnOk.OnMouseClick := BtnOkClick;
  FBtnOk.OnKeyboardPress(Options.KeyCancel, BtnOkClick);

  FEdtTitle.Big := True;
  FEdtTitle.Align := ALIGN_CENTER;
  FEdtTitle.VerticalAlign := ALIGN_MIDDLE;
  FEdtTitle.WordWrap := True;
  FEdtTitle.Text := FTarget.Name(Game.Language);
  FEdtTitle.OnChange := EdtTitleChange;

  FTxtTargetted.Align := ALIGN_CENTER;
  FTxtTargetted.Text := Tr('STR_TARGETTED_BY');

  FTxtFollowers.Align := ALIGN_CENTER;
  ss := '';
  for i := 0 to FTarget.Followers.Count - 1 do
    ss := ss + TMovingTarget(FTarget.Followers[i]).Name(Game.Language) + #13#10;
  FTxtFollowers.Text := ss;
end;

destructor TTargetInfoState.Destroy;
begin
  inherited;
end;

procedure TTargetInfoState.BtnInterceptClick(AAction: TAction);
begin
  Game.PushState(TInterceptState.Create(FGlobe, nil, FTarget));
end;

procedure TTargetInfoState.BtnOkClick(AAction: TAction);
begin
  Game.PopState;
end;

procedure TTargetInfoState.EdtTitleChange(AAction: TAction);
begin
  if FEdtTitle.Text = FTarget.DefaultName(Game.Language) then
    FTarget.Name := ''
  else
    FTarget.Name := FEdtTitle.Text;
  if (AAction.Details.key.keysym.sym = SDLK_RETURN) or
     (AAction.Details.key.keysym.sym = SDLK_KP_ENTER) then
    FEdtTitle.Text := FTarget.Name(Game.Language);
end;

end.