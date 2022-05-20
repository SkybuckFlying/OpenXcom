#pragma once

#include <SDL.h>
#include <string>


namespace OpenXcom
{

// --- VoxelData ---

struct VoxelData
{
	bool mPresent;
	Uint8 mPaletteIndex;
	std::string mMaterial;

	void Clear();
};

// --- VoxelGrid ---

// not good:
// typedef VoxelData VoxelGrid[24][16][16]; // already a pointer, so just pass it. kinda bad, doesn't allow nice method to be implemented

// better:
struct VoxelGrid
{
	VoxelData mEntry[24][16][16];

	void Clear();
};





}
