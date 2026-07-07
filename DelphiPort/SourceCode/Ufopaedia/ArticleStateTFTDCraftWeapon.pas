{----------------------------------------------------------------------------}
{ Unit: ArticleStateTFTDCraftWeapon                                          }
{ TFTD craft weapon article state.                                           }
{----------------------------------------------------------------------------}
unit ArticleStateTFTDCraftWeapon;

interface

uses
  Classes, SysUtils,
  ArticleStateTFTD, Engine.Game, Engine.Palette, Engine.TextList,
  Engine.LocalizedText, Engine.Unicode, Mod.ArticleDefinition, Mod.Mod,
  Mod.RuleCraftWeapon;

type
  TArticleStateTFTDCraftWeapon = class(TArticleStateTFTD)
  private
    FLstInfo: TTextList;
  public
    constructor Create(defs: TArticleDefinitionTFTD);
    destructor Destroy; override;
  end;

implementation

{ TArticleStateTFTDCraftWeapon }

constructor TArticleStateTFTDCraftWeapon.Create(defs: TArticleDefinitionTFTD);
var
  weapon: TRuleCraftWeapon;
begin
  inherited Create(defs);
  FTxtInfo.Height := 88;

  weapon := FGame.Mod.GetCraftWeapon(defs.Id, True);

  FLstInfo := TTextList.Create(150, 50, 168, 126);
  Add(FLstInfo);
  FLstInfo.Color := Palette.BlockOffset(0) + 2;
  FLstInfo.Columns := [100, 68];
  FLstInfo.Dot := True;

  FLstInfo.AddRow([tr('STR_DAMAGE'), Unicode.FormatNumber(weapon.Damage)]);
  FLstInfo.SetCellColor(0, 1, Palette.BlockOffset(15) + 4);

  FLstInfo.AddRow([tr('STR_RANGE'), tr('STR_KILOMETERS').Arg(IntToStr(weapon.Range))]);
  FLstInfo.SetCellColor(1, 1, Palette.BlockOffset(15) + 4);

  FLstInfo.AddRow([tr('STR_ACCURACY'), Unicode.FormatPercentage(weapon.Accuracy)]);
  FLstInfo.SetCellColor(2, 1, Palette.BlockOffset(15) + 4);

  FLstInfo.AddRow([tr('STR_RE_LOAD_TIME'), tr('STR_SECONDS').Arg(IntToStr(weapon.StandardReload))]);
  FLstInfo.SetCellColor(3, 1, Palette.BlockOffset(15) + 4);

  CenterAllSurfaces;
end;

destructor TArticleStateTFTDCraftWeapon.Destroy;
begin
  FLstInfo.Free;
  inherited;
end;

end.