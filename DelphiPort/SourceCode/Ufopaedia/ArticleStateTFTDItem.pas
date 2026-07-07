{----------------------------------------------------------------------------}
{ Unit: ArticleStateTFTDItem                                                 }
{ TFTD item article state.                                                   }
{----------------------------------------------------------------------------}
unit ArticleStateTFTDItem;

interface

uses
  Classes, SysUtils, Generics.Collections,
  ArticleStateTFTD, Engine.Game, Engine.Palette, Engine.Text,
  Engine.TextList, Engine.LocalizedText, Engine.Unicode, Mod.ArticleDefinition,
  Mod.Mod, Mod.RuleItem;

type
  TArticleStateTFTDItem = class(TArticleStateTFTD)
  private
    FLstInfo: TTextList;
    FTxtShotType: TText;
    FTxtAccuracy: TText;
    FTxtTuCost: TText;
    FTxtAmmoType: array[0..2] of TText;
    FTxtAmmoDamage: array[0..2] of TText;
  public
    constructor Create(defs: TArticleDefinitionTFTD);
    destructor Destroy; override;
  end;

implementation

uses
  Math;

{ TArticleStateTFTDItem }

constructor TArticleStateTFTDItem.Create(defs: TArticleDefinitionTFTD);
var
  item: TRuleItem;
  ammo_data: TList<string>;
  i: Integer;
  ss: TStringBuilder;
  ammo_article: TArticleDefinition;
  ammo_rule: TRuleItem;
  current_row: Integer;
begin
  inherited Create(defs);
  item := FGame.Mod.GetItem(defs.Id, True);

  ammo_data := item.CompatibleAmmo;

  // SHOT STATS TABLE (for firearms only)
  if item.BattleType = BT_FIREARM then
  begin
    FTxtShotType := TText.Create(53, 17, 8, 157);
    Add(FTxtShotType);
    FTxtShotType.Color := Palette.BlockOffset(0) + 2;
    FTxtShotType.WordWrap := True;
    FTxtShotType.Text := tr('STR_SHOT_TYPE');

    FTxtAccuracy := TText.Create(57, 17, 61, 157);
    Add(FTxtAccuracy);
    FTxtAccuracy.Color := Palette.BlockOffset(0) + 2;
    FTxtAccuracy.WordWrap := True;
    FTxtAccuracy.Text := tr('STR_ACCURACY_UC');

    FTxtTuCost := TText.Create(56, 17, 118, 157);
    Add(FTxtTuCost);
    FTxtTuCost.Color := Palette.BlockOffset(0) + 2;
    FTxtTuCost.WordWrap := True;
    FTxtTuCost.Text := tr('STR_TIME_UNIT_COST');

    FLstInfo := TTextList.Create(140, 55, 8, 170);
    Add(FLstInfo);
    FLstInfo.Color := Palette.BlockOffset(15) + 4;
    FLstInfo.Columns := [70, 40, 30];

    current_row := 0;
    if item.TUAuto > 0 then
    begin
      ss := TStringBuilder.Create;
      try
        ss.Append(Unicode.FormatPercentage(item.TUAuto));
        if item.FlatRate then
          ss.Length := ss.Length - 1;
        FLstInfo.AddRow([tr('STR_SHOT_TYPE_AUTO'),
                         Unicode.FormatPercentage(item.AccuracyAuto),
                         ss.ToString]);
      finally
        ss.Free;
      end;
      FLstInfo.SetCellColor(current_row, 0, Palette.BlockOffset(0) + 2);
      Inc(current_row);
    end;

    if item.TUSnap > 0 then
    begin
      ss := TStringBuilder.Create;
      try
        ss.Append(Unicode.FormatPercentage(item.TUSnap));
        if item.FlatRate then
          ss.Length := ss.Length - 1;
        FLstInfo.AddRow([tr('STR_SHOT_TYPE_SNAP'),
                         Unicode.FormatPercentage(item.AccuracySnap),
                         ss.ToString]);
      finally
        ss.Free;
      end;
      FLstInfo.SetCellColor(current_row, 0, Palette.BlockOffset(0) + 2);
      Inc(current_row);
    end;

    if item.TUAimed > 0 then
    begin
      ss := TStringBuilder.Create;
      try
        ss.Append(Unicode.FormatPercentage(item.TUAimed));
        if item.FlatRate then
          ss.Length := ss.Length - 1;
        FLstInfo.AddRow([tr('STR_SHOT_TYPE_AIMED'),
                         Unicode.FormatPercentage(item.AccuracyAimed),
                         ss.ToString]);
      finally
        ss.Free;
      end;
      FLstInfo.SetCellColor(current_row, 0, Palette.BlockOffset(0) + 2);
    end;
  end;

  // AMMO column
  for i := 0 to 2 do
  begin
    FTxtAmmoType[i] := TText.Create(120, 9, 168, 144 + i * 10);
    Add(FTxtAmmoType[i]);
    FTxtAmmoType[i].Color := Palette.BlockOffset(0) + 2;
    FTxtAmmoType[i].WordWrap := True;

    FTxtAmmoDamage[i] := TText.Create(20, 9, 300, 144 + i * 10);
    Add(FTxtAmmoDamage[i]);
    FTxtAmmoDamage[i].Color := Palette.BlockOffset(3) + 6;
  end;

  case item.BattleType of
    BT_FIREARM:
    begin
      if ammo_data.Count = 0 then
      begin
        FTxtAmmoType[0].Text := tr(GetDamageTypeText(item.DamageType));
        ss := TStringBuilder.Create;
        try
          ss.Append(IntToStr(item.Power));
          if item.ShotgunPellets > 0 then
            ss.Append('x').Append(IntToStr(item.ShotgunPellets));
          FTxtAmmoDamage[0].Text := ss.ToString;
        finally
          ss.Free;
        end;
      end
      else
      begin
        for i := 0 to Min(ammo_data.Count, 3) - 1 do
        begin
          ammo_article := FGame.Mod.GetUfopaediaArticle(ammo_data[i], True);
          if TUfopaedia.IsArticleAvailable(FGame.SavedGame, ammo_article) then
          begin
            ammo_rule := FGame.Mod.GetItem(ammo_data[i], True);
            FTxtAmmoType[i].Text := tr(GetDamageTypeText(ammo_rule.DamageType));
            ss := TStringBuilder.Create;
            try
              ss.Append(IntToStr(ammo_rule.Power));
              if ammo_rule.ShotgunPellets > 0 then
                ss.Append('x').Append(IntToStr(ammo_rule.ShotgunPellets));
              FTxtAmmoDamage[i].Text := ss.ToString;
            finally
              ss.Free;
            end;
          end;
        end;
      end;
    end;

    BT_AMMO, BT_GRENADE, BT_PROXIMITYGRENADE, BT_MELEE:
    begin
      FTxtAmmoType[0].Text := tr(GetDamageTypeText(item.DamageType));
      ss := TStringBuilder.Create;
      try
        ss.Append(IntToStr(item.Power));
        FTxtAmmoDamage[0].Text := ss.ToString;
      finally
        ss.Free;
      end;
    end;
  end;

  if FTxtAmmoType[0].Text <> '' then
    FTxtInfo.Height := 112;

  CenterAllSurfaces;
end;

destructor TArticleStateTFTDItem.Destroy;
var
  i: Integer;
begin
  FLstInfo.Free;
  FTxtShotType.Free;
  FTxtAccuracy.Free;
  FTxtTuCost.Free;
  for i := 0 to 2 do
  begin
    FTxtAmmoType[i].Free;
    FTxtAmmoDamage[i].Free;
  end;
  inherited;
end;

end.