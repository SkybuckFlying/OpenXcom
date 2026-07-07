{----------------------------------------------------------------------------}
{ Unit: Ufopaedia                                                            }
{ Static class for Ufopaedia navigation and article management.              }
{----------------------------------------------------------------------------}
unit Ufopaedia;

interface

uses
  Classes, SysUtils, Generics.Collections,
  Engine.Game, Savegame.SavedGame, Mod.Mod, Mod.ArticleDefinition,
  ArticleState;

type
  TArticleDefinitionList = TList<TArticleDefinition>;

  TUfopaedia = class
  private
    class var FCurrentIndex: Integer;
    class function GetArticleIndex(save: TSavedGame; mod_: TMod; var article_id: string): Integer;
    class function GetAvailableArticles(save: TSavedGame; mod_: TMod): TArticleDefinitionList;
    class function CreateArticleState(article: TArticleDefinition): TArticleState;
  public
    class function IsArticleAvailable(save: TSavedGame; article: TArticleDefinition): Boolean;
    class procedure OpenArticle(game: TGame; article_id: string); overload;
    class procedure OpenArticle(game: TGame; article: TArticleDefinition); overload;
    class procedure Open(game: TGame);
    class procedure Next(game: TGame);
    class procedure Prev(game: TGame);
    class procedure List(save: TSavedGame; mod_: TMod; const section: string; data: TArticleDefinitionList);
  end;

const
  UFOPAEDIA_NOT_AVAILABLE = 'STR_NOT_AVAILABLE';

implementation

uses
  ArticleStateBaseFacility, ArticleStateCraft, ArticleStateCraftWeapon,
  ArticleStateItem, ArticleStateArmor, ArticleStateText, ArticleStateTextImage,
  ArticleStateUfo, ArticleStateVehicle,
  ArticleStateTFTD, ArticleStateTFTDArmor, ArticleStateTFTDVehicle,
  ArticleStateTFTDItem, ArticleStateTFTDFacility, ArticleStateTFTDCraft,
  ArticleStateTFTDCraftWeapon, ArticleStateTFTDUso,
  UfopaediaStartState;

{ TUfopaedia }

class function TUfopaedia.IsArticleAvailable(save: TSavedGame; article: TArticleDefinition): Boolean;
begin
  Result := save.IsResearched(article.Requires);
end;

class function TUfopaedia.GetArticleIndex(save: TSavedGame; mod_: TMod; var article_id: string): Integer;
var
  list: TArticleDefinitionList;
  i: Integer;
  UC_ID: string;
  j: string;
begin
  UC_ID := article_id + '_UC';
  list := GetAvailableArticles(save, mod_);
  try
    for i := 0 to list.Count - 1 do
    begin
      if list[i].Id = article_id then
        Exit(i);
    end;
    for i := 0 to list.Count - 1 do
    begin
      if list[i].Id = UC_ID then
      begin
        article_id := UC_ID;
        Exit(i);
      end;
    end;
    for i := 0 to list.Count - 1 do
    begin
      for j in list[i].Requires do
      begin
        if article_id = j then
        begin
          article_id := list[i].Id;
          Exit(i);
        end;
      end;
    end;
  finally
    list.Free;
  end;
  Result := -1;
end;

class function TUfopaedia.GetAvailableArticles(save: TSavedGame; mod_: TMod): TArticleDefinitionList;
var
  list: TStringList;
  article: TArticleDefinition;
begin
  Result := TArticleDefinitionList.Create;
  list := mod_.GetUfopaediaList;
  try
    for var s in list do
    begin
      article := mod_.GetUfopaediaArticle(s);
      if IsArticleAvailable(save, article) and (article.Section <> UFOPAEDIA_NOT_AVAILABLE) then
        Result.Add(article);
    end;
  finally
    list.Free;
  end;
end;

