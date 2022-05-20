#include "VoxelGrid.h"

// --- VoxelData ---

namespace OpenXcom
{

void VoxelData::Clear()
{
	mPresent = false;
	mPaletteIndex = 0;
	mMaterial = "";
}

// --- VoxelGrid ---

void VoxelGrid::Clear()
{
	int z,y,x;

	// clean em, just in case ?! ;) though I could do a direct compute but probably not hahahahahaha.
	for (z=0; z<24; z++)
	{
		for (y=0; y<16; y++)
		{
			for (x=0; x<16; x++)
			{
				mEntry[z][y][x].Clear();
			}
		}
	}
}

}
