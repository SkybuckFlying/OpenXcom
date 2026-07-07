unit UFlcPlayer;

interface

uses
  SysUtils, Classes, SDL, USurface, UScreen, UGame;

type
  TFlcPlayer = class
  private
    FFileBuf: TBytes;
    FFileSize: Integer;
    FVideoFrameData, FChunkData, FAudioFrameData: PByte;
    FFrameCount: Word;
    FHeaderSize, FVideoFrameSize, FAudioFrameSize: Cardinal;
    FHeaderType, FHeaderFrames, FHeaderWidth, FHeaderHeight, FHeaderDepth: Word;
    FHeaderSpeed: Word;
    FVideoFrameType, FFrameChunks, FDelayOverride, FAudioFrameType: Word;
    FChunkSize: Cardinal;
    FChunkType: Word;
    FScreenWidth, FScreenHeight, FScreenDepth: Integer;
    FDX, FDY: Integer;
    FOffset: Integer;
    FPlayingState: Integer;
    FHasAudio, FUseInternalAudio: Boolean;
    FVideoDelay: Integer;
    FVolume: Double;
    FColors: array[0..255] of TSDL_Color;
    FMainScreen: PSDL_Surface;
    FRealScreen: TScreen;
    FGame: TGame;
    FFrameCallback: procedure;
    FCallbackAssigned: Boolean;
    procedure ReadFileHeader;
    function IsValidFrame(FrameHeader: PByte; out FrameSize: Cardinal; out FrameType: Word): Boolean;
    procedure DecodeVideo(SkipLastFrame: Boolean);
    procedure DecodeAudio(Frames: Integer);
    procedure WaitForNextFrame(Delay: Cardinal);
    procedure SDLPolling;
    function ShouldQuit: Boolean;
    procedure PlayVideoFrame;
    procedure Color256;
    procedure FliSS2;
    procedure FliBRun;
    procedure FliLC;
    procedure Color64;
    procedure Black;
    procedure FliCopy;
    procedure PlayAudioFrame(SampleRate: Word);
    procedure InitAudio(Format: Word; Channels: Byte);
    procedure DeInitAudio;
    function IsEndOfFile(Pos: PByte): Boolean;
    class procedure AudioCallback(UserData: Pointer; Stream: PByte; Len: Integer); static;
    // Endian helpers
    function ReadU16(Src: PByte): Word;
    function ReadU32(Src: PByte): Cardinal;
    function ReadS16(Src: PShortInt): SmallInt;
    function ReadS32(Src: PShortInt): Integer;
  public
    constructor Create;
    destructor Destroy; override;
    function Init(const Filename: string; FrameCallBack: procedure; Game: TGame; UseAudio: Boolean; DX, DY: Integer): Boolean;
    procedure Play(SkipLastFrame: Boolean);
    procedure DeInit;
    procedure Stop;
    procedure Delay(Milliseconds: Cardinal);
    procedure SetHeaderSpeed(Speed: Integer);
    function GetFrameCount: Integer;
    function WasSkipped: Boolean;
  end;

implementation

uses
  UException, ULogger, UOptions, UCrossPlatform, UFileMap;

constructor TFlcPlayer.Create;
begin
  FFileBuf := nil;
  FFileSize := 0;
  FMainScreen := nil;
  FRealScreen := nil;
  FGame := nil;
  FFrameCallback := nil;
  FCallbackAssigned := False;
  FVolume := 1.0;
  FHasAudio := False;
  FUseInternalAudio := False;
  FPlayingState := 0; // 0=playing, 1=finished, 2=skipped
  FFrameCount := 0;
end;

destructor TFlcPlayer.Destroy;
begin
  DeInit;
  inherited;
end;

function TFlcPlayer.Init(const Filename: string; FrameCallBack: procedure; Game: TGame; UseAudio, DX, DY: Integer): Boolean;
var
  F: TFileStream;
