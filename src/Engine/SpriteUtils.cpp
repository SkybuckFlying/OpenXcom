#include "SpriteUtils.h"

namespace OpenXcom
{

void ComputeSpriteCoordinate( int ParaVoxelX, int ParaVoxelY, int ParaVoxelZ, int *ParaSpriteX, int *ParaSpriteY )
{
	int SpriteStartX, SpriteStartY;
	int Component;
//	float Component;
	int SpriteX, SpriteY;

	// setup sprite start x, sprite start y
	SpriteStartX = 15; // tile width
	SpriteStartY = 24; // tile depth

	// calculate sprite x position based on voxel position (x,y,z)
	*ParaSpriteX = (SpriteStartX + ParaVoxelX) - ParaVoxelY;

	Component = ParaVoxelX + ParaVoxelY;
	Component = Component >> 1; // should this be a float ? is this causing imprecise graphics ? probably not maybe check it later
//				Component = Component / 2.0;

	*ParaSpriteY = (SpriteStartY + Component) - ParaVoxelZ;
}

}
