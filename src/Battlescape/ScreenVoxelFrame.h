#pragma once

#include "VoxelFramePosition.h"
#include "..\Savegame\Tile.h"
#include "..\Engine\Surface.h"

namespace OpenXcom
{

class ScreenVoxelFrame
{
public:
	Uint8 *mPixelColor;  
	VoxelFramePosition *mVoxelPosition;

	int mWidth;
	int mHeight;

	ScreenVoxelFrame();
	~ScreenVoxelFrame();

	void SetWidth( int ParaWidth );
	void SetHeight( int ParaHeight );

	void ReSize( int ParaWidth, int ParaHeight );

	void Clear( void );

//	void CollectSpriteVoxelFrame( int DstX, int DstY, Tile *ParaTile );
	void CollectSpriteVoxelFrame( int DstX, int DstY, Tile *ParaTile, Surface *ParaSprite );
};

}
