unit Armor;

interface

uses
  System.Classes, System.SysUtils, System.Generics.Collections,
  Yaml, MapData, UnitStats;

type
  TForcedTorso = (ftUseGender, ftAlwaysMale, ftAlwaysFemale);

  TItemDamageType = (dtNone, dtAp, dtIn, dtHe, dtLaser, dtPlasma, dtStun,
                     dtMelee, dtAcid, dtSmoke);

  TMovementType = (mtWalk, mtFly, mtSlide, mtFloat, mtSink);

  TArmor = class
  public const
    DAMAGE_TYPES = 10;
    NONE = 'STR_NONE';
  private
    FType: string;
    FSpriteSheet: string;
    FSpriteInv: string;
    FCorpseBattle: TArray<string>;
    FCorpseGeo: string;
    FStoreItem: string;
    FSpecWeapon: string;
    FFrontArmor: Integer;
    FSideArmor: Integer;
    FRearArmor: Integer;
    FUnderArmor: Integer;
    FDrawingRoutine: Integer;
    FDrawBubbles: Boolean;
    FMovementType: TMovementType;
    FSize: Integer;
    FWeight: Integer;
    FDamageModifier: array[0..DAMAGE_TYPES-1] of Single;
    FLoftempsSet: TArray<Integer>;
    FStats: TUnitStats;
    FDeathFrames: Integer;
    FConstantAnimation: Boolean;
    FHasInventory: Boolean;
    FForcedTorso: TForcedTorso;
    FFaceColorGroup: Integer;
    FHairColorGroup: Integer;
    FUtileColorGroup: Integer;
    FRankColorGroup: Integer;
    FFaceColor: TArray<Integer>;
    FHairColor: TArray<Integer>;
    FUtileColor: TArray<Integer>;
    FRankColor: TArray<Integer>;
    FUnits: TArray<string>;
  public
    constructor Create(const AType: string);
    destructor Destroy; override;
    procedure Load(const Node: TYamlNode);
    function GetType: string;
    function GetSpriteSheet: string;
    function GetSpriteInventory: string;
    function GetFrontArmor: Integer;
    function GetSideArmor: Integer;
    function GetRearArmor: Integer;
    function GetUnderArmor: Integer;
    function GetCorpseGeoscape: string;
    function GetCorpseBattlescape: TArray<string>;
    function GetStoreItem: string;
    function GetSpecialWeapon: string;
    function GetDrawingRoutine: Integer;
    function DrawBubbles: Boolean;
    function GetMovementType: TMovementType;
    function GetSize: Integer;
    function GetDamageModifier(DT: TItemDamageType): Single;
    function GetLoftempsSet: TArray<Integer>;
    function GetStats: TUnitStats;
    function GetWeight: Integer;
    function GetDeathFrames: Integer;
    function GetConstantAnimation: Boolean;
    function GetForcedTorso: TForcedTorso;
    function GetFaceColorGroup: Integer;
    function GetHairColorGroup: Integer;
    function GetUtileColorGroup: Integer;
    function GetRankColorGroup: Integer;
    function GetFaceColor(Index: Integer): Integer;
    function GetHairColor(Index: Integer): Integer;
    function GetUtileColor(Index: Integer): Integer;
    function GetRankColor(Index: Integer): Integer;
    function HasInventory: Boolean;
    function GetUnits: TArray<string>;
  end;

implementation

{ TArmor }

constructor TArmor.Create(const AType: string);
var
  i: Integer;
begin
  inherited Create;
  FType := AType;
  FFrontArmor := 0; FSideArmor := 0; FRearArmor := 0; FUnderArmor := 0;
  FDrawingRoutine := 0; FDrawBubbles := False;
  FMovementType := mtWalk; FSize := 1; FWeight := 0;
  FDeathFrames := 3; FConstantAnimation := False; FHasInventory := True;
  FForcedTorso := ftUseGender;
  FFaceColorGroup := 0; FHairColorGroup := 0; FUtileColorGroup := 0; FRankColorGroup := 0;
  for i := 0 to DAMAGE_TYPES-1 do
    FDamageModifier[i] := 1.0;
end;

destructor TArmor.Destroy;
begin
  inherited;
end;

procedure TArmor.Load(const Node: TYamlNode);
var
  dmgNode: TYamlNode;
  i: Integer;
