{----------------------------------------------------------------------------}
{ Unit: ArticleStateTFTD                                                     }
{ Base class for TFTD article states.                                        }
{----------------------------------------------------------------------------}
unit ArticleStateTFTD;

interface

uses
  Classes, SysUtils,
  ArticleState, Engine.Game, Engine.Palette, Engine.Surface, Engine.Text,
  Engine.TextButton, Engine.LocalizedText, Mod.ArticleDefinition, Mod.Mod;

type
  TArticleStateTFTD = class(TArticleState)
  protected
    FTxtTitle: TText;
    FTxtInfo: TText;
  public
    constructor Create(defs: TArticleDefinitionTFTD); virtual;
    destructor Destroy; override;
  end;

implementation

{ TArticleStateTFTD }

constructor TArticleStateTFTD.Create(defs: TArticleDefinitionTFTD);
begin
  inherited Create(defs.Id);
  SetPalette('PAL_BASESCAPE');

  FBtnOk.X := 227;
  FBtnOk.Y := 179;
  FBtnOk.Height := 10;
  FBtnOk.Width := 23;
  FBtnOk.Color := Palette.BlockOffset(0) + 2;

  FBtnPrev.X := 254;
  FBtnPrev.Y := 179;
  FBtnPrev.Height := 10;
  FBtnPrev.Width := 23;
  FBtnPrev.Color := Palette.BlockOffset(0) + 2;

  FBtnNext.X := 281;
  FBtnNext.Y := 179;
  FBtnNext.Height := 10;
  FBtnNext.Width := 23;
  FBtnNext.Color := Palette.BlockOffset(0) + 2;

  InitLayout;

  FGame.Mod.GetSurface('BACK08.SCR').Blit(FBg);
  FGame.Mod.GetSurface(defs.ImageId).Blit(FBg);

  FTxtInfo := TText.Create(defs.TextWidth, 136, 320 - defs.TextWidth, 34);
  FTxtTitle := TText.Create(284, 16, 36, 14);

  Add(FTxtTitle);
  Add(FTxtInfo);

  FTxtTitle.Color := Palette.BlockOffset(0) + 2;
  FTxtTitle.Big := True;
  FTxtTitle.WordWrap := True;
  FTxtTitle.Align := ALIGN_CENTER;
  FTxtTitle.Text := tr(defs.Title);

  FTxtInfo.Color := Palette.BlockOffset(0) + 2;
  FTxtInfo.WordWrap := True;
  FTxtInfo.Scrollable := True;
  FTxtInfo.Text := tr(defs.Text);

  if defs.ArticleType = UFOPAEDIA_TYPE_TFTD then
    CenterAllSurfaces;
end;

destructor TArticleStateTFTD.Destroy;
begin
  FTxtTitle.Free;
  FTxtInfo.Free;
  inherited;
end;

end.