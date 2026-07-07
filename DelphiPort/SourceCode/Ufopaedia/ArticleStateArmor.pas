{----------------------------------------------------------------------------}
{ Unit: ArticleStateArmor                                                    }
{ Armor article state (UFOpaedia).                                           }
{----------------------------------------------------------------------------}
unit ArticleStateArmor;

interface

uses
  Classes, SysUtils, Generics.Collections,
  ArticleState, Engine.Game, Engine.Palette, Engine.Surface, Engine.Text,
  Engine.TextList, Engine.LocalizedText, Engine.CrossPlatform, Engine.FileMap,
  Engine.Unicode, Interface.Text, Interface.TextButton, Mod.ArticleDefinition,
  Mod.Mod, Mod.Armor;

type
  TArticleStateArmor = class(TArticleState)
  private
    FRow: Integer;
    FImage: TSurface;
    FTxtTitle: TText;
    FLstInfo: TTextList;
    FTxtInfo: TText;
    procedure AddStat(const label_: string; stat: Integer; plus: Boolean = False);
    procedure AddStatString(const label_, stat: string);
  public
    constructor Create(defs: TArticleDefinitionArmor);
    destructor Destroy; override;
  end;

implementation

uses
  Math;

{ TArticleStateArmor }

constructor TArticleStateArmor.Create(defs: TArticleDefinitionArmor);
var
  armor: TArmor;
  look: string;
  i: Integer;
  dt: TItemDamageType;
  percentage: Integer;
  damage: string;
begin
  inherited Create(defs.Id);
  FRow := 0;
  armor := FGame.Mod.GetArmor(defs.Id, True);

  FTxtTitle := TText.Create(300, 17, 5, 24);
  SetPalette('PAL_BATTLEPEDIA');

  InitLayout;

  Add(FTxtTitle);

  FBtnOk.Color := Palette.BlockOffset(0) + 15;
  FBtnPrev.Color := Palette.BlockOffset(0) + 15;
  FBtnNext.Color := Palette.BlockOffset(0) + 15;

  FTxtTitle.Color := Palette.BlockOffset(14) + 15;
  FTxtTitle.Big := True;
  FTxtTitle.Text := tr(defs.Title);

  FImage := TSurface.Create(320, 200, 0, 0);
  Add(FImage);

  look := armor.SpriteInventory + 'M0.SPK';
  if not FGame.Mod.GetSurface(look, False) then
  begin
    look := armor.SpriteInventory + '.SPK';
    if not FGame.Mod.GetSurface(look, False) then
      look := armor.SpriteInventory;
  end;
  FGame.Mod.GetSurface(look).Blit(FImage);

  FLstInfo := TTextList.Create(150, 96, 150, 46);
  Add(FLstInfo);
  FLstInfo.Color := Palette.BlockOffset(14) + 15;
  FLstInfo.Columns := [125, 25];
  FLstInfo.Dot := True;

  FTxtInfo := TText.Create(300, 48, 8, 150);
  Add(FTxtInfo);
  FTxtInfo.Color := Palette.BlockOffset(14) + 15;
  FTxtInfo.WordWrap := True;
  FTxtInfo.Scrollable := True;
  FTxtInfo.Text := tr(defs.Text);

  // Add armor values
  AddStat('STR_FRONT_ARMOR', armor.FrontArmor);
  AddStat('STR_LEFT_ARMOR', armor.SideArmor);
  AddStat('STR_RIGHT_ARMOR', armor.SideArmor);
  AddStat('STR_REAR_ARMOR', armor.RearArmor);
  AddStat('STR_UNDER_ARMOR', armor.UnderArmor);

  FLstInfo.AddRow(0);
  Inc(FRow);

  // Add damage modifiers
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

  // Add unit stats
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

destructor TArticleStateArmor.Destroy;
begin
  FImage.Free;
  FTxtTitle.Free;
  FLstInfo.Free;
  FTxtInfo.Free;
  inherited;
end;

procedure TArticleStateArmor.AddStat(const label_: string; stat: Integer; plus: Boolean);
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

procedure TArticleStateArmor.AddStatString(const label_, stat: string);
begin
  FLstInfo.AddRow([tr(label_), stat]);
  FLstInfo.SetCellColor(FRow, 1, Palette.BlockOffset(15) + 4);
  Inc(FRow);
end;

end.