begin
  if Length(FFileBuf) > 0 then
  begin
    Log(LOG_ERROR) << 'Trying to init a video player that is already initialized';
    Exit(False);
  end;
  FFrameCallback := FrameCallBack;
  FRealScreen := Game.GetScreen;
  FGame := Game;
  FUseInternalAudio := UseAudio;
  FDX := DX; FDY := DY;
  FFileSize := 0;
  FFrameCount := 0;
  FVideoFrameData := nil;
  FHasAudio := False;
  // Load file
  F := TFileStream.Create(Filename, fmOpenRead or fmShareDenyWrite);
  try
    FFileSize := F.Size;
    SetLength(FFileBuf, FFileSize);
    F.Read(FFileBuf[0], FFileSize);
  finally
    F.Free;
  end;
  // Read header
  FVideoFrameData := @FFileBuf[128];
  FAudioFrameData := FVideoFrameData;
  ReadFileHeader;
  if (FHeaderType = $AF11) or (FHeaderType = $AF12) then
  begin
    FScreenWidth := FHeaderWidth;
    FScreenHeight := FHeaderHeight;
    FScreenDepth := 8;
    Log(LOG_INFO) << Format('Playing flx, %dx%d, %d frames', [FScreenWidth, FScreenHeight, FHeaderFrames]);
  end
  else
  begin
    Log(LOG_ERROR) << 'Flx file failed header check.';
    Exit(False);
  end;
  // Create surface if needed
  if FRealScreen.GetSurface.GetSurface.format.BitsPerPixel = 8 then
    FMainScreen := FRealScreen.GetSurface.GetSurface
  else
    FMainScreen := SDL_AllocSurface(SDL_SWSURFACE, FRealScreen.GetSurface.GetWidth, FRealScreen.GetSurface.GetHeight, 8, 0,0,0,0);
  Result := True;
end;

procedure TFlcPlayer.DeInit;
begin
  if (FMainScreen <> nil) and (FRealScreen <> nil) then
  begin
    if FMainScreen <> FRealScreen.GetSurface.GetSurface then
      SDL_FreeSurface(FMainScreen);
    FMainScreen := nil;
  end;
  if Length(FFileBuf) > 0 then
  begin
    SetLength(FFileBuf, 0);
    DeInitAudio;
  end;
end;

procedure TFlcPlayer.Play(SkipLastFrame: Boolean);
begin
  FPlayingState := 0; // PLAYING
  FDY := (FMainScreen.h - FHeaderHeight) div 2;
  FOffset := FDY * FMainScreen.pitch + FMainScreen.format.BytesPerPixel * FDX;
  FVideoFrameData := @FFileBuf[128];
  FAudioFrameData := FVideoFrameData;
  while not ShouldQuit do
  begin
    if FCallbackAssigned and Assigned(FFrameCallback) then
      FFrameCallback();
    if not ShouldQuit then
      DecodeAudio(2);
    if not ShouldQuit then
      DecodeVideo(SkipLastFrame);
    if not ShouldQuit then
      SDLPolling;
  end;
end;

procedure TFlcPlayer.Delay(Milliseconds: Cardinal);
var
  PauseStart: Cardinal;
begin
  PauseStart := SDL_GetTicks;
  while (FPlayingState <> 2) and (SDL_GetTicks < PauseStart + Milliseconds) do
    SDLPolling;
end;

procedure TFlcPlayer.SDLPolling;
var
  Event: TSDL_Event;
begin
  while SDL_PollEvent(@Event) <> 0 do
  begin
    case Event.type_ of
      SDL_MOUSEBUTTONDOWN, SDL_KEYDOWN:
        FPlayingState := 2; // SKIPPED
      SDL_VIDEORESIZE:
        if UOptions.allowResize then
        begin
          // Handle resize (stub)
        end;
      SDL_QUIT:
        Halt(0);
    end;
  end;
end;

function TFlcPlayer.ShouldQuit: Boolean;
begin
  Result := (FPlayingState = 1) or (FPlayingState = 2);
end;

procedure TFlcPlayer.ReadFileHeader;
begin
  FHeaderSize := ReadU32(@FFileBuf[0]);
  FHeaderType := ReadU16(@FFileBuf[4]);
  FHeaderFrames := ReadU16(@FFileBuf[6]);
  FHeaderWidth := ReadU16(@FFileBuf[8]);
  FHeaderHeight := ReadU16(@FFileBuf[10]);
  FHeaderDepth := ReadU16(@FFileBuf[12]);
  FHeaderSpeed := ReadU16(@FFileBuf[16]);
end;

function TFlcPlayer.IsValidFrame(FrameHeader: PByte; out FrameSize: Cardinal; out FrameType: Word): Boolean;
begin
  FrameSize := ReadU32(FrameHeader);
  FrameType := ReadU16(FrameHeader + 4);
  Result := (FrameType = $F1FA) or (FrameType = $AAAA) or (FrameType = $F100);
