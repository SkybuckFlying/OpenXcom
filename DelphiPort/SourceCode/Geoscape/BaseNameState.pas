unit BaseNameState;

interface

uses
  Engine.State, Engine.Game, Engine.Action, Mod.Mod,
  Engine.LocalizedText, Interface.Window, Interface.Text,
  Interface.TextEdit, Interface.TextButton,
  Savegame.Base, Basescape.PlaceLiftState,
  Engine.Options;

type
  TBaseNameState = class(TState)
  private
    FBase: TBase;
    FGlobe: TGlobe;
    FWindow: TWindow;
    FTxtTitle: TText;
    FEdtName: TTextEdit;
    FBtnOk: TTextButton;
    FFirst: Boolean;
    procedure BtnOkClick(AAction: TAction);
    procedure EdtNameChange(AAction: TAction);
  public
    constructor Create(ABase: TBase; AGlobe: TGlobe; AFirst: Boolean);
    destructor Destroy; override;
  end;

implementation

uses
  System.SysUtils, System.Classes;

{ TBaseNameState }

constructor TBaseNameState.Create(ABase: TBase; AGlobe: TGlobe; AFirst: Boolean);
begin
  inherited Create(nil);
  FBase := ABase;
  FGlobe := AGlobe;
  FFirst := AFirst;

  FGlobe.OnMouseOver(nil);

  FScreen := False;

  FWindow := TWindow.Create(Self, 192, 80, 32, 60, POPUP_BOTH);
  FBtnOk := TTextButton.Create(162, 12, 47, 118);
  FTxtTitle := TText.Create(182, 17, 37, 70);
  FEdtName := TTextEdit.Create(Self, 127, 16, 59, 94);

  SetInterface('baseNaming');

  Add(FWindow, 'window', 'baseNaming');
  Add(FBtnOk, 'button', 'baseNaming');
  Add(FTxtTitle, 'text', 'baseNaming');
  Add(FEdtName, 'text', 'baseNaming');

  CenterAllSurfaces;

  FWindow.SetBackground(Game.Mod.GetSurface('BACK01.SCR'));

  FBtnOk.Text := Tr('STR_OK');
  FBtnOk.OnMouseClick := BtnOkClick;
  FBtnOk.OnKeyboardPress(Options.keyCancel, BtnOkClick);
  FBtnOk.Visible := False; // hidden until text entered

  FTxtTitle.Align := ALIGN_CENTER;
  FTxtTitle.Big := True;
  FTxtTitle.Text := Tr('STR_BASE_NAME');

  FEdtName.Big := True;
  FEdtName.SetFocus(True, False);
  FEdtName.OnChange := EdtNameChange;
end;

destructor TBaseNameState.Destroy;
begin
  inherited;
end;

procedure TBaseNameState.EdtNameChange(AAction: TAction);
begin
  FBase.Name := FEdtName.Text;
  if (AAction.Details.key.keysym.sym = SDLK_RETURN) or
     (AAction.Details.key.keysym.sym = SDLK_KP_ENTER) then
  begin
    if not FEdtName.Text.IsEmpty then
      BtnOkClick(AAction);
  end
  else
    FBtnOk.Visible := not FEdtName.Text.IsEmpty;
end;

procedure TBaseNameState.BtnOkClick(AAction: TAction);
begin
  if FEdtName.Text.IsEmpty then Exit;

  Game.PopState; // closes this state
  Game.PopState; // closes previous state (BuildNewBaseState or similar)

  if not FFirst or Options.CustomInitialBase then
  begin
    if not FFirst then
      Game.PopState; // pop another state if not first base
    Game.PushState(TPlaceLiftState.Create(FBase, FGlobe, FFirst));
  end;
end;

end.