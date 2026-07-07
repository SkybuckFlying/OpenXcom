{----------------------------------------------------------------------------}
{ Unit: ArticleStateTFTDCraft                                                }
{ TFTD craft article state.                                                  }
{----------------------------------------------------------------------------}
unit ArticleStateTFTDCraft;

interface

uses
  Classes, SysUtils,
  ArticleStateTFTD, Engine.Game, Engine.Palette, Engine.Text,
  Engine.LocalizedText, Engine.Unicode, Mod.ArticleDefinition, Mod.Mod,
  Mod.RuleCraft;

type
  TArticleStateTFTDCraft = class(TArticleStateTFTD)
  private
    FTxtStats: TText;
  public
    constructor Create(defs: TArticleDefinitionTFTD);
    destructor Destroy; override;
  end;

implementation

{ TArticleStateTFTDCraft }

constructor TArticleStateTFTDCraft.Create(defs: TArticleDefinitionTFTD);
var
  craft: TRuleCraft;
  ss: TStringBuilder;
begin
  inherited Create(defs);
  FTxtInfo.Height := 80;

  craft := FGame.Mod.GetCraft(defs.Id, True);
  FTxtStats := TText.Create(131, 56, 187, 116);
  Add(FTxtStats);
  FTxtStats.Color := Palette.BlockOffset(0) + 2;
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

destructor TArticleStateTFTDCraft.Destroy;
begin
  FTxtStats.Free;
  inherited;
end;

end.