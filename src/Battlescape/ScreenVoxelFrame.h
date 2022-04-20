#pragma once

// #include "VoxelFramePosition.h"
#include "..\Savegame\Tile.h"
#include "..\Engine\Surface.h"

namespace OpenXcom
{

struct ScreenVoxelPosition
{
	Sint16 X, Y, Z; // signed 16 bit, this will limit map voxel positions to -32k to +32k
};

class ScreenVoxelFrame
{
public:
//	Uint8 *mPixelColor;  // not being allocated currently, get it from a real surface as it's updated/drawn on, it will probably have better data.
	ScreenVoxelPosition *mVoxelPosition;

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
