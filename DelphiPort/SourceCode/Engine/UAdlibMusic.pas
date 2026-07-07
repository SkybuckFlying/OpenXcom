unit UAdlibMusic;

interface

uses
  UMusic, SysUtils, UOptions;

type
  TAdlibMusic = class(TMusic)
  private
    FData: TBytes;
    FSize: Integer;
    FVolume: Single;
    class var FDelay, FRate: Integer;
    class var FDelayRates: TDictionary<Integer, Integer>;
    procedure Player(Stream: Pointer; Len: Integer); // callback stub
  public
    constructor Create(Volume: Single = 1.0);
    destructor Destroy; override;
    procedure Load(const Filename: string); override;
    procedure LoadFromMemory(const Data: Pointer; Size: Integer); override;
    procedure Play(Loop: Integer = -1); override;
    function IsPlaying: Boolean; override;
  end;

implementation

uses
  UException, ULogger, UGame, UOptions;

constructor TAdlibMusic.Create(Volume: Single);
begin
  inherited Create;
  FData := nil;
  FSize := 0;
  FVolume := Volume;
  // Initialize delay rates if needed
  if FDelayRates = nil then
  begin
    FDelayRates := TDictionary<Integer,Integer>.Create;
    FDelayRates.Add(8000, 114*4);
    FDelayRates.Add(11025, 157*4);
    FDelayRates.Add(16000, 228*4);
    FDelayRates.Add(22050, 314*4);
    FDelayRates.Add(32000, 456*4);
    FDelayRates.Add(44100, 629*4);
    FDelayRates.Add(48000, 685*4);
  end;
end;

destructor TAdlibMusic.Destroy;
begin
  // Stop and free OPL emulator if used (stub)
  inherited;
end;

procedure TAdlibMusic.Load(const Filename: string);
var
  F: TFileStream;
begin
  F := TFileStream.Create(Filename, fmOpenRead or fmShareDenyWrite);
  try
    FSize := F.Size;
    SetLength(FData, FSize);
    F.Read(FData[0], FSize);
  finally
    F.Free;
  end;
end;

procedure TAdlibMusic.LoadFromMemory(const Data: Pointer; Size: Integer);
begin
  SetLength(FData, Size);
  Move(Data^, FData[0], Size);
  FSize := Size;
end;

procedure TAdlibMusic.Play(Loop: Integer);
begin
  if UOptions.mute then Exit;
  // Stub: would initialize OPL emulator and set callback
  // For real implementation, link to fmopl and adlplayer
  Log(LOG_INFO) << 'AdlibMusic: Play called (stub)';
end;

function TAdlibMusic.IsPlaying: Boolean;
begin
  // Stub: return false always
  Result := False;
end;

procedure TAdlibMusic.Player(Stream: Pointer; Len: Integer);
begin
  // Stub
end;

initialization
  TAdlibMusic.FDelayRates := nil;
end.