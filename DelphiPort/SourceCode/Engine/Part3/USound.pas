unit USound;

interface

uses
  SDL_mixer;

type
  TSound = class
  private
    FChunk: PMix_Chunk;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Load(const Filename: string);
    procedure LoadFromMemory(const Data: Pointer; Size: Cardinal);
    procedure Play(Channel: Integer = -1; Angle: Integer = 0; Distance: Integer = 0);
    class procedure Stop;
    procedure Loop;
    procedure StopLoop;
  end;

implementation

uses
  UException, UOptions, ULogger, UUnicode, UCrossPlatform;

constructor TSound.Create;
begin
  FChunk := nil;
end;

destructor TSound.Destroy;
begin
  if FChunk <> nil then
    Mix_FreeChunk(FChunk);
  inherited;
end;

procedure TSound.Load(const Filename: string);
var
  Utf8Path: string;
begin
  Utf8Path := Unicode.ConvPathToUtf8(Filename);
  FChunk := Mix_LoadWAV(PAnsiChar(AnsiString(Utf8Path)));
  if FChunk = nil then
    raise EOpenXcom.Create(Filename + ':' + Mix_GetError);
end;

procedure TSound.LoadFromMemory(const Data: Pointer; Size: Cardinal);
var
  RW: PSDL_RWops;
begin
  RW := SDL_RWFromConstMem(Data, Size);
  FChunk := Mix_LoadWAV_RW(RW, 1);
  if FChunk = nil then
    raise EOpenXcom.Create(Mix_GetError);
end;

procedure TSound.Play(Channel, Angle, Distance: Integer);
var
  Chan: Integer;
begin
  if UOptions.mute or (FChunk = nil) then Exit;
  Chan := Mix_PlayChannel(Channel, FChunk, 0);
  if Chan = -1 then
    Log(LOG_WARNING) << Mix_GetError
  else if UOptions.StereoSound then
    if not Mix_SetPosition(Chan, Angle, Distance) then
      Log(LOG_WARNING) << Mix_GetError;
end;

class procedure TSound.Stop;
begin
  if not UOptions.mute then
    Mix_HaltChannel(-1);
end;

procedure TSound.Loop;
begin
  if UOptions.mute or (FChunk = nil) then Exit;
  if Mix_Playing(3) = 0 then
  begin
    if Mix_PlayChannel(3, FChunk, -1) = -1 then
      Log(LOG_WARNING) << Mix_GetError;
  end;
end;

procedure TSound.StopLoop;
begin
  if not UOptions.mute then
    Mix_HaltChannel(3);
end;

end.