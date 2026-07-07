unit ArticleDefinition;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections,
  Yaml;

type
  TUfopaediaTypeId = (
    utUnknown,
    utCraft,
    utCraftWeapon,
    utVehicle,
    utItem,
    utArmor,
    utBaseFacility,
    utTextImage,
    utText,
    utUfo,
    utTftd,
    utTftdCraft,
    utTftdCraftWeapon,
    utTftdVehicle,
    utTftdItem,
    utTftdArmor,
    utTftdBaseFacility,
    utTftdUso
  );

  TArticleDefinitionRect = record
    X, Y, Width, Height: Integer;
    procedure SetRect(AX, AY, AWidth, AHeight: Integer);
  end;

  TArticleDefinition = class
  private
    FTypeId: TUfopaediaTypeId;
    FListOrder: Integer;
  protected
    constructor Create(ATypeId: TUfopaediaTypeId);
  public
    Id: string;
    Title: string;
    Section: string;
    Requires: TArray<string>;
    destructor Destroy; override;
    function GetType: TUfopaediaTypeId;
    procedure Load(const Node: TYamlNode; AListOrder: Integer); virtual;
    function GetListOrder: Integer;
  end;

  TArticleDefinitionCraft = class(TArticleDefinition)
  public
    ImageId: string;
    RectStats: TArticleDefinitionRect;
    RectText: TArticleDefinitionRect;
    Text: string;
    constructor Create;
    procedure Load(const Node: TYamlNode; AListOrder: Integer); override;
  end;

  TArticleDefinitionCraftWeapon = class(TArticleDefinition)
  public
    ImageId: string;
    Text: string;
    constructor Create;
    procedure Load(const Node: TYamlNode; AListOrder: Integer); override;
  end;

  TArticleDefinitionText = class(TArticleDefinition)
  public
    Text: string;
    constructor Create;
    procedure Load(const Node: TYamlNode; AListOrder: Integer); override;
  end;

  TArticleDefinitionTextImage = class(TArticleDefinition)
  public
    ImageId: string;
    Text: string;
    TextWidth: Integer;
    constructor Create;
    procedure Load(const Node: TYamlNode; AListOrder: Integer); override;
  end;

  TArticleDefinitionTFTD = class(TArticleDefinition)
  public
    ImageId: string;
    Text: string;
    TextWidth: Integer;
    Weapon: string;
    constructor Create;
    procedure Load(const Node: TYamlNode; AListOrder: Integer); override;
  end;

  TArticleDefinitionBaseFacility = class(TArticleDefinition)
  public
    Text: string;
    constructor Create;
    procedure Load(const Node: TYamlNode; AListOrder: Integer); override;
  end;

  TArticleDefinitionItem = class(TArticleDefinition)
  public
    Text: string;
    constructor Create;
    procedure Load(const Node: TYamlNode; AListOrder: Integer); override;
  end;

  TArticleDefinitionUfo = class(TArticleDefinition)
  public
    Text: string;
    constructor Create;
    procedure Load(const Node: TYamlNode; AListOrder: Integer); override;
  end;

  TArticleDefinitionArmor = class(TArticleDefinition)
  public
    Text: string;
    constructor Create;
    procedure Load(const Node: TYamlNode; AListOrder: Integer); override;
  end;

  TArticleDefinitionVehicle = class(TArticleDefinition)
  public
    Text: string;
    Weapon: string;
    constructor Create;
    procedure Load(const Node: TYamlNode; AListOrder: Integer); override;
  end;

implementation

{ TArticleDefinitionRect }

procedure TArticleDefinitionRect.SetRect(AX, AY, AWidth, AHeight: Integer);
begin
  X := AX; Y := AY; Width := AWidth; Height := AHeight;
end;

{ TArticleDefinition }

constructor TArticleDefinition.Create(ATypeId: TUfopaediaTypeId);
begin
  inherited Create;
  FTypeId := ATypeId;
  FListOrder := 0;
end;

destructor TArticleDefinition.Destroy;
begin
  inherited;
end;

function TArticleDefinition.GetType: TUfopaediaTypeId;
begin
  Result := FTypeId;
end;

procedure TArticleDefinition.Load(const Node: TYamlNode; AListOrder: Integer);
begin
  Id := Node['id'].AsString(Id);
  Section := Node['section'].AsString(Section);
  Requires := Node['requires'].AsArray<string>(Requires);
  Title := Node['title'].AsString(Title);
  FListOrder := Node['listOrder'].AsInteger(FListOrder);
  if FListOrder = 0 then
    FListOrder := AListOrder;