end;

procedure TFlcPlayer.DecodeAudio(Frames: Integer);
var
  Found: Integer;
begin
  Found := 0;
  while (Found < Frames) and not IsEndOfFile(FAudioFrameData) do
  begin
    if not IsValidFrame(FAudioFrameData, FAudioFrameSize, FAudioFrameType) then
    begin
      FPlayingState := 1;
      Break;
    end;
    case FAudioFrameType of
      $F1FA, $F100:
        FAudioFrameData := FAudioFrameData + FAudioFrameSize;
      $AAAA:
        begin
          var SampleRate: Word := ReadU16(FAudioFrameData + 8);
          FChunkData := FAudioFrameData + 16;
          PlayAudioFrame(SampleRate);
          FAudioFrameData := FAudioFrameData + FAudioFrameSize + 16;
          Inc(Found);
        end;
    end;
  end;
end;

procedure TFlcPlayer.DecodeVideo(SkipLastFrame: Boolean);
var
  Found: Boolean;
  Delay: Cardinal;
begin
  Found := False;
  while not Found do
  begin
    if not IsValidFrame(FVideoFrameData, FVideoFrameSize, FVideoFrameType) then
    begin
      FPlayingState := 1;
      Break;
    end;
    case FVideoFrameType of
      $F1FA:
        begin
          FFrameChunks := ReadU16(FVideoFrameData + 6);
          FDelayOverride := ReadU16(FVideoFrameData + 8);
          if FHeaderType = $AF11 then
            Delay := FDelayOverride * 1000 div 70
          else if FUseInternalAudio and (FFrameCallback = nil) then
            Delay := FVideoDelay
          else
            Delay := FHeaderSpeed;
          WaitForNextFrame(Delay);
          FChunkData := FVideoFrameData + 16;
          FVideoFrameData := FVideoFrameData + FVideoFrameSize;
          if IsEndOfFile(FVideoFrameData) then
            FPlayingState := 1;
          if not ShouldQuit or not SkipLastFrame then
            PlayVideoFrame;
          Found := True;
        end;
      $AAAA:
        FVideoFrameData := FVideoFrameData + FVideoFrameSize + 16;
      $F100:
        FVideoFrameData := FVideoFrameData + FVideoFrameSize;
    end;
  end;
end;

procedure TFlcPlayer.PlayVideoFrame;
var
  I: Integer;
begin
  Inc(FFrameCount);
  SDL_LockSurface(FMainScreen);
  for I := 0 to FFrameChunks-1 do
  begin
    FChunkSize := ReadU32(FChunkData);
    FChunkType := ReadU16(FChunkData + 4);
    case FChunkType of
      $04: Color256;
      $07: FliSS2;
      $0B: Color64;
      $0C: FliLC;
      $0D: Black;
      $0F: FliBRun;
      $10: FliCopy;
    end;
    FChunkData := FChunkData + FChunkSize;
  end;
  SDL_UnlockSurface(FMainScreen);
  if FMainScreen <> FRealScreen.GetSurface.GetSurface then
    SDL_BlitSurface(FMainScreen, nil, FRealScreen.GetSurface.GetSurface, nil);
  FRealScreen.Flip;
end;

procedure TFlcPlayer.Color256;
var
  P: PByte;
  NumPackets, NumColors: Word;
  Skip, ColorCount: Byte;
  I, J: Integer;
begin
  P := FChunkData + 6;
  NumPackets := ReadU16(P); Inc(P, 2);
  while NumPackets > 0 do
  begin
    Skip := P^; Inc(P);
    ColorCount := P^; Inc(P);
    if ColorCount = 0 then ColorCount := 255;
    for I := 0 to ColorCount-1 do
    begin
      FColors[I].r := P^; Inc(P);
      FColors[I].g := P^; Inc(P);
      FColors[I].b := P^; Inc(P);
    end;
    if FMainScreen <> FRealScreen.GetSurface.GetSurface then
      SDL_SetColors(FMainScreen, @FColors[0], Skip, ColorCount);
    FRealScreen.SetPalette(@FColors[0], Skip, ColorCount, True);
    Dec(NumPackets);
  end;
end;

