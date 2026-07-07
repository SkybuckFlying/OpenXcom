unit LowFuelState;

interface

uses
  System.SysUtils, Engine.State, Engine.Game, Engine.Mod,
  Engine.LocalizedText, Interface.TextButton, Interface.Window,
  Interface.Text, Savegame.Craft, Geoscape.GeoscapeState,
  Engine.Options;

type
  TLowFuelState = class(TState)
  private
    FCraft: TCraft;
    FState: TGeoscapeState;
    FBtnOk, FBtnOk5Secs: TTextButton;
    FWindow: TWindow;
    FTxtTitle, FTxtMessage: TText;
    procedure BtnOkClick(AAction: TAction);
    procedure BtnOk5SecsClick(AAction: TAction);
  public
    constructor Create(ACraft: TCraft; AState: TGeoscapeState);
    destructor Destroy; override;
  end;

implementation

{ TLowFuelState }

constructor TLowFuelState.Create(ACraft: TCraft; AState: TGeoscapeState);
begin
  inherited Create(nil);
  FCraft := ACraft;
  FState := AState;
  FScreen := False;

  FWindow := TWindow.Create(Self, 224, 120, 16, 40, POPUP_BOTH);
  FBtnOk := TTextButton.Create(90, 18, 30, 120);
  FBtnOk5Secs := TTextButton.Create(90, 18, 136, 120);
  FTxtTitle := TText.Create(214, 17, 21, 60);
  FTxtMessage := TText.Create(214, 17, 21, 90);

  SetInterface('lowFuel');

  Add(FWindow, 'window', 'lowFuel');
  Add(FBtnOk, 'button', 'lowFuel');
  Add(FBtnOk5Secs, 'button', 'lowFuel');
  Add(FTxtTitle, 'text', 'lowFuel');
  Add(FTxtMessage, 'text', 'lowFuel');

  CenterAllSurfaces;

  FWindow.SetBackground(Game.Mod.GetSurface('BACK12.SCR'));

  FBtnOk.Text := Tr('STR_OK');
  FBtnOk.OnMouseClick := BtnOkClick;
  FBtnOk.OnKeyboardPress(Options.KeyCancel, BtnOkClick);

  FBtnOk5Secs.Text := Tr('STR_OK_5_SECONDS');
  FBtnOk5Secs.OnMouseClick := BtnOk5SecsClick;
  FBtnOk5Secs.OnKeyboardPress(Options.KeyOk, BtnOk5SecsClick);

  FTxtTitle.Align := ALIGN_CENTER;
  FTxtTitle.Big := True;
  FTxtTitle.Text := FCraft.Name(Game.Language);

  FTxtMessage.Align := ALIGN_CENTER;
  FTxtMessage.Text := Tr('STR_IS_LOW_ON_FUEL_RETURNING_TO_BASE');
end;

destructor TLowFuelState.Destroy;
begin
  inherited;
end;

procedure TLowFuelState.BtnOkClick(AAction: TAction);
begin
  Game.PopState;
end;

procedure TLowFuelState.BtnOk5SecsClick(AAction: TAction);
begin
  FState.TimerReset;
  Game.PopState;
end;

end.