end;

function TArticleDefinition.GetListOrder: Integer;
begin
  Result := FListOrder;
end;

{ TArticleDefinitionCraft }

constructor TArticleDefinitionCraft.Create;
begin
  inherited Create(utCraft);
end;

procedure TArticleDefinitionCraft.Load(const Node: TYamlNode; AListOrder: Integer);
begin
  inherited Load(Node, AListOrder);
  ImageId := Node['image_id'].AsString(ImageId);
  RectStats := Node['rect_stats'].As<TArticleDefinitionRect>(RectStats);
  RectText := Node['rect_text'].As<TArticleDefinitionRect>(RectText);
  Text := Node['text'].AsString(Text);
end;

{ TArticleDefinitionCraftWeapon }

constructor TArticleDefinitionCraftWeapon.Create;
begin
  inherited Create(utCraftWeapon);
end;

procedure TArticleDefinitionCraftWeapon.Load(const Node: TYamlNode; AListOrder: Integer);
begin
  inherited Load(Node, AListOrder);
  ImageId := Node['image_id'].AsString(ImageId);
  Text := Node['text'].AsString(Text);
end;

{ TArticleDefinitionText }

constructor TArticleDefinitionText.Create;
begin
  inherited Create(utText);
end;

procedure TArticleDefinitionText.Load(const Node: TYamlNode; AListOrder: Integer);
begin
  inherited Load(Node, AListOrder);
  Text := Node['text'].AsString(Text);
end;

{ TArticleDefinitionTextImage }

constructor TArticleDefinitionTextImage.Create;
begin
  inherited Create(utTextImage);
  TextWidth := 0;
end;

procedure TArticleDefinitionTextImage.Load(const Node: TYamlNode; AListOrder: Integer);
begin
  inherited Load(Node, AListOrder);
  ImageId := Node['image_id'].AsString(ImageId);
  Text := Node['text'].AsString(Text);
  TextWidth := Node['text_width'].AsInteger(TextWidth);
end;

{ TArticleDefinitionTFTD }

constructor TArticleDefinitionTFTD.Create;
begin
  inherited Create(utTftd);
  TextWidth := 0;
end;

procedure TArticleDefinitionTFTD.Load(const Node: TYamlNode; AListOrder: Integer);
begin
  inherited Load(Node, AListOrder);
  FTypeId := TUfopaediaTypeId(Node['type_id'].AsInteger(Integer(FTypeId)));
  ImageId := Node['image_id'].AsString(ImageId);
  Text := Node['text'].AsString(Text);
  TextWidth := Node['text_width'].AsInteger(157);
  Weapon := Node['weapon'].AsString(Weapon);
end;

{ TArticleDefinitionBaseFacility }

constructor TArticleDefinitionBaseFacility.Create;
begin
  inherited Create(utBaseFacility);
end;

procedure TArticleDefinitionBaseFacility.Load(const Node: TYamlNode; AListOrder: Integer);
begin
  inherited Load(Node, AListOrder);
  Text := Node['text'].AsString(Text);
end;

{ TArticleDefinitionItem }

constructor TArticleDefinitionItem.Create;
begin
  inherited Create(utItem);
end;

procedure TArticleDefinitionItem.Load(const Node: TYamlNode; AListOrder: Integer);
begin
  inherited Load(Node, AListOrder);
  Text := Node['text'].AsString(Text);
end;

{ TArticleDefinitionUfo }

constructor TArticleDefinitionUfo.Create;
begin
  inherited Create(utUfo);
end;

procedure TArticleDefinitionUfo.Load(const Node: TYamlNode; AListOrder: Integer);
begin
  inherited Load(Node, AListOrder);
  Text := Node['text'].AsString(Text);
end;

{ TArticleDefinitionArmor }

constructor TArticleDefinitionArmor.Create;
begin
  inherited Create(utArmor);
end;

procedure TArticleDefinitionArmor.Load(const Node: TYamlNode; AListOrder: Integer);
begin
  inherited Load(Node, AListOrder);
  Text := Node['text'].AsString(Text);
end;

{ TArticleDefinitionVehicle }

constructor TArticleDefinitionVehicle.Create;
begin
  inherited Create(utVehicle);
end;

procedure TArticleDefinitionVehicle.Load(const Node: TYamlNode; AListOrder: Integer);
begin
  inherited Load(Node, AListOrder);
  Weapon := Node['weapon'].AsString(Weapon);
  Text := Node['text'].AsString(Text);
end;

end.