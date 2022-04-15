#pragma once

// ScreenRayBlock yeah cool name

#include "VoxelRay.h"

namespace OpenXcom
{ // open/associate OpenXcom namespace


struct ScreenRayBlock
{
	VoxelRay voxelRay[40][30];
};

class ScreenRayBlocks
{
	ScreenRayBlock *mRayBlock;

	int mScreenWidth;
	int mScreenHeight;

	int mBlocksHorizontal;
	int mBlocksVertical;

	void CreateArrays( void );
	void DestroyArrays( void );

	ScreenRayBlocks();
	~ScreenRayBlocks();

	void SetWidth( int ParaWidth );
	void SetHeight( int ParaHeight );

	void ComputeRayBlockDimensions();

	void ReSize( int ParaWidth, int ParaHeight );

	VoxelRay *getVoxelRay( int ParaBlockX, int ParaBlockY, int ParaBlockPixelX, int ParaBlockPixelY );
};



} // close/de-associate OpenXcom namespace
