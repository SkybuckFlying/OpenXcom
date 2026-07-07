unit PsiTrainingState;

interface

uses
  System.SysUtils, System.Classes,
  Engine.State, Engine.Game, Engine.Action, Engine.Mod,
  Engine.LocalizedText, Interface.TextButton, Interface.Window,
  Interface.Text, Savegame.SavedGame, Savegame.Base,
  Geoscape.AllocatePsiTrainingState, Engine.Options;

type
  TPsiTrainingState = class(TState)
  private
    FBtnOk: TTextButton;
    FWindow: TWindow;
    FTxtTitle: TText;
    FBtnBases: TList;
    FBases: TList;
    procedure BtnOkClick(AAction: TAction);
    procedure BtnBaseXClick(AAction: TAction);
  public
    constructor Create;
    destructor Destroy; override;
  end;

implementation

{ TPsiTrainingState }

constructor TPsiTrainingState.Create;
var
  b: TBase;
  btn: TTextButton;
  buttons: Integer;
begin
  inherited Create(nil);
  FBtnBases := TList.Create;
  FBases := TList.Create;

  FWindow := TWindow.Create(Self, 320, 200, 0, 0);
  FTxtTitle := TText.Create(300, 17, 10, 16);
  FBtnOk := TTextButton.Create(160, 14, 80, 174);

  SetInterface('psiTraining');

  Add(FWindow, 'window', 'psiTraining');
  Add(FBtnOk, 'button2', 'psiTraining');
  Add(FTxtTitle, 'text', 'psiTraining');

  FWindow.SetBackground(Game.Mod.GetSurface('BACK01.SCR'));

  FBtnOk.Text := Tr('STR_OK');
  FBtnOk.OnMouseClick := BtnOkClick;
  FBtnOk.OnKeyboardPress(Options.KeyCancel, BtnOkClick);

  FTxtTitle.Big := True;
  FTxtTitle.Align := ALIGN_CENTER;
  FTxtTitle.Text := Tr('STR_PSIONIC_TRAINING');

  buttons := 0;
  for b in Game.SavedGame.Bases do
  begin
    if b.AvailablePsiLabs > 0 then
    begin
      btn := TTextButton.Create(160, 14, 80, 40 + 16 * buttons);
      btn.OnMouseClick := BtnBaseXClick;
      btn.Text := b.Name;
      Add(btn, 'button1', 'psiTraining');
      FBases.Add(b);
      FBtnBases.Add(btn);
      Inc(buttons);
      if buttons >= 8 then Break;
    end;
  end;

  CenterAllSurfaces;
end;

destructor TPsiTrainingState.Destroy;
begin
  FBtnBases.Free;
  FBases.Free;
  inherited;
end;

procedure TPsiTrainingState.BtnOkClick(AAction: TAction);
begin
  Game.PopState;
end;

procedure TPsiTrainingState.BtnBaseXClick(AAction: TAction);
var
  i: Integer;
begin
  for i := 0 to FBtnBases.Count - 1 do
    if AAction.Sender = FBtnBases[i] then
    begin
      Game.PushState(TAllocatePsiTrainingState.Create(TBase(FBases[i])));
      Break;
    end;
end;

end.