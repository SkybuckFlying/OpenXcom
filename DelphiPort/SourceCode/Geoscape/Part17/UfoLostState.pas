unit UfoLostState;

interface

uses
  System.SysUtils,
  Engine.State, Engine.Game, Engine.Mod, Engine.LocalizedText,
  Interface.TextButton, Interface.Window, Interface.Text,
  Engine.Options;

type
  TUfoLostState = class(TState)
  private
    FBtnOk: TTextButton;
    FWindow: TWindow;
    FTxtTitle: TText;
    FId: string;
    procedure BtnOkClick(AAction: TAction);
  public
    constructor Create(const AId: string);
    destructor Destroy; override;
  end;

implementation

{ TUfoLostState }

constructor TUfoLostState.Create(const AId: string);
begin
  inherited Create(nil);
  FId := AId;
  FScreen := False;

  FWindow := TWindow.Create(Self, 192, 104, 32, 48, POPUP_BOTH);
  FBtnOk := TTextButton.Create(60, 12, 98, 112);
  FTxtTitle := TText.Create(160, 32, 48, 72);

  SetInterface('UFOLost');

  Add(FWindow, 'window', 'UFOLost');
  Add(FBtnOk, 'button', 'UFOLost');
  Add(FTxtTitle, 'text', 'UFOLost');

  CenterAllSurfaces;

  FWindow.SetBackground(Game.Mod.GetSurface('BACK15.SCR'));

  FBtnOk.Text := Tr('STR_OK');
  FBtnOk.OnMouseClick := BtnOkClick;
  FBtnOk.OnKeyboardPress(Options.KeyOk, BtnOkClick);
  FBtnOk.OnKeyboardPress(Options.KeyCancel, BtnOkClick);

  FTxtTitle.Big := True;
  FTxtTitle.Align := ALIGN_CENTER;
  FTxtTitle.Text := FId + #13#10 + Tr('STR_TRACKING_LOST');
end;

destructor TUfoLostState.Destroy;
begin
  inherited;
end;

procedure TUfoLostState.BtnOkClick(AAction: TAction);
begin
  Game.PopState;
end;

end.