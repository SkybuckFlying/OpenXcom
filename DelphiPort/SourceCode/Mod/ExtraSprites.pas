unit ExtraSprites;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections,
  Yaml, Engine.Surface, Engine.SurfaceSet, Engine.FileMap, ModUnit;

type
  TExtraSprites = class
  private
    FType: string;
    FSprites: TDictionary<Integer, string>;
    FCurrent: TModData;
    FWidth, FHeight: Integer;
    FSingleImage: Boolean;
    FSubX, FSubY: Integer;
    FLoaded: Boolean;
    function GetFrame(SetObj: TSurfaceSet; Index: Integer): TSurface;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Load(const Node: TYamlNode; const Current: TModData);
    function GetType: string;
    function GetSprites: TDictionary<Integer, string>;
    function GetWidth: Integer;
    function GetHeight: Integer;
    function GetSingleImage: Boolean;
    function GetSubX: Integer;
    function GetSubY: Integer;
    function IsLoaded: Boolean;
    class function IsImageFile(const FileName: string): Boolean; static;
    function LoadSurface(Surface: TSurface): TSurface;
    function LoadSurfaceSet(SetObj: TSurfaceSet): TSurfaceSet;
  end;

implementation

{ TExtraSprites }

constructor TExtraSprites.Create;
begin
  inherited Create;
  FSprites := TDictionary<Integer, string>.Create;
  FWidth := 320; FHeight := 200;
  FSingleImage := False;
  FSubX := 0; FSubY := 0;
  FLoaded := False;
end;

destructor TExtraSprites.Destroy;
begin
  FSprites.Free;
  inherited;
end;

procedure TExtraSprites.Load(const Node: TYamlNode; const Current: TModData);
begin
  FType := Node['type'].AsString(FType);
  FSprites.Clear;
  var dictNode := Node['files'];
  if not dictNode.IsNull then
  begin
    for var kv in dictNode do
      FSprites.Add(kv.Key.AsInteger, kv.Value.AsString);
  end;
  FWidth := Node['width'].AsInteger(FWidth);
  FHeight := Node['height'].AsInteger(FHeight);
  FSingleImage := Node['singleImage'].AsBoolean(FSingleImage);
  FSubX := Node['subX'].AsInteger(FSubX);
  FSubY := Node['subY'].AsInteger(FSubY);
  FCurrent := Current;
end;

function TExtraSprites.GetType: string;
begin
  Result := FType;
end;

function TExtraSprites.GetSprites: TDictionary<Integer, string>;
begin
  Result := FSprites;
end;

function TExtraSprites.GetWidth: Integer;
begin
  Result := FWidth;
end;

function TExtraSprites.GetHeight: Integer;
begin
  Result := FHeight;
end;

function TExtraSprites.GetSingleImage: Boolean;
begin
  Result := FSingleImage;
end;

function TExtraSprites.GetSubX: Integer;
begin
  Result := FSubX;
end;

function TExtraSprites.GetSubY: Integer;
begin
  Result := FSubY;
end;

function TExtraSprites.IsLoaded: Boolean;
begin
  Result := FLoaded;
end;

class function TExtraSprites.IsImageFile(const FileName: string): Boolean;
const
  Exts: array[0..8] of string = ('.PNG', '.GIF', '.BMP', '.LBM', '.IFF', '.PCX', '.TGA', '.TIF', '.TIFF');
var
  Ext: string;
begin
  Ext := ExtractFileExt(FileName).ToUpper;
  for var E in Exts do
    if Ext = E then
      Exit(True);
  Result := False;
end;

function TExtraSprites.GetFrame(SetObj: TSurfaceSet; Index: Integer): TSurface;
var
  indexWithOffset: Integer;
