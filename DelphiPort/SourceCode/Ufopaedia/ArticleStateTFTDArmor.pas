{----------------------------------------------------------------------------}
{ Unit: ArticleStateTFTDArmor                                                }
{ TFTD armor article state.                                                  }
{----------------------------------------------------------------------------}
unit ArticleStateTFTDArmor;

interface

uses
  Classes, SysUtils,
  ArticleStateTFTD, Engine.Game, Engine.Palette, Engine.TextList,
  Engine.LocalizedText, Engine.Unicode, Mod.ArticleDefinition, Mod.Mod,
  Mod.Armor;

type
  TArticleStateTFTDArmor = class(TArticleStateTFTD)
  private
    FRow: Integer;
    FLstInfo: TTextList;
    procedure AddStat(const label_: string; stat: Integer; plus: Boolean = False);
    procedure AddStatString(const label_, stat: string);
  public
    constructor Create(defs: TArticleDefinitionTFTD);
    destructor Destroy; override;
  end;

implementation

uses
  Math;

{ TArticleStateTFTDArmor }

constructor TArticleStateTFTDArmor.Create(defs: TArticleDefinitionTFTD);
var
  armor: TArmor;
  i: Integer;
  dt: TItemDamageType;
  percentage: Integer;
  damage: string;
begin
  inherited Create(defs);
  FTxtInfo.Height := 72;
  FRow := 0;

  armor := FGame.Mod.GetArmor(defs.Id, True);

  FLstInfo := TTextList.Create(150, 64, 168, 110);
  Add(FLstInfo);
  FLstInfo.Color := Palette.BlockOffset(0) + 2;
  FLstInfo.Columns := [125, 25];
  FLstInfo.Dot := True;

  AddStat('STR_FRONT_ARMOR', armor.FrontArmor);
  AddStat('STR_LEFT_ARMOR', armor.SideArmor);
  AddStat('STR_RIGHT_ARMOR', armor.SideArmor);
  AddStat('STR_REAR_ARMOR', armor.RearArmor);
  AddStat('STR_UNDER_ARMOR', armor.UnderArmor);

  FLstInfo.AddRow(0);
  Inc(FRow);

  for i := 0 to TArmor.DAMAGE_TYPES - 1 do
  begin
    dt := TItemDamageType(i);
    percentage := Round(armor.GetDamageModifier(dt) * 100.0);
    damage := GetDamageTypeText(dt);
    if (percentage <> 100) and (damage <> 'STR_UNKNOWN') then
      AddStat(damage, Unicode.FormatPercentage(percentage));
  end;

  FLstInfo.AddRow(0);
  Inc(FRow);

  AddStat('STR_TIME_UNITS', armor.Stats.tu, True);
  AddStat('STR_STAMINA', armor.Stats.stamina, True);
  AddStat('STR_HEALTH', armor.Stats.health, True);
  AddStat('STR_BRAVERY', armor.Stats.bravery, True);
  AddStat('STR_REACTIONS', armor.Stats.reactions, True);
  AddStat('STR_FIRING_ACCURACY', armor.Stats.firing, True);
  AddStat('STR_THROWING_ACCURACY', armor.Stats.throwing, True);
  AddStat('STR_MELEE_ACCURACY', armor.Stats.melee, True);
  AddStat('STR_STRENGTH', armor.Stats.strength, True);
  AddStat('STR_PSIONIC_STRENGTH', armor.Stats.psiStrength, True);
  AddStat('STR_PSIONIC_SKILL', armor.Stats.psiSkill, True);

  CenterAllSurfaces;
end;

destructor TArticleStateTFTDArmor.Destroy;
begin
  FLstInfo.Free;
  inherited;
end;

procedure TArticleStateTFTDArmor.AddStat(const label_: string; stat: Integer; plus: Boolean);
var
  ss: string;
begin
  if stat <> 0 then
  begin
    if plus and (stat > 0) then
      ss := '+' + IntToStr(stat)
    else
      ss := IntToStr(stat);
    FLstInfo.AddRow([tr(label_), ss]);
    FLstInfo.SetCellColor(FRow, 1, Palette.BlockOffset(15) + 4);
    Inc(FRow);
  end;
end;

procedure TArticleStateTFTDArmor.AddStatString(const label_, stat: string);
begin
  FLstInfo.AddRow([tr(label_), stat]);
  FLstInfo.SetCellColor(FRow, 1, Palette.BlockOffset(15) + 4);
  Inc(FRow);
end;

end.