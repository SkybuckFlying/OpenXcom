unit SoldierNamePool;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections,
  Yaml, Savegame.Soldier, Engine.RNG;

type
  TSoldierNamePool = class
  private
    FMaleFirst: TArray<string>;
    FFemaleFirst: TArray<string>;
    FMaleLast: TArray<string>;
    FFemaleLast: TArray<string>;
    FLookWeights: TArray<Integer>;
    FTotalWeight: Integer;
    FFemaleFrequency: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Load(const FileName: string);
    function GenName(var Gender: TSoldierGender; AFemaleFrequency: Integer): string;
    function GenLook(NumLooks: Integer): Integer;
  end;

implementation

{ TSoldierNamePool }

constructor TSoldierNamePool.Create;
begin
  inherited Create;
  FTotalWeight := 0;
  FFemaleFrequency := -1;
end;

destructor TSoldierNamePool.Destroy;
begin
  inherited;
end;

procedure TSoldierNamePool.Load(const FileName: string);
var
  doc: TYamlNode;
begin
  doc := TYamlNode.LoadFromFile(FileName);
  FMaleFirst := doc['maleFirst'].AsArray<string>(FMaleFirst);
  FFemaleFirst := doc['femaleFirst'].AsArray<string>(FFemaleFirst);
  FMaleLast := doc['maleLast'].AsArray<string>(FMaleLast);
  FFemaleLast := doc['femaleLast'].AsArray<string>(FFemaleLast);
  if Length(FFemaleFirst) = 0 then FFemaleFirst := FMaleFirst;
  if Length(FFemaleLast) = 0 then FFemaleLast := FMaleLast;
  FLookWeights := doc['lookWeights'].AsArray<Integer>(FLookWeights);
  FTotalWeight := 0;
  for var w in FLookWeights do Inc(FTotalWeight, w);
  FFemaleFrequency := doc['femaleFrequency'].AsInteger(FFemaleFrequency);
end;

function TSoldierNamePool.GenName(var Gender: TSoldierGender; AFemaleFrequency: Integer): string;
var
  female: Boolean;
  firstIdx, lastIdx: Integer;
begin
  if FFemaleFrequency > -1 then
    female := RNG.Percent(FFemaleFrequency)
  else
    female := RNG.Percent(AFemaleFrequency);
  if not female then
  begin
    Gender := GENDER_MALE;
    firstIdx := RNG.Generate(0, Length(FMaleFirst)-1);
    Result := FMaleFirst[firstIdx];
    if Length(FMaleLast) > 0 then
    begin
      lastIdx := RNG.Generate(0, Length(FMaleLast)-1);
      Result := Result + ' ' + FMaleLast[lastIdx];
    end;
  end
  else
  begin
    Gender := GENDER_FEMALE;
    firstIdx := RNG.Generate(0, Length(FFemaleFirst)-1);
    Result := FFemaleFirst[firstIdx];
    if Length(FFemaleLast) > 0 then
    begin
      lastIdx := RNG.Generate(0, Length(FFemaleLast)-1);
      Result := Result + ' ' + FFemaleLast[lastIdx];
    end;
  end;
end;

function TSoldierNamePool.GenLook(NumLooks: Integer): Integer;
var
  lookIdx: Integer;
  random: Integer;
begin
  while Length(FLookWeights) < NumLooks do
  begin
    FLookWeights := FLookWeights + [2];
    Inc(FTotalWeight, 2);
  end;
  while Length(FLookWeights) > NumLooks do
  begin
    Dec(FTotalWeight, FLookWeights[High(FLookWeights)]);
    SetLength(FLookWeights, Length(FLookWeights)-1);
  end;
  random := RNG.Generate(0, FTotalWeight);
  lookIdx := 0;
  for var w in FLookWeights do
  begin
    if random <= w then
      Exit(lookIdx);
    Dec(random, w);
    Inc(lookIdx);
  end;
  Result := RNG.Generate(0, NumLooks-1);
end;

end.