#pragma once
#include <XYZ.h>
#include <TraverseDimension.h>

template <typename IT>
struct TraverseGrid
{
	TraverseDimension<XYZ<IT>> mDimension;
};

