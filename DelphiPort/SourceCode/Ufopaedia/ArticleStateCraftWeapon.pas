{----------------------------------------------------------------------------}
{ Unit: ArticleStateCraftWeapon                                              }
{ Craft weapon article state.                                                }
{----------------------------------------------------------------------------}
unit ArticleStateCraftWeapon;

interface

uses
  Classes, SysUtils,
  ArticleState, Engine.Game, Engine.Palette, Engine.Surface, Engine.Text,
  Engine.TextList, Engine.LocalizedText, Engine.Unicode, Interface.Text,
  Interface.TextButton, Mod.ArticleDefinition, Mod.Mod, Mod.RuleCraftWeapon;

type
  TArticleStateCraftWeapon = class(TArticleState)
  private
    FTxtTitle: TText;
    FTxtInfo: TText;
    FLstInfo: TTextList;
  public
    constructor Create(defs: TArticleDefinitionCraftWeapon);
    destructor Destroy; override;
  end;

implementation

{ TArticleStateCraftWeapon }

constructor TArticleStateCraftWeapon.Create(defs: TArticleDefinitionCraftWeapon);
var
  weapon: TRuleCraftWeapon;
begin
  inherited Create(defs.Id);
  weapon := FGame.Mod.GetCraftWeapon(defs.Id, True);

  FTxtTitle := TText.Create(200, 32, 5, 24);
  SetPalette('PAL_BATTLEPEDIA');
  InitLayout;

  Add(FTxtTitle);

  FGame.Mod.GetSurface(defs.ImageId).Blit(FBg);
  FBtnOk.Color := Palette.BlockOffset(1);
  FBtnPrev.Color := Palette.BlockOffset(1);
  FBtnNext.Color := Palette.BlockOffset(1);

  FTxtTitle.Color := Palette.BlockOffset(14) + 15;
  FTxtTitle.Big := True;
  FTxtTitle.WordWrap := True;
  FTxtTitle.Text := tr(defs.Title);

  FTxtInfo := TText.Create(310, 32, 5, 160);
  Add(FTxtInfo);
  FTxtInfo.Color := Palette.BlockOffset(14) + 15;
  FTxtInfo.WordWrap := True;
  FTxtInfo.Scrollable := True;
  FTxtInfo.Text := tr(defs.Text);

  FLstInfo := TTextList.Create(250, 111, 5, 80);
  Add(FLstInfo);
  FLstInfo.Color := Palette.BlockOffset(14) + 15;
  FLstInfo.Columns := [180, 70];
  FLstInfo.Dot := True;
  FLstInfo.Big := True;

  FLstInfo.AddRow([tr('STR_DAMAGE'), Unicode.FormatNumber(weapon.Damage)]);
  FLstInfo.SetCellColor(0, 1, Palette.BlockOffset(15) + 4);

  FLstInfo.AddRow([tr('STR_RANGE'), tr('STR_KILOMETERS').Arg(IntToStr(weapon.Range))]);
  FLstInfo.SetCellColor(1, 1, Palette.BlockOffset(15) + 4);

  FLstInfo.AddRow([tr('STR_ACCURACY'), Unicode.FormatPercentage(weapon.Accuracy)]);
  FLstInfo.SetCellColor(2, 1, Palette.BlockOffset(15) + 4);

  FLstInfo.AddRow([tr('STR_RE_LOAD_TIME'), tr('STR_SECONDS').Arg(IntToStr(weapon.StandardReload))]);
  FLstInfo.SetCellColor(3, 1, Palette.BlockOffset(15) + 4);

  FLstInfo.AddRow([tr('STR_ROUNDS'), Unicode.FormatNumber(weapon.AmmoMax)]);
  FLstInfo.SetCellColor(4, 1, Palette.BlockOffset(15) + 4);

  CenterAllSurfaces;
end;

destructor TArticleStateCraftWeapon.Destroy;
begin
  FTxtTitle.Free;
  FTxtInfo.Free;
  FLstInfo.Free;
  inherited;
end;

end.