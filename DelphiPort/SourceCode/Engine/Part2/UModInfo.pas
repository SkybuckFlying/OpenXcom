unit UModInfo;

interface

uses
  SysUtils, Classes;

type
  TModInfo = class
  private
    FPath: string;
    FName, FDesc, FVersion, FAuthor, FId, FMaster: string;
    FIsMaster: Boolean;
    FReservedSpace: Integer;
    FEngineOk: Boolean;
    FRequiredExtendedEngine: string;
    FRequiredExtendedVersion: string;
    FResourceConfigFile: string;
    FExternalResourceDirs: TArray<string>;
  public
    constructor Create(const APath: string);
    procedure Load(const Filename: string);
    function GetPath: string;
    function GetName: string;
    function GetDescription: string;
    function GetVersion: string;
    function GetAuthor: string;
    function GetId: string;
    function GetMaster: string;
    function IsMaster: Boolean;
    function IsEngineOk: Boolean;
    function GetRequiredExtendedEngine: string;
    function GetRequiredExtendedVersion: string;
    function GetResourceConfigFile: string;
    function GetReservedSpace: Integer;
    function CanActivate(const CurMaster: string): Boolean;
    function GetExternalResourceDirs: TArray<string>;
  end;

implementation

constructor TModInfo.Create(const APath: string);
begin
  FPath := APath;
  FName := ExtractFileName(APath);
  FDesc := 'No description.';
  FVersion := '1.0';
  FAuthor := 'unknown';
  FId := FName;
  FMaster := 'xcom1';
  FIsMaster := False;
  FReservedSpace := 1;
  FEngineOk := True;
end;

procedure TModInfo.Load(const Filename: string);
begin
  // Parse YAML (simplified for stub)
end;

function TModInfo.GetPath: string; begin Result := FPath; end;
function TModInfo.GetName: string; begin Result := FName; end;
function TModInfo.GetDescription: string; begin Result := FDesc; end;
function TModInfo.GetVersion: string; begin Result := FVersion; end;
function TModInfo.GetAuthor: string; begin Result := FAuthor; end;
function TModInfo.GetId: string; begin Result := FId; end;
function TModInfo.GetMaster: string; begin Result := FMaster; end;
function TModInfo.IsMaster: Boolean; begin Result := FIsMaster; end;
function TModInfo.IsEngineOk: Boolean; begin Result := FEngineOk; end;
function TModInfo.GetRequiredExtendedEngine: string; begin Result := FRequiredExtendedEngine; end;
function TModInfo.GetRequiredExtendedVersion: string; begin Result := FRequiredExtendedVersion; end;
function TModInfo.GetResourceConfigFile: string; begin Result := FResourceConfigFile; end;
function TModInfo.GetReservedSpace: Integer; begin Result := FReservedSpace; end;
function TModInfo.CanActivate(const CurMaster: string): Boolean;
begin
  Result := FIsMaster or (FMaster = '') or (FMaster = CurMaster);
end;
function TModInfo.GetExternalResourceDirs: TArray<string>; begin Result := FExternalResourceDirs; end;

end.