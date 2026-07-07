unit ProductionCompleteState;

interface

uses
  System.SysUtils, System.Classes,
  Engine.State, Engine.Game, Engine.Mod, Engine.LocalizedText,
  Interface.TextButton, Interface.Window, Interface.Text,
  Savegame.Base, Geoscape.GeoscapeState, Engine.Options,
  Basescape.BasescapeState, Basescape.ManufactureState,
  Savegame.Production;

type
  TProductionCompleteState = class(TState)
  private
    FBase: TBase;
    FState: TGeoscapeState;
    FBtnOk, FBtnGotoBase: TTextButton;
    FWindow: TWindow;
    FTxtMessage: TText;
    FEndType: TProductionProgress;
    procedure BtnOkClick(AAction: TAction);
    procedure BtnGotoBaseClick(AAction: TAction);
  public
    constructor Create(ABase: TBase; const AItem: string; AState: TGeoscapeState; AEndType: TProductionProgress = PROGRESS_COMPLETE);
    destructor Destroy; override;
  end;

implementation

{ TProductionCompleteState }

constructor TProductionCompleteState.Create(ABase: TBase; const AItem: string; AState: TGeoscapeState; AEndType: TProductionProgress);
var
  s: string;
begin
  inherited Create(nil);
  FBase := ABase;
  FState := AState;
  FEndType := AEndType;
  FScreen := False;

  FWindow := TWindow.Create(Self, 256, 160, 32, 20, POPUP_BOTH);
  FBtnOk := TTextButton.Create(118, 18, 40, 154);
  FBtnGotoBase := TTextButton.Create(118, 18, 162, 154);
  FTxtMessage := TText.Create(246, 110, 37, 35);

  SetInterface('geoManufactureComplete');

  Add(FWindow, 'window', 'geoManufactureComplete');
  Add(FBtnOk, 'button', 'geoManufactureComplete');
  Add(FBtnGotoBase, 'button', 'geoManufactureComplete');
  Add(FTxtMessage, 'text1', 'geoManufactureComplete');

  CenterAllSurfaces;

  FWindow.SetBackground(Game.Mod.GetSurface('BACK17.SCR'));

  FBtnOk.Text := Tr('STR_OK');
  FBtnOk.OnMouseClick := BtnOkClick;
  FBtnOk.OnKeyboardPress(Options.KeyCancel, BtnOkClick);

  if FEndType <> PROGRESS_CONSTRUCTION then
    FBtnGotoBase.Text := Tr('STR_ALLOCATE_MANUFACTURE')
  else
    FBtnGotoBase.Text := Tr('STR_GO_TO_BASE');
  FBtnGotoBase.OnMouseClick := BtnGotoBaseClick;

  FTxtMessage.Align := ALIGN_CENTER;
  FTxtMessage.VerticalAlign := ALIGN_MIDDLE;
  FTxtMessage.Big := True;
  FTxtMessage.WordWrap := True;

  case FEndType of
    PROGRESS_CONSTRUCTION:
      s := Tr('STR_CONSTRUCTION_OF_FACILITY_AT_BASE_IS_COMPLETE').Arg(AItem).Arg(FBase.Name);
    PROGRESS_COMPLETE:
      s := Tr('STR_PRODUCTION_OF_ITEM_AT_BASE_IS_COMPLETE').Arg(AItem).Arg(FBase.Name);
    PROGRESS_NOT_ENOUGH_MONEY:
      s := Tr('STR_NOT_ENOUGH_MONEY_TO_PRODUCE_ITEM_AT_BASE').Arg(AItem).Arg(FBase.Name);
    PROGRESS_NOT_ENOUGH_MATERIALS:
      s := Tr('STR_NOT_ENOUGH_SPECIAL_MATERIALS_TO_PRODUCE_ITEM_AT_BASE').Arg(AItem).Arg(FBase.Name);
  else
    s := AItem; // fallback
  end;
  FTxtMessage.Text := s;
end;

destructor TProductionCompleteState.Destroy;
begin
  inherited;
end;

procedure TProductionCompleteState.BtnOkClick(AAction: TAction);
begin
  Game.PopState;
end;

procedure TProductionCompleteState.BtnGotoBaseClick(AAction: TAction);
begin
  FState.TimerReset;
  Game.PopState;
  if FEndType <> PROGRESS_CONSTRUCTION then
    Game.PushState(TManufactureState.Create(FBase))
  else
    Game.PushState(TBasescapeState.Create(FBase, FState.Globe));
end;

end.