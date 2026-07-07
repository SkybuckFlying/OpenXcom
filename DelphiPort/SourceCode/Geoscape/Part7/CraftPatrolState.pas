unit CraftPatrolState;

interface

uses
  Engine.State, Engine.Game, Mod.Mod, Engine.LocalizedText,
  Interface.TextButton, Interface.Window, Interface.Text,
  Savegame.Craft, Savegame.Target, Geoscape.GeoscapeCraftState,
  Engine.Options;

type
  TCraftPatrolState = class(TState)
  private
    FCraft: TCraft;
    FGlobe: TGlobe;
    FBtnOk, FBtnRedirect: TTextButton;
    FWindow: TWindow;
    FTxtDestination, FTxtPatrolling: TText;
    procedure BtnOkClick(AAction: TAction);
    procedure BtnRedirectClick(AAction: TAction);
  public
    constructor Create(ACraft: TCraft; AGlobe: TGlobe);
    destructor Destroy; override;
  end;

implementation

uses
  System.SysUtils;

{ TCraftPatrolState }

constructor TCraftPatrolState.Create(ACraft: TCraft; AGlobe: TGlobe);
begin
  inherited Create(nil);
  FCraft := ACraft;
  FGlobe := AGlobe;
  FScreen := False;

  FWindow := TWindow.Create(Self, 224, 168, 16, 16, POPUP_BOTH);
  FBtnOk := TTextButton.Create(140, 12, 58, 144);
  FBtnRedirect := TTextButton.Create(140, 12, 58, 160);
  FTxtDestination := TText.Create(224, 64, 16, 48);
  FTxtPatrolling := TText.Create(224, 17, 16, 120);

  SetInterface('craftPatrol');

  Add(FWindow, 'window', 'craftPatrol');
  Add(FBtnOk, 'button', 'craftPatrol');
  Add(FBtnRedirect, 'button', 'craftPatrol');
  Add(FTxtDestination, 'text1', 'craftPatrol');
  Add(FTxtPatrolling, 'text1', 'craftPatrol');

  CenterAllSurfaces;

  FWindow.SetBackground(Game.Mod.GetSurface('BACK12.SCR'));

  FBtnOk.Text := Tr('STR_OK');
  FBtnOk.OnMouseClick := BtnOkClick;
  FBtnOk.OnKeyboardPress(Options.keyCancel, BtnOkClick);

  FBtnRedirect.Text := Tr('STR_REDIRECT_CRAFT');
  FBtnRedirect.OnMouseClick := BtnRedirectClick;
  FBtnRedirect.OnKeyboardPress(Options.keyOk, BtnRedirectClick);

  FTxtDestination.Big := True;
  FTxtDestination.Align := ALIGN_CENTER;
  FTxtDestination.WordWrap := True;
  FTxtDestination.Text := Tr('STR_CRAFT_HAS_REACHED_DESTINATION')
                           .Arg(FCraft.Name(Game.Language))
                           .Arg(FCraft.Destination.Name(Game.Language));

  FTxtPatrolling.Big := True;
  FTxtPatrolling.Align := ALIGN_CENTER;
  FTxtPatrolling.Text := Tr('STR_NOW_PATROLLING');
end;

destructor TCraftPatrolState.Destroy;
begin
  inherited;
end;

procedure TCraftPatrolState.BtnOkClick(AAction: TAction);
begin
  Game.PopState;
end;

procedure TCraftPatrolState.BtnRedirectClick(AAction: TAction);
begin
  Game.PopState;
  Game.PushState(TGeoscapeCraftState.Create(FCraft, FGlobe, nil));
end;

end.