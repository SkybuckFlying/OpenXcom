unit ULanguagePlurality;

interface

uses
  SysUtils;

type
  TLanguagePlurality = class
  public
    function GetSuffix(N: Cardinal): string; virtual; abstract;
    class function Create(const Language: string): TLanguagePlurality;
  end;

implementation

type
  TOneSingular = class(TLanguagePlurality)
    function GetSuffix(N: Cardinal): string; override;
  end;
  TZeroOneSingular = class(TLanguagePlurality)
    function GetSuffix(N: Cardinal): string; override;
  end;
  TNoSingular = class(TLanguagePlurality)
    function GetSuffix(N: Cardinal): string; override;
  end;
  TCyrillicPlurality = class(TLanguagePlurality)
    function GetSuffix(N: Cardinal): string; override;
  end;
  TCzechPlurality = class(TLanguagePlurality)
    function GetSuffix(N: Cardinal): string; override;
  end;
  TPolishPlurality = class(TLanguagePlurality)
    function GetSuffix(N: Cardinal): string; override;
  end;
  TRomanianPlurality = class(TLanguagePlurality)
    function GetSuffix(N: Cardinal): string; override;
  end;
  TCroatianPlurality = class(TLanguagePlurality)
    function GetSuffix(N: Cardinal): string; override;
  end;

function TOneSingular.GetSuffix(N: Cardinal): string;
begin
  if N = 1 then Result := '_one' else Result := '_other';
end;

function TZeroOneSingular.GetSuffix(N: Cardinal): string;
begin
  if (N = 0) or (N = 1) then Result := '_one' else Result := '_other';
end;

function TNoSingular.GetSuffix(N: Cardinal): string;
begin
  Result := '_other';
end;

function TCyrillicPlurality.GetSuffix(N: Cardinal): string;
var
  Mod10, Mod100: Integer;
begin
  Mod10 := N mod 10;
  Mod100 := N mod 100;
  if (Mod10 = 1) and (Mod100 <> 11) then Result := '_one'
  else if (Mod10 >= 2) and (Mod10 <= 4) and not (Mod100 in [12..14]) then Result := '_few'
  else if (Mod10 = 0) or ((Mod10 >= 5) and (Mod10 <= 9)) or (Mod100 in [11..14]) then Result := '_many'
  else Result := '_other';
end;

function TCzechPlurality.GetSuffix(N: Cardinal): string;
begin
  if N = 1 then Result := '_one'
  else if (N >= 2) and (N <= 4) then Result := '_few'
  else Result := '_other';
end;

function TPolishPlurality.GetSuffix(N: Cardinal): string;
var
  Mod10, Mod100: Integer;
begin
  Mod10 := N mod 10;
  Mod100 := N mod 100;
  if N = 1 then Result := '_one'
  else if (Mod10 >= 2) and (Mod10 <= 4) and not (Mod100 in [12..14]) then Result := '_few'
  else if (Mod10 <= 1) or ((Mod10 >= 5) and (Mod10 <= 9)) or (Mod100 in [12..14]) then Result := '_many'
  else Result := '_other';
end;

function TRomanianPlurality.GetSuffix(N: Cardinal): string;
begin
  if N = 1 then Result := '_one'
  else if (N = 0) or ((N mod 100) in [1..19]) then Result := '_few'
  else Result := '_other';
end;

function TCroatianPlurality.GetSuffix(N: Cardinal): string;
var
  Mod10, Mod100: Integer;
begin
  Mod10 := N mod 10;
  Mod100 := N mod 100;
  if (Mod10 = 1) and (Mod100 <> 11) then Result := '_one'
  else if (Mod10 >= 2) and (Mod10 <= 4) and not (Mod100 in [12..14]) then Result := '_few'
  else Result := '_other';
end;

class function TLanguagePlurality.Create(const Language: string): TLanguagePlurality;
var
  Lang: string;
begin
  Lang := Copy(Language, 1, 2);
  // Map language to class
  if (Lang = 'fr') or (Lang = 'hu') or (Lang = 'tr') then
    Result := TZeroOneSingular.Create
  else if (Lang = 'cs') or (Lang = 'sk') then
    Result := TCzechPlurality.Create
  else if (Lang = 'pl') then
    Result := TPolishPlurality.Create
  else if (Lang = 'ro') then
    Result := TRomanianPlurality.Create
  else if (Lang = 'ru') or (Lang = 'uk') then
    Result := TCyrillicPlurality.Create
  else if (Lang = 'ja') or (Lang = 'ko') or (Language = 'zh-CN') or (Language = 'zh-TW') then
    Result := TNoSingular.Create
  else if (Lang = 'hr') then
    Result := TCroatianPlurality.Create
  else
    Result := TOneSingular.Create;
end;

end.