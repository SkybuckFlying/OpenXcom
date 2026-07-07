unit MCDPatch;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections,
  Yaml, MapDataSet;

type
  TMDCPatch = class
  private
    FBigWalls: TArray<TPair<Integer, Integer>>;
    FTUWalks: TArray<TPair<Integer, Integer>>;
    FTUFlys: TArray<TPair<Integer, Integer>>;
    FTUSlides: TArray<TPair<Integer, Integer>>;
    FDeathTiles: TArray<TPair<Integer, Integer>>;
    FTerrainHeight: TArray<TPair<Integer, Integer>>;
    FSpecialTypes: TArray<TPair<Integer, Integer>>;
    FExplosives: TArray<TPair<Integer, Integer>>;
    FArmors: TArray<TPair<Integer, Integer>>;
    FFlammabilities: TArray<TPair<Integer, Integer>>;
    FFuels: TArray<TPair<Integer, Integer>>;
    FHEBlocks: TArray<TPair<Integer, Integer>>;
    FFootstepSounds: TArray<TPair<Integer, Integer>>;
    FObjectTypes: TArray<TPair<Integer, Integer>>;
    FNoFloors: TArray<TPair<Integer, Boolean>>;
    FStopLOSses: TArray<TPair<Integer, Boolean>>;
    FLOFTS: TArray<TPair<Integer, TArray<Integer>>>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Load(const Node: TYamlNode);
    procedure ModifyData(DataSet: TMapDataSet);
  end;

implementation

{ TMDCPatch }

constructor TMDCPatch.Create;
begin
  inherited;
end;

destructor TMDCPatch.Destroy;
begin
  inherited;
end;

procedure TMDCPatch.Load(const Node: TYamlNode);
begin
  var dataNode := Node['data'];
  if dataNode.IsNull then Exit;
  for var i := 0 to dataNode.Count-1 do
  begin
    var item := dataNode[i];
    var MCDIndex := item['MCDIndex'].AsInteger;
    if item.Has('bigWall') then
    begin
      SetLength(FBigWalls, Length(FBigWalls)+1);
      FBigWalls[High(FBigWalls)] := TPair<Integer,Integer>.Create(MCDIndex, item['bigWall'].AsInteger);
    end;
    if item.Has('TUWalk') then
    begin
      SetLength(FTUWalks, Length(FTUWalks)+1);
      FTUWalks[High(FTUWalks)] := TPair<Integer,Integer>.Create(MCDIndex, item['TUWalk'].AsInteger);
    end;
    if item.Has('TUFly') then
    begin
      SetLength(FTUFlys, Length(FTUFlys)+1);
      FTUFlys[High(FTUFlys)] := TPair<Integer,Integer>.Create(MCDIndex, item['TUFly'].AsInteger);
    end;
    if item.Has('TUSlide') then
    begin
      SetLength(FTUSlides, Length(FTUSlides)+1);
      FTUSlides[High(FTUSlides)] := TPair<Integer,Integer>.Create(MCDIndex, item['TUSlide'].AsInteger);
    end;
    if item.Has('deathTile') then
    begin
      SetLength(FDeathTiles, Length(FDeathTiles)+1);
      FDeathTiles[High(FDeathTiles)] := TPair<Integer,Integer>.Create(MCDIndex, item['deathTile'].AsInteger);
    end;
    if item.Has('terrainHeight') then
    begin
      SetLength(FTerrainHeight, Length(FTerrainHeight)+1);
      FTerrainHeight[High(FTerrainHeight)] := TPair<Integer,Integer>.Create(MCDIndex, item['terrainHeight'].AsInteger);
    end;
    if item.Has('specialType') then
    begin
      SetLength(FSpecialTypes, Length(FSpecialTypes)+1);
      FSpecialTypes[High(FSpecialTypes)] := TPair<Integer,Integer>.Create(MCDIndex, item['specialType'].AsInteger);
    end;
    if item.Has('explosive') then
    begin
      SetLength(FExplosives, Length(FExplosives)+1);
      FExplosives[High(FExplosives)] := TPair<Integer,Integer>.Create(MCDIndex, item['explosive'].AsInteger);
    end;
    if item.Has('armor') then
    begin
      SetLength(FArmors, Length(FArmors)+1);
      FArmors[High(FArmors)] := TPair<Integer,Integer>.Create(MCDIndex, item['armor'].AsInteger);
    end;
    if item.Has('flammability') then
    begin
      SetLength(FFlammabilities, Length(FFlammabilities)+1);
      FFlammabilities[High(FFlammabilities)] := TPair<Integer,Integer>.Create(MCDIndex, item['flammability'].AsInteger);
    end;
    if item.Has('fuel') then
    begin
      SetLength(FFuels, Length(FFuels)+1);
      FFuels[High(FFuels)] := TPair<Integer,Integer>.Create(MCDIndex, item['fuel'].AsInteger);
    end;
    if item.Has('footstepSound') then
    begin
      SetLength(FFootstepSounds, Length(FFootstepSounds)+1);
      FFootstepSounds[High(FFootstepSounds)] := TPair<Integer,Integer>.Create(MCDIndex, item['footstepSound'].AsInteger);
    end;
    if item.Has('HEBlock') then
    begin
      SetLength(FHEBlocks, Length(FHEBlocks)+1);
      FHEBlocks[High(FHEBlocks)] := TPair<Integer,Integer>.Create(MCDIndex, item['HEBlock'].AsInteger);
    end;
    if item.Has('noFloor') then
    begin
      SetLength(FNoFloors, Length(FNoFloors)+1);
      FNoFloors[High(FNoFloors)] := TPair<Integer,Boolean>.Create(MCDIndex, item['noFloor'].AsBoolean);
    end;
    if item.Has('LOFTS') then
    begin
      SetLength(FLOFTS, Length(FLOFTS)+1);
      FLOFTS[High(FLOFTS)] := TPair<Integer,TArray<Integer>>.Create(MCDIndex, item['LOFTS'].AsArray<Integer>);
    end;
    if item.Has('stopLOS') then
    begin
      SetLength(FStopLOSses, Length(FStopLOSses)+1);
      FStopLOSses[High(FStopLOSses)] := TPair<Integer,Boolean>.Create(MCDIndex, item['stopLOS'].AsBoolean);
    end;
    if item.Has('objectType') then
    begin
      SetLength(FObjectTypes, Length(FObjectTypes)+1);
      FObjectTypes[High(FObjectTypes)] := TPair<Integer,Integer>.Create(MCDIndex, item['objectType'].AsInteger);
    end;
  end;
