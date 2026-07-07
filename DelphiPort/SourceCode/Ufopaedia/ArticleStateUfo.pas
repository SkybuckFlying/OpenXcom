{----------------------------------------------------------------------------}
{ Unit: ArticleStateUfo                                                      }
{ UFO article state.                                                         }
{----------------------------------------------------------------------------}
unit ArticleStateUfo;

interface

uses
  Classes, SysUtils,
  ArticleState, Engine.Game, Engine.Palette, Engine.Surface, Engine.Text,
  Engine.TextList, Engine.LocalizedText, Engine.Unicode, Interface.Text,
  Interface.TextButton, Mod.ArticleDefinition, Mod.Mod, Mod.RuleUfo,
  Mod.RuleInterface;

type
  TArticleStateUfo = class(TArticleState)
  private
    FImage: TSurface;
    FTxtTitle: TText;
    FTxtInfo: TText;
    FLstInfo: TTextList;
  public
    constructor Create(defs: TArticleDefinitionUfo);
    destructor Destroy; override;
  end;

implementation

{ TArticleStateUfo }

constructor TArticleStateUfo.Create(defs: TArticleDefinitionUfo);
var
  ufo: TRuleUfo;
  dogfightInterface: TRuleInterface;
  graphic: TSurface;
begin
  inherited Create(defs.Id);
  ufo := FGame.Mod.GetUfo(defs.Id, True);

  FTxtTitle := TText.Create(155, 32, 5, 24);
  SetPalette('PAL_GEOSCAPE');
  InitLayout;

  Add(FTxtTitle);

  FGame.Mod.GetSurface('BACK11.SCR').Blit(FBg);
  FBtnOk.Color := Palette.BlockOffset(8) + 5;
  FBtnPrev.Color := Palette.BlockOffset(8) + 5;
  FBtnNext.Color := Palette.BlockOffset(8) + 5;

  FTxtTitle.Color := Palette.BlockOffset(8) + 5;
  FTxtTitle.Big := True;
  FTxtTitle.WordWrap := True;
  FTxtTitle.Text := tr(defs.Title);

  FImage := TSurface.Create(160, 52, 160, 6);
  Add(FImage);

  dogfightInterface := FGame.Mod.GetInterface('dogfight');
  graphic := FGame.Mod.GetSurface('INTERWIN.DAT');
  graphic.X := 0;
  graphic.Y := 0;
  graphic.Crop := Rect(0, 0, FImage.Width, FImage.Height);
  FImage.DrawRect(graphic.Crop, 15);
  graphic.Blit(FImage);

  if ufo.ModSprite = '' then
  begin
    graphic.Crop.Top := dogfightInterface.GetElement('previewMid').Y +
                        dogfightInterface.GetElement('previewMid').Height * ufo.Sprite;
    graphic.Crop.Height := dogfightInterface.GetElement('previewMid').Height;
  end
  else
    graphic := FGame.Mod.GetSurface(ufo.ModSprite);

  graphic.X := 0;
  graphic.Y := 0;
  graphic.Blit(FImage);

  FTxtInfo := TText.Create(300, 50, 10, 140);
  Add(FTxtInfo);
  FTxtInfo.Color := Palette.BlockOffset(8) + 5;
  FTxtInfo.WordWrap := True;
  FTxtInfo.Scrollable := True;
  FTxtInfo.Text := tr(defs.Text);

  FLstInfo := TTextList.Create(310, 64, 10, 68);
  Add(FLstInfo);

  CenterAllSurfaces;

  FLstInfo.Color := Palette.BlockOffset(8) + 5;
  FLstInfo.Columns := [200, 110];
  FLstInfo.Big := True;
  FLstInfo.Dot := True;

  FLstInfo.AddRow([tr('STR_DAMAGE_CAPACITY'), Unicode.FormatNumber(ufo.MaxDamage)]);
  FLstInfo.AddRow([tr('STR_WEAPON_POWER'), Unicode.FormatNumber(ufo.WeaponPower)]);
  FLstInfo.AddRow([tr('STR_WEAPON_RANGE'), tr('STR_KILOMETERS').Arg(IntToStr(ufo.WeaponRange))]);
  FLstInfo.AddRow([tr('STR_MAXIMUM_SPEED'), tr('STR_KNOTS').Arg(Unicode.FormatNumber(ufo.MaxSpeed))]);
end;

destructor TArticleStateUfo.Destroy;
begin
  FImage.Free;
  FTxtTitle.Free;
  FTxtInfo.Free;
  FLstInfo.Free;
  inherited;
end;

end.