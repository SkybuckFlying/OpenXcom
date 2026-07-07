unit UFileMap;

interface

uses
  SysUtils, Classes, Generics.Collections;

type
  TFileMap = class
  private
    class var FResources: TDictionary<string, string>;
    class var FVDirs: TDictionary<string, TArray<string>>;
    class var FRulesets: TArray<TPair<string, TArray<string>>>;
    class function Canonicalize(const S: string): string;
  public
    class function GetFilePath(const RelativeFilePath: string): string;
    class function GetVFolderContents(const RelativePath: string): TArray<string>;
    class function FilterFiles(const Files: TArray<string>; const Ext: string): TArray<string>;
    class function GetRulesets: TArray<TPair<string, TArray<string>>>;
    class procedure Clear;
    class procedure Load(const ModId, Path: string; IgnoreMods: Boolean);
    class function IsResourcesEmpty: Boolean;
  end;

implementation

uses
  UCrossPlatform, ULogger;

class function TFileMap.Canonicalize(const S: string): string;
begin
  Result := AnsiLowerCase(S);
end;

class function TFileMap.GetFilePath(const RelativeFilePath: string): string;
begin
  Result := RelativeFilePath; // simplified stub
end;

class function TFileMap.GetVFolderContents(const RelativePath: string): TArray<string>;
begin
  SetLength(Result, 0); // stub
end;

class function TFileMap.FilterFiles(const Files: TArray<string>; const Ext: string): TArray<string>;
var
  S: string;
begin
  Result := [];
  for S in Files do
    if (Ext <> '') and (Copy(AnsiLowerCase(S), Length(S)-Length(Ext), Length(Ext)) = AnsiLowerCase(Ext)) then
    begin
      SetLength(Result, Length(Result)+1);
      Result[High(Result)] := S;
    end;
end;

class function TFileMap.GetRulesets: TArray<TPair<string, TArray<string>>>;
begin
  SetLength(Result, 0); // stub
end;

class procedure TFileMap.Clear;
begin
  FResources.Free;
  FResources := TDictionary<string,string>.Create;
  FVDirs.Free;
  FVDirs := TDictionary<string, TArray<string>>.Create;
  SetLength(FRulesets, 0);
end;

class procedure TFileMap.Load(const ModId, Path: string; IgnoreMods: Boolean);
begin
  // Scan directory and populate maps
end;

class function TFileMap.IsResourcesEmpty: Boolean;
begin
  Result := (FResources = nil) or (FResources.Count = 0);
end;

initialization
  TFileMap.Clear;
end.