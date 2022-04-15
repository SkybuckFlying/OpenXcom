#include "ScreenRayBlocks.h"

namespace OpenXcom
{

ScreenRayBlocks::ScreenRayBlocks()
{
	mScreenWidth = 0;
	mScreenHeight = 0;

	// nullify array
	mRayBlock = 0;
}

ScreenRayBlocks::~ScreenRayBlocks()
{
	DestroyArrays();
}

void ScreenRayBlocks::CreateArrays( void )
{
	mRayBlock = new ScreenRayBlock[mBlocksHorizontal * mBlocksVertical];
}

void ScreenRayBlocks::DestroyArrays( void )
{
	// delete array
	if (mRayBlock != 0 )
	{
		delete[] mRayBlock;
		mRayBlock = 0; // nullify for re-usage/re-size !
	}
}

void ScreenRayBlocks::ComputeRayBlockDimensions()
{
	mBlocksHorizontal = mScreenWidth / 32; // / sprite width
	mBlocksVertical = mScreenHeight / 40; // / sprite height
}

void ScreenRayBlocks::ReSize( int ParaWidth, int ParaHeight )
{
	DestroyArrays();

	if
	(
		(ParaWidth > 0) && (ParaHeight > 0)
	)
	{
		ComputeRayBlockDimensions();
		CreateArrays();

		mScreenWidth = ParaWidth;
		mScreenHeight = ParaHeight;
	}
}

void ScreenRayBlocks::SetWidth( int ParaWidth )
{
	if (ParaWidth != mScreenWidth)
	{
		ReSize( ParaWidth, mScreenHeight );
		mScreenWidth = ParaWidth;
	}
}

void ScreenRayBlocks::SetHeight( int ParaHeight )
{
	if (ParaHeight != mScreenHeight)
	{
		ReSize( mScreenWidth, ParaHeight );
		mScreenHeight = ParaHeight;
	}
}

VoxelRay *ScreenRayBlocks::getVoxelRay( int ParaBlockX, int ParaBlockY, int ParaBlockPixelX, int ParaBlockPixelY )
{
	return &mRayBlock[ ParaBlockY * mBlocksHorizontal + ParaBlockX ].voxelRay[ParaBlockPixelY][ParaBlockPixelX];
}

}
