{----------------------------------------------------------------------------}
{ Unit: ArticleStateTFTDFacility                                             }
{ TFTD base facility article state.                                          }
{----------------------------------------------------------------------------}
unit ArticleStateTFTDFacility;

interface

uses
  Classes, SysUtils,
  ArticleStateTFTD, Engine.Game, Engine.Palette, Engine.TextList,
  Engine.LocalizedText, Engine.Unicode, Mod.ArticleDefinition, Mod.Mod,
  Mod.RuleBaseFacility;

type
  TArticleStateTFTDFacility = class(TArticleStateTFTD)
  private
    FLstInfo: TTextList;
  public
    constructor Create(defs: TArticleDefinitionTFTD);
    destructor Destroy; override;
  end;

implementation

{ TArticleStateTFTDFacility }

constructor TArticleStateTFTDFacility.Create(defs: TArticleDefinitionTFTD);
var
  facility: TRuleBaseFacility;
  ss: TStringBuilder;
  row: Integer;
begin
  inherited Create(defs);
  FTxtInfo.Height := 112;

  facility := FGame.Mod.GetBaseFacility(defs.Id, True);

  FLstInfo := TTextList.Create(150, 50, 168, 150);
  Add(FLstInfo);
  FLstInfo.Color := Palette.BlockOffset(0) + 2;
  FLstInfo.Columns := [104, 46];
  FLstInfo.Dot := True;

  ss := TStringBuilder.Create;
  try
    row := 0;
    if facility.DefenseValue > 0 then
    begin
      FLstInfo.Y := FLstInfo.Y - 16;
      FTxtInfo.Height := FTxtInfo.Height - 16;
      FLstInfo.AddRow([tr('STR_DEFENSE_VALUE'), IntToStr(facility.DefenseValue)]);
      FLstInfo.SetCellColor(row, 1, Palette.BlockOffset(15) + 4);
      Inc(row);

      FLstInfo.AddRow([tr('STR_HIT_RATIO'), Unicode.FormatPercentage(facility.HitRatio)]);
      FLstInfo.SetCellColor(row, 1, Palette.BlockOffset(15) + 4);
      Inc(row);
    end;

    FLstInfo.AddRow([tr('STR_CONSTRUCTION_TIME'), tr('STR_DAY', facility.BuildTime)]);
    FLstInfo.SetCellColor(row, 1, Palette.BlockOffset(15) + 4);
    Inc(row);

    FLstInfo.AddRow([tr('STR_CONSTRUCTION_COST'), Unicode.FormatFunding(facility.BuildCost)]);
    FLstInfo.SetCellColor(row, 1, Palette.BlockOffset(15) + 4);
    Inc(row);

    FLstInfo.AddRow([tr('STR_MAINTENANCE_COST'), Unicode.FormatFunding(facility.MonthlyCost)]);
    FLstInfo.SetCellColor(row, 1, Palette.BlockOffset(15) + 4);

  finally
    ss.Free;
  end;

  CenterAllSurfaces;
end;

destructor TArticleStateTFTDFacility.Destroy;
begin
  FLstInfo.Free;
  inherited;
end;

end.