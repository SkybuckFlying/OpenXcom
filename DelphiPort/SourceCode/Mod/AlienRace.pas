unit AlienRace;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections,
  Yaml;

type
  TAlienRank = (arHuman, arCommander, arLeader, arEngineer, arMedic,
                arNavigator, arSoldier, arTerrorist, arTerrorist2);

  TAlienRace = class
  private
    FId: string;
    FMembers: TArray<string>;
  public
    constructor Create(const AId: string);
    destructor Destroy; override;
    procedure Load(const Node: TYamlNode);
    function GetId: string;
    function GetMember(Index: Integer): string;
  end;

implementation

{ TAlienRace }

constructor TAlienRace.Create(const AId: string);
begin
  inherited Create;
  FId := AId;
end;

destructor TAlienRace.Destroy;
begin
  inherited;
end;

procedure TAlienRace.Load(const Node: TYamlNode);
begin
  FId := Node['id'].AsString(FId);
  FMembers := Node['members'].AsArray<string>(FMembers);
end;

function TAlienRace.GetId: string;
begin
  Result := FId;
end;

function TAlienRace.GetMember(Index: Integer): string;
begin
  Result := FMembers[Index];
end;

end.