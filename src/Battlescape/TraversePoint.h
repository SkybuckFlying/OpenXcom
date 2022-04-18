#pragma once

template <typename FPT>
struct TraversePoint
{
	bool mExists = false;
	FPT mX, mY, mZ;

	void Set( FPT ParaX, FPT ParaY, FPT ParaZ );
};

template <typename FPT>
void TraversePoint<FPT>::Set( FPT ParaX, FPT ParaY, FPT ParaZ )
{
	mExists = true;
	mX = ParaX;
	mY = ParaY;
	mZ = ParaZ;
}
