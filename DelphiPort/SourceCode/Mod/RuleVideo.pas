unit RuleVideo;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections,
  Yaml, Engine.Screen, Interface.Text;

type
  TSlideshowSlide = record
    ImagePath: string;
    Caption: string;
    W, H, X, Y, Color: Integer;
    Align: TTextHAlign;
    TransitionSeconds: Integer;
  end;

  TSlideshowHeader = record
    MusicId: string;
    TransitionSeconds: Integer;
  end;

  TRuleVideo = class
  private
    FId: string;
    FUseUfoAudioSequence: Boolean;
    FVideos: TArray<string>;
    FAudioTracks: TArray<string>;
    FSlideshowHeader: TSlideshowHeader;
    FSlides: TArray<TSlideshowSlide>;
  public
    constructor Create(const AId: string);
    destructor Destroy; override;
    procedure Load(const Node: TYamlNode);
    function UseUfoAudioSequence: Boolean;
    function GetVideos: TArray<string>;
    function GetAudioTracks: TArray<string>;
    function GetSlideshowHeader: TSlideshowHeader;
    function GetSlides: TArray<TSlideshowSlide>;
  end;

implementation

{ TRuleVideo }

constructor TRuleVideo.Create(const AId: string);
begin
  inherited Create;
  FId := AId;
  FUseUfoAudioSequence := False;
end;

destructor TRuleVideo.Destroy;
begin
  inherited;
end;

procedure TRuleVideo.Load(const Node: TYamlNode);
begin
  FUseUfoAudioSequence := Node['useUfoAudioSequence'].AsBoolean(FUseUfoAudioSequence);
  var vidNode := Node['videos'];
  if not vidNode.IsNull then
  begin
    FVideos := [];
    for var item in vidNode do
      FVideos := FVideos + [item.AsString];
  end;
  var audNode := Node['audioTracks'];
  if not audNode.IsNull then
  begin
    FAudioTracks := [];
    for var item in audNode do
      FAudioTracks := FAudioTracks + [item.AsString];
  end;
  var ssNode := Node['slideshow'];
  if not ssNode.IsNull then
  begin
    FSlideshowHeader.MusicId := ssNode['musicId'].AsString('');
    FSlideshowHeader.TransitionSeconds := ssNode['transitionSeconds'].AsInteger(30);
    var slidesNode := ssNode['slides'];
    if not slidesNode.IsNull then
    begin
      FSlides := [];
      for var slideNode in slidesNode do
      begin
        var slide: TSlideshowSlide;
        slide.ImagePath := slideNode['imagePath'].AsString('');
        slide.Caption := slideNode['caption'].AsString('');
        var sz := slideNode['captionSize'].As<TPair<Integer,Integer>>;
        if sz.Key = 0 then
        begin
          slide.W := Screen.ORIGINAL_WIDTH;
          slide.H := Screen.ORIGINAL_HEIGHT;
        end
        else
        begin
          slide.W := sz.Key;
          slide.H := sz.Value;
        end;
        var pos := slideNode['captionPos'].As<TPair<Integer,Integer>>;
        slide.X := pos.Key; slide.Y := pos.Value;
        slide.Color := slideNode['captionColor'].AsInteger(MaxInt);
        slide.TransitionSeconds := slideNode['transitionSeconds'].AsInteger(0);
        slide.Align := TTextHAlign(slideNode['captionAlign'].AsInteger(Integer(ALIGN_LEFT)));
        FSlides := FSlides + [slide];
      end;
    end;
  end;
end;

function TRuleVideo.UseUfoAudioSequence: Boolean;
begin
  Result := FUseUfoAudioSequence;
end;

function TRuleVideo.GetVideos: TArray<string>;
begin
  Result := FVideos;
end;

function TRuleVideo.GetAudioTracks: TArray<string>;
begin
  Result := FAudioTracks;
end;

function TRuleVideo.GetSlideshowHeader: TSlideshowHeader;
begin
  Result := FSlideshowHeader;
end;

function TRuleVideo.GetSlides: TArray<TSlideshowSlide>;
begin
  Result := FSlides;
end;

end.