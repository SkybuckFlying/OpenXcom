unit UOpenGL;

interface

{$IFNDEF NO_OPENGL}
uses
  SDL, SysUtils;
{$ENDIF}

type
  TOpenGL = class
  private
    FTexture: Cardinal;
    FProgram: Cardinal;
    FLinear: Boolean;
    FBuffer: Pointer;
    FBufferSurface: TObject; // placeholder
    FWidth, FHeight: Cardinal;
    FFormat: Cardinal;
    FBPP: Cardinal;
    class var FCheckErrors: Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Resize(Width, Height: Cardinal);
    function Lock(out Data: Pointer; out Pitch: Cardinal): Boolean;
    procedure Clear;
    procedure Refresh(Smooth: Boolean; InWidth, InHeight, OutWidth, OutHeight: Cardinal; TopBlackBand, BottomBlackBand, LeftBlackBand, RightBlackBand: Integer);
    function SetShader(const Source: string): Boolean;
    procedure SetFragmentShader(const Source: string);
    procedure SetVertexShader(const Source: string);
    procedure Init(Width, Height: Integer);
    procedure SetVSync(Sync: Boolean);
    procedure Term;
    class procedure SetCheckErrors(Value: Boolean);
  end;

implementation

{$IFDEF NO_OPENGL}
// Stub implementation
constructor TOpenGL.Create; begin end;
destructor TOpenGL.Destroy; begin end;
procedure TOpenGL.Resize(Width, Height: Cardinal); begin end;
function TOpenGL.Lock(out Data: Pointer; out Pitch: Cardinal): Boolean; begin Data:=nil; Pitch:=0; Result:=False; end;
procedure TOpenGL.Clear; begin end;
procedure TOpenGL.Refresh(Smooth: Boolean; InWidth, InHeight, OutWidth, OutHeight: Cardinal; TopBlackBand, BottomBlackBand, LeftBlackBand, RightBlackBand: Integer); begin end;
function TOpenGL.SetShader(const Source: string): Boolean; begin Result:=False; end;
procedure TOpenGL.SetFragmentShader(const Source: string); begin end;
procedure TOpenGL.SetVertexShader(const Source: string); begin end;
procedure TOpenGL.Init(Width, Height: Integer); begin end;
procedure TOpenGL.SetVSync(Sync: Boolean); begin end;
procedure TOpenGL.Term; begin end;
class procedure TOpenGL.SetCheckErrors(Value: Boolean); begin end;
{$ELSE}
// Full implementation would require OpenGL headers and function pointers.
// For now, we provide a stub.
constructor TOpenGL.Create; begin FTexture:=0; FProgram:=0; FLinear:=False; FBuffer:=nil; FBufferSurface:=nil; FWidth:=0; FHeight:=0; FFormat:=0; FBPP:=32; end;
destructor TOpenGL.Destroy; begin Term; inherited; end;
procedure TOpenGL.Resize(Width, Height: Cardinal); begin end;
function TOpenGL.Lock(out Data: Pointer; out Pitch: Cardinal): Boolean; begin Data:=nil; Pitch:=0; Result:=False; end;
procedure TOpenGL.Clear; begin end;
procedure TOpenGL.Refresh(Smooth: Boolean; InWidth, InHeight, OutWidth, OutHeight: Cardinal; TopBlackBand, BottomBlackBand, LeftBlackBand, RightBlackBand: Integer); begin end;
function TOpenGL.SetShader(const Source: string): Boolean; begin Result:=False; end;
procedure TOpenGL.SetFragmentShader(const Source: string); begin end;
procedure TOpenGL.SetVertexShader(const Source: string); begin end;
procedure TOpenGL.Init(Width, Height: Integer); begin end;
procedure TOpenGL.SetVSync(Sync: Boolean); begin end;
procedure TOpenGL.Term; begin end;
class procedure TOpenGL.SetCheckErrors(Value: Boolean); begin FCheckErrors:=Value; end;
{$ENDIF}

end.