{----------------------------------------------------------------------------}
{ Unit: ArticleStateTFTDUso                                                  }
{ TFTD USO (UFO) article state.                                              }
{----------------------------------------------------------------------------}
unit ArticleStateTFTDUso;

interface

uses
  Classes, SysUtils,
  ArticleStateTFTD, Engine.Game, Engine.Palette, Engine.TextList,
  Engine.LocalizedText, Engine.Unicode, Mod.ArticleDefinition, Mod.Mod,
  Mod.RuleUfo;

type
  TArticleStateTFTDUso = class(TArticleStateTFTD)
  private
    FLstInfo: TTextList;
  public
    constructor Create(defs: TArticleDefinitionTFTD);
    destructor Destroy; override;
  end;

implementation

{ TArticleStateTFTDUso }

constructor TArticleStateTFTDUso.Create(defs: TArticleDefinitionTFTD);
var
  ufo: TRuleUfo;
begin
  inherited Create(defs);
  FTxtInfo.Height := 112;

  ufo := FGame.Mod.GetUfo(defs.Id, True);

  FLstInfo := TTextList.Create(150, 50, 168, 142);
  Add(FLstInfo);
  FLstInfo.Color := Palette.BlockOffset(0) + 2;
  FLstInfo.Columns := [95, 55];
  FLstInfo.Dot := True;

  FLstInfo.AddRow([tr('STR_DAMAGE_CAPACITY'), Unicode.FormatNumber(ufo.MaxDamage)]);
  FLstInfo.AddRow([tr('STR_WEAPON_POWER'), Unicode.FormatNumber(ufo.WeaponPower)]);
  FLstInfo.AddRow([tr('STR_WEAPON_RANGE'), tr('STR_KILOMETERS').Arg(IntToStr(ufo.WeaponRange))]);
  FLstInfo.AddRow([tr('STR_MAXIMUM_SPEED'), tr('STR_KNOTS').Arg(Unicode.FormatNumber(ufo.MaxSpeed))]);

  FLstInfo.SetCellColor(0, 1, Palette.BlockOffset(15) + 4);
  FLstInfo.SetCellColor(1, 1, Palette.BlockOffset(15) + 4);
  FLstInfo.SetCellColor(2, 1, Palette.BlockOffset(15) + 4);
  FLstInfo.SetCellColor(3, 1, Palette.BlockOffset(15) + 4);

  CenterAllSurfaces;
end;

destructor TArticleStateTFTDUso.Destroy;
begin
  FLstInfo.Free;
  inherited;
end;

end.