procedure TFlcPlayer.FliSS2;
var
  Src, Dst, TmpDst: PByte;
  CountData: ShortInt;
  ColSkip, Fill1, Fill2: Byte;
  Lines, Count: Word;
  SetLast: Boolean;
  LastByte: Byte;
begin
  Src := FChunkData + 6;
  Dst := PByte(FMainScreen.pixels) + FOffset;
  Lines := ReadU16(Src); Inc(Src, 2);
  while Lines > 0 do
  begin
    Count := ReadS16(Src); Inc(Src, 2);
    if (Count and $C000) = $C000 then // skip lines
    begin
      Dst := Dst + (-Count) * FMainScreen.pitch;
      Continue;
    end
    else if (Count and $8000) <> 0 then
    begin
      SetLast := True;
      LastByte := Count and $FF;
      Count := ReadS16(Src); Inc(Src, 2);
    end;
    if (Count and $C000) = 0 then
    begin
      TmpDst := Dst;
      while Count > 0 do
      begin
        ColSkip := Src^; Inc(Src);
        TmpDst := TmpDst + ColSkip;
        CountData := ShortInt(Src^); Inc(Src);
        if CountData > 0 then
        begin
          Move(Src^, TmpDst^, 2 * CountData);
          TmpDst := TmpDst + 2 * CountData;
          Src := Src + 2 * CountData;
        end
        else
        begin
          CountData := -CountData;
          Fill1 := Src^; Fill2 := Src^+1; Inc(Src, 2);
          while CountData > 0 do
          begin
            TmpDst^ := Fill1; Inc(TmpDst);
            TmpDst^ := Fill2; Inc(TmpDst);
            Dec(CountData);
          end;
        end;
        Dec(Count);
      end;
      if SetLast then
      begin
        SetLast := False;
        (Dst + FMainScreen.pitch - 1)^ := LastByte;
      end;
      Dst := Dst + FMainScreen.pitch;
      Dec(Lines);
    end;
  end;
end;

procedure TFlcPlayer.FliBRun;
var
  Src, Dst, TmpDst: PByte;
  CountData: ShortInt;
  Fill: Byte;
  Height, Pixels: Integer;
begin
  Src := FChunkData + 6;
  Dst := PByte(FMainScreen.pixels) + FOffset;
  Height := FHeaderHeight;
  while Height > 0 do
  begin
    TmpDst := Dst;
    Inc(Src); // skip packet count
    Pixels := 0;
    while Pixels < FHeaderWidth do
    begin
      CountData := ShortInt(Src^); Inc(Src);
      if CountData > 0 then
      begin
        Fill := Src^; Inc(Src);
        FillChar(TmpDst^, CountData, Fill);
        TmpDst := TmpDst + CountData;
        Pixels := Pixels + CountData;
      end
      else
      begin
        CountData := -CountData;
        Move(Src^, TmpDst^, CountData);
        TmpDst := TmpDst + CountData;
        Src := Src + CountData;
        Pixels := Pixels + CountData;
      end;
    end;
    Dst := Dst + FMainScreen.pitch;
    Dec(Height);
  end;
end;

procedure TFlcPlayer.FliLC;
var
  Src, Dst, TmpDst: PByte;
  CountData: ShortInt;
  CountSkip, Fill: Byte;
  Lines, Tmp: Word;
  Packets: Integer;
begin
  Src := FChunkData + 6;
  Dst := PByte(FMainScreen.pixels) + FOffset;
  Tmp := ReadU16(Src); Inc(Src, 2);
  Dst := Dst + Tmp * FMainScreen.pitch;
  Lines := ReadU16(Src); Inc(Src, 2);
  while Lines > 0 do
  begin
    TmpDst := Dst;
    Packets := Src^; Inc(Src);
    while Packets > 0 do
    begin
      CountSkip := Src^; Inc(Src);
      TmpDst := TmpDst + CountSkip;
      CountData := ShortInt(Src^); Inc(Src);
      if CountData > 0 then
      begin
        Move(Src^, TmpDst^, CountData);
        TmpDst := TmpDst + CountData;
        Src := Src + CountData;
      end
      else
      begin
        CountData := -CountData;
        Fill := Src^; Inc(Src);
        FillChar(TmpDst^, CountData, Fill);
        TmpDst := TmpDst + CountData;
      end;
      Dec(Packets);
    end;
    Dst := Dst + FMainScreen.pitch;
    Dec(Lines);
  end;
