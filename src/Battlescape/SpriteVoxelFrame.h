#pragma once

#include "VoxelFramePosition.h"

namespace OpenXcom
{

struct SpriteVoxelPosition
{
	signed char X, Y, Z; // signed 8 bit
};

struct SpriteVoxelFrame
{
	SpriteVoxelPosition _VoxelPosition[40][32]; // [Y, X] 
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
