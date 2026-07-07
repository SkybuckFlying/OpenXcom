unit UMusic;

interface

uses
  SDL_mixer;

type
  TMusic = class
  private
    FMusic: PMix_Music;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Load(const Filename: string); virtual;
    procedure LoadFromMemory(const Data: Pointer; Size: Integer); virtual;
    procedure Play(Loop: Integer = -1); virtual;
    class procedure Stop; virtual;
    class procedure Pause; virtual;
    class procedure Resume; virtual;
    class function IsPlaying: Boolean; virtual;
  end;

implementation

uses
  UException, UOptions, ULogger, UUnicode, UCrossPlatform;

constructor TMusic.Create;
begin
  FMusic := nil;
end;

destructor TMusic.Destroy;
begin
  if FMusic <> nil then
    Mix_FreeMusic(FMusic);
  inherited;
end;

procedure TMusic.Load(const Filename: string);
var
  Utf8Path: string;
begin
  Utf8Path := Unicode.ConvPathToUtf8(Filename);
  FMusic := Mix_LoadMUS(PAnsiChar(AnsiString(Utf8Path)));
  if FMusic = nil then
    raise EOpenXcom.Create(Mix_GetError);
end;

procedure TMusic.LoadFromMemory(const Data: Pointer; Size: Integer);
var
  RW: PSDL_RWops;
begin
  RW := SDL_RWFromConstMem(Data, Size);
  FMusic := Mix_LoadMUS_RW(RW);
  SDL_FreeRW(RW);
  if FMusic = nil then
    raise EOpenXcom.Create(Mix_GetError);
end;

procedure TMusic.Play(Loop: Integer);
begin
  if UOptions.mute then Exit;
  if FMusic <> nil then
  begin
    Stop;
    if Mix_PlayMusic(FMusic, Loop) = -1 then
      Log(LOG_WARNING) << Mix_GetError;
  end;
end;

class procedure TMusic.Stop;
begin
  if not UOptions.mute then
  begin
    Mix_HaltMusic;
  end;
end;

class procedure TMusic.Pause;
begin
  if not UOptions.mute then
    Mix_PauseMusic;
end;

class procedure TMusic.Resume;
begin
  if not UOptions.mute then
    Mix_ResumeMusic;
end;

class function TMusic.IsPlaying: Boolean;
begin
  if UOptions.mute then
    Result := False
  else
    Result := Mix_PlayingMusic <> 0;
end;

end.