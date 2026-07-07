{----------------------------------------------------------------------------}
{ Unit: ArticleState                                                         }
{ Base class for all Ufopaedia article states.                               }
{----------------------------------------------------------------------------}
unit ArticleState;

interface

uses
  Classes, SysUtils, Generics.Collections,
  Engine.Game, Engine.Action, Engine.Surface, Engine.Text, Engine.TextButton,
  Engine.LocalizedText, Engine.Options, Mod.RuleItem;

type
  TItemDamageType = (DT_AP, DT_IN, DT_HE, DT_LASER, DT_PLASMA, DT_STUN,
                     DT_MELEE, DT_ACID, DT_SMOKE);

  TArticleState = class(TState)
  protected
    FId: string;
    FBg: TSurface;
    FBtnOk: TTextButton;
    FBtnPrev: TTextButton;
    FBtnNext: TTextButton;
    FGame: TGame; // will be assigned via constructor? In C++ it's inherited from State, we'll use FGame as a field.

    constructor Create(const article_id: string); virtual;
    destructor Destroy; override;

    function GetDamageTypeText(dt: TItemDamageType): string;
    procedure InitLayout; virtual;

    procedure BtnOkClick(Action: TAction);
    procedure BtnPrevClick(Action: TAction);
    procedure BtnNextClick(Action: TAction);

  public
    function GetId: string;
  end;

implementation

{ TArticleState }

constructor TArticleState.Create(const article_id: string);
begin
  inherited Create;
  FId := article_id;
  FBg := TSurface.Create(320, 200, 0, 0);
  FBtnOk := TTextButton.Create(30, 14, 5, 5);
  FBtnPrev := TTextButton.Create(30, 14, 40, 5);
  FBtnNext := TTextButton.Create(30, 14, 75, 5);
end;

destructor TArticleState.Destroy;
begin
  FBg.Free;
  FBtnOk.Free;
  FBtnPrev.Free;
  FBtnNext.Free;
  inherited;
end;

function TArticleState.GetDamageTypeText(dt: TItemDamageType): string;
begin
  case dt of
    DT_AP:     Result := 'STR_DAMAGE_ARMOR_PIERCING';
    DT_IN:     Result := 'STR_DAMAGE_INCENDIARY';
    DT_HE:     Result := 'STR_DAMAGE_HIGH_EXPLOSIVE';
    DT_LASER:  Result := 'STR_DAMAGE_LASER_BEAM';
    DT_PLASMA: Result := 'STR_DAMAGE_PLASMA_BEAM';
    DT_STUN:   Result := 'STR_DAMAGE_STUN';
    DT_MELEE:  Result := 'STR_DAMAGE_MELEE';
    DT_ACID:   Result := 'STR_DAMAGE_ACID';
    DT_SMOKE:  Result := 'STR_DAMAGE_SMOKE';
  else
    Result := 'STR_UNKNOWN';
  end;
end;

procedure TArticleState.InitLayout;
begin
  Add(FBg);
  Add(FBtnOk);
  Add(FBtnPrev);
  Add(FBtnNext);

  FBtnOk.SetText(tr('STR_OK'));
  FBtnOk.OnMouseClick := BtnOkClick;
  FBtnOk.OnKeyboardPress := BtnOkClick;
  FBtnOk.KeyboardPressKey := Options.KeyOk; // simplified; need to set key properly
  // We need to handle multiple keys; in Delphi we might assign separate handlers or check key in event.
  // For simplicity, we'll keep the same method but we'll need to handle key checks.
  FBtnPrev.SetText('<<');
  FBtnPrev.OnMouseClick := BtnPrevClick;
  FBtnPrev.OnKeyboardPress := BtnPrevClick;
  FBtnPrev.KeyboardPressKey := Options.KeyGeoLeft;
  FBtnNext.SetText('>>');
  FBtnNext.OnMouseClick := BtnNextClick;
  FBtnNext.OnKeyboardPress := BtnNextClick;
  FBtnNext.KeyboardPressKey := Options.KeyGeoRight;
end;

procedure TArticleState.BtnOkClick(Action: TAction);
begin
  FGame.PopState;
end;

procedure TArticleState.BtnPrevClick(Action: TAction);
begin
  // forward to Ufopaedia::prev, we'll later implement as class method
  TUfopaedia.Prev(FGame);
end;

procedure TArticleState.BtnNextClick(Action: TAction);
begin
  TUfopaedia.Next(FGame);
end;

function TArticleState.GetId: string;
begin
  Result := FId;
end;

end.