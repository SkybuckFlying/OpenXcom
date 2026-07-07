{----------------------------------------------------------------------------}
{ Unit: ArticleStateVehicle                                                  }
{ Vehicle article state.                                                     }
{----------------------------------------------------------------------------}
unit ArticleStateVehicle;

interface

uses
  Classes, SysUtils,
  ArticleState, Engine.Game, Engine.Palette, Engine.Surface, Engine.Text,
  Engine.TextList, Engine.LocalizedText, Interface.TextButton, Mod.ArticleDefinition,
  Mod.Mod, Mod.Unit_, Mod.Armor, Mod.RuleItem;

type
  TArticleStateVehicle = class(TArticleState)
  private
    FTxtTitle: TText;
    FTxtInfo: TText;
    FLstStats: TTextList;
  public
    constructor Create(defs: TArticleDefinitionVehicle);
    destructor Destroy; override;
  end;

implementation

{ TArticleStateVehicle }

constructor TArticleStateVehicle.Create(defs: TArticleDefinitionVehicle);
var
  unit_: TUnit;
  armor: TArmor;
  item: TRuleItem;
  ammo: TRuleItem;
  ss: TStringBuilder;
begin
  inherited Create(defs.Id);
  unit_ := FGame.Mod.GetUnit(defs.Id, True);
  armor := FGame.Mod.GetArmor(unit_.Armor, True);
  item := FGame.Mod.GetItem(defs.Id, True);

  FTxtTitle := TText.Create(310, 17, 5, 23);
  FTxtInfo := TText.Create(300, 150, 10, 122);
  FLstStats := TTextList.Create(300, 89, 10, 48);

  SetPalette('PAL_UFOPAEDIA');
  InitLayout;

  Add(FTxtTitle);
  Add(FTxtInfo);
  Add(FLstStats);

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

  FLstStats.Color := Palette.BlockOffset(15) + 4;
  FLstStats.Columns := [175, 145];
  FLstStats.Dot := True;

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

    FLstStats.AddRow([tr('STR_WEAPON'), tr(defs.Weapon)]);

    if item.CompatibleAmmo.Count > 0 then
    begin
      ammo := FGame.Mod.GetItem(item.CompatibleAmmo[0], True);
      ss.Clear;
      ss.Append(IntToStr(ammo.Power));
      FLstStats.AddRow([tr('STR_WEAPON_POWER'), ss.ToString]);

      FLstStats.AddRow([tr('STR_AMMUNITION'), tr(ammo.Name)]);

      ss.Clear;
      if item.ClipSize > 0 then
        ss.Append(IntToStr(item.ClipSize))
      else
        ss.Append(IntToStr(ammo.ClipSize));
      FLstStats.AddRow([tr('STR_ROUNDS'), ss.ToString]);

      FTxtInfo.Y := 138;
    end
    else
    begin
      ss.Clear;
      ss.Append(IntToStr(item.Power));
      FLstStats.AddRow([tr('STR_WEAPON_POWER'), ss.ToString]);
    end;

  finally
    ss.Free;
  end;

  CenterAllSurfaces;
end;

destructor TArticleStateVehicle.Destroy;
begin
  FTxtTitle.Free;
  FTxtInfo.Free;
  FLstStats.Free;
  inherited;
end;

end.