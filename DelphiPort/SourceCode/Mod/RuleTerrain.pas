unit RuleTerrain;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections,
  Yaml, MapBlock, MapDataSet, ModUnit, Engine.RNG;

type
  TRuleTerrain = class
  private
    FName: string;
    FScript: string;
    FCivilianTypes: TArray<string>;
    FMusic: TArray<string>;
    FMinDepth: Integer;
    FMaxDepth: Integer;
    FAmbience: Integer;
    FAmbientVolume: Double;
    FMapDataSets: TArray<TMapDataSet>;
    FMapBlocks: TArray<TMapBlock>;
  public
    constructor Create(const AName: string);
    destructor Destroy; override;
    procedure Load(const Node: TYamlNode; ModObj: TMod);
    function GetName: string;
    function GetScript: string;
    function GetCivilianTypes: TArray<string>;
    function GetMusic: TArray<string>;
    function GetMinDepth: Integer;
    function GetMaxDepth: Integer;
    function GetAmbience: Integer;
    function GetAmbientVolume: Double;
    function GetMapBlocks: TArray<TMapBlock>;
    function GetMapDataSets: TArray<TMapDataSet>;
    function GetRandomMapBlock(MaxSizeX, MaxSizeY, Group: Integer; Force: Boolean = True): TMapBlock;
    function GetMapBlock(const Name: string): TMapBlock;
    function GetMapData(var Id: Integer; var MapDataSetId: Integer): TMapData;
  end;

implementation

{ TRuleTerrain }

constructor TRuleTerrain.Create(const AName: string);
begin
  inherited Create;
  FName := AName;
  FScript := 'DEFAULT';
  FMinDepth := 0; FMaxDepth := 0; FAmbience := -1; FAmbientVolume := 0.5;
  FCivilianTypes := ['MALE_CIVILIAN', 'FEMALE_CIVILIAN'];
end;

destructor TRuleTerrain.Destroy;
begin
  for var block in FMapBlocks do block.Free;
  inherited;
end;

procedure TRuleTerrain.Load(const Node: TYamlNode; ModObj: TMod);
begin
  var dsNode := Node['mapDataSets'];
  if not dsNode.IsNull then
  begin
    FMapDataSets := [];
    for var item in dsNode do
      FMapDataSets := FMapDataSets + [ModObj.GetMapDataSet(item.AsString)];
  end;

  var blockNode := Node['mapBlocks'];
  if not blockNode.IsNull then
  begin
    for var block in FMapBlocks do block.Free;
    FMapBlocks := [];
    for var item in blockNode do
    begin
      var mb := TMapBlock.Create(item['name'].AsString);
      mb.Load(item);
      FMapBlocks := FMapBlocks + [mb];
    end;
  end;

  FName := Node['name'].AsString(FName);
  var civNode := Node['civilianTypes'];
  if not civNode.IsNull then
    FCivilianTypes := civNode.AsArray<string>(FCivilianTypes);

  var musNode := Node['music'];
  if not musNode.IsNull then
  begin
    FMusic := [];
    for var item in musNode do
      FMusic := FMusic + [item.AsString];
  end;

  var depthNode := Node['depth'];
  if not depthNode.IsNull then
  begin
    FMinDepth := depthNode[0].AsInteger(FMinDepth);
    FMaxDepth := depthNode[1].AsInteger(FMaxDepth);
  end;
  ModObj.LoadSoundOffset(FName, FAmbience, Node['ambience'], 'BATTLE.CAT');
  FAmbientVolume := Node['ambientVolume'].AsDouble(FAmbientVolume);
  FScript := Node['script'].AsString(FScript);
end;

function TRuleTerrain.GetName: string; begin Result := FName; end;
function TRuleTerrain.GetScript: string; begin Result := FScript; end;
function TRuleTerrain.GetCivilianTypes: TArray<string>; begin Result := FCivilianTypes; end;
function TRuleTerrain.GetMusic: TArray<string>; begin Result := FMusic; end;
function TRuleTerrain.GetMinDepth: Integer; begin Result := FMinDepth; end;
function TRuleTerrain.GetMaxDepth: Integer; begin Result := FMaxDepth; end;
function TRuleTerrain.GetAmbience: Integer; begin Result := FAmbience; end;
function TRuleTerrain.GetAmbientVolume: Double; begin Result := FAmbientVolume; end;
function TRuleTerrain.GetMapBlocks: TArray<TMapBlock>; begin Result := FMapBlocks; end;
function TRuleTerrain.GetMapDataSets: TArray<TMapDataSet>; begin Result := FMapDataSets; end;

function TRuleTerrain.GetRandomMapBlock(MaxSizeX, MaxSizeY, Group: Integer; Force: Boolean = True): TMapBlock;
var
  candidates: TArray<TMapBlock>;
  idx: Integer;
begin
  candidates := [];
  for var block in FMapBlocks do
    if ((block.GetSizeX = MaxSizeX) or ((not Force) and (block.GetSizeX < MaxSizeX))) and
       ((block.GetSizeY = MaxSizeY) or ((not Force) and (block.GetSizeY < MaxSizeY))) and
       block.IsInGroup(Group) then
      candidates := candidates + [block];
  if Length(candidates) = 0 then Exit(nil);
  idx := RNG.Generate(0, Length(candidates)-1);
  Result := candidates[idx];
end;

function TRuleTerrain.GetMapBlock(const Name: string): TMapBlock;
begin
  for var block in FMapBlocks do
    if block.GetName = Name then
      Exit(block);
  Result := nil;
end;

function TRuleTerrain.GetMapData(var Id: Integer; var MapDataSetId: Integer): TMapData;
var
  mdf: TMapDataSet;
  i: Integer;
begin
  for i := 0 to High(FMapDataSets) do
  begin
    mdf := FMapDataSets[i];
    if Id < mdf.GetSize then
    begin
      Result := mdf.GetObject(Id);
      MapDataSetId := i;
      Exit;
    end;
    Id := Id - mdf.GetSize;
  end;
  // Fallback
  mdf := FMapDataSets[0];
  Id := 0;
  MapDataSetId := 0;
  Result := mdf.GetObject(0);
end;

end.