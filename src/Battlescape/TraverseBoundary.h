#pragma once
#include "TraverseCell.h"

template <typename FPT>
struct TraverseBoundary
{
	FPT MinX, MinY, MinZ;
	FPT MaxX, MaxY, MaxZ;

	void Set( FPT ParaMinX, FPT ParaMinY, FPT ParaMinZ, FPT ParaMaxX, FPT ParaMaxY, FPT ParaMaxZ );

	void ScaleDown( const TraverseCell<FPT> ParaTraverseCell );
};

template <typename FPT>
void TraverseBoundary<FPT>::Set( FPT ParaMinX, FPT ParaMinY, FPT ParaMinZ, FPT ParaMaxX, FPT ParaMaxY, FPT ParaMaxZ )
{
	mMinX = ParaMinX;
	mMinY = ParaMinY;
	mMinZ = ParaMinZ;

	mMaxX = ParaMaxX;
	mMaxY = ParaMaxY;
	mMaxZ = ParaMaxZ;

}
template <typename FPT>
void TraverseBoundary<FPT>::ScaleDown( const TraverseCell<FPT> ParaTraverseCell )
{
	mMinX /= ParaTraverseCell.mWidth;
	mMinY /= ParaTraverseCell.mHeight;
	mMinZ /= ParaTraverseCell.mDepth;

	mMaxX /= ParaTraverseCell.mWidth;
	mMaxY /= ParaTraverseCell.mHeight;
	mMaxZ /= ParaTraverseCell.mDepth;
}


