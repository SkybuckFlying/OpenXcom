{----------------------------------------------------------------------------}
{ Unit: ArticleStateBaseFacility                                             }
{ Base facility article state.                                               }
{----------------------------------------------------------------------------}
unit ArticleStateBaseFacility;

interface

uses
  Classes, SysUtils,
  ArticleState, Engine.Game, Engine.Palette, Engine.Surface, Engine.Text,
  Engine.TextList, Engine.LocalizedText, Engine.Unicode, Interface.Text,
  Interface.TextButton, Mod.ArticleDefinition, Mod.Mod, Mod.RuleBaseFacility;

type
  TArticleStateBaseFacility = class(TArticleState)
  private
    FImage: TSurface;
    FTxtTitle: TText;
    FTxtInfo: TText;
    FLstInfo: TTextList;
  public
    constructor Create(defs: TArticleDefinitionBaseFacility);
    destructor Destroy; override;
  end;

implementation

uses
  Math;

{ TArticleStateBaseFacility }

constructor TArticleStateBaseFacility.Create(defs: TArticleDefinitionBaseFacility);
var
  facility: TRuleBaseFacility;
  tile_size: Integer;
  graphic: TSurfaceSet;
  frame: TSurface;
  x_offset, y_offset, x_pos, y_pos, num, x, y: Integer;
begin
  inherited Create(defs.Id);
  facility := FGame.Mod.GetBaseFacility(defs.Id, True);

  FTxtTitle := TText.Create(200, 17, 10, 24);
  SetPalette('PAL_BASESCAPE');
  InitLayout;

  Add(FTxtTitle);

  FGame.Mod.GetSurface('BACK09.SCR').Blit(FBg);
  FBtnOk.Color := Palette.BlockOffset(4);
  FBtnPrev.Color := Palette.BlockOffset(4);
  FBtnNext.Color := Palette.BlockOffset(4);

  FTxtTitle.Color := Palette.BlockOffset(13) + 10;
  FTxtTitle.Big := True;
  FTxtTitle.Text := tr(defs.Title);

  // build preview image
  tile_size := 32;
  FImage := TSurface.Create(tile_size * 2, tile_size * 2, 232, 16);
  Add(FImage);

  graphic := FGame.Mod.GetSurfaceSet('BASEBITS.PCK');
  if facility.Size = 1 then
  begin
    x_offset := tile_size div 2;
    y_offset := tile_size div 2;
  end
  else
  begin
    x_offset := 0;
    y_offset := 0;
  end;

  num := 0;
  y_pos := y_offset;
  for y := 0 to facility.Size - 1 do
  begin
    x_pos := x_offset;
    for x := 0 to facility.Size - 1 do
    begin
      frame := graphic.GetFrame(facility.SpriteShape + num);
      frame.X := x_pos;
      frame.Y := y_pos;
      frame.Blit(FImage);

      if facility.Size = 1 then
      begin
        frame := graphic.GetFrame(facility.SpriteFacility + num);
        frame.X := x_pos;
        frame.Y := y_pos;
        frame.Blit(FImage);
      end;

      Inc(x_pos, tile_size);
      Inc(num);
    end;
    Inc(y_pos, tile_size);
  end;

  FTxtInfo := TText.Create(300, 90, 10, 104);
  Add(FTxtInfo);
  FTxtInfo.Color := Palette.BlockOffset(13) + 10;
  FTxtInfo.WordWrap := True;
  FTxtInfo.Scrollable := True;
  FTxtInfo.Text := tr(defs.Text);

  FLstInfo := TTextList.Create(200, 42, 10, 42);
  Add(FLstInfo);
  FLstInfo.Color := Palette.BlockOffset(13) + 10;
  FLstInfo.Columns := [140, 60];
  FLstInfo.Dot := True;

  FLstInfo.AddRow([tr('STR_CONSTRUCTION_TIME'), tr('STR_DAY', facility.BuildTime)]);
  FLstInfo.SetCellColor(0, 1, Palette.BlockOffset(13) + 0);

  FLstInfo.AddRow([tr('STR_CONSTRUCTION_COST'), Unicode.FormatFunding(facility.BuildCost)]);
  FLstInfo.SetCellColor(1, 1, Palette.BlockOffset(13) + 0);

  FLstInfo.AddRow([tr('STR_MAINTENANCE_COST'), Unicode.FormatFunding(facility.MonthlyCost)]);
  FLstInfo.SetCellColor(2, 1, Palette.BlockOffset(13) + 0);

  if facility.DefenseValue > 0 then
  begin
    FLstInfo.AddRow([tr('STR_DEFENSE_VALUE'), IntToStr(facility.DefenseValue)]);
    FLstInfo.SetCellColor(3, 1, Palette.BlockOffset(13) + 0);
    FLstInfo.AddRow([tr('STR_HIT_RATIO'), Unicode.FormatPercentage(facility.HitRatio)]);
    FLstInfo.SetCellColor(4, 1, Palette.BlockOffset(13) + 0);
  end;

  CenterAllSurfaces;
end;

destructor TArticleStateBaseFacility.Destroy;
begin
  FImage.Free;
  FTxtTitle.Free;
  FTxtInfo.Free;
  FLstInfo.Free;
  inherited;
end;

end.