class function TUfopaedia.CreateArticleState(article: TArticleDefinition): TArticleState;
begin
  case article.ArticleType of
    UFOPAEDIA_TYPE_CRAFT:
      Result := TArticleStateCraft.Create(article as TArticleDefinitionCraft);
    UFOPAEDIA_TYPE_CRAFT_WEAPON:
      Result := TArticleStateCraftWeapon.Create(article as TArticleDefinitionCraftWeapon);
    UFOPAEDIA_TYPE_VEHICLE:
      Result := TArticleStateVehicle.Create(article as TArticleDefinitionVehicle);
    UFOPAEDIA_TYPE_ITEM:
      Result := TArticleStateItem.Create(article as TArticleDefinitionItem);
    UFOPAEDIA_TYPE_ARMOR:
      Result := TArticleStateArmor.Create(article as TArticleDefinitionArmor);
    UFOPAEDIA_TYPE_BASE_FACILITY:
      Result := TArticleStateBaseFacility.Create(article as TArticleDefinitionBaseFacility);
    UFOPAEDIA_TYPE_TEXT:
      Result := TArticleStateText.Create(article as TArticleDefinitionText);
    UFOPAEDIA_TYPE_TEXTIMAGE:
      Result := TArticleStateTextImage.Create(article as TArticleDefinitionTextImage);
    UFOPAEDIA_TYPE_UFO:
      Result := TArticleStateUfo.Create(article as TArticleDefinitionUfo);
    UFOPAEDIA_TYPE_TFTD:
      Result := TArticleStateTFTD.Create(article as TArticleDefinitionTFTD);
    UFOPAEDIA_TYPE_TFTD_CRAFT:
      Result := TArticleStateTFTDCraft.Create(article as TArticleDefinitionTFTD);
    UFOPAEDIA_TYPE_TFTD_CRAFT_WEAPON:
      Result := TArticleStateTFTDCraftWeapon.Create(article as TArticleDefinitionTFTD);
    UFOPAEDIA_TYPE_TFTD_VEHICLE:
      Result := TArticleStateTFTDVehicle.Create(article as TArticleDefinitionTFTD);
    UFOPAEDIA_TYPE_TFTD_ITEM:
      Result := TArticleStateTFTDItem.Create(article as TArticleDefinitionTFTD);
    UFOPAEDIA_TYPE_TFTD_ARMOR:
      Result := TArticleStateTFTDArmor.Create(article as TArticleDefinitionTFTD);
    UFOPAEDIA_TYPE_TFTD_BASE_FACILITY:
      Result := TArticleStateTFTDFacility.Create(article as TArticleDefinitionTFTD);
    UFOPAEDIA_TYPE_TFTD_USO:
      Result := TArticleStateTFTDUso.Create(article as TArticleDefinitionTFTD);
  else
    Result := nil;
  end;
end;

class procedure TUfopaedia.OpenArticle(game: TGame; article_id: string);
var
  id: string;
  idx: Integer;
  article: TArticleDefinition;
begin
  id := article_id;
  idx := GetArticleIndex(game.SavedGame, game.Mod, id);
  if idx <> -1 then
  begin
    FCurrentIndex := idx;
    article := game.Mod.GetUfopaediaArticle(id);
    game.PushState(CreateArticleState(article));
  end;
end;

class procedure TUfopaedia.OpenArticle(game: TGame; article: TArticleDefinition);
var
  id: string;
begin
  id := article.Id;
  FCurrentIndex := GetArticleIndex(game.SavedGame, game.Mod, id);
  if FCurrentIndex <> -1 then
    game.PushState(CreateArticleState(article));
end;

class procedure TUfopaedia.Open(game: TGame);
begin
  game.PushState(TUfopaediaStartState.Create);
end;

class procedure TUfopaedia.Next(game: TGame);
var
  list: TArticleDefinitionList;
begin
  list := GetAvailableArticles(game.SavedGame, game.Mod);
  try
    if FCurrentIndex >= list.Count - 1 then
      FCurrentIndex := 0
    else
      Inc(FCurrentIndex);
    game.PopState;
    game.PushState(CreateArticleState(list[FCurrentIndex]));
  finally
    list.Free;
  end;
end;

class procedure TUfopaedia.Prev(game: TGame);
var
  list: TArticleDefinitionList;
begin
  list := GetAvailableArticles(game.SavedGame, game.Mod);
  try
    if FCurrentIndex = 0 then
      FCurrentIndex := list.Count - 1
    else
      Dec(FCurrentIndex);
    game.PopState;
    game.PushState(CreateArticleState(list[FCurrentIndex]));
  finally
    list.Free;
  end;
end;

class procedure TUfopaedia.List(save: TSavedGame; mod_: TMod; const section: string; data: TArticleDefinitionList);
var
  list: TArticleDefinitionList;
  a: TArticleDefinition;
begin
  list := GetAvailableArticles(save, mod_);
  try
    for a in list do
      if a.Section = section then
        data.Add(a);
  finally
    list.Free;
  end;
end;

initialization
  TUfopaedia.FCurrentIndex := 0;

end.