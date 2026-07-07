unit USavedGame;

interface

uses
  SysUtils, Classes, Generics.Collections;

type
  TSavedGame = class
  private
    FName: string;
    FIronman: Boolean;
    FMods: TArray<string>;
    // Other fields (stub)
  public
    constructor Create;
    destructor Destroy; override;
    procedure Save(const Filename: string);
    procedure Load(const Filename: string);
    function IsIronman: Boolean;
    function GetName: string;
    procedure SetName(const Name: string);
    procedure SetIronman(Enabled: Boolean);
  end;

implementation

constructor TSavedGame.Create;
begin
  FName := '';
  FIronman := False;
  FMods := nil;
end;

destructor TSavedGame.Destroy;
begin
  inherited;
end;

procedure TSavedGame.Save(const Filename: string);
begin
  // Stub: write YAML
end;

procedure TSavedGame.Load(const Filename: string);
begin
  // Stub: read YAML
end;

function TSavedGame.IsIronman: Boolean;
begin
  Result := FIronman;
end;

function TSavedGame.GetName: string;
begin
  Result := FName;
end;

procedure TSavedGame.SetName(const Name: string);
begin
  FName := Name;
end;

procedure TSavedGame.SetIronman(Enabled: Boolean);
begin
  FIronman := Enabled;
end;

end.