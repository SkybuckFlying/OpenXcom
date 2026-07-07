unit ULanguage;

interface

uses
  SysUtils, Classes, Generics.Collections, ULocalizedText, UExtraStrings, USoldier;

type
  TTextDirection = (DIRECTION_LTR, DIRECTION_RTL);
  TTextWrapping = (WRAP_AUTO, WRAP_WORDS, WRAP_LETTERS);

  TLanguage = class
  private
    FStrings: TDictionary<string, string>;
    FHandler: TLanguagePlurality;
    FDirection: TTextDirection;
    FWrap: TTextWrapping;
    class var FNames: TDictionary<string, string>;
    class var FRTL, FCJK: TArray<string>;
    function LoadString(const S: string): string;
    procedure Load(const Filename: string);
  public
    constructor Create;
    destructor Destroy; override;
    class procedure GetList(var Files, Names: TArray<string>);
    class function IsSupported(const Lang: string): Boolean;
    procedure LoadFile(const Filename: string);
    procedure LoadRule(const ExtraStrings: TDictionary<string, TExtraStrings>; const ID: string);
    procedure ToHtml(const Filename: string);
    function GetString(const ID: string): TLocalizedText; overload;
    function GetString(const ID: string; N: Cardinal): TLocalizedText; overload;
    function GetString(const ID: string; Gender: TSoldierGender): TLocalizedText; overload;
    function GetTextDirection: TTextDirection;
    function GetTextWrapping: TTextWrapping;
  end;

implementation

uses
  UUnicode, ULogger, UOptions, ULanguagePlurality;

constructor TLanguage.Create;
begin
  FStrings := TDictionary<string,string>.Create;
  // Initialize statics if empty
  if FNames = nil then
  begin
    FNames := TDictionary<string,string>.Create;
    FNames.Add('en-US', 'English (US)');
    // ... add others
  end;
  if FRTL = nil then
    FRTL := [];
  if FCJK = nil then
    FCJK := ['ja', 'ko', 'zh-CN', 'zh-TW'];
  FHandler := TLanguagePlurality.Create(UOptions.language);
  if (UOptions.language in FRTL) then
    FDirection := DIRECTION_RTL
  else
    FDirection := DIRECTION_LTR;
  if UOptions.wordwrap = WRAP_AUTO then
  begin
    if (UOptions.language in FCJK) then
      FWrap := WRAP_LETTERS
    else
      FWrap := WRAP_WORDS;
  end
  else
    FWrap := UOptions.wordwrap;
end;

destructor TLanguage.Destroy;
begin
  FStrings.Free;
  FHandler.Free;
  inherited;
end;

class procedure TLanguage.GetList(var Files, Names: TArray<string>);
begin
  // Stub
end;

class function TLanguage.IsSupported(const Lang: string): Boolean;
begin
  Result := FNames.ContainsKey(Lang);
end;

procedure TLanguage.LoadFile(const Filename: string);
begin
  // Load YAML
end;

procedure TLanguage.LoadRule(const ExtraStrings: TDictionary<string, TExtraStrings>; const ID: string);
begin
  // Load from extra strings
end;

function TLanguage.GetString(const ID: string): TLocalizedText;
begin
  if FStrings.ContainsKey(ID) then
    Result := TLocalizedText.Create(FStrings[ID])
  else
    Result := TLocalizedText.Create(ID);
end;

function TLanguage.GetString(const ID: string; N: Cardinal): TLocalizedText;
var
  Key: string;
  S: string;
begin
  Key := ID + FHandler.GetSuffix(N);
  if FStrings.ContainsKey(Key) then
    S := FStrings[Key]
  else if FStrings.ContainsKey(ID + '_other') then
    S := FStrings[ID + '_other']
  else
    S := ID;
  S := StringReplace(S, '{N}', IntToStr(N), [rfReplaceAll]);
  Result := TLocalizedText.Create(S);
end;

function TLanguage.GetString(const ID: string; Gender: TSoldierGender): TLocalizedText;
begin
  if Gender = GENDER_MALE then
    Result := GetString(ID + '_MALE')
  else
    Result := GetString(ID + '_FEMALE');
end;

function TLanguage.GetTextDirection: TTextDirection;
begin
  Result := FDirection;
end;

function TLanguage.GetTextWrapping: TTextWrapping;
begin
  Result := FWrap;
end;

end.