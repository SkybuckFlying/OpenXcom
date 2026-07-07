unit ActionMenuItem;

interface

uses
  System.SysUtils,
  Engine.InteractiveSurface, Engine.Game, Engine.Action, Engine.State,
  Battlescape.BattlescapeGame, Interface.Text, Interface.Frame,
  Mod.RuleInterface, Mod.Mod, Engine.Font, Engine.Language;

type
  TActionMenuItem = class(TInteractiveSurface)
  private
    FHighlighted: Boolean;
    FAction: TBattleActionType;
    FTU: Integer;
    FHighlightModifier: Integer;
    FFrame: TFrame;
    FTxtDescription: TText;
    FTxtAcc: TText;
    FTxtTU: TText;
  public
    constructor Create(AID: Integer; AGame: TGame; AX, AY: Integer);
    destructor Destroy; override;
    procedure SetAction(AAction: TBattleActionType; const ADesc, AAcc, ATUStr: string; ATU: Integer);
    function GetAction: TBattleActionType;
    function GetTUs: Integer;
    procedure SetPalette(AColors: PSDL_Color; AFirstColor, ANColors: Integer); override;
    procedure Draw; override;
    procedure MouseIn(AAction: TAction; AState: TState); override;
    procedure MouseOut(AAction: TAction; AState: TState); override;
  end;

implementation

constructor TActionMenuItem.Create(AID: Integer; AGame: TGame; AX, AY: Integer);
var
  ActionMenu: TElement;
  BigFont, SmallFont: TFont;
begin
  inherited Create(272, 40, AX + 24, AY - (AID * 40));
  FHighlighted := False;
  FAction := BA_NONE;
  FTU := 0;

  BigFont := AGame.GetMod.GetFont('FONT_BIG');
  SmallFont := AGame.GetMod.GetFont('FONT_SMALL');

  ActionMenu := AGame.GetMod.GetInterface('battlescape').GetElement('actionMenu');
  FHighlightModifier := IfThen(ActionMenu.TFTDMode, 12, 3);

  FFrame := TFrame.Create(GetWidth, GetHeight, 0, 0);
  FFrame.SetHighContrast(True);
  FFrame.SetColor(ActionMenu.Border);
  FFrame.SetSecondaryColor(ActionMenu.Color2);
  FFrame.SetThickness(8);

  FTxtDescription := TText.Create(200, 20, 10, 13);
  FTxtDescription.InitText(BigFont, SmallFont, AGame.GetLanguage);
  FTxtDescription.SetBig;
  FTxtDescription.SetHighContrast(True);
  FTxtDescription.SetColor(ActionMenu.Color);
  FTxtDescription.SetVisible(True);

  FTxtAcc := TText.Create(100, 20, 140, 13);
  FTxtAcc.InitText(BigFont, SmallFont, AGame.GetLanguage);
  FTxtAcc.SetBig;
  FTxtAcc.SetHighContrast(True);
  FTxtAcc.SetColor(ActionMenu.Color);

  FTxtTU := TText.Create(80, 20, 210, 13);
  FTxtTU.InitText(BigFont, SmallFont, AGame.GetLanguage);
  FTxtTU.SetBig;
  FTxtTU.SetHighContrast(True);
  FTxtTU.SetColor(ActionMenu.Color);
end;

destructor TActionMenuItem.Destroy;
begin
  FFrame.Free;
  FTxtDescription.Free;
  FTxtAcc.Free;
  FTxtTU.Free;
  inherited;
end;

procedure TActionMenuItem.SetAction(AAction: TBattleActionType; const ADesc, AAcc, ATUStr: string; ATU: Integer);
begin
  FAction := AAction;
  FTxtDescription.SetText(ADesc);
  FTxtAcc.SetText(AAcc);
  FTxtTU.SetText(ATUStr);
  FTU := ATU;
  _redraw := True;
end;

function TActionMenuItem.GetAction: TBattleActionType;
begin
  Result := FAction;
end;

function TActionMenuItem.GetTUs: Integer;
begin
  Result := FTU;
end;

procedure TActionMenuItem.SetPalette(AColors: PSDL_Color; AFirstColor, ANColors: Integer);
begin
  inherited SetPalette(AColors, AFirstColor, ANColors);
  FFrame.SetPalette(AColors, AFirstColor, ANColors);
  FTxtDescription.SetPalette(AColors, AFirstColor, ANColors);
  FTxtAcc.SetPalette(AColors, AFirstColor, ANColors);
  FTxtTU.SetPalette(AColors, AFirstColor, ANColors);
end;

procedure TActionMenuItem.Draw;
begin
  FFrame.Blit(Self);
  FTxtDescription.Blit(Self);
  FTxtAcc.Blit(Self);
  FTxtTU.Blit(Self);
end;

procedure TActionMenuItem.MouseIn(AAction: TAction; AState: TState);
begin
  FHighlighted := True;
  FFrame.SetSecondaryColor(FFrame.GetSecondaryColor - FHighlightModifier);
  Draw;
  inherited MouseIn(AAction, AState);
end;

procedure TActionMenuItem.MouseOut(AAction: TAction; AState: TState);
begin
  FHighlighted := False;
  FFrame.SetSecondaryColor(FFrame.GetSecondaryColor + FHighlightModifier);
  Draw;
  inherited MouseOut(AAction, AState);
end;

end.