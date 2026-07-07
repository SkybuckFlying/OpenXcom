unit City;

interface

uses
  System.Classes, System.SysUtils,
  Savegame.Target, Language;

type
  TCity = class(TTarget)
  private
    FName: string;
    FLon, FLat: Double;
  protected
    function GetType: string; override;
  public
    constructor Create(const AName: string; ALon, ALat: Double);
    destructor Destroy; override;
    function GetName(Lang: TLanguage): string; override;
    function GetMarker: Integer; override;
  end;

implementation

{ TCity }

constructor TCity.Create(const AName: string; ALon, ALat: Double);
begin
  inherited Create;
  FName := AName;
  FLon := ALon;
  FLat := ALat;
end;

destructor TCity.Destroy;
begin
  inherited;
end;

function TCity.GetType: string;
begin
  Result := '';
end;

function TCity.GetName(Lang: TLanguage): string;
begin
  Result := Lang.GetString(FName);
end;

function TCity.GetMarker: Integer;
begin
  Result := 8;
end;

end.