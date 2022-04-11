#pragma once

namespace OpenXcom
{

struct VoxelPosition
{
	signed char X, Y, Z;
};

struct SpriteVoxelFrame
{
	VoxelPosition _VoxelPosition[40][32]; // [Y, X] 
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
