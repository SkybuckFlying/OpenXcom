#pragma once

#include <SDL.h>

int SpecialBlit
(
	SDL_Surface *src, SDL_Rect *srcrect,
	SDL_Surface *dst, SDL_Rect *dstrect
);

int SpecialBlitV2
(
	SDL_Surface *src, 
	SDL_Surface *dst, SDL_Rect *dstrect
);

void SpecialGradientTest( SDL_Surface *ParaSurface );
