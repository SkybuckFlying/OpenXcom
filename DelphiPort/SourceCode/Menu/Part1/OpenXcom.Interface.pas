unit OpenXcom.Interface;

interface

uses
  System.Classes, System.Types, SDL.Api;

type
  TSurface = class
  end;

  TInteractiveSurface = class(TSurface)
  end;

  TWindow = class(TSurface)
  end;

  TText = class(TSurface)
  end;

  TTextButton = class(TSurface)
  end;

  TToggleTextButton = class(TTextButton)
  end;

  TTextList = class(TSurface)
  end;

  TArrowButton = class(TSurface)
  end;

  TComboBox = class(TSurface)
  end;

  TSlider = class(TSurface)
  end;

  TFrame = class(TSurface)
  end;

  TTextEdit = class(TSurface)
  end;

  TFpsCounter = class
  end;

  TCursor = class
  end;

  TFont = class
  end;

  TLanguage = class
  end;

  TMusic = class
  end;

  TSound = class
  end;

  TMod = class
  end;

implementation

end.