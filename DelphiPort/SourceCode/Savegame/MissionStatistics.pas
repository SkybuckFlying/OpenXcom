unit MissionStatistics;

interface

uses
  Classes, SysUtils, YAML, GameTime, Language, TileEngine;

type
  TMissionStatistics = class
  private
    FId: Integer;
    FMarkerName: string;
    FMarkerId: Integer;
    FTime: TGameTime;
    FRegion: string;
    FCountry: string;
    FType: string;
    FUfo: string;
    FSuccess: Boolean;
    FRating: string;
    FScore: Integer;
    FAlienRace: string;
    FDaylight: Integer;
    FInjuryList: TDictionary<Integer, Integer>;
    FValiantCrux: Boolean;
    FLootValue: Integer;
  public
    constructor Create; overload;
    constructor Create(const Node: TYamlNode); overload;
    destructor Destroy; override;
    procedure Load(const Node: TYamlNode);
    function Save: TYamlNode;
    function GetMissionName(Lang: TLanguage): string;
    function GetRatingString(Lang: TLanguage): string;
    function GetLocationString: string;
    function IsDarkness: Boolean;
    function GetDaylightString: string;
    function IsAlienBase: Boolean;
    function IsBaseDefense: Boolean;
    function IsUfoMission: Boolean;
    property Id: Integer read FId;
    property Time: TGameTime read FTime;
    property Region: string read FRegion;
    property Country: string read FCountry;
    property &Type: string read FType;
    property Ufo: string read FUfo;
    property Success: Boolean read FSuccess;
    property Rating: string read FRating;
    property Score: Integer read FScore;
    property AlienRace: string read FAlienRace;
    property Daylight: Integer read FDaylight;
    property InjuryList: TDictionary<Integer, Integer> read FInjuryList;
    property ValiantCrux: Boolean read FValiantCrux;
    property LootValue: Integer read FLootValue;
  end;

implementation

constructor TMissionStatistics.Create;
begin
  FTime := TGameTime.Create(0,0,0,0,0,0,0);
  FInjuryList := TDictionary<Integer, Integer>.Create;
  FRegion := 'STR_REGION_UNKNOWN';
  FCountry := 'STR_UNKNOWN';
  FUfo := 'NO_UFO';
  FSuccess := False;
  FScore := 0;
  FAlienRace := 'STR_UNKNOWN';
  FDaylight := 0;
  FValiantCrux := False;
  FLootValue := 0;
end;

constructor TMissionStatistics.Create(const Node: TYamlNode);
begin
  Create;
  Load(Node);
end;

destructor TMissionStatistics.Destroy;
begin
  FTime.Free;
  FInjuryList.Free;
  inherited;
end;

procedure TMissionStatistics.Load(const Node: TYamlNode);
begin
  FId := Node['id'].AsInteger(FId);
  FMarkerName := Node['markerName'].AsString(FMarkerName);
  FMarkerId := Node['markerId'].AsInteger(FMarkerId);
  FTime.Load(Node['time']);
  FRegion := Node['region'].AsString(FRegion);
  FCountry := Node['country'].AsString(FCountry);
  FType := Node['type'].AsString(FType);
  FUfo := Node['ufo'].AsString(FUfo);
  FSuccess := Node['success'].AsBoolean(FSuccess);
  FScore := Node['score'].AsInteger(FScore);
  FRating := Node['rating'].AsString(FRating);
  FAlienRace := Node['alienRace'].AsString(FAlienRace);
  FDaylight := Node['daylight'].AsInteger(FDaylight);
  FInjuryList.Clear;
  for var pair in Node['injuryList'] do
    FInjuryList.Add(pair.Key.AsInteger, pair.Value.AsInteger);
  FValiantCrux := Node['valiantCrux'].AsBoolean(FValiantCrux);
  FLootValue := Node['lootValue'].AsInteger(FLootValue);
end;

function TMissionStatistics.Save: TYamlNode;
begin
  Result := TYamlNode.Create;
  Result['id'] := FId;
  if FMarkerName <> '' then
  begin
    Result['markerName'] := FMarkerName;
    Result['markerId'] := FMarkerId;
  end;
  Result['time'] := FTime.Save;
  Result['region'] := FRegion;
  Result['country'] := FCountry;
  Result['type'] := FType;
  Result['ufo'] := FUfo;
  Result['success'] := FSuccess;
  Result['score'] := FScore;
  Result['rating'] := FRating;
  Result['alienRace'] := FAlienRace;
  Result['daylight'] := FDaylight;
  for var pair in FInjuryList do
    Result['injuryList'][pair.Key] := pair.Value;
  if FValiantCrux then Result['valiantCrux'] := FValiantCrux;
  if FLootValue <> 0 then Result['lootValue'] := FLootValue;
end;

function TMissionStatistics.GetMissionName(Lang: TLanguage): string;
begin
  if FMarkerName <> '' then
    Result := Lang.GetString(FMarkerName) + ' ' + IntToStr(FMarkerId)
  else
    Result := Lang.GetString(FType);
end;

function TMissionStatistics.GetRatingString(Lang: TLanguage): string;
begin
  if FSuccess then
    Result := Lang.GetString('STR_VICTORY')
  else
    Result := Lang.GetString('STR_DEFEAT');
  Result := Result + ' - ' + Lang.GetString(FRating);
end;

function TMissionStatistics.GetLocationString: string;
begin
  if FCountry = 'STR_UNKNOWN' then
    Result := FRegion
  else
    Result := FCountry;
end;

function TMissionStatistics.IsDarkness: Boolean;
begin
  Result := FDaylight > TileEngine.MAX_DARKNESS_TO_SEE_UNITS;
end;

function TMissionStatistics.GetDaylightString: string;
begin
  if IsDarkness then Result := 'STR_NIGHT' else Result := 'STR_DAY';
end;

function TMissionStatistics.IsAlienBase: Boolean;
begin
  Result := (FType = 'STR_ALIEN_BASE') or (FType = 'STR_ALIEN_COLONY');
end;

function TMissionStatistics.IsBaseDefense: Boolean;
begin
  Result := FType = 'STR_BASE_DEFENSE';
end;

function TMissionStatistics.IsUfoMission: Boolean;
begin
  Result := FUfo <> 'NO_UFO';
end;

end.