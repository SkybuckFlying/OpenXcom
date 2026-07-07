unit RuleGlobe;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections,
  Yaml, Polygon, Polyline, Texture, Engine.Palette, Geoscape.Globe, Engine.FileMap;

type
  TRuleGlobe = class
  private
    FPolygons: TList<TPolygon>;
    FPolylines: TList<TPolyline>;
    FTextures: TDictionary<Integer, TTexture>;
    procedure LoadDat(const FileName: string);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Load(const Node: TYamlNode);
    function GetPolygons: TList<TPolygon>;
    function GetPolylines: TList<TPolyline>;
    function GetTexture(Id: Integer): TTexture;
    function GetTerrains(const Deployment: string): TArray<string>;
  end;

implementation

{ TRuleGlobe }

constructor TRuleGlobe.Create;
begin
  inherited Create;
  FPolygons := TList<TPolygon>.Create;
  FPolylines := TList<TPolyline>.Create;
  FTextures := TDictionary<Integer, TTexture>.Create;
end;

destructor TRuleGlobe.Destroy;
begin
  FPolygons.Free;
  FPolylines.Free;
  FTextures.Free;
  inherited;
end;

procedure TRuleGlobe.Load(const Node: TYamlNode);
begin
  // Load polygons from data or inline
  var dataNode := Node['data'];
  if not dataNode.IsNull then
  begin
    FPolygons.Clear;
    LoadDat(TFileMap.GetFilePath(dataNode.AsString));
  end;
  // ... load other parts
  Globe.COUNTRY_LABEL_COLOR := Node['countryColor'].AsInteger(Globe.COUNTRY_LABEL_COLOR);
  // ...
end;

procedure TRuleGlobe.LoadDat(const FileName: string);
begin
  // Implementation similar to C++ version
end;

function TRuleGlobe.GetPolygons: TList<TPolygon>;
begin
  Result := FPolygons;
end;

function TRuleGlobe.GetPolylines: TList<TPolyline>;
begin
  Result := FPolylines;
end;

function TRuleGlobe.GetTexture(Id: Integer): TTexture;
begin
  FTextures.TryGetValue(Id, Result);
end;

function TRuleGlobe.GetTerrains(const Deployment: string): TArray<string>;
begin
  // Implementation omitted for brevity
  Result := [];
end;

end.