end;

procedure TFlcPlayer.Color64;
var
  P: PByte;
  NumPackets, NumColors: Word;
  Skip, ColorCount: Byte;
  I: Integer;
begin
  P := FChunkData + 6;
  NumPackets := ReadU16(P); Inc(P, 2);
  while NumPackets > 0 do
  begin
    Skip := P^; Inc(P);
    ColorCount := P^; Inc(P);
    if ColorCount = 0 then ColorCount := 255;
    for I := 0 to ColorCount-1 do
    begin
      FColors[I].r := P^ shl 2; Inc(P);
      FColors[I].g := P^ shl 2; Inc(P);
      FColors[I].b := P^ shl 2; Inc(P);
    end;
    if FMainScreen <> FRealScreen.GetSurface.GetSurface then
      SDL_SetColors(FMainScreen, @FColors[0], Skip, ColorCount);
    FRealScreen.SetPalette(@FColors[0], Skip, ColorCount, True);
    Dec(NumPackets);
  end;
end;

procedure TFlcPlayer.Black;
var
  Dst: PByte;
  Lines: Integer;
begin
  Dst := PByte(FMainScreen.pixels) + FOffset;
  Lines := FHeaderHeight;
  while Lines > 0 do
  begin
    FillChar(Dst^, FHeaderWidth, 0);
    Dst := Dst + FMainScreen.pitch;
    Dec(Lines);
  end;
end;

procedure TFlcPlayer.FliCopy;
var
  Src, Dst: PByte;
  Lines: Integer;
begin
  Src := FChunkData + 6;
  Dst := PByte(FMainScreen.pixels) + FOffset;
  Lines := FHeaderHeight;
  while Lines > 0 do
  begin
    Move(Src^, Dst^, FHeaderWidth);
    Src := Src + FHeaderWidth;
    Dst := Dst + FMainScreen.pitch;
    Dec(Lines);
  end;
end;

procedure TFlcPlayer.PlayAudioFrame(SampleRate: Word);
begin
  // Stub
end;

procedure TFlcPlayer.InitAudio(Format: Word; Channels: Byte);
begin
  // Stub
end;

procedure TFlcPlayer.DeInitAudio;
begin
  // Stub
end;

procedure TFlcPlayer.Stop;
begin
  FPlayingState := 1;
end;

function TFlcPlayer.IsEndOfFile(Pos: PByte): Boolean;
begin
  Result := (PtrUInt(Pos) - PtrUInt(@FFileBuf[0])) >= FFileSize;
end;

function TFlcPlayer.GetFrameCount: Integer;
begin
  Result := FFrameCount;
end;

procedure TFlcPlayer.SetHeaderSpeed(Speed: Integer);
begin
  FHeaderSpeed := Speed;
end;

function TFlcPlayer.WasSkipped: Boolean;
begin
  Result := FPlayingState = 2;
end;

procedure TFlcPlayer.WaitForNextFrame(Delay: Cardinal);
var
  OldTick, NewTick, CurrentTick: Cardinal;
begin
  OldTick := SDL_GetTicks;
  NewTick := OldTick + Delay;
  while SDL_GetTicks < NewTick do
  begin
    if FHasAudio then
    begin
      // Decode audio while waiting
      while (NewTick - SDL_GetTicks) > 10 do
        DecodeAudio(1);
    end;
    SDL_Delay(1);
  end;
end;

// Endian helpers
function TFlcPlayer.ReadU16(Src: PByte): Word;
begin
  Result := Src[0] or (Src[1] shl 8);
end;

function TFlcPlayer.ReadU32(Src: PByte): Cardinal;
begin
  Result := Src[0] or (Src[1] shl 8) or (Src[2] shl 16) or (Src[3] shl 24);
end;

function TFlcPlayer.ReadS16(Src: PShortInt): SmallInt;
begin
  Result := SmallInt(Src[0] or (Src[1] shl 8));
end;

function TFlcPlayer.ReadS32(Src: PShortInt): Integer;
begin
  Result := Src[0] or (Src[1] shl 8) or (Src[2] shl 16) or (Src[3] shl 24);
end;

class procedure TFlcPlayer.AudioCallback(UserData: Pointer; Stream: PByte; Len: Integer);
begin
  // Stub
end;

end.