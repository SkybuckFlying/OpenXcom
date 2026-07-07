unit Waypoint;

interface

uses
  Target;

type
  TWaypoint = class(TTarget)
  public
    constructor Create;
    destructor Destroy; override;
    function GetType: string; override;
    function GetMarker: Integer; override;
  end;

implementation

constructor TWaypoint.Create;
begin
  inherited;
end;

destructor TWaypoint.Destroy;
begin
  inherited;
end;

function TWaypoint.GetType: string;
begin
  Result := 'STR_WAY_POINT';
end;

function TWaypoint.GetMarker: Integer;
begin
  Result := 6;
end;

end.