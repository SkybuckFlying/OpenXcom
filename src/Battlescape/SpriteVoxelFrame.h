#pragma once

#include "VoxelFramePosition.h"

namespace OpenXcom
{

struct SpriteVoxelFrame
{
	VoxelFramePosition _VoxelPosition[40][32]; // [Y, X] 
};

struct SpriteVoxelFrameComputed
{
	bool _Computed[40][32];
};

struct TileVoxelMap3D
{
	bool _Present[24][16][16]; // Z, Y, X
};

}
