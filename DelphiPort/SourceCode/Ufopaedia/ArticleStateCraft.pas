{----------------------------------------------------------------------------}
{ Unit: ArticleStateCraft                                                    }
{ Craft article state.                                                       }
{----------------------------------------------------------------------------}
unit ArticleStateCraft;

interface

uses
  Classes, SysUtils,
  ArticleState, Engine.Game, Engine.Palette, Engine.Surface, Engine.Text,
  Engine.LocalizedText, Engine.Unicode, Interface.Text, Interface.TextButton,
  Mod.ArticleDefinition, Mod.Mod, Mod.RuleCraft;

type
  TArticleStateCraft = class(TArticleState)
  private
    FTxtTitle: TText;
    FTxtInfo: TText;
    FTxtStats: TText;
  public
    constructor Create(defs: TArticleDefinitionCraft);
    destructor Destroy; override;
  end;

implementation

{ TArticleStateCraft }

constructor TArticleStateCraft.Create(defs: TArticleDefinitionCraft);
var
  craft: TRuleCraft;
  ss: TStringBuilder;
begin
  inherited Create(defs.Id);
  craft := FGame.Mod.GetCraft(defs.Id, True);

  FTxtTitle := TText.Create(210, 32, 5, 24);
  SetPalette('PAL_UFOPAEDIA');
  InitLayout;

  Add(FTxtTitle);

  FGame.Mod.GetSurface(defs.ImageId).Blit(FBg);
  FBtnOk.Color := Palette.BlockOffset(15) - 1;
  FBtnPrev.Color := Palette.BlockOffset(15) - 1;
  FBtnNext.Color := Palette.BlockOffset(15) - 1;

  FTxtTitle.Color := Palette.BlockOffset(14) + 15;
  FTxtTitle.Big := True;
  FTxtTitle.WordWrap := True;
  FTxtTitle.Text := tr(defs.Title);

  FTxtInfo := TText.Create(defs.RectText.Width, defs.RectText.Height,
                           defs.RectText.X, defs.RectText.Y);
  Add(FTxtInfo);
  FTxtInfo.Color := Palette.BlockOffset(14) + 15;
  FTxtInfo.WordWrap := True;
  FTxtInfo.Scrollable := True;
  FTxtInfo.Text := tr(defs.Text);

  FTxtStats := TText.Create(defs.RectStats.Width, defs.RectStats.Height,
                            defs.RectStats.X, defs.RectStats.Y);
  Add(FTxtStats);
  FTxtStats.Color := Palette.BlockOffset(14) + 15;
  FTxtStats.SecondaryColor := Palette.BlockOffset(15) + 4;

  ss := TStringBuilder.Create;
  try
    ss.Append(tr('STR_MAXIMUM_SPEED_UC').Arg(Unicode.FormatNumber(craft.MaxSpeed))).Append(sLineBreak);
    ss.Append(tr('STR_ACCELERATION').Arg(IntToStr(craft.Acceleration))).Append(sLineBreak);
    ss.Append(tr('STR_FUEL_CAPACITY').Arg(Unicode.FormatNumber(craft.MaxFuel))).Append(sLineBreak);
    ss.Append(tr('STR_WEAPON_PODS').Arg(IntToStr(craft.Weapons))).Append(sLineBreak);
    ss.Append(tr('STR_DAMAGE_CAPACITY_UC').Arg(Unicode.FormatNumber(craft.MaxDamage))).Append(sLineBreak);
    ss.Append(tr('STR_CARGO_SPACE').Arg(IntToStr(craft.Soldiers))).Append(sLineBreak);
    ss.Append(tr('STR_HWP_CAPACITY').Arg(IntToStr(craft.Vehicles)));
    FTxtStats.Text := ss.ToString;
  finally
    ss.Free;
  end;

  CenterAllSurfaces;
end;

destructor TArticleStateCraft.Destroy;
begin
  FTxtTitle.Free;
  FTxtInfo.Free;
  FTxtStats.Free;
  inherited;
end;

end.