end;

procedure TMDCPatch.ModifyData(DataSet: TMapDataSet);
begin
  for var pair in FBigWalls do
    DataSet.GetObject(pair.Key).SetBigWall(pair.Value);
  for var pair in FTUWalks do
    DataSet.GetObject(pair.Key).SetTUWalk(pair.Value);
  for var pair in FTUFlys do
    DataSet.GetObject(pair.Key).SetTUFly(pair.Value);
  for var pair in FTUSlides do
    DataSet.GetObject(pair.Key).SetTUSlide(pair.Value);
  for var pair in FDeathTiles do
    DataSet.GetObject(pair.Key).SetDieMCD(pair.Value);
  for var pair in FTerrainHeight do
    DataSet.GetObject(pair.Key).SetTerrainLevel(pair.Value);
  for var pair in FSpecialTypes do
    DataSet.GetObject(pair.Key).SetSpecialType(pair.Value, DataSet.GetObject(pair.Key).GetObjectType);
  for var pair in FExplosives do
    DataSet.GetObject(pair.Key).SetExplosive(pair.Value);
  for var pair in FArmors do
    DataSet.GetObject(pair.Key).SetArmor(pair.Value);
  for var pair in FFlammabilities do
    DataSet.GetObject(pair.Key).SetFlammable(pair.Value);
  for var pair in FFuels do
    DataSet.GetObject(pair.Key).SetFuel(pair.Value);
  for var pair in FHEBlocks do
    DataSet.GetObject(pair.Key).SetHEBlock(pair.Value);
  for var pair in FFootstepSounds do
    DataSet.GetObject(pair.Key).SetFootstepSound(pair.Value);
  for var pair in FObjectTypes do
    DataSet.GetObject(pair.Key).SetObjectType(TTilePart(pair.Value));
  for var pair in FNoFloors do
    DataSet.GetObject(pair.Key).SetNoFloor(pair.Value);
  for var pair in FStopLOSses do
    DataSet.GetObject(pair.Key).SetStopLOS(pair.Value);
  for var pair in FLOFTS do
  begin
    var layer := 0;
    for var loftId in pair.Value do
    begin
      DataSet.GetObject(pair.Key).SetLoftID(loftId, layer);
      Inc(layer);
    end;
  end;
end;

end.