begin
  indexWithOffset := Index;
  if indexWithOffset >= SetObj.GetMaxSharedFrames then
  begin
    if indexWithOffset >= FCurrent.Size then
      raise Exception.CreateFmt('ExtraSprites ''%s'' frame ''%d'' exceeds mod ''%s'' size limit %d',
        [FType, indexWithOffset, FCurrent.Name, FCurrent.Size]);
    indexWithOffset := indexWithOffset + FCurrent.Offset;
  end
  else if indexWithOffset < 0 then
    raise Exception.CreateFmt('ExtraSprites ''%s'' frame ''%d'' in mod ''%s'' is not allowed.',
      [FType, indexWithOffset, FCurrent.Name]);

  var Frame := SetObj.GetFrame(indexWithOffset);
  if Frame = nil then
    Frame := SetObj.AddFrame(indexWithOffset);
  Result := Frame;
end;

function TExtraSprites.LoadSurface(Surface: TSurface): TSurface;
begin
  if not FSingleImage then
    Exit(Surface);
  FLoaded := True;
  if Surface <> nil then
    Surface.Free;
  Surface := TSurface.Create(FWidth, FHeight);
  var kv := FSprites.ToArray;
  if Length(kv) > 0 then
    Surface.LoadImage(TFileMap.GetFilePath(kv[0].Value));
  Result := Surface;
end;

function TExtraSprites.LoadSurfaceSet(SetObj: TSurfaceSet): TSurfaceSet;
var
  subdivision: Boolean;
  surfaceSetX, surfaceSetY: Integer;
begin
  if FSingleImage then
    Exit(SetObj);
  FLoaded := True;
  subdivision := (FSubX <> 0) and (FSubY <> 0);
  if subdivision then
  begin
    surfaceSetX := FSubX;
    surfaceSetY := FSubY;
  end
  else
  begin
    surfaceSetX := FWidth;
    surfaceSetY := FHeight;
  end;

  if SetObj = nil then
    SetObj := TSurfaceSet.Create(surfaceSetX, surfaceSetY)
  else
  begin
    if (SetObj.GetTotalFrames = 0) and
       ((SetObj.GetWidth <> surfaceSetX) or (SetObj.GetHeight <> surfaceSetY)) then
    begin
      var shared := SetObj.GetMaxSharedFrames;
      SetObj.Free;
      SetObj := TSurfaceSet.Create(surfaceSetX, surfaceSetY);
      SetObj.SetMaxSharedFrames(shared);
    end;
  end;

  for var kv in FSprites do
  begin
    var StartFrame := kv.Key;
    var FileName := kv.Value;
    if FileName[FileName.Length] = '/' then
    begin
      var Offset := StartFrame;
      var Contents := TFileMap.GetVFolderContents(FileName);
      for var SubFile in Contents do
      begin
        if not IsImageFile(SubFile) then
          Continue;
        try
          var FullPath := TFileMap.GetFilePath(FileName + SubFile);
          var Frame := GetFrame(SetObj, Offset);
          Frame.LoadImage(FullPath);
          Inc(Offset);
        except
          on E: Exception do
            // Log warning
        end;
      end;
    end
    else
    begin
      var FullPath := TFileMap.GetFilePath(FileName);
      if not subdivision then
      begin
        var Frame := GetFrame(SetObj, StartFrame);
        Frame.LoadImage(FullPath);
      end
      else
      begin
        var Temp := TSurface.Create(FWidth, FHeight);
        try
          Temp.LoadImage(FullPath);
          var XDiv := FWidth div FSubX;
          var YDiv := FHeight div FSubY;
          var Frames := XDiv * YDiv;
          var Offset := StartFrame;
          for var y := 0 to YDiv-1 do
            for var x := 0 to XDiv-1 do
            begin
              var Frame := GetFrame(SetObj, Offset);
              Temp.BlitNShade(Frame, -x * FSubX, -y * FSubY, 0);
              Inc(Offset);
            end;
        finally
          Temp.Free;
        end;
      end;
    end;
  end;
  Result := SetObj;
end;

end.