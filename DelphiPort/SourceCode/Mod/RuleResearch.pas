unit RuleResearch;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections,
  Yaml;

type
  TRuleResearch = class
  private
    FName: string;
    FLookup: string;
    FCutscene: string;
    FCost: Integer;
    FPoints: Integer;
    FDependencies: TArray<string>;
    FUnlocks: TArray<string>;
    FGetOneFree: TArray<string>;
    FRequires: TArray<string>;
    FNeedItem: Boolean;
    FDestroyItem: Boolean;
    FListOrder: Integer;
  public
    constructor Create(const AName: string);
    destructor Destroy; override;
    procedure Load(const Node: TYamlNode; AListOrder: Integer);
    function GetName: string;
    function GetLookup: string;
    function GetCutscene: string;
    function GetCost: Integer;
    function GetPoints: Integer;
    function GetDependencies: TArray<string>;
    function GetUnlocked: TArray<string>;
    function GetGetOneFree: TArray<string>;
    function GetRequirements: TArray<string>;
    function NeedItem: Boolean;
    function DestroyItem: Boolean;
    function GetListOrder: Integer;
  end;

implementation

{ TRuleResearch }

constructor TRuleResearch.Create(const AName: string);
begin
  inherited Create;
  FName := AName;
  FCost := 0; FPoints := 0;
  FNeedItem := False; FDestroyItem := False;
  FListOrder := 0;
end;

destructor TRuleResearch.Destroy;
begin
  inherited;
end;

procedure TRuleResearch.Load(const Node: TYamlNode; AListOrder: Integer);
begin
  FName := Node['name'].AsString(FName);
  FLookup := Node['lookup'].AsString(FLookup);
  FCutscene := Node['cutscene'].AsString(FCutscene);
  FCost := Node['cost'].AsInteger(FCost);
  FPoints := Node['points'].AsInteger(FPoints);
  FDependencies := Node['dependencies'].AsArray<string>(FDependencies);
  FUnlocks := Node['unlocks'].AsArray<string>(FUnlocks);
  FGetOneFree := Node['getOneFree'].AsArray<string>(FGetOneFree);
  FRequires := Node['requires'].AsArray<string>(FRequires);
  FNeedItem := Node['needItem'].AsBoolean(FNeedItem);
  FDestroyItem := Node['destroyItem'].AsBoolean(FDestroyItem);
  FListOrder := Node['listOrder'].AsInteger(FListOrder);
  if FListOrder = 0 then FListOrder := AListOrder;
end;

function TRuleResearch.GetName: string;
begin
  Result := FName;
end;

function TRuleResearch.GetLookup: string;
begin
  Result := FLookup;
end;

function TRuleResearch.GetCutscene: string;
begin
  Result := FCutscene;
end;

function TRuleResearch.GetCost: Integer;
begin
  Result := FCost;
end;

function TRuleResearch.GetPoints: Integer;
begin
  Result := FPoints;
end;

function TRuleResearch.GetDependencies: TArray<string>;
begin
  Result := FDependencies;
end;

function TRuleResearch.GetUnlocked: TArray<string>;
begin
  Result := FUnlocks;
end;

function TRuleResearch.GetGetOneFree: TArray<string>;
begin
  Result := FGetOneFree;
end;

function TRuleResearch.GetRequirements: TArray<string>;
begin
  Result := FRequires;
end;

function TRuleResearch.NeedItem: Boolean;
begin
  Result := FNeedItem;
end;

function TRuleResearch.DestroyItem: Boolean;
begin
  Result := FDestroyItem;
end;

function TRuleResearch.GetListOrder: Integer;
begin
  Result := FListOrder;
end;

end.