unit DogfightErrorState;

interface

uses
  Engine.State, Engine.Game, Mod.Mod, Engine.LocalizedText,
  Interface.TextButton, Interface.Window, Interface.Text,
  Savegame.Craft, Engine.Options;

type
  TDogfightErrorState = class(TState)
  private
    FCraft: TCraft;
    FBtnIntercept, FBtnBase: TTextButton;
    FWindow: TWindow;
    FTxtCraft, FTxtMessage: TText;
    procedure BtnInterceptClick(AAction: TAction);
    procedure BtnBaseClick(AAction: TAction);
  public
    constructor Create(ACraft: TCraft; const AMsg: string);
    destructor Destroy; override;
  end;

implementation

uses
  System.SysUtils;

{ TDogfightErrorState }

constructor TDogfightErrorState.Create(ACraft: TCraft; const AMsg: string);
begin
  inherited Create(nil);
  FCraft := ACraft;
  FScreen := False;

  FWindow := TWindow.Create(Self, 208, 120, 24, 48, POPUP_BOTH);
  FBtnIntercept := TTextButton.Create(180, 12, 38, 128);
  FBtnBase := TTextButton.Create(180, 12, 38, 144);
  FTxtCraft := TText.Create(198, 16, 29, 63);
  FTxtMessage := TText.Create(198, 20, 29, 94);

  SetInterface('dogfightInfo');

  Add(FWindow, 'window', 'dogfightInfo');
  Add(FBtnIntercept, 'button', 'dogfightInfo');
  Add(FBtnBase, 'button', 'dogfightInfo');
  Add(FTxtCraft, 'text', 'dogfightInfo');
  Add(FTxtMessage, 'text', 'dogfightInfo');

  CenterAllSurfaces;

  FWindow.SetBackground(Game.Mod.GetSurface('BACK15.SCR'));

  FBtnIntercept.Text := Tr('STR_CONTINUE_INTERCEPTION_PURSUIT');
  FBtnIntercept.OnMouseClick := BtnInterceptClick;
  FBtnIntercept.OnKeyboardPress(Options.keyCancel, BtnInterceptClick);

  FBtnBase.Text := Tr('STR_RETURN_TO_BASE');
  FBtnBase.OnMouseClick := BtnBaseClick;
  FBtnBase.OnKeyboardPress(Options.keyOk, BtnBaseClick);

  FTxtCraft.Align := ALIGN_CENTER;
  FTxtCraft.Big := True;
  FTxtCraft.Text := FCraft.Name(Game.Language);

  FTxtMessage.Align := ALIGN_CENTER;
  FTxtMessage.WordWrap := True;
  FTxtMessage.Text := AMsg;
end;

destructor TDogfightErrorState.Destroy;
begin
  inherited;
end;

procedure TDogfightErrorState.BtnInterceptClick(AAction: TAction);
begin
  Game.PopState;
end;

procedure TDogfightErrorState.BtnBaseClick(AAction: TAction);
begin
  FCraft.ReturnToBase;
  Game.PopState;
end;

end.