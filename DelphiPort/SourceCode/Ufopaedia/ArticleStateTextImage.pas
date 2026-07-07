{----------------------------------------------------------------------------}
{ Unit: ArticleStateTextImage                                                }
{ Text with background image article state.                                  }
{----------------------------------------------------------------------------}
unit ArticleStateTextImage;

interface

uses
  Classes, SysUtils,
  ArticleState, Engine.Game, Engine.Palette, Engine.Surface, Engine.Text,
  Engine.LocalizedText, Interface.TextButton, Mod.ArticleDefinition, Mod.Mod;

type
  TArticleStateTextImage = class(TArticleState)
  private
    FTxtTitle: TText;
    FTxtInfo: TText;
  public
    constructor Create(defs: TArticleDefinitionTextImage);
    destructor Destroy; override;
  end;

implementation

{ TArticleStateTextImage }

constructor TArticleStateTextImage.Create(defs: TArticleDefinitionTextImage);
var
  text_height: Integer;
begin
  inherited Create(defs.Id);

  FTxtTitle := TText.Create(defs.TextWidth, 48, 5, 22);
  SetPalette('PAL_UFOPAEDIA');
  InitLayout;

  Add(FTxtTitle);

  FGame.Mod.GetSurface(defs.ImageId).Blit(FBg);
  FBtnOk.Color := Palette.BlockOffset(5) + 3;
  FBtnPrev.Color := Palette.BlockOffset(5) + 3;
  FBtnNext.Color := Palette.BlockOffset(5) + 3;

  FTxtTitle.Color := Palette.BlockOffset(15) + 4;
  FTxtTitle.Big := True;
  FTxtTitle.WordWrap := True;
  FTxtTitle.Text := tr(defs.Title);

  text_height := FTxtTitle.GetTextHeight;

  FTxtInfo := TText.Create(defs.TextWidth, 176 - text_height, 5, 23 + text_height);
  Add(FTxtInfo);
  FTxtInfo.Color := Palette.BlockOffset(15) - 1;
  FTxtInfo.WordWrap := True;
  FTxtInfo.Scrollable := True;
  FTxtInfo.Text := tr(defs.Text);

  CenterAllSurfaces;
end;

destructor TArticleStateTextImage.Destroy;
begin
  FTxtTitle.Free;
  FTxtInfo.Free;
  inherited;
end;

end.