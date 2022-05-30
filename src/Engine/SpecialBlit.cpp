#include "SpecialBlit.h"

// Skybuck: re-use clipping from SDL_UpperBlit

// maybe a custom blitter is possible, but for now it seems a recompile of SDL would be needed.
/** typedef for private surface blitting functions */
// typedef int (*SDL_blit)(struct SDL_Surface *src, SDL_Rect *srcrect,
//			struct SDL_Surface *dst, SDL_Rect *dstrect);




/* 
 * Set up a blit between two surfaces -- split into three parts:
 * The upper part, SDL_UpperBlit(), performs clipping and rectangle 
 * verification.  The lower part is a pointer to a low level
 * accelerated blitting function.
 *
 * These parts are separated out and each used internally by this 
 * library in the optimimum places.  They are exported so that if
 * you know exactly what you are doing, you can optimize your code
 * by calling the one(s) you need.
 */
 /*
int SDL_LowerBlit (SDL_Surface *src, SDL_Rect *srcrect,
				SDL_Surface *dst, SDL_Rect *dstrect)
{
	SDL_blit do_blit;
	SDL_Rect hw_srcrect;
	SDL_Rect hw_dstrect;

	// Check to make sure the blit mapping is valid 
	if ( (src->map->dst != dst) ||
             (src->map->dst->format_version != src->map->format_version) ) {
		if ( SDL_MapSurface(src, dst) < 0 ) {
			return(-1);
		}
	}

	// Figure out which blitter to use 
	if ( (src->flags & SDL_HWACCEL) == SDL_HWACCEL ) {
		if ( src == SDL_VideoSurface ) {
			hw_srcrect = *srcrect;
			hw_srcrect.x += current_video->offset_x;
			hw_srcrect.y += current_video->offset_y;
			srcrect = &hw_srcrect;
		}
		if ( dst == SDL_VideoSurface ) {
			hw_dstrect = *dstrect;
			hw_dstrect.x += current_video->offset_x;
			hw_dstrect.y += current_video->offset_y;
			dstrect = &hw_dstrect;
		}
		do_blit = src->map->hw_blit;
	} else {
		do_blit = src->map->sw_blit;
	}
	return(do_blit(src, srcrect, dst, dstrect));
}
*/


int SDL_LowerBlitSpecial
(
	SDL_Surface *src, SDL_Rect *srcrect,
	SDL_Surface *dst, SDL_Rect *dstrect
)
{
	int x, y;
	int w, h;
	int sp, dp;

	Uint8 *SrcPointer;
	SDL_Color *DstPointer;

	Uint8 SrcColor;
	SDL_Color DstColor;

	int SrcW, SrcH;
	int DstW, DstH;

	int SrcX, SrcY;
	int DstX, DstY;

	int SrcOffset;
	int DstOffset;


	SrcW = src->w;
	SrcH = src->h;

	DstW = dst->w;
	DstH = dst->h;

	sp = src->pitch;
	dp = dst->pitch;

	SDL_LockSurface( src );
	SDL_LockSurface( dst );

	w = SrcW;
	h = SrcH;
	for (y=0; y<h; y++)
	{
		for (x=0; x<w; x++)
		{
			SrcX = srcrect->x + x;
			SrcY = srcrect->y + y;

			DstX = dstrect->x + x;
			DstY = dstrect->y + y;


//			SrcOffset = y * sp + x;
//			DstOffset = y * dp + x * 4;

			// pointers below already multiply by data structure width so don't do it in formulas below =D

			SrcOffset = SrcY * SrcW + SrcX;
			DstOffset = DstY * DstW + DstX;

			SrcPointer = (Uint8*) src->pixels;
			DstPointer = (SDL_Color*) dst->pixels;

			SrcColor = SrcPointer[SrcOffset];

			//if (SrcColor != 0)
			{
				DstColor.r = SrcColor;
				DstColor.g = SrcColor;
				DstColor.b = SrcColor;

				DstPointer[DstOffset] = DstColor;
			}
		}
	}

    SDL_UnlockSurface( dst );
	SDL_UnlockSurface( src );

	return 1;
}

