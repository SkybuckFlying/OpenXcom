#pragma once

namespace OpenXcom
{

// converts (local/inside tile) voxel coordinate to sprite coordinate (inside surface)
void ComputeSpriteCoordinate( int ParaVoxelX, int ParaVoxelY, int ParaVoxelZ, int *ParaSpriteX, int *ParaSpriteY );

}
