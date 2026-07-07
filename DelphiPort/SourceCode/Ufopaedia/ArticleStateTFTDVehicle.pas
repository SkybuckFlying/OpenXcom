{----------------------------------------------------------------------------}
{ Unit: ArticleStateTFTDVehicle                                              }
{ TFTD vehicle article state.                                                }
{----------------------------------------------------------------------------}
unit ArticleStateTFTDVehicle;

interface

uses
  Classes, SysUtils,
  ArticleStateTFTD, Engine.Game, Engine.Palette, Engine.TextList,
  Engine.LocalizedText, Mod.ArticleDefinition, Mod.Mod, Mod.Unit_, Mod.Armor,
  Mod.RuleItem;

type
  TArticleStateTFTDVehicle = class(TArticleStateTFTD)
  private
    FLstStats: TTextList;
    FLstStats2: TTextList;
  public
    constructor Create(defs: TArticleDefinitionTFTD);
    destructor Destroy; override;
  end;

implementation

{ TArticleStateTFTDVehicle }

constructor TArticleStateTFTDVehicle.Create(defs: TArticleDefinitionTFTD);
var
  unit_: TUnit;
  armor: TArmor;
  item: TRuleItem;
  ammo: TRuleItem;
  ss: TStringBuilder;
  i: Integer;
begin
  inherited Create(defs);
  FTxtInfo.Height := 72;

  unit_ := FGame.Mod.GetUnit(defs.Id, True);
  armor := FGame.Mod.GetArmor(unit_.Armor, True);
  item := FGame.Mod.GetItem(defs.Id, True);

  FLstStats := TTextList.Create(150, 65, 168, 106);
  Add(FLstStats);
  FLstStats.Color := Palette.BlockOffset(0) + 2;
  FLstStats.Columns := [100, 50];
  FLstStats.Dot := True;

  FLstStats2 := TTextList.Create(195, 33, 25, 166);
  Add(FLstStats2);
  FLstStats2.Color := Palette.BlockOffset(0) + 2;
  FLstStats2.Columns := [65, 130];
  FLstStats2.Dot := True;

  ss := TStringBuilder.Create;
  try
    ss.Append(IntToStr(unit_.Stats.tu));
    FLstStats.AddRow([tr('STR_TIME_UNITS'), ss.ToString]);

    ss.Clear;
    ss.Append(IntToStr(unit_.Stats.health));
    FLstStats.AddRow([tr('STR_HEALTH'), ss.ToString]);

    ss.Clear;
    ss.Append(IntToStr(armor.FrontArmor));
    FLstStats.AddRow([tr('STR_FRONT_ARMOR'), ss.ToString]);

    ss.Clear;
    ss.Append(IntToStr(armor.SideArmor));
    FLstStats.AddRow([tr('STR_LEFT_ARMOR'), ss.ToString]);

    ss.Clear;
    ss.Append(IntToStr(armor.SideArmor));
    FLstStats.AddRow([tr('STR_RIGHT_ARMOR'), ss.ToString]);

    ss.Clear;
    ss.Append(IntToStr(armor.RearArmor));
    FLstStats.AddRow([tr('STR_REAR_ARMOR'), ss.ToString]);

    ss.Clear;
    ss.Append(IntToStr(armor.UnderArmor));
    FLstStats.AddRow([tr('STR_UNDER_ARMOR'), ss.ToString]);

    // second list
    FLstStats2.AddRow([tr('STR_WEAPON'), tr(defs.Weapon)]);

    if item.CompatibleAmmo.Count > 0 then
    begin
      ammo := FGame.Mod.GetItem(item.CompatibleAmmo[0], True);
      ss.Clear;
      ss.Append(IntToStr(ammo.Power));
      FLstStats2.AddRow([tr('STR_WEAPON_POWER'), ss.ToString]);

      FLstStats2.AddRow([tr('STR_AMMUNITION'), tr(ammo.Name)]);

      ss.Clear;
      if item.ClipSize > 0 then
        ss.Append(IntToStr(item.ClipSize))
      else
        ss.Append(IntToStr(ammo.ClipSize));
      FLstStats2.AddRow([tr('STR_ROUNDS'), ss.ToString]);
    end
    else
    begin
      ss.Clear;
      ss.Append(IntToStr(item.Power));
      FLstStats2.AddRow([tr('STR_WEAPON_POWER'), ss.ToString]);
    end;

  finally
    ss.Free;
  end;

  // set colors
  for i := 0 to FLstStats.Rows - 1 do
    FLstStats.SetCellColor(i, 1, Palette.BlockOffset(15) + 4);
  for i := 0 to FLstStats2.Rows - 1 do
    FLstStats2.SetCellColor(i, 1, Palette.BlockOffset(15) + 4);

  CenterAllSurfaces;
end;

destructor TArticleStateTFTDVehicle.Destroy;
begin
  FLstStats.Free;
  FLstStats2.Free;
  inherited;
end;

end.