begin
  FType := Node['type'].AsString(FType);
  FSpriteSheet := Node['spriteSheet'].AsString(FSpriteSheet);
  FSpriteInv := Node['spriteInv'].AsString(FSpriteInv);
  FHasInventory := Node['allowInv'].AsBoolean(FHasInventory);

  if Node.Has('corpseItem') then
  begin
    FCorpseBattle := [Node['corpseItem'].AsString('')];
    FCorpseGeo := FCorpseBattle[0];
  end
  else if Node.Has('corpseBattle') then
  begin
    FCorpseBattle := Node['corpseBattle'].AsArray<string>(FCorpseBattle);
    if Length(FCorpseBattle) > 0 then
      FCorpseGeo := FCorpseBattle[0];
  end;
  FCorpseGeo := Node['corpseGeo'].AsString(FCorpseGeo);
  FStoreItem := Node['storeItem'].AsString(FStoreItem);
  FSpecWeapon := Node['specialWeapon'].AsString(FSpecWeapon);

  FFrontArmor := Node['frontArmor'].AsInteger(FFrontArmor);
  FSideArmor := Node['sideArmor'].AsInteger(FSideArmor);
  FRearArmor := Node['rearArmor'].AsInteger(FRearArmor);
  FUnderArmor := Node['underArmor'].AsInteger(FUnderArmor);
  FDrawingRoutine := Node['drawingRoutine'].AsInteger(FDrawingRoutine);
  FDrawBubbles := Node['drawBubbles'].AsBoolean(FDrawBubbles);
  FMovementType := TMovementType(Node['movementType'].AsInteger(Integer(FMovementType)));
  FSize := Node['size'].AsInteger(FSize);
  FWeight := Node['weight'].AsInteger(FWeight);
  FStats.Merge(Node['stats'].As<TUnitStats>(FStats));

  dmgNode := Node['damageModifier'];
  if not dmgNode.IsNull then
  begin
    for i := 0 to dmgNode.Count-1 do
      if i < DAMAGE_TYPES then
        FDamageModifier[i] := dmgNode[i].AsFloat;
  end;

  FLoftempsSet := Node['loftempsSet'].AsArray<Integer>(FLoftempsSet);
  if Node.Has('loftemps') then
    FLoftempsSet := [Node['loftemps'].AsInteger(0)];

  FDeathFrames := Node['deathFrames'].AsInteger(FDeathFrames);
  FConstantAnimation := Node['constantAnimation'].AsBoolean(FConstantAnimation);
  FForcedTorso := TForcedTorso(Node['forcedTorso'].AsInteger(Integer(FForcedTorso)));

  FFaceColorGroup := Node['spriteFaceGroup'].AsInteger(FFaceColorGroup);
  FHairColorGroup := Node['spriteHairGroup'].AsInteger(FHairColorGroup);
  FRankColorGroup := Node['spriteRankGroup'].AsInteger(FRankColorGroup);
  FUtileColorGroup := Node['spriteUtileGroup'].AsInteger(FUtileColorGroup);
  FFaceColor := Node['spriteFaceColor'].AsArray<Integer>(FFaceColor);
  FHairColor := Node['spriteHairColor'].AsArray<Integer>(FHairColor);
  FRankColor := Node['spriteRankColor'].AsArray<Integer>(FRankColor);
  FUtileColor := Node['spriteUtileColor'].AsArray<Integer>(FUtileColor);
  FUnits := Node['units'].AsArray<string>(FUnits);
end;

function TArmor.GetType: string;
begin
  Result := FType;
end;

function TArmor.GetSpriteSheet: string;
begin
  Result := FSpriteSheet;
end;

function TArmor.GetSpriteInventory: string;
begin
  Result := FSpriteInv;
end;

function TArmor.GetFrontArmor: Integer;
begin
  Result := FFrontArmor;
end;

function TArmor.GetSideArmor: Integer;
begin
  Result := FSideArmor;
end;

function TArmor.GetRearArmor: Integer;
begin
  Result := FRearArmor;
end;

function TArmor.GetUnderArmor: Integer;
begin
  Result := FUnderArmor;
end;

function TArmor.GetCorpseGeoscape: string;
begin
  Result := FCorpseGeo;
end;

function TArmor.GetCorpseBattlescape: TArray<string>;
begin
  Result := FCorpseBattle;
end;

function TArmor.GetStoreItem: string;
begin
  Result := FStoreItem;
end;

function TArmor.GetSpecialWeapon: string;
begin
  Result := FSpecWeapon;
end;

function TArmor.GetDrawingRoutine: Integer;
begin
  Result := FDrawingRoutine;
end;

function TArmor.DrawBubbles: Boolean;
begin
  Result := FDrawBubbles;
end;

function TArmor.GetMovementType: TMovementType;
begin
  Result := FMovementType;
end;

function TArmor.GetSize: Integer;
begin
  Result := FSize;
end;

function TArmor.GetDamageModifier(DT: TItemDamageType): Single;
begin
  Result := FDamageModifier[Integer(DT)];
end;

function TArmor.GetLoftempsSet: TArray<Integer>;
begin
  Result := FLoftempsSet;
end;

function TArmor.GetStats: TUnitStats;
begin
  Result := FStats;
end;

function TArmor.GetWeight: Integer;
begin
  Result := FWeight;
end;

function TArmor.GetDeathFrames: Integer;
begin
  Result := FDeathFrames;
end;

function TArmor.GetConstantAnimation: Boolean;
begin
  Result := FConstantAnimation;
end;

function TArmor.GetForcedTorso: TForcedTorso;
begin
  Result := FForcedTorso;
end;

function TArmor.GetFaceColorGroup: Integer;
begin
  Result := FFaceColorGroup;
end;

function TArmor.GetHairColorGroup: Integer;
begin
  Result := FHairColorGroup;
end;

function TArmor.GetUtileColorGroup: Integer;
begin
  Result := FUtileColorGroup;
end;

function TArmor.GetRankColorGroup: Integer;
begin
  Result := FRankColorGroup;
end;

function TArmor.GetFaceColor(Index: Integer): Integer;
begin
  if (Index >= 0) and (Index < Length(FFaceColor)) then
    Result := FFaceColor[Index]
  else
    Result := 0;
end;

function TArmor.GetHairColor(Index: Integer): Integer;
begin
  if (Index >= 0) and (Index < Length(FHairColor)) then
    Result := FHairColor[Index]
  else
    Result := 0;
end;

function TArmor.GetUtileColor(Index: Integer): Integer;
begin
  if (Index >= 0) and (Index < Length(FUtileColor)) then
    Result := FUtileColor[Index]
  else
    Result := 0;
end;

function TArmor.GetRankColor(Index: Integer): Integer;
begin
  if (Index >= 0) and (Index < Length(FRankColor)) then
    Result := FRankColor[Index]
  else
    Result := 0;
end;

function TArmor.HasInventory: Boolean;
begin
  Result := FHasInventory;
end;

function TArmor.GetUnits: TArray<string>;
begin
  Result := FUnits;
end;

end.