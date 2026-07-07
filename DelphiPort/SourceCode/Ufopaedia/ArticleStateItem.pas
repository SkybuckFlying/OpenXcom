{----------------------------------------------------------------------------}
{ Unit: ArticleStateItem                                                     }
{ Item article state.                                                        }
{----------------------------------------------------------------------------}
unit ArticleStateItem;

interface

uses
  Classes, SysUtils, Generics.Collections,
  ArticleState, Engine.Game, Engine.Palette, Engine.Surface, Engine.Text,
  Engine.TextList, Engine.LocalizedText, Engine.Unicode, Interface.Text,
  Interface.TextButton, Mod.ArticleDefinition, Mod.Mod, Mod.RuleItem;

type
  TArticleStateItem = class(TArticleState)
  private
    FImage: TSurface;
    FTxtTitle: TText;
    FTxtInfo: TText;
    FLstInfo: TTextList;
    FTxtShotType: TText;
    FTxtAccuracy: TText;
    FTxtTuCost: TText;
    FTxtDamage: TText;
    FTxtAmmo: TText;
    FTxtAmmoType: array[0..2] of TText;
    FTxtAmmoDamage: array[0..2] of TText;
    FImageAmmo: array[0..2] of TSurface;
  public
    constructor Create(defs: TArticleDefinitionItem);
    destructor Destroy; override;
  end;

implementation

uses
  Math;

{ TArticleStateItem }

constructor TArticleStateItem.Create(defs: TArticleDefinitionItem);
var
  item: TRuleItem;
  ammo_data: TList<string>;
  i, current_row: Integer;
  ss: TStringBuilder;
  ammo_article: TArticleDefinition;
  ammo_rule: TRuleItem;
begin
  inherited Create(defs.Id);
  item := FGame.Mod.GetItem(defs.Id, True);

  FTxtTitle := TText.Create(148, 32, 5, 24);
  SetPalette('PAL_BATTLEPEDIA');
  InitLayout;

  Add(FTxtTitle);

  FGame.Mod.GetSurface('BACK08.SCR').Blit(FBg);
  FBtnOk.Color := Palette.BlockOffset(9);
  FBtnPrev.Color := Palette.BlockOffset(9);
  FBtnNext.Color := Palette.BlockOffset(9);

  FTxtTitle.Color := Palette.BlockOffset(14) + 15;
  FTxtTitle.Big := True;
  FTxtTitle.WordWrap := True;
  FTxtTitle.Text := tr(defs.Title);

  FImage := TSurface.Create(32, 48, 157, 5);
  Add(FImage);
  item.DrawHandSprite(FGame.Mod.GetSurfaceSet('BIGOBS.PCK'), FImage);

  ammo_data := item.CompatibleAmmo;

  // SHOT STATS TABLE (for firearms only)
  if item.BattleType = BT_FIREARM then
  begin
    FTxtShotType := TText.Create(100, 17, 8, 66);
    Add(FTxtShotType);
    FTxtShotType.Color := Palette.BlockOffset(14) + 15;
    FTxtShotType.WordWrap := True;
    FTxtShotType.Text := tr('STR_SHOT_TYPE');

    FTxtAccuracy := TText.Create(50, 17, 104, 66);
    Add(FTxtAccuracy);
    FTxtAccuracy.Color := Palette.BlockOffset(14) + 15;
    FTxtAccuracy.WordWrap := True;
    FTxtAccuracy.Text := tr('STR_ACCURACY_UC');

    FTxtTuCost := TText.Create(60, 17, 158, 66);
    Add(FTxtTuCost);
    FTxtTuCost.Color := Palette.BlockOffset(14) + 15;
    FTxtTuCost.WordWrap := True;
    FTxtTuCost.Text := tr('STR_TIME_UNIT_COST');

    FLstInfo := TTextList.Create(204, 55, 8, 82);
    Add(FLstInfo);
    FLstInfo.Color := Palette.BlockOffset(15) + 4;
    FLstInfo.Columns := [100, 52, 52];
    FLstInfo.Big := True;

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
      FLstInfo.SetCellColor(current_row, 0, Palette.BlockOffset(14) + 15);
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
      FLstInfo.SetCellColor(current_row, 0, Palette.BlockOffset(14) + 15);
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
      FLstInfo.SetCellColor(current_row, 0, Palette.BlockOffset(14) + 15);
      Inc(current_row);
    end;

    if ammo_data.Count < 3 then
      FTxtInfo := TText.Create(300, 56, 8, 138)
    else
      FTxtInfo := TText.Create(180, 56, 8, 138);
  end
  else
  begin
    FTxtInfo := TText.Create(300, 125, 8, 67);
  end;

  Add(FTxtInfo);
  FTxtInfo.Color := Palette.BlockOffset(14) + 15;
  FTxtInfo.WordWrap := True;
  FTxtInfo.Scrollable := True;
  FTxtInfo.Text := tr(defs.Text);

  // AMMO column
  for i := 0 to 2 do
  begin
    FTxtAmmoType[i] := TText.Create(82, 16, 194, 20 + i * 49);
    Add(FTxtAmmoType[i]);
    FTxtAmmoType[i].Color := Palette.BlockOffset(14) + 15;
    FTxtAmmoType[i].Align := ALIGN_CENTER;
    FTxtAmmoType[i].VerticalAlign := ALIGN_MIDDLE;
    FTxtAmmoType[i].WordWrap := True;

    FTxtAmmoDamage[i] := TText.Create(82, 17, 194, 40 + i * 49);
    Add(FTxtAmmoDamage[i]);
    FTxtAmmoDamage[i].Color := Palette.BlockOffset(2);
    FTxtAmmoDamage[i].Align := ALIGN_CENTER;
    FTxtAmmoDamage[i].Big := True;

    FImageAmmo[i] := TSurface.Create(32, 48, 280, 16 + i * 49);
    Add(FImageAmmo[i]);
  end;

  case item.BattleType of
    BT_FIREARM:
    begin
      FTxtDamage := TText.Create(82, 10, 194, 7);
      Add(FTxtDamage);
      FTxtDamage.Color := Palette.BlockOffset(14) + 15;
      FTxtDamage.Align := ALIGN_CENTER;
      FTxtDamage.Text := tr('STR_DAMAGE_UC');

      FTxtAmmo := TText.Create(50, 10, 268, 7);
      Add(FTxtAmmo);
      FTxtAmmo.Color := Palette.BlockOffset(14) + 15;
      FTxtAmmo.Align := ALIGN_CENTER;
      FTxtAmmo.Text := tr('STR_AMMO');

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
            ammo_rule.DrawHandSprite(FGame.Mod.GetSurfaceSet('BIGOBS.PCK'), FImageAmmo[i]);
          end;
        end;
      end;
    end;

    BT_AMMO, BT_GRENADE, BT_PROXIMITYGRENADE, BT_MELEE:
    begin
      FTxtDamage := TText.Create(82, 10, 194, 7);
      Add(FTxtDamage);
      FTxtDamage.Color := Palette.BlockOffset(14) + 15;
      FTxtDamage.Align := ALIGN_CENTER;
      FTxtDamage.Text := tr('STR_DAMAGE_UC');

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
    end;
  end;

  CenterAllSurfaces;
end;

destructor TArticleStateItem.Destroy;
var
  i: Integer;
begin
  FImage.Free;
  FTxtTitle.Free;
  FTxtInfo.Free;
  FLstInfo.Free;
  FTxtShotType.Free;
  FTxtAccuracy.Free;
  FTxtTuCost.Free;
  FTxtDamage.Free;
  FTxtAmmo.Free;
  for i := 0 to 2 do
  begin
    FTxtAmmoType[i].Free;
    FTxtAmmoDamage[i].Free;
    FImageAmmo[i].Free;
  end;
  inherited;
end;

end.