#include "ScreenVoxelFrame.h"

namespace OpenXcom
{

ScreenVoxelFrame::ScreenVoxelFrame()
{
	mWidth = 0;
	mHeight = 0;

	// mPixelColor = 0;
	mVoxelPosition = 0;
}

ScreenVoxelFrame::~ScreenVoxelFrame()
{
//	if (mPixelColor !=0 ) delete[] mPixelColor;
	if (mVoxelPosition != 0 ) delete[] mVoxelPosition;
}

// Delphi whore crap style, fuck it
/*
void ScreenVoxelFrame::ReSize( int ParaWidth, int ParaHeight )
{
	int OldArea;
	int NewArea;

	OldArea = mWidth * mHeight;
	NewArea = ParaWidth * ParaHeight;

	if (NewArea != OldArea)
	{
//		if (mPixelColor != 0) delete[] mPixelColor;
		if (mVoxelPosition != 0)
		{
			delete[] mVoxelPosition;
			mVoxelPosition = 0;
		}

		if (NewArea > 0)
		{
//			mPixelColor = new Uint8[NewArea];
			mVoxelPosition = new VoxelPosition[NewArea];
		}
	}
}
*/

void ScreenVoxelFrame::ReSize( int ParaWidth, int ParaHeight )
{
	if (mVoxelPosition != 0)
	{
		delete[] mVoxelPosition;
		mVoxelPosition = 0;
	}

	if
	(
		(ParaWidth > 0) && (ParaHeight > 0)
	)
	{
		mVoxelPosition = new VoxelPosition[ParaWidth * ParaHeight];
		mWidth = ParaWidth;
		mHeight = ParaHeight;
	}
}

void ScreenVoxelFrame::SetWidth( int ParaWidth )
{
	if (ParaWidth != mWidth)
	{
		ReSize( ParaWidth, mHeight );
		mWidth = ParaWidth;
	}
}

void ScreenVoxelFrame::SetHeight( int ParaHeight )
{
	if (ParaHeight != mHeight)
	{
		ReSize( mWidth, ParaHeight );
		mHeight = ParaHeight;
	}
}


/*
void ScreenVoxelFrame::CollectSpriteVoxelFrame( int DstX, int DstY, Tile *ParaTile, Surface *ParaSprite )
{
	int vScreenPixelOffset;

	VoxelPosition vVoxelPosition;
	int SpriteX, SpriteY;

	Uint8 SpriteColor;

	vScreenPixelOffset = DstY * mWidth;
	for (SpriteY=0; SpriteY < 40; SpriteY++)
	{
		vScreenPixelOffset += DstX;
		for (SpriteX=0; SpriteX < 32; SpriteX++)
		{
			SpriteColor = ParaSprite->getPixel( SpriteX, SpriteY ); 

			if (SpriteColor != 0)
			{
				mPixelColor[vScreenPixelOffset] = SpriteColor;

				vVoxelPosition = ParaTile->getSpriteVoxelFrame()->_VoxelPosition[SpriteY][SpriteX];
				if (vVoxelPosition.Z >= 0)
				{
					mVoxelPosition[vScreenPixelOffset] = vVoxelPosition; 
				}

			}
			vScreenPixelOffset++;
		}
		vScreenPixelOffset += mWidth;
	}
}
*/

void ScreenVoxelFrame::Clear( void )
{
	VoxelPosition vVoxelPosition;
	int vIndex;

	vVoxelPosition.X = -1;
	vVoxelPosition.Y = -1;
	vVoxelPosition.Z = -1;
	for (vIndex=0; vIndex < (mWidth * mHeight); vIndex++)
	{
		mVoxelPosition[vIndex] = vVoxelPosition;
	}
}

void ScreenVoxelFrame::CollectSpriteVoxelFrame( int DstX, int DstY, Tile *ParaTile )
{
	int vScreenPixelOffset;

	VoxelPosition vVoxelPosition;
	int SpriteX, SpriteY;

	int vArea = mHeight * mWidth;

//	vScreenPixelOffset = DstY * mWidth;
	for (SpriteY=0; SpriteY < 40; SpriteY++)
	{
//		vScreenPixelOffset += DstX;
		for (SpriteX=0; SpriteX < 32; SpriteX++)
		{
//			int CheckMe = (DstY + SpriteY) * mWidth + (DstX + SpriteX);
			vScreenPixelOffset = (DstY + SpriteY) * mWidth + (DstX + SpriteX);

//			if (CheckMe != vScreenPixelOffset)
//			{
//				mVoxelPosition[vScreenPixelOffset].Z = 666; 
//			}

			if
			(
				(vScreenPixelOffset>=0) && (vScreenPixelOffset < vArea)
			)
			{
				vVoxelPosition = ParaTile->getSpriteVoxelFrame()->_VoxelPosition[SpriteY][SpriteX];
				if (vVoxelPosition.Z >= 0)
				{
					mVoxelPosition[vScreenPixelOffset] = vVoxelPosition; 
				}
			}
//			vScreenPixelOffset++;
		}
//		vScreenPixelOffset += mWidth; // formula incorrect probably needs subtact 32 maybe even subtract DstX
	}
}

}
