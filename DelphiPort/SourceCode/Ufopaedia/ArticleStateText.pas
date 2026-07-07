{----------------------------------------------------------------------------}
{ Unit: ArticleStateText                                                     }
{ Plain text article state.                                                  }
{----------------------------------------------------------------------------}
unit ArticleStateText;

interface

uses
  Classes, SysUtils,
  ArticleState, Engine.Game, Engine.Palette, Engine.Surface, Engine.Text,
  Engine.LocalizedText, Interface.TextButton, Mod.ArticleDefinition, Mod.Mod;

type
  TArticleStateText = class(TArticleState)
  private
    FTxtTitle: TText;
    FTxtInfo: TText;
  public
    constructor Create(defs: TArticleDefinitionText);
    destructor Destroy; override;
  end;

implementation

{ TArticleStateText }

constructor TArticleStateText.Create(defs: TArticleDefinitionText);
begin
  inherited Create(defs.Id);

  FTxtTitle := TText.Create(296, 17, 5, 23);
  FTxtInfo := TText.Create(296, 150, 10, 48);

  SetPalette('PAL_UFOPAEDIA');
  InitLayout;

  Add(FTxtTitle);
  Add(FTxtInfo);

  CenterAllSurfaces;

  FGame.Mod.GetSurface('BACK10.SCR').Blit(FBg);
  FBtnOk.Color := Palette.BlockOffset(5);
  FBtnPrev.Color := Palette.BlockOffset(5);
  FBtnNext.Color := Palette.BlockOffset(5);

  FTxtTitle.Color := Palette.BlockOffset(15) + 4;
  FTxtTitle.Big := True;
  FTxtTitle.Text := tr(defs.Title);

  FTxtInfo.Color := Palette.BlockOffset(15) - 1;
  FTxtInfo.WordWrap := True;
  FTxtInfo.Scrollable := True;
  FTxtInfo.Text := tr(defs.Text);
end;

destructor TArticleStateText.Destroy;
begin
  FTxtTitle.Free;
  FTxtInfo.Free;
  inherited;
end;

end.