int SpecialBlit
(
	SDL_Surface *src, SDL_Rect *srcrect,
	SDL_Surface *dst, SDL_Rect *dstrect
)
{
    SDL_Rect fulldst;
	int srcx, srcy, w, h;

	/* Make sure the surfaces aren't locked */
	if ( ! src || ! dst )
	{
		SDL_SetError("SDL_UpperBlit: passed a NULL surface");
		return(-1);
	}
	if ( src->locked || dst->locked )
	{
		SDL_SetError("Surfaces must not be locked during blit");
		return(-1);
	}

	/* If the destination rectangle is NULL, use the entire dest surface */
	if ( dstrect == NULL )
	{
	    fulldst.x = fulldst.y = 0;
		dstrect = &fulldst;
	}

	/* clip the source rectangle to the source surface */
	if(srcrect)
	{
	    int maxw, maxh;
	
		srcx = srcrect->x;
		w = srcrect->w;
		if(srcx < 0)
		{
		    w += srcx;
			dstrect->x -= srcx;
			srcx = 0;
		}
		maxw = src->w - srcx;
		if(maxw < w) w = maxw;

		srcy = srcrect->y;
		h = srcrect->h;
		if(srcy < 0)
		{
		    h += srcy;
			dstrect->y -= srcy;
			srcy = 0;
		}
		maxh = src->h - srcy;
		if(maxh < h) h = maxh;
	    
	} else
	{
	    srcx = srcy = 0;
		w = src->w;
		h = src->h;
	}

	/* clip the destination rectangle against the clip rectangle */
	{
	    SDL_Rect *clip = &dst->clip_rect;
		int dx, dy;

		dx = clip->x - dstrect->x;
		if(dx > 0)
		{
			w -= dx;
			dstrect->x += dx;
			srcx += dx;
		}
		dx = dstrect->x + w - clip->x - clip->w;
		if(dx > 0) w -= dx;

		dy = clip->y - dstrect->y;
		if(dy > 0)
		{
			h -= dy;
			dstrect->y += dy;
			srcy += dy;
		}
		dy = dstrect->y + h - clip->y - clip->h;
		if(dy > 0) h -= dy;
	}

	if(w > 0 && h > 0)
	{
	    SDL_Rect sr;
	    sr.x = srcx;
		sr.y = srcy;
		sr.w = dstrect->w = w;
		sr.h = dstrect->h = h;
		return SDL_LowerBlitSpecial(src, &sr, dst, dstrect);
	}
	dstrect->w = dstrect->h = 0;
	return 0;
}


int SpecialBlitV2
(
	SDL_Surface *src,
	SDL_Surface *dst, SDL_Rect *dstrect
)
{
	int x, y;
	int w, h;
	int sp, dp;

	Uint8 *SrcPointer;
	SDL_Color *DstPointer;

	Uint8 SrcColor;
	SDL_Color DstColor;

	int SrcW, SrcH;
	int DstW, DstH;

	int SrcX, SrcY;
	int DstX, DstY;

	int SrcOffset;
	int DstOffset;

	SrcW = src->w;
	SrcH = src->h;

	DstW = dst->w;
	DstH = dst->h;

	sp = src->pitch;
	dp = dst->pitch;

	SDL_LockSurface( src );
	SDL_LockSurface( dst );

	w = SrcW;
	h = SrcH;
	for (y=0; y<h; y++)
	{
		for (x=0; x<w; x++)
		{
			SrcX = x;
			SrcY = y;

			DstX = dstrect->x + x;
			DstY = dstrect->y + y;


//			SrcOffset = y * sp + x;
//			DstOffset = y * dp + x * 4;

			// pointers below already multiply by data structure width so don't do it in formulas below =D

			SrcOffset = SrcY * SrcW + SrcX;
			DstOffset = DstY * DstW + DstX;

			SrcPointer = (Uint8*) src->pixels;
			DstPointer = (SDL_Color*) dst->pixels;

			SrcColor = SrcPointer[SrcOffset];

			if
			(
				(DstX >= 0) && (DstX < DstW) &&
				(DstY >= 0) && (DstY < DstH)
			)
			{

				//if (SrcColor != 0)
				{
					DstColor.r = SrcColor;
					DstColor.g = SrcColor;
					DstColor.b = SrcColor;

					DstPointer[DstOffset] = DstColor;
				}
			}
		}
	}

    SDL_UnlockSurface( dst );
	SDL_UnlockSurface( src );

	return 1;
}

void SpecialGradientTest( SDL_Surface *ParaSurface )
{
	int x, y;
	int w, h, p, b;
	int offset;
	SDL_Color color;
	SDL_Color *pointer;

	h = ParaSurface->h;
	w = ParaSurface->w;
	p = ParaSurface->pitch;
	b = ParaSurface->format->BytesPerPixel;
	pointer = (SDL_Color*)(ParaSurface->pixels);

	SDL_LockSurface( ParaSurface );

	for (y=0; y<h; y++)
	{
		for (x=0; x<w; x++)
		{
			offset = y * w + x;

			color.r = x & 255;
			color.b = y & 255;
			color.g = 0;

			pointer[offset] = color;

//			pointer = (SDL_Color *)ParaSurface->pixels + (y * ParaSurface->pitch + x * ParaSurface->format->BytesPerPixel);
//			*pointer = color;
		}
	}

    SDL_UnlockSurface( ParaSurface );
}
