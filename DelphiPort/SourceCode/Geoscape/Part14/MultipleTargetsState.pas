unit MultipleTargetsState;

interface

uses
  System.SysUtils, System.Classes,
  Engine.State, Engine.Game, Engine.Mod, Engine.LocalizedText,
  Interface.TextButton, Interface.Window, Savegame.Target,
  Savegame.Base, Savegame.Craft, Savegame.Ufo,
  Geoscape.GeoscapeState, Geoscape.ConfirmDestinationState,
  Geoscape.InterceptState, Geoscape.UfoDetectedState,
  Geoscape.GeoscapeCraftState, Geoscape.TargetInfoState,
  Engine.Options, Engine.Action;

type
  TMultipleTargetsState = class(TState)
  private
    const MARGIN = 10;
    const SPACING = 4;
    const BUTTON_HEIGHT = 16;
    FTargets: TList;
    FCraft: TCraft;
    FState: TGeoscapeState;
    FWindow: TWindow;
    FBtnTargets: TList;
    procedure PopupTarget(ATarget: TTarget);
    procedure BtnCancelClick(AAction: TAction);
    procedure BtnTargetClick(AAction: TAction);
  public
    constructor Create(ATargets: TList; ACraft: TCraft; AState: TGeoscapeState);
    destructor Destroy; override;
    procedure Init; override;
  end;

implementation

{ TMultipleTargetsState }

constructor TMultipleTargetsState.Create(ATargets: TList; ACraft: TCraft; AState: TGeoscapeState);
var
  winHeight, winY, btnY: Integer;
  i: Integer;
  btn: TTextButton;
begin
  inherited Create(nil);
  FTargets := ATargets; // we take ownership
  FCraft := ACraft;
  FState := AState;
  FScreen := False;
  FBtnTargets := TList.Create;

  if FTargets.Count > 1 then
  begin
    winHeight := BUTTON_HEIGHT * FTargets.Count + SPACING * (FTargets.Count - 1) + MARGIN * 2;
    winY := (200 - winHeight) div 2;
    btnY := winY + MARGIN;

    FWindow := TWindow.Create(Self, 136, winHeight, 60, winY, POPUP_VERTICAL);
    SetInterface('multipleTargets');
    Add(FWindow, 'window', 'multipleTargets');
    FWindow.SetBackground(Game.Mod.GetSurface('BACK15.SCR'));

    for i := 0 to FTargets.Count - 1 do
    begin
      btn := TTextButton.Create(116, BUTTON_HEIGHT, 70, btnY);
      btn.Text := TTarget(FTargets[i]).Name(Game.Language);
      btn.OnMouseClick := BtnTargetClick;
      Add(btn, 'button', 'multipleTargets');
      FBtnTargets.Add(btn);
      Inc(btnY, btn.Height + SPACING);
    end;
    if FBtnTargets.Count > 0 then
      TTextButton(FBtnTargets[0]).OnKeyboardPress(Options.KeyCancel, BtnCancelClick);

    CenterAllSurfaces;
  end;
end;

destructor TMultipleTargetsState.Destroy;
begin
  // FTargets is owned by caller? In original it's not freed here, but we'll free it.
  // Actually the caller creates a list and passes it; we take ownership.
  FTargets.Free;
  FBtnTargets.Free;
  inherited;
end;

procedure TMultipleTargetsState.Init;
begin
  if FTargets.Count = 1 then
    PopupTarget(TTarget(FTargets[0]))
  else
    inherited;
end;

procedure TMultipleTargetsState.PopupTarget(ATarget: TTarget);
var
  b: TBase;
  c: TCraft;
  u: TUfo;
begin
  Game.PopState;
  if FCraft = nil then
  begin
    b := ATarget as TBase;
    c := ATarget as TCraft;
    u := ATarget as TUfo;
    if Assigned(b) then
      Game.PushState(TInterceptState.Create(FState.Globe, b))
    else if Assigned(c) then
      Game.PushState(TGeoscapeCraftState.Create(c, FState.Globe, nil))
    else if Assigned(u) then
      Game.PushState(TUfoDetectedState.Create(u, FState, False, u.HyperDetected))
    else
      Game.PushState(TTargetInfoState.Create(ATarget, FState.Globe));
  end
  else
    Game.PushState(TConfirmDestinationState.Create(FCraft, ATarget));
end;

procedure TMultipleTargetsState.BtnCancelClick(AAction: TAction);
begin
  Game.PopState;
end;

procedure TMultipleTargetsState.BtnTargetClick(AAction: TAction);
var
  i: Integer;
begin
  for i := 0 to FBtnTargets.Count - 1 do
    if AAction.Sender = FBtnTargets[i] then
    begin
      PopupTarget(TTarget(FTargets[i]));
      Break;
    end;
end;

end.