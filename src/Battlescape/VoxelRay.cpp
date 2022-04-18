//
// VoxelRay.cpp
//
// VoxelRay design/header/implementation by Skybuck Flying
//
// version 0.01 created on 15 april 2022 by Skybuck Flying
// for any questions, comments, feedback, improvements: skybuck2000@hotmail.com
//

#include "VoxelRay.h"
#include <math.h>

namespace OpenXcom
{ // open/associate OpenXcom namespace

// macros for fast voxel traversal algoritm in code below
// original macros disabled, to not be reliant on macro language ! ;)
// #define SIGN(x) (x > 0 ? 1 : (x < 0 ? -1 : 0))
// #define FRAC0(x) (x - floorf(x))
// #define FRAC1(x) (1 - x + floorf(x))

// note: the floating point type below in these helper functions should match the floating point type in funtion below
//       for maximum accuracy and correctness, otherwise problems will occur !
float TraverseData::SignSingle( float x )
{
	return (x > 0 ? 1 : (x < 0 ? -1 : 0));
}

float TraverseData::Frac0Single( float x )
{
	return (x - floorf(x));
}

float TraverseData::Frac1Single( float x )
{
	return (1 - x + floorf(x));
}

float TraverseData::MaxSingle(float A, float B)
{
	if (A > B) return A; else return B;
}

float TraverseData::MinSingle(float A, float B)
{
	if (A < B) return A; else return B;
}

bool VoxelRay::PointInBoxSingle
(
	float X, float Y, float Z,
	float BoxX1, float BoxY1, float BoxZ1,
	float BoxX2, float BoxY2, float BoxZ2
)
{
	float MinX, MinY, MinZ;
	float MaxX, MaxY, MaxZ;

	bool result = false;

	if (BoxX1 < BoxX2)
	{
		MinX = BoxX1;
		MaxX = BoxX2;
	} else
	{
		MinX = BoxX2;
		MaxX = BoxX1;
	}

	if (BoxY1 < BoxY2)
	{
		MinY = BoxY1;
		MaxY = BoxY2;
	} else
	{
		MinY = BoxY2;
		MaxY = BoxY1;
	}

	if (BoxZ1 < BoxZ2)
	{
		MinZ = BoxZ1;
		MaxZ = BoxZ2;
	} else
	{
		MinZ = BoxZ2;
		MaxZ = BoxZ1;
	}

	if
	(
		(X >= MinX) && (Y >= MinY) && (Z >= MinZ) &&
		(X <= MaxX) && (Y <= MaxY) && (Z <= MaxZ)
	)
	{
		result = true;
	}
	return result;
}

/*
// code not needed for now.
void VoxelRay::ComputeVoxelPosition( float ParaStartX, float ParaStartY, float ParaStartZ, int ParaVoxelX, int ParaVoxelY, int ParaVoxelZ )
{
	// can also subtract boundary start/stop from it first if I really want too... hmmm... maybe I should...
	// and then also add voxel grid start to make it complete... lot's of unnecessary overhead but makes it more flexible
	// for other purposes, later can disable this and optimize for OpenXcom
	// I kinda like this idea.
	// maybe add these features later, keeping it simple for now.

//	*ParaVoxelX = ParaStartX / float VoxelCD.Width;
//	*ParaVoxelY = ParaStartY / float VoxelCD.Height;
//	*ParaVoxelZ = ParaStartY / float VoxelCD.Depth;

	// since voxel are just 1 in size don't need this for now.
	*ParaVoxelX = ParaStartX;
	*ParaVoxelY = ParaStartY;
	*ParaVoxelZ = ParaStartZ;
}
*/

// idea for later in the future perhaps, keeping it simple above for now
/*
// special for OpenXcom optimized computation
void VoxelRay::OptimizedComputeVoxelPosition( float ParaStartX, float ParaStartY, float ParaStartZ, int ParaVoxelX, int ParaVoxelY, int ParaVoxelZ )
{
	// can also subtract boundary start/stop from it first if I really want too... hmmm... maybe I should...
	// and then also add voxel grid start to make it complete... lot's of unnecessary overhead but makes it more flexible
	// for other purposes, later can disable this and optimize for OpenXcom
	// I kinda like this idea.
}
*/

float VoxelRay::Epsilon = 0.01;


bool VoxelRay::IsSinglePoint()
{
	if
	(	(Start.X == Stop.X) &&
		(Start.Y == Stop.Y) &&
		(Start.Z == Stop.Z)
	)
	{
		return true;
	}
	else
	{
		return false;
	}
}

bool VoxelRay::IsSinglePointInTileBoundary()
{
	// check if single point is inside the tile boundary in real/world/voxel coordinates (as stored in TileBD)
	return 
	(
		// alternative more precision solution
		PointInBoxSingle
		(
			Start.X, Start.Y, Start.Z,

			TileBD.MinX,
			TileBD.MinY,
			TileBD.MinZ,

			TileBD.MaxX,
			TileBD.MaxY,
			TileBD.MaxZ
		)
	);
}

void VoxelRay::ComputeVoxelStartPosition()
{
	VoxelTD.X = fmod( Start.X, TileCD.Width );
	VoxelTD.Y = fmod( Start.Y, TileCD.Height );
	VoxelTD.Z = fmod( Start.Z, TileCD.Depth );
}



bool VoxelRay::IsTileDirect()
{

	// maybe use Tile coordinates to check if tile coordinates are inside grid would be better ?!????
	// could use real/voxel world coordinates, but let's do tile coordinates.

	// if original ray is a single point then

	// real world/voxel coordinates
	if
	(	(Start.X == Stop.X) &&
		(Start.Y == Stop.Y) &&
		(Start.Z == Stop.Z)
	)

	{
		// check if single point is inside the tile boundary in real/world/voxel coordinates (as stored in TileBD)
		if
		(
			// alternative more precision solution
			PointInBoxSingle
			(
				Start.X, Start.Y, Start.Z,

				TileBD.MinX,
				TileBD.MinY,
				TileBD.MinZ,

				TileBD.MaxX,
				TileBD.MaxY,
				TileBD.MaxZ
			) == true
		)
		{
			// set traversal mode to tmDirect
			// could do a seperated tmTileDirect and tmVoxelDirect but for now I see no reason too
			// and it will just create an unnecessary branch and slow things down.
			traverseMode = TraverseMode::tmDirect; 

			// setup voxel coordinate for processing later.

			// compute voxel coordinate based on real voxel/world coordinate and divide it by tile width to get
			// depends on what kind of coordinates we want... for now... 0 to 15 would be the "easy" way... though
			// the "reusability way" to there could be other wise why entire voxel range is used to cover the map.
			// since input coordinates are in voxel space can leave it as is... however must mod it... to stay within
			// range 0..15 and 0..23, that would be best I think

			// little bit expensive to use these mods but for now I go with it for simple/consistent/correct/easy implementation
			// I could compute this differently as follows:
			// take fractional part of TileTD.x and multiply it by 16 and 24 and such but I worry that might become more inprecise.
			// so sticking with this for now, but be carefull that start coordinate does not lie outside the grid
			// but since code check below that it is within grid it should be fine, though there is a slight chance
			// that it might be slightly outside because of epsilon.
			// to prevent this from happening code check above should also use ParaStart.X
			// I don't like this... shitty...
			// I could multiple above code...
			// ok better solution implemented, hope it works and doesn't slow code down to much the comparison above it
			// will usually be not true anyway.

			// now restrict and keep the voxel coordinate inside the tile.
			// could also add tile coordinates and multiple but that is not how the game is currently working, not one big voxel map
			// but small little lofts/small voxel maps of 16x16x24 conceptually.


			// compute tile position

			// compute voxel position
			// nothing to compute for now (for simple openxcom grids and such.)
//			ComputeVoxelPosition( ParaStartX, ParaStartY, ParaStartZ, &VoxelTD.X, &VoxelTD.Y, &VoxelTD.Z ); 
//			VoxelTD.X = Start.X;
//			VoxelTD.Y = Start.Y;
//			VoxelTD.Z = Start.Z;

//			ModVoxelPositionToTileGrid

			// could use a boolean here
//			if ConfineVoxelSpace

			// do confine it to tile grid width, height, depth and such... 16x16x24 basically.
//			VoxelTD.X = Start.X % TileCD.Width;
//			VoxelTD.Y = Start.Y % TileCD.Height;
//			VoxelTD.Z = Start.Z % TileCD.Depth;

			VoxelTD.X = fmod( Start.X, TileCD.Width );
			VoxelTD.Y = fmod( Start.Y, TileCD.Height );
			VoxelTD.Z = fmod( Start.Z, TileCD.Depth );

			return true;
		}
	}

	return false;
}

// let's make a scale version of this for increased safety/numerical stability and correctness/association with scaled start/stop
// except when computing voxel, that uses unscaled start/stop, maybe should have moved that code of it...  so that
// these two different version are not necessary, maybe only the scaled version is necessary, though the other one is interesting
// in case we want to use a different approach and switch to a slightly different traverse algorithm later on that uses
// full world coordinates and lengths and distance and such instead of scaled down version.
// scaled down version will be a little bit more accurate though thanks to smaller floating point values and this is beneficial
// for 32 bit floating point format.
bool VoxelRay::IsTileDirectScaled()
{

	// maybe use Tile coordinates to check if tile coordinates are inside grid would be better ?!????
	// could use real/voxel world coordinates, but let's do tile coordinates.

	// if original ray is a single point then

	// real world/voxel coordinates
	if
	(	(TileStartScaled.X == TileStopScaled.X) &&
		(TileStartScaled.Y == TileStopScaled.Y) &&
		(TileStartScaled.Z == TileStopScaled.Z)
	)

	{
		// check if single point is inside the tile boundary in real/world/voxel coordinates (as stored in TileBD)
		// alternative more precision solution
		if
		(
			PointInBoxSingle
			(
				TileStartScaled.X, TileStartScaled.Y, TileStartScaled.Z,

				TileBDScaled.MinX,
				TileBDScaled.MinY,
				TileBDScaled.MinZ,

				TileBDScaled.MaxX,
				TileBDScaled.MaxY,
				TileBDScaled.MaxZ
			) == true
		)
		{
			// set traversal mode to tmDirect
			// could do a seperated tmTileDirect and tmVoxelDirect but for now I see no reason too
			// and it will just create an unnecessary branch and slow things down.
			traverseMode = TraverseMode::tmDirect; 

			// setup voxel coordinate for processing later.

			// compute voxel coordinate based on real voxel/world coordinate and divide it by tile width to get
			// depends on what kind of coordinates we want... for now... 0 to 15 would be the "easy" way... though
			// the "reusability way" to there could be other wise why entire voxel range is used to cover the map.
			// since input coordinates are in voxel space can leave it as is... however must mod it... to stay within
			// range 0..15 and 0..23, that would be best I think

			// little bit expensive to use these mods but for now I go with it for simple/consistent/correct/easy implementation
			// I could compute this differently as follows:
			// take fractional part of TileTD.x and multiply it by 16 and 24 and such but I worry that might become more inprecise.
			// so sticking with this for now, but be carefull that start coordinate does not lie outside the grid
			// but since code check below that it is within grid it should be fine, though there is a slight chance
			// that it might be slightly outside because of epsilon.
			// to prevent this from happening code check above should also use ParaStart.X
			// I don't like this... shitty...
			// I could multiple above code...
			// ok better solution implemented, hope it works and doesn't slow code down to much the comparison above it
			// will usually be not true anyway.

			// now restrict and keep the voxel coordinate inside the tile.
			// could also add tile coordinates and multiple but that is not how the game is currently working, not one big voxel map
			// but small little lofts/small voxel maps of 16x16x24 conceptually.


			// compute tile position

			// compute voxel position
			// nothing to compute for now (for simple openxcom grids and such.)
//			ComputeVoxelPosition( ParaStartX, ParaStartY, ParaStartZ, &VoxelTD.X, &VoxelTD.Y, &VoxelTD.Z ); 
//			VoxelTD.X = Start.X;
//			VoxelTD.Y = Start.Y;
//			VoxelTD.Z = Start.Z;

//			ModVoxelPositionToTileGrid

			// could use a boolean here
//			if ConfineVoxelSpace

			// do confine it to tile grid width, height, depth and such... 16x16x24 basically.
//			VoxelTD.X = Start.X % TileCD.Width;
//			VoxelTD.Y = Start.Y % TileCD.Height;
//			VoxelTD.Z = Start.Z % TileCD.Depth;

			VoxelTD.X = fmod( Start.X, TileCD.Width );
			VoxelTD.Y = fmod( Start.Y, TileCD.Height );
			VoxelTD.Z = fmod( Start.Z, TileCD.Depth );

			return true;
		}
	}

	return false;
}

bool VoxelRay::IsVoxelDirect()
{
	if
	(
		(VoxelTD.TraverseX1 == VoxelTD.TraverseX2) &&
		(VoxelTD.TraverseY1 == VoxelTD.TraverseY2) &&
		(VoxelTD.TraverseZ1 == VoxelTD.TraverseZ2)
	)
	{
		// check if single point is inside tile boundary could be setup per tile
		// not sure yet... may have to constrait to boundaries within a tile.
		// yeah
		if
		(
			PointInBoxSingle
			(
				VoxelTD.TraverseX1, TileTD.TraverseY1, TileTD.TraverseZ1,

				VoxelBD.MinX,
				VoxelBD.MinY,
				VoxelBD.MinZ,

				VoxelBD.MaxX-Epsilon,
				VoxelBD.MaxY-Epsilon,
				VoxelBD.MaxZ-Epsilon
			) == true
		)
		{
			// set traversal mode to tmDirect
			traverseMode = TraverseMode::tmDirect;

			// setup voxel coordinate for processing later.

			// most likely these voxel coordinates are not modded yet to stay within voxel range of a tile so let's also
			// apply mod here.
			// however these coordinates could be modified/clipped against the tile that they lie in... so must use
			// VoxelTD coordinates

//			VoxelTD.X = VoxelTD.TraverseX1 % 16;
//			VoxelTD.Y = VoxelTD.TraverseY1 % 16;
//			VoxelTD.Z = VoxelTD.TraverseZ1 % 24;

			VoxelTD.X = fmod( VoxelTD.TraverseX1, TileCD.Width );
			VoxelTD.Y = fmod( VoxelTD.TraverseY1, TileCD.Height );
			VoxelTD.Z = fmod( VoxelTD.TraverseZ1, TileCD.Depth );

			return true;
		}
	}

	return false;
}


bool VoxelRay::IsInsideTileBoundary()
{
	// check if both world points are in tile grid, but multiple boundary by tile size to get world voxel coordinates for good check.
	if
	(
		PointInBoxSingle
		(
			Start.X, Start.Y, Start.Z,
			TileBD.MinX, TileBD.MinY, TileBD.MinZ,
			TileBD.MaxX, TileBD.MaxY, TileBD.MaxZ
		)
		&&
		PointInBoxSingle
		(
			Stop.X, Stop.Y, Stop.Z,
			TileBD.MinX, TileBD.MinY, TileBD.MinZ,
			TileBD.MaxX, TileBD.MaxY, TileBD.MaxZ
		)
	)
	{
		return true;
	}
	return false;
}

// let's also make a scaled version of this, could even translate boundaries later and such but for now not gonna do it ;)
// I would recommend using more/different data structure for that though less caching but for debugging purposes might help
// then again maybe just use same data structure I will leave this up to you, for a potential future implementor ! ;) :)
// I know crazy comments ! ;) =D
bool VoxelRay::IsInsideTileBoundaryScaled()
{
	// check if both world points are in tile grid, scaled down version.
	if
	(
		PointInBoxSingle
		(
			TileStartScaled.X, TileStartScaled.Y, TileStartScaled.Z,
			TileBDScaled.MinX, TileBDScaled.MinY, TileBDScaled.MinZ,
			TileBDScaled.MaxX, TileBDScaled.MaxY, TileBDScaled.MaxZ
		)
		&&
		PointInBoxSingle
		(
			TileStopScaled.X, TileStopScaled.Y, TileStopScaled.Z,
			TileBDScaled.MinX, TileBDScaled.MinY, TileBDScaled.MinZ,
			TileBDScaled.MaxX, TileBDScaled.MaxY, TileBDScaled.MaxZ
		)
	)
	{
		return true;
	}
	return false;
}


bool VoxelRay::IsInsideVoxelBoundary()
{
	// check if both world points are in voxel boundary
	if
	(
		PointInBoxSingle
		(
//			VoxelTD.TraverseX1, VoxelTD.TraverseY1, VoxelTD.TraverseZ1,
			Start.X, Start.Y, Start.Z,
			VoxelBD.MinX, VoxelBD.MinY, VoxelBD.MinZ,
			VoxelBD.MaxX, VoxelBD.MaxY, VoxelBD.MaxZ
		)
		&&
		PointInBoxSingle
		(
//			VoxelTD.TraverseX2, VoxelTD.TraverseY2, VoxelTD.TraverseZ2,
			Stop.X, Stop.Y, Stop.Z,
			VoxelBD.MinX, VoxelBD.MinY, VoxelBD.MinZ,
			VoxelBD.MaxX, VoxelBD.MaxY, VoxelBD.MaxZ
		)
	)
	{
		return true;
	}
	return false;
}

// Skybuck: THIS CODE HAS TO BE RE-TESTED WHERE ONE OF THE INPUT PARAMETERS IS NEGATIVE, ESPECIALLY THE LINE
// PERHAPS TEST FOR NEGATIVE BOX COORDINATES AS WELL.
bool VoxelRay::LineSegmentIntersectsBoxSingle
(
	float LineX1, float LineY1, float LineZ1,
	float LineX2, float LineY2, float LineZ2,

	float BoxX1, float BoxY1, float BoxZ1,
	float BoxX2, float BoxY2, float BoxZ2,

	// nearest to line origin, doesn't necessarily mean closes to box...
	bool *MinIntersectionPoint,
	float *MinIntersectionPointX, float *MinIntersectionPointY, float *MinIntersectionPointZ,

	// farthest to line origin, doesn't necessarily mean farthest from box...
	bool *MaxIntersectionPoint,
	float *MaxIntersectionPointX, float *MaxIntersectionPointY, float *MaxIntersectionPointZ
)
{
	float LineDeltaX;
	float LineDeltaY;
	float LineDeltaZ;

	float LineDistanceToBoxX1;
	float LineDistanceToBoxX2;

	float LineDistanceToBoxY1;
	float LineDistanceToBoxY2;

	float LineDistanceToBoxZ1;
	float LineDistanceToBoxZ2;

	float LineMinDistanceToBoxX;
	float LineMaxDistanceToBoxX;

	float LineMinDistanceToBoxY;
	float LineMaxDistanceToBoxY;

	float LineMinDistanceToBoxZ;
	float LineMaxDistanceToBoxZ;

	float LineMaxMinDistanceToBox;
	float LineMinMaxDistanceToBox;

	float LineMinDistanceToBox;
	float LineMaxDistanceToBox;

	bool result = false;
	*MinIntersectionPoint = false;
	*MaxIntersectionPoint = false;

	LineDeltaX = LineX2 - LineX1;
	LineDeltaY = LineY2 - LineY1;
	LineDeltaZ = LineZ2 - LineZ1;

	// T (distance along line) calculations which will be used to figure out Tmins and Tmaxs:
	// t = (LocationX - x0) / (DeltaX)
	if (LineDeltaX != 0)
	{
		LineDistanceToBoxX1 = (BoxX1 - LineX1) / LineDeltaX;
		LineDistanceToBoxX2 = (BoxX2 - LineX1) / LineDeltaX;
	} else
	{
		LineDistanceToBoxX1 = (BoxX1 - LineX1);
		LineDistanceToBoxX2 = (BoxX2 - LineX1);
	}

	// now we take the minimum's and maximum's
	if (LineDistanceToBoxX1 < LineDistanceToBoxX2)
	{
		LineMinDistanceToBoxX = LineDistanceToBoxX1;
		LineMaxDistanceToBoxX = LineDistanceToBoxX2;
	} else
	{
		LineMinDistanceToBoxX = LineDistanceToBoxX2;
		LineMaxDistanceToBoxX = LineDistanceToBoxX1;
	}

	if (LineDeltaY != 0)
	{
		LineDistanceToBoxY1 = (BoxY1 - LineY1) / LineDeltaY;
		LineDistanceToBoxY2 = (BoxY2 - LineY1) / LineDeltaY;
	} else
	{
		LineDistanceToBoxY1 = BoxY1 - LineY1;
		LineDistanceToBoxY2 = BoxY2 - LineY1;
	}

	if (LineDistanceToBoxY1 < LineDistanceToBoxY2)
	{
		LineMinDistanceToBoxY = LineDistanceToBoxY1;
		LineMaxDistanceToBoxY = LineDistanceToBoxY2;
	} else
	{
		LineMinDistanceToBoxY = LineDistanceToBoxY2;
		LineMaxDistanceToBoxY = LineDistanceToBoxY1;
	}

	if (LineDeltaZ != 0)
	{
		LineDistanceToBoxZ1 = (BoxZ1 - LineZ1) / LineDeltaZ;
		LineDistanceToBoxZ2 = (BoxZ2 - LineZ1) / LineDeltaZ;
	} else
	{
		LineDistanceToBoxZ1 = (BoxZ1 - LineZ1);
		LineDistanceToBoxZ2 = (BoxZ2 - LineZ1);
	}

	if (LineDistanceToBoxZ1 < LineDistanceToBoxZ2)
	{
		LineMinDistanceToBoxZ = LineDistanceToBoxZ1;
		LineMaxDistanceToBoxZ = LineDistanceToBoxZ2;
	} else
	{
		LineMinDistanceToBoxZ = LineDistanceToBoxZ2;
		LineMaxDistanceToBoxZ = LineDistanceToBoxZ1;
	}

	// these 6 distances all represent distances on a line.
	// we want to clip this line to the box.
	// so the } points of the line which are outside the box need to be clipped.
	// so we clipping the line to the box.
	// this means we are interested in the most minimum minimum
	// and the most maximum, maximum.
	// these min's and max's represent the outer intersections.
	// if for whatever reason the minimum is larger than the maximum
	// then the line misses the box ! ;)
	// nooooooooooooooooooooooooooooooooo
	// we want the maximum of the minimums
	// and we want the minimum of the maximums
	// that should give us the bounding intersections ! ;)


	// find the maximum minimum
	LineMaxMinDistanceToBox = LineMinDistanceToBoxX;

	if (LineMinDistanceToBoxY > LineMaxMinDistanceToBox)
	{
		LineMaxMinDistanceToBox = LineMinDistanceToBoxY;
	}

	if (LineMinDistanceToBoxZ > LineMaxMinDistanceToBox)
	{
		LineMaxMinDistanceToBox = LineMinDistanceToBoxZ;
	}

	// find the minimum maximum
	LineMinMaxDistanceToBox = LineMaxDistanceToBoxX;

	if (LineMaxDistanceToBoxY < LineMinMaxDistanceToBox)
	{
		LineMinMaxDistanceToBox = LineMaxDistanceToBoxY;
	}

	if (LineMaxDistanceToBoxZ < LineMinMaxDistanceToBox)
	{
		LineMinMaxDistanceToBox = LineMaxDistanceToBoxZ;
	}

	// these two points are now the minimum and maximum distance to box
	LineMinDistanceToBox = LineMaxMinDistanceToBox;
	LineMaxDistanceToBox = LineMinMaxDistanceToBox;

	// now check if the max distance is smaller than the minimum distance
	// if so then the line segment does not intersect the box.
	if (LineMaxDistanceToBox < LineMinDistanceToBox)
	{
		return result;
	}

	// if distances are within the line then there is an intersection
	// Skybuck: dangerous change but I am going to do it, untested
	// this will make code more consistent with point inside box though, otherwise it might come to different conclusions
	// and this would create logical problems in the setup routine, I fear that doing this might cause stepping outside
	// of grid but maybe not, re-test this in delphi later on.
//	if ( (LineMinDistanceToBox > 0) && (LineMinDistanceToBox < 1) )
	// Skybuck: Tested in Delphi and seems safe for now:
	if ( (LineMinDistanceToBox >= 0) && (LineMinDistanceToBox <= 1) )
	{
		// else the min and max are the intersection points so calculate
		// those using the parametric equation and return true.
		// x = x0 + t(x1 - x0)
		// y = y0 + t(y1 - y0)
		// z = z0 + t(z1 - z0)

		*MinIntersectionPoint = true;
		*MinIntersectionPointX = LineX1 + LineMinDistanceToBox * LineDeltaX;
		*MinIntersectionPointY = LineY1 + LineMinDistanceToBox * LineDeltaY;
		*MinIntersectionPointZ = LineZ1 + LineMinDistanceToBox * LineDeltaZ;

		result = true;
	}

	// Skybuck: Dangerous change:
	// but this will make code more consistent with point inside box routine above somewhere and also come to same
	// logical conclusions inside setup routine below.
//	if ( (LineMaxDistanceToBox > 0) && (LineMaxDistanceToBox < 1) )
	// Skybuck: Tested in Delphi and seems safe for now:
	if ( (LineMaxDistanceToBox >= 0) && (LineMaxDistanceToBox <= 1) )
	{
		*MaxIntersectionPoint = true;
		*MaxIntersectionPointX = LineX1 + LineMaxDistanceToBox * LineDeltaX;
		*MaxIntersectionPointY = LineY1 + LineMaxDistanceToBox * LineDeltaY;
		*MaxIntersectionPointZ = LineZ1 + LineMaxDistanceToBox * LineDeltaZ;

		result = true;
	}

	return result;
}

bool VoxelRay::IsIntersectingTileBoundary()
{
	bool IntersectionPoint1;
	bool IntersectionPoint2;

	float IntersectionPointX1, IntersectionPointY1, IntersectionPointZ1;
	float IntersectionPointX2, IntersectionPointY2, IntersectionPointZ2;

	// check if line intersects box
	if
	(
		LineSegmentIntersectsBoxSingle
		(
			Start.X, Start.Y, Start.Z,
			Stop.X, Stop.Y, Stop.Z,

			TileBD.MinX, TileBD.MinY, TileBD.MinZ,
			TileBD.MaxY, TileBD.MaxY, TileBD.MaxZ,

			&IntersectionPoint1,
			&IntersectionPointX1,
			&IntersectionPointY1,
			&IntersectionPointZ1,

			&IntersectionPoint2,
			&IntersectionPointX2,
			&IntersectionPointY2,
			&IntersectionPointZ2
		) == true
	)
	{
		if (IntersectionPoint1 == true)
		{
			TileTD.TraverseX1 = IntersectionPointX1;
			TileTD.TraverseY1 = IntersectionPointY1;
			TileTD.TraverseZ1 = IntersectionPointZ1;
		}
		else
		{
			TileTD.TraverseX1 = Start.X;
			TileTD.TraverseY1 = Start.Y;
			TileTD.TraverseZ1 = Start.Z;
		}

		// compensate for any floating point errors (inaccuracies)
		TileTD.TraverseX1 = TraverseData::MaxSingle( TileTD.TraverseX1, TileBD.MinX );
		TileTD.TraverseY1 = TraverseData::MaxSingle( TileTD.TraverseY1, TileBD.MinY );
		TileTD.TraverseZ1 = TraverseData::MaxSingle( TileTD.TraverseZ1, TileBD.MinZ );

		TileTD.TraverseX1 = TraverseData::MinSingle( TileTD.TraverseX1, TileBD.MaxX );
		TileTD.TraverseY1 = TraverseData::MinSingle( TileTD.TraverseY1, TileBD.MaxY );
		TileTD.TraverseZ1 = TraverseData::MinSingle( TileTD.TraverseZ1, TileBD.MaxZ );

		if (IntersectionPoint2 == true)
		{
			TileTD.TraverseX2 = IntersectionPointX2;
			TileTD.TraverseY2 = IntersectionPointY2;
			TileTD.TraverseZ2 = IntersectionPointZ2;
		}
		else
		{
			TileTD.TraverseX2 = Stop.X;
			TileTD.TraverseY2 = Stop.Y;
			TileTD.TraverseZ2 = Stop.Z;
		}

		// compensate for any floating point errors (inaccuracies)
		TileTD.TraverseX2 = TraverseData::MaxSingle( TileTD.TraverseX2, TileBD.MinX );
		TileTD.TraverseY2 = TraverseData::MaxSingle( TileTD.TraverseY2, TileBD.MinY );
		TileTD.TraverseZ2 = TraverseData::MaxSingle( TileTD.TraverseZ2, TileBD.MinZ );

		TileTD.TraverseX2 = TraverseData::MinSingle( TileTD.TraverseX2, TileBD.MaxX );
		TileTD.TraverseY2 = TraverseData::MinSingle( TileTD.TraverseY2, TileBD.MaxY );
		TileTD.TraverseZ2 = TraverseData::MinSingle( TileTD.TraverseZ2, TileBD.MaxZ );

		// it is possible that after intersection testing the line is just a dot
		// on the intersection box so check for this and then process voxel
		// seperately.
		if
		(
			(TileTD.TraverseX1==TileTD.TraverseX2) &&
			(TileTD.TraverseY1==TileTD.TraverseY2) &&
			(TileTD.TraverseZ1==TileTD.TraverseZ2)
		)
		{
			// setup traverse mode direct
			traverseMode = TraverseMode::tmDirect;

			// process voxel

			// keep it within tile grid boundaries
//			VoxelX = TileTD.TraverseX1 % TileCD.Width; 
//			VoxelY = TileTD.TraverseY1 % TileCD.Height; 
//			VoxelZ = TileTD.TraverseZ1 % TileCD.Depth;

			VoxelTD.X = fmod( TileTD.TraverseX1, TileCD.Width ); 
			VoxelTD.Y = fmod( TileTD.TraverseY1, TileCD.Height ); 
			VoxelTD.Z = fmod( TileTD.TraverseZ1, TileCD.Depth );

			return false;
		}
		return true;
	}
	return false;
}

// I apply scaling down to 0..1 for ray coordinates, but also boundary coordinates, I think that is correct and it should be.
// however this is creating problems with code further down below to constrain it so I will stored these scaled down coordinates
// in some special data structure or so. YEAH !
bool VoxelRay::IsIntersectingTileBoundaryScaled()
{
	bool IntersectionPoint1;
	bool IntersectionPoint2;

	float IntersectionPointX1, IntersectionPointY1, IntersectionPointZ1;
	float IntersectionPointX2, IntersectionPointY2, IntersectionPointZ2;

	// check if line intersects box
	if
	(
		LineSegmentIntersectsBoxSingle
		(
			TileStartScaled.X, TileStartScaled.Y, TileStartScaled.Z,
			TileStopScaled.X, TileStopScaled.Y, TileStopScaled.Z,

			TileBDScaled.MinX, TileBDScaled.MinY, TileBDScaled.MinZ,
			TileBDScaled.MaxY, TileBDScaled.MaxY, TileBDScaled.MaxZ,

			&IntersectionPoint1,
			&IntersectionPointX1,
			&IntersectionPointY1,
			&IntersectionPointZ1,

			&IntersectionPoint2,
			&IntersectionPointX2,
			&IntersectionPointY2,
			&IntersectionPointZ2
		) == true
	)
	{
		if (IntersectionPoint1 == true)
		{
			TileTD.TraverseX1 = IntersectionPointX1;
			TileTD.TraverseY1 = IntersectionPointY1;
			TileTD.TraverseZ1 = IntersectionPointZ1;
		}
		else
		{
			TileTD.TraverseX1 = Start.X;
			TileTD.TraverseY1 = Start.Y;
			TileTD.TraverseZ1 = Start.Z;
		}

		// compensate for any floating point errors (inaccuracies)
		TileTD.TraverseX1 = TraverseData::MaxSingle( TileTD.TraverseX1, TileBDScaled.MinX );
		TileTD.TraverseY1 = TraverseData::MaxSingle( TileTD.TraverseY1, TileBDScaled.MinY );
		TileTD.TraverseZ1 = TraverseData::MaxSingle( TileTD.TraverseZ1, TileBDScaled.MinZ );

		TileTD.TraverseX1 = TraverseData::MinSingle( TileTD.TraverseX1, TileBDScaled.MaxX );
		TileTD.TraverseY1 = TraverseData::MinSingle( TileTD.TraverseY1, TileBDScaled.MaxY );
		TileTD.TraverseZ1 = TraverseData::MinSingle( TileTD.TraverseZ1, TileBDScaled.MaxZ );

		if (IntersectionPoint2 == true)
		{
			TileTD.TraverseX2 = IntersectionPointX2;
			TileTD.TraverseY2 = IntersectionPointY2;
			TileTD.TraverseZ2 = IntersectionPointZ2;
		}
		else
		{
			TileTD.TraverseX2 = Stop.X;
			TileTD.TraverseY2 = Stop.Y;
			TileTD.TraverseZ2 = Stop.Z;
		}

		// compensate for any floating point errors (inaccuracies)
		TileTD.TraverseX2 = TraverseData::MaxSingle( TileTD.TraverseX2, TileBDScaled.MinX );
		TileTD.TraverseY2 = TraverseData::MaxSingle( TileTD.TraverseY2, TileBDScaled.MinY );
		TileTD.TraverseZ2 = TraverseData::MaxSingle( TileTD.TraverseZ2, TileBDScaled.MinZ );

		TileTD.TraverseX2 = TraverseData::MinSingle( TileTD.TraverseX2, TileBDScaled.MaxX );
		TileTD.TraverseY2 = TraverseData::MinSingle( TileTD.TraverseY2, TileBDScaled.MaxY );
		TileTD.TraverseZ2 = TraverseData::MinSingle( TileTD.TraverseZ2, TileBDScaled.MaxZ );

		// it is possible that after intersection testing the line is just a dot
		// on the intersection box so check for this and then process voxel
		// seperately.
		if
		(
			(TileTD.TraverseX1==TileTD.TraverseX2) &&
			(TileTD.TraverseY1==TileTD.TraverseY2) &&
			(TileTD.TraverseZ1==TileTD.TraverseZ2)
		)
		{
			// setup traverse mode direct
			traverseMode = TraverseMode::tmDirect;

			// process voxel

			// keep it within tile grid boundaries
//			VoxelTD.X = TileTD.TraverseX1 % TileCD.Width; 
//			VoxelTD.Y = TileTD.TraverseY1 % TileCD.Height; 
//			VoxelTD.Z = TileTD.TraverseZ1 % TileCD.Depth;

			VoxelTD.X = fmod( TileTD.TraverseX1, TileCD.Width ); 
			VoxelTD.Y = fmod( TileTD.TraverseY1, TileCD.Height ); 
			VoxelTD.Z = fmod( TileTD.TraverseZ1, TileCD.Depth );

			return false;
		}
		return true;
	}
	return false;
}


// now we can very easily intersect a voxel boundary if we set it up in 'world voxel coordinates'
// this can be used in case our algorithm is not yet optimized/merge together with Ts and what not
// and most likely at least two dimensional will be "off" from their walls/boundaries/dimension lines and may have to be
// 'intercepted', no intercept code yet for that, there are also other solutions possible... like calculating and then
// stepping the ammount of voxels every time a tile steps, but for now we going to compute the traverse points
// when entering a "voxel boundary" this is accurate, safe and numerically stable thanks to code below.
bool VoxelRay::IsIntersectingVoxelBoundary()
{
	bool IntersectionPoint1;
	bool IntersectionPoint2;

	float IntersectionPointX1, IntersectionPointY1, IntersectionPointZ1;
	float IntersectionPointX2, IntersectionPointY2, IntersectionPointZ2;

	// check if line intersects box
	if
	(
		LineSegmentIntersectsBoxSingle
		(
			Start.X, Start.Y, Start.Z,
			Stop.X, Stop.Y, Stop.Z,

			VoxelBD.MinX, VoxelBD.MinY, VoxelBD.MinZ,
			VoxelBD.MaxY, VoxelBD.MaxY, VoxelBD.MaxZ,

			&IntersectionPoint1,
			&IntersectionPointX1,
			&IntersectionPointY1,
			&IntersectionPointZ1,

			&IntersectionPoint2,
			&IntersectionPointX2,
			&IntersectionPointY2,
			&IntersectionPointZ2
		) == true
	)
	{
		if (IntersectionPoint1 == true)
		{
			VoxelTD.TraverseX1 = IntersectionPointX1;
			VoxelTD.TraverseY1 = IntersectionPointY1;
			VoxelTD.TraverseZ1 = IntersectionPointZ1;
		}
		else
		{
			VoxelTD.TraverseX1 = Start.X;
			VoxelTD.TraverseY1 = Start.Y;
			VoxelTD.TraverseZ1 = Start.Z;
		}

		// compensate for any floating point errors (inaccuracies)
		VoxelTD.TraverseX1 = TraverseData::MaxSingle( VoxelTD.TraverseX1, VoxelBD.MinX );
		VoxelTD.TraverseY1 = TraverseData::MaxSingle( VoxelTD.TraverseY1, VoxelBD.MinY );
		VoxelTD.TraverseZ1 = TraverseData::MaxSingle( VoxelTD.TraverseZ1, VoxelBD.MinZ );

		VoxelTD.TraverseX1 = TraverseData::MinSingle( VoxelTD.TraverseX1, VoxelBD.MaxX );
		VoxelTD.TraverseY1 = TraverseData::MinSingle( VoxelTD.TraverseY1, VoxelBD.MaxY );
		VoxelTD.TraverseZ1 = TraverseData::MinSingle( VoxelTD.TraverseZ1, VoxelBD.MaxZ );

		if (IntersectionPoint2 == true)
		{
			VoxelTD.TraverseX2 = IntersectionPointX2;
			VoxelTD.TraverseY2 = IntersectionPointY2;
			VoxelTD.TraverseZ2 = IntersectionPointZ2;
		}
		else
		{
			VoxelTD.TraverseX2 = Stop.X;
			VoxelTD.TraverseY2 = Stop.Y;
			VoxelTD.TraverseZ2 = Stop.Z;
		}

		// compensate for any floating point errors (inaccuracies)
		VoxelTD.TraverseX2 = TraverseData::MaxSingle( VoxelTD.TraverseX2, VoxelBD.MinX );
		VoxelTD.TraverseY2 = TraverseData::MaxSingle( VoxelTD.TraverseY2, VoxelBD.MinY );
		VoxelTD.TraverseZ2 = TraverseData::MaxSingle( VoxelTD.TraverseZ2, VoxelBD.MinZ );

		VoxelTD.TraverseX2 = TraverseData::MinSingle( VoxelTD.TraverseX2, VoxelBD.MaxX );
		VoxelTD.TraverseY2 = TraverseData::MinSingle( VoxelTD.TraverseY2, VoxelBD.MaxY );
		VoxelTD.TraverseZ2 = TraverseData::MinSingle( VoxelTD.TraverseZ2, VoxelBD.MaxZ );

		// it is possible that after intersection testing the line is just a dot
		// on the intersection box so check for this and then process voxel
		// seperately.
		if
		(
			(VoxelTD.TraverseX1==VoxelTD.TraverseX2) &&
			(VoxelTD.TraverseY1==VoxelTD.TraverseY2) &&
			(VoxelTD.TraverseZ1==VoxelTD.TraverseZ2)
		)
		{
			// setup traverse mode direct
			traverseMode = TraverseMode::tmDirect;

			// process voxel

			// keep it within tile grid boundaries
//			VoxelTD.X = VoxelTD.TraverseX1 % TileCD.Width; 
//			VoxelTD.Y = VoxelTD.TraverseY1 % TileCD.Height; 
//			VoxelTD.Z = VoxelTD.TraverseZ1 % TileCD.Depth;

			VoxelTD.X = fmod( VoxelTD.TraverseX1, TileCD.Width ); 
			VoxelTD.Y = fmod( VoxelTD.TraverseY1, TileCD.Height ); 
			VoxelTD.Z = fmod( VoxelTD.TraverseZ1, TileCD.Depth );

			return false;
		}
		return true;
	}
	return false;
}

void VoxelRay::SetupTileDimensions( int ParaTileWidth, int ParaTileHeight, int ParaTileDepth )
{
	TileCD.Width = ParaTileWidth;
	TileCD.Height = ParaTileHeight;
	TileCD.Depth = ParaTileDepth;
}

void VoxelRay::SetupVoxelDimensions( int ParaVoxelWidth, int ParaVoxelHeight, int ParaVoxelDepth )
{
	VoxelCD.Width = ParaVoxelWidth;
	VoxelCD.Height = ParaVoxelHeight;
	VoxelCD.Depth = ParaVoxelDepth;
}

// in grid index coordates, much cooler. can start at a different offset min basically.
void VoxelRay::SetupGridData( int ParaMinX, int ParaMinY, int ParaMinZ, int ParaMaxX, int ParaMaxY, int ParaMaxZ )
{
	TileGD.MinX = ParaMinX;
	TileGD.MinY = ParaMinY;
	TileGD.MinZ = ParaMinZ;

	TileGD.MaxX = ParaMaxX; 
	TileGD.MaxY = ParaMaxY;
	TileGD.MaxZ = ParaMaxZ;
}

// in some kind of world/voxel coordinates or so...
void VoxelRay::SetupTileBoundary( float ParaMinX, float ParaMinY, float ParaMinZ, float ParaMaxX, float ParaMaxY, float ParaMaxZ )
{
	TileBD.MinX = ParaMinX;
	TileBD.MinY = ParaMinY;
	TileBD.MinZ = ParaMinZ;

	TileBD.MaxX = ParaMaxX;
	TileBD.MaxY = ParaMaxY;
	TileBD.MaxZ = ParaMaxZ;
}

// computes tile boundary based on grid data, this can be used as an alternative to setup tile boundary
void VoxelRay::ComputeTileBoundary()
{
	TileBD.MinX = TileGD.MinX * TileCD.Width;
	TileBD.MinY = TileGD.MinY * TileCD.Height;
	TileBD.MinZ = TileGD.MinZ * TileCD.Depth;

	TileBD.MaxX = ((TileGD.MaxX+1) * TileCD.Width) - Epsilon;
	TileBD.MaxY = ((TileGD.MaxY+1) * TileCD.Height) - Epsilon;
	TileBD.MaxZ = ((TileGD.MaxZ+1) * TileCD.Depth) - Epsilon;
}

void VoxelRay::ComputeTileBoundaryScaled()
{
	// TileBDScaled = TileBD / TileCD; is same as TileGD for now, plus little epislon correct for numerical stability.
	TileBDScaled.MinX = TileGD.MinX;
	TileBDScaled.MinY = TileGD.MinY;
	TileBDScaled.MinZ = TileGD.MinZ;

	TileBDScaled.MaxX = (TileGD.MaxX+1) - Epsilon;
	TileBDScaled.MaxY = (TileGD.MaxY+1) - Epsilon;
	TileBDScaled.MaxZ = (TileGD.MaxZ+1) - Epsilon;
}

void VoxelRay::ComputeTileStartScaled()
{
	// force floating point division, must also make sure that the left side is a float
	TileStartScaled.X = Start.X / (float)(TileCD.Width);
	TileStartScaled.Y = Start.Y / (float)(TileCD.Height);
	TileStartScaled.Z = Start.Z / (float)(TileCD.Depth);
}

void VoxelRay::ComputeTileStopScaled()
{
	// force floating point division, must also make sure that the left side is a float
	TileStopScaled.X = Stop.X / (float)(TileCD.Width);
	TileStopScaled.Y = Stop.Y / (float)(TileCD.Height);
	TileStopScaled.Z = Stop.Z / (float)(TileCD.Depth);
}

// old version
/*
void VoxelRay.ComputeVoxelBoundary( int ParaTileX, int ParaTileY, int ParatileZ )
{
	// calculation depends on if we zero-offset the voxel from tile x,y or not
	// could build in a branch here but for now... zero-offset it.

	// if zero-offset, and no tile based offsts
	VoxelBD.MinX = 0;
	VoxelBD.MinY = 0;
	VoxelBD.MinZ = 0;

	// just using tile width, height, depth for now, to create a voxel boundary plus little bit of epsilon subtract to
	// combat floating point inaccuraries and to keep coorindates/calculations inside.
	VoxelBD.MaxX = TileCD.Width - Epsilon;
	VoxelBD.MaxY = TileCD.Height - Epsilon;
	VoxelBD.MaxZ = TileCD.Depth - Epsilon;


	// if not zero-offset, and tile based offsets
	// could also do something with VoxelGD and such to offset it even further
//	VoxelBD.MinX = ParaTileX * TileCD.Width;
//	VoxelBD.MinY = ParaTileY * TileCD.Height;
//	VoxelBD.MinZ = ParaTileZ * TileCD.Depth;

//	VoxelBD.MaxX = (VoxelBD.MinX + TileCD.Width) - Epsilon;
//	VoxelBD.MaxY = (VoxelBD.MinY + TileCD.Height) - Epsilon;
//	VoxelBD.MaxZ = (VoxelBD.MinZ + TileCD.Depth) - Epsilon;


}
*/

// new version
// we are going to compute a voxel boundary in voxel/world space so that later a line can be clipped/intersected against it
// so that it can return nice traversal coordinates and make sure everything is nice and stable.
void VoxelRay::ComputeVoxelBoundary( int ParaTileX, int ParaTileY, int ParaTileZ )
{
	// if not zero-offset, and tile based offsets
	// could also do something with VoxelGD and such to offset it even further
	VoxelBD.MinX = ParaTileX * TileCD.Width;
	VoxelBD.MinY = ParaTileY * TileCD.Height;
	VoxelBD.MinZ = ParaTileZ * TileCD.Depth;

	VoxelBD.MaxX = (VoxelBD.MinX + TileCD.Width) - Epsilon;
	VoxelBD.MaxY = (VoxelBD.MinY + TileCD.Height) - Epsilon;
	VoxelBD.MaxZ = (VoxelBD.MinZ + TileCD.Depth) - Epsilon;
}

void VoxelRay::SetupTileTraversal()
{
	// traverse code, fast voxel traversal algorithm
	TileTD.dx = TraverseData::SignSingle(TileTD.TraverseX2 - TileTD.TraverseX1);
	if (TileTD.dx != 0) TileTD.tDeltaX = fmin(TileTD.dx / (TileTD.TraverseX2 - TileTD.TraverseX1), 10000000.0f); else TileTD.tDeltaX = 10000000.0f;
	if (TileTD.dx > 0) TileTD.tMaxX = TileTD.tDeltaX * TraverseData::Frac1Single(TileTD.TraverseX1); else TileTD.tMaxX = TileTD.tDeltaX * TraverseData::Frac0Single(TileTD.TraverseX1);
	TileTD.X = (int) TileTD.TraverseX1;

	TileTD.dy = TraverseData::SignSingle(TileTD.TraverseY2 - TileTD.TraverseY1);
	if (TileTD.dy != 0) TileTD.tDeltaY = fmin(TileTD.dy / (TileTD.TraverseY2 - TileTD.TraverseY1), 10000000.0f); else TileTD.tDeltaY = 10000000.0f;
	if (TileTD.dy > 0) TileTD.tMaxY = TileTD.tDeltaY * TraverseData::Frac1Single(TileTD.TraverseY1); else TileTD.tMaxY = TileTD.tDeltaY * TraverseData::Frac0Single(TileTD.TraverseY1);
	TileTD.Y = (int) TileTD.TraverseY1;

	TileTD.dz = TraverseData::SignSingle(TileTD.TraverseZ2 - TileTD.TraverseZ1);
	if (TileTD.dz != 0) TileTD.tDeltaZ = fmin(TileTD.dz / (TileTD.TraverseZ2 - TileTD.TraverseZ1), 10000000.0f); else TileTD.tDeltaZ = 10000000.0f;
	if (TileTD.dz > 0) TileTD.tMaxZ = TileTD.tDeltaZ * TraverseData::Frac1Single(TileTD.TraverseZ1); else TileTD.tMaxZ = TileTD.tDeltaZ * TraverseData::Frac0Single(TileTD.TraverseZ1);
	TileTD.Z = (int) TileTD.TraverseZ1;

	if (TileTD.dx > 0) TileTD.OutX = TileGD.MaxX+1; else TileTD.OutX = TileGD.MinX-1;
	if (TileTD.dy > 0) TileTD.OutY = TileGD.MaxY+1; else TileTD.OutY = TileGD.MinY-1;
	if (TileTD.dz > 0) TileTD.OutZ = TileGD.MaxZ+1; else TileTD.OutZ = TileGD.MinZ-1;

	TileTD.T = 0;
	TileTD.TraverseDone = false;
}

void VoxelRay::SetupVoxelBoundary( float ParaMinX, float ParaMinY, float ParaMinZ, float ParaMaxX, float ParaMaxY, float ParaMaxZ )
{
	VoxelBD.MinX = ParaMinX;
	VoxelBD.MinY = ParaMinY;
	VoxelBD.MinZ = ParaMinZ;

	VoxelBD.MaxX = ParaMaxX;
	VoxelBD.MaxY = ParaMaxY;
	VoxelBD.MaxZ = ParaMaxZ;
}

void VoxelRay::SetupVoxelTraversal()
{
	// traverse code, fast voxel traversal algorithm
	VoxelTD.dx = TraverseData::SignSingle(VoxelTD.TraverseX2 - VoxelTD.TraverseX1);
	if (VoxelTD.dx != 0) VoxelTD.tDeltaX = fmin(VoxelTD.dx / (VoxelTD.TraverseX2 - VoxelTD.TraverseX1), 10000000.0f); else VoxelTD.tDeltaX = 10000000.0f;
	if (VoxelTD.dx > 0) VoxelTD.tMaxX = VoxelTD.tDeltaX * TraverseData::Frac1Single(VoxelTD.TraverseX1); else VoxelTD.tMaxX = VoxelTD.tDeltaX * TraverseData::Frac0Single(VoxelTD.TraverseX1);
	VoxelTD.X = (int) VoxelTD.TraverseX1;

	VoxelTD.dy = TraverseData::SignSingle(VoxelTD.TraverseY2 - VoxelTD.TraverseY1);
	if (VoxelTD.dy != 0) VoxelTD.tDeltaY = fmin(VoxelTD.dy / (VoxelTD.TraverseY2 - VoxelTD.TraverseY1), 10000000.0f); else VoxelTD.tDeltaY = 10000000.0f;
	if (VoxelTD.dy > 0) VoxelTD.tMaxY = VoxelTD.tDeltaY * TraverseData::Frac1Single(VoxelTD.TraverseY1); else VoxelTD.tMaxY = VoxelTD.tDeltaY * TraverseData::Frac0Single(VoxelTD.TraverseY1);
	VoxelTD.Y = (int) VoxelTD.TraverseY1;

	VoxelTD.dz = TraverseData::SignSingle(VoxelTD.TraverseZ2 - VoxelTD.TraverseZ1);
	if (VoxelTD.dz != 0) VoxelTD.tDeltaZ = fmin(VoxelTD.dz / (VoxelTD.TraverseZ2 - VoxelTD.TraverseZ1), 10000000.0f); else VoxelTD.tDeltaZ = 10000000.0f;
	if (VoxelTD.dz > 0) VoxelTD.tMaxZ = VoxelTD.tDeltaZ * TraverseData::Frac1Single(VoxelTD.TraverseZ1); else VoxelTD.tMaxZ = VoxelTD.tDeltaZ * TraverseData::Frac0Single(VoxelTD.TraverseZ1);
	VoxelTD.Z = (int) VoxelTD.TraverseZ1;

	if (VoxelTD.dx > 0) VoxelTD.OutX = VoxelGD.MaxX+1; else VoxelTD.OutX = VoxelGD.MinX-1;
	if (VoxelTD.dy > 0) VoxelTD.OutY = VoxelGD.MaxY+1; else VoxelTD.OutY = VoxelGD.MinY-1;
	if (VoxelTD.dz > 0) VoxelTD.OutZ = VoxelGD.MaxZ+1; else VoxelTD.OutZ = VoxelGD.MinZ-1;

	VoxelTD.T = 0;
	VoxelTD.TraverseDone = false;
}

// could rename this to tile setup if I really wanted to or copy it... allows custom traversing for user
// maybe a bit safr.
void VoxelRay::Setup( VoxelPosition ParaStart, VoxelPosition ParaStop, int TileWidth, int TileHeight, int TileDepth )
{
	traverseMode = TraverseMode::tmUnknown;

	Start = ParaStart;
	Stop = ParaStop;

//	SetupTileBoundary();

	ComputeTileBoundary();
	ComputeTileBoundaryScaled();

	ComputeTileStartScaled();
	ComputeTileStopScaled();

	// check if ray is a point directly in tile boundary/tile grid and if so setup for direct traverse/processing of one voxel.
//	if (!IsTileDirect())
	if (!IsTileDirectScaled())
	{
		// check if ray is fully inside tile boundary/tile grid if not then 
//		if (!IsInsideTileBoundary())
		if (!IsInsideTileBoundaryScaled())
		{
			// check if ray is intersecting tile boundary and if so compute one or two intersection points
// 			if (!IsIntersectingTileBoundary())
			if (!IsIntersectingTileBoundaryScaled()) // using scaled down version
			{
				// ray is not intersecting the tile boundary so return
				// could set done to true or whatever... but there is no boolean yet... could create it
				// or just skip over rays that don't need traversing, might be nicer to use a boolean to keep things
				// easy processing in arrays and such. I think this could/might be better and probably is ! ;) =D
				traverseDone = true;
//				TileTD.TraverseDone = true;
//				VoxelTD.TraverseDone = true;
				return;
			}
		} else
		{
			// for a none-scaled future version, possiby.
//			TileTD.TraverseX1 = Start.X;
//			TileTD.TraverseY1 = Start.Y;
//			TileTD.TraverseZ1 = Start.Z;

//			TileTD.TraverseX2 = Stop.X;
//			TileTD.TraverseY2 = stop.Y;
//			TileTD.TraverseZ2 = Stop.Z;

			// both points inside boundary/tile grid, setup both traverse points and fall/pass through to below traversal code
			TileTD.TraverseX1 = TileStartScaled.X;
			TileTD.TraverseY1 = TileStartScaled.Y;
			TileTD.TraverseZ1 = TileStartScaled.Z;

			TileTD.TraverseX2 = TileStopScaled.X;
			TileTD.TraverseY2 = TileStopScaled.Y;
			TileTD.TraverseZ2 = TileStopScaled.Z;
		}
	} else
	{
		traverseDone = true;
		return;
	}

	// what about this ?! ;)
	// hmmmm.... maybe compute this after stop is checked below...  hmmmm or store it elsewhere or re-use traversex and such
	// could be risky though ebcause of return values in intersect box but I think it's ok.
	// I may have to scale down these coordinates to stay within 0..1 range for the cells for the algorithmetic code of traversal
	// though I could also change the code and multiplie by tile width and such or divide whatever by it...
	// and instead of check against 1.0 check against ray length though that would also need a somewhat
	// expensive square root length computation of ray length, though it might keep seperate traversals compatible with each other
	// but for now I am not interested in that... also perhaps t 0..1 is also compatible with each other thenagain maybe not
	// and most likely not for tmax and such and tdelta or maybe... not sure... probably not
	// anyway I think a scaled down version could be created to solve this problem, with the code above...
	// and that is what I will try for now.

	// code above is using scaled start position and scaled tile boundary data.

	// now that everything is done with scaled coordinates it should be good to setup the tile traversal below
	// and then later it can be traversed with next step and such.

	// the ray is now ready for traversing
	// setup the ray traversal data for traversing
	SetupTileTraversal();
	traverseMode = TraverseMode::tmTile;
	traverseDone = false;

	// maybe do this later/dynamicallu
/*
	VoxelTD.x1 = ParaStart.X; // divide by voxel width but there are 1 anyway so not necessary to divide.
	VoxelTD.y1 = ParaStart.Y;
	VoxelTD.z1 = ParaStart.Z;

	VoxelTD.x2 = ParaStop.X;
	VoxelTD.y2 = ParaStop.Y;
	VoxelTD.z2 = ParaStop.Z;
*/

//	SetupVoxelTraversal();
}




// only use this if not following the main setup and main traversal code
// this function will re-check the ray.
void VoxelRay::SetupVoxelTraversal( VoxelPosition ParaStart, VoxelPosition ParaStop, int TileX, int TileY, int TileZ )
{
	traverseMode = TraverseMode::tmUnknown;

	Start = ParaStart;
	Stop = ParaStop;

	ComputeVoxelBoundary( TileX, TileY, TileZ );

	if (IsSinglePoint())
	{
		if (IsSinglePointInTileBoundary())
		{
			ComputeVoxelStartPosition();
			VoxelTD.ForwardStart = true;
			VoxelTD.ForwardStop = false;
			return;
		} else
		{
			VoxelTD.ForwardStart = false;
			VoxelTD.ForwardStop = true;
			return;
		}
	}
	else
	{




	}




	// check if start and stop positions are a single point
	if (IsTileDirect())
	{
		VoxelTD.TraverseDone = true;
		return;
	}
	else
	{
		// check if start and stop positions are fully inside the world voxel boundary
		if (IsInsideVoxelBoundary())
		{
			VoxelTD.TraverseX1 = Start.X;
			VoxelTD.TraverseY1 = Start.Y;
			VoxelTD.TraverseZ1 = Start.Z;

			VoxelTD.TraverseX2 = Stop.X;
			VoxelTD.TraverseY2 = Stop.Y;
			VoxelTD.TraverseZ2 = Stop.Z;
		}
		else
		{
			if (IsIntersectingVoxelBoundary())
			{



			} else
			{
				if (IsVoxelDirect())
				{
					VoxelTD.TraverseDone = true;
					return;
				}
				else
				{

					// setup the traverse points so that there are within voxel space of the tile 0..15 and such
					VoxelTD.TraverseX1 = fmod( VoxelTD.TraverseX1, TileCD.Width );
					VoxelTD.TraverseY1 = fmod( VoxelTD.TraverseY1, TileCD.Height );
					VoxelTD.TraverseZ1 = fmod( VoxelTD.TraverseZ1, TileCD.Depth );

					VoxelTD.TraverseX2 = fmod( VoxelTD.TraverseX2, TileCD.Width );
					VoxelTD.TraverseY2 = fmod( VoxelTD.TraverseY2, TileCD.Height );
					VoxelTD.TraverseZ2 = fmod( VoxelTD.TraverseZ2, TileCD.Depth );

				}

			}
		}
	}
	else
	{

	}




















	// new to check the original start coordinates and such

	// check if original start and stop position is a single point
	if (!IsTileDirect())
	{
		// check if start and stop position lie fully inside the tile boundary, if so the intersection calculate will fail, and thus it should not be done
		// so only do intersection calculation if ray is not fully inside the tile boundary
		if (!IsInsideVoxelBoundary())
		{
			// now instead of computing a line intersection with the entire tile boundary it is now computed
			// against a single voxel boundary which basically means the single tile boundary which is computed at start of function
			if (!IsIntersectingVoxelBoundary())
			{
				// if it's not interesting the single tile boundary then that would be kinda strange
				// I think this is where we have to do another check
				// so check if the voxel ray inside this tile is only one point
				if (!IsVoxelDirect())
				{
					// setup the traverse points so that there are within voxel space of the tile 0..15 and such
					VoxelTD.TraverseX1 = fmod( VoxelTD.TraverseX1, TileCD.Width );
					VoxelTD.TraverseY1 = fmod( VoxelTD.TraverseY1, TileCD.Height );
					VoxelTD.TraverseZ1 = fmod( VoxelTD.TraverseZ1, TileCD.Depth );

					VoxelTD.TraverseX2 = fmod( VoxelTD.TraverseX2, TileCD.Width );
					VoxelTD.TraverseY2 = fmod( VoxelTD.TraverseY2, TileCD.Height );
					VoxelTD.TraverseZ2 = fmod( VoxelTD.TraverseZ2, TileCD.Depth );

				}
				else
				{
					VoxelTD.TraverseDone = true;
					return;
				}
			}
		}
		else
		{
			TileTD.TraverseX1 = TileStartScaled.X;
			TileTD.TraverseY1 = TileStartScaled.Y;
			TileTD.TraverseZ1 = TileStartScaled.Z;

			TileTD.TraverseX2 = TileStopScaled.X;
			TileTD.TraverseY2 = TileStopScaled.Y;
			TileTD.TraverseZ2 = TileStopScaled.Z;

		}
	}
	else
	{
		VoxelTD.TraverseDone = true;
		return;
	}




	// check if ray is a point directly in voxel boundary / voxel grid and if so setup for direct traverse/processing of one voxel.
	if (!IsVoxelDirect())
	{
		// check if ray is fully inside voxel boundary/voxel grid if not then 
		if (!IsInsideVoxelBoundary())
		{
			// check if ray is intersecting tile boundary and if so compute one or two intersection points
// 			if (!IsIntersectingTileBoundary())
			if (!IsIntersectingTileBoundaryScaled()) // using scaled down version
			{
				// ray is not intersecting the tile boundary so return
				// could set done to true or whatever... but there is no boolean yet... could create it
				// or just skip over rays that don't need traversing, might be nicer to use a boolean to keep things
				// easy processing in arrays and such. I think this could/might be better and probably is ! ;) =D
				traverseDone = true;
//				TileTD.TraverseDone = true;
//				VoxelTD.TraverseDone = true;
				return;
			}
		} else
		{
			// for a none-scaled future version, possiby.
//			TileTD.TraverseX1 = Start.X;
//			TileTD.TraverseY1 = Start.Y;
//			TileTD.TraverseZ1 = Start.Z;

//			TileTD.TraverseX2 = Stop.X;
//			TileTD.TraverseY2 = stop.Y;
//			TileTD.TraverseZ2 = Stop.Z;

			// both points inside boundary/tile grid, setup both traverse points and fall/pass through to below traversal code
			TileTD.TraverseX1 = TileStartScaled.X;
			TileTD.TraverseY1 = TileStartScaled.Y;
			TileTD.TraverseZ1 = TileStartScaled.Z;

			TileTD.TraverseX2 = TileStopScaled.X;
			TileTD.TraverseY2 = TileStopScaled.Y;
			TileTD.TraverseZ2 = TileStopScaled.Z;
		}
	} else
	{
		traverseDone = true;
		return;
	}

	// what about this ?! ;)
	// hmmmm.... maybe compute this after stop is checked below...  hmmmm or store it elsewhere or re-use traversex and such
	// could be risky though ebcause of return values in intersect box but I think it's ok.
	// I may have to scale down these coordinates to stay within 0..1 range for the cells for the algorithmetic code of traversal
	// though I could also change the code and multiplie by tile width and such or divide whatever by it...
	// and instead of check against 1.0 check against ray length though that would also need a somewhat
	// expensive square root length computation of ray length, though it might keep seperate traversals compatible with each other
	// but for now I am not interested in that... also perhaps t 0..1 is also compatible with each other thenagain maybe not
	// and most likely not for tmax and such and tdelta or maybe... not sure... probably not
	// anyway I think a scaled down version could be created to solve this problem, with the code above...
	// and that is what I will try for now.

	// code above is using scaled start position and scaled tile boundary data.

	// now that everything is done with scaled coordinates it should be good to setup the tile traversal below
	// and then later it can be traversed with next step and such.

	// the ray is now ready for traversing
	// setup the ray traversal data for traversing
	SetupTileTraversal();
	traverseMode = TraverseMode::tmTile;
	traverseDone = false;

	// maybe do this later/dynamicallu
/*
	VoxelTD.x1 = ParaStart.X; // divide by voxel width but there are 1 anyway so not necessary to divide.
	VoxelTD.y1 = ParaStart.Y;
	VoxelTD.z1 = ParaStart.Z;

	VoxelTD.x2 = ParaStop.X;
	VoxelTD.y2 = ParaStop.Y;
	VoxelTD.z2 = ParaStop.Z;
*/

//	SetupVoxelTraversal();
}



/*
bool VoxelRay::IsTraverseDone()
{
	// if traverse not yet done, then check if it's done
	if (!TileTD.TraverseDone) && (!VoxelTD.TraverseDone)
	{
		if (TraverseMode == tmTile)
		{
			if (TileTD.T > 1.0)
			{
				TileTD.TraverseDone = true;
			}
		)
		else
		{
			if (VoxelTD.T > 1.0)
			{
				VoxelTD.TraverseDone = true;
			}
		}
	}

	return (TileTD.TraverseDone && VoxelTD.TraverseDone);
}
*/


bool VoxelRay::IsTileTraverseDone()
{
	if (!TileTD.TraverseDone)
	{
		if (traverseMode == TraverseMode::tmTile)
		{
			if (TileTD.T > 1.0)
			{
				TileTD.TraverseDone = true;

			}
		}
	}

	return TileTD.TraverseDone;
}

bool VoxelRay::IsVoxelTraverseDone()
{
	if (!VoxelTD.TraverseDone)
	{
		if (traverseMode == TraverseMode::tmVoxel)
		{
			// to support backward traversal could also check for smaller than 0. but for now gonna let it be.
			// user could just reverse start/stop point and thus this code does not need to be slowed down unnecessarily
			// unless user wants to step back and forth, back and forth and such... but then also the NextStep
			// could be copied and also made a PreviousStep which is kinda a cool idea but ok.
			if (VoxelTD.T > 1.0)
			{
				VoxelTD.TraverseDone = true;
			}
		}
	}

	return VoxelTD.TraverseDone;
}

// different techniques possible
// I think I will like one boolean only better to avoid some instructions and to prevent boolean logic confusion and limitations and such.
// also a little bit less data usage/data space.
// simplified logic, also less bug prone ;)
// SHIITTTZZZZ... this code is inflexible... it does not allow traversing multiple voxel grids insides multiple tiles
// I will leave the code like it is for now, but create a different version down below...
// ya know what... I am just gonna split it into two functions for now maybe... and let the user decide what to do
// maybe not though... I don't know yet holyshit.... I just want to have something generic so I am gonna fix it below
// in a new version... to make it nice and easy for end user for now.
/// but it might be wise to have custom functions anyway in case the user has any doubts about what this function does.
// let's start with that ! =D for custom stepping/traversing through grids yeah ! =D maximum flexibility and shit.
// could be good and handy in certain cases maybe but could also lead to inefficiency or even bugs but maybe not
// it depends on brain of user hahahahaha. >=D
bool VoxelRay::IsTraverseDone()
{
	if (!traverseDone)
	{
		if (traverseMode == TraverseMode::tmTile)
		{
			if (TileTD.T > 1.0)
			{
				TileTD.TraverseDone = true;
				traverseDone = true;
				return true;
			}
		} else
//		if (traverseMode == tmVoxel)
		{
			if (VoxelTD.T > 1.0)
			{
				VoxelTD.TraverseDone = true;
				traverseDone = true;
			}
		}

		if (TileTD.TraverseDone && VoxelTD.TraverseDone)
		{
			traverseDone = true;
		}
	}

	return traverseDone;
}

// more correct version, which allows tracing/collision detection through multiple voxel grids basically, assuming
// at least that the voxel t will end inside a voxel/tile grid basically, in case algorithm changes, then above
// version would have been good, but not now, not in this version... where t stops at the tile boundary for now, there it
// should be 1 already. So that is the problem with above code sort of it assumes, that the ray traversal is done after
// entering one tile, for voxel checking, but there might be no collisions, so it should be able to continue back into
// tile tracing mode !

// it depends on brain of user hahahahaha. >=D
// I don't want to fix this yet... cause it's killing my brain...
// let's seperate into seperate see above functions for now, might be helpfull too.
/*
bool VoxelRay::IsTraverseDone()
{
	if (!traverseDone)
	{
		if (traverseMode == tmTile)
		{
			if (TileTD.T > 1.0)
			{
				TileTD.TraverseDone = true;
				traverseDone = true;
				return true;
			}
		} else
//		if (traverseMode == tmVoxel)
		{
			if (VoxelTD.T > 1.0)
			{
				VoxelTD.TraverseDone = true;
				traverseDone = true;
			}
		}

		if (TileTD.TraverseDone && VoxelTD.TraverseDone)
		{
			traverseDone = true;
		}
	}

	return traverseDone;
}
*/


void VoxelRay::NextStep()
{
	// direct end result
	if (traverseMode == TraverseMode::tmDirect)
	{
		traverseDone = true;
	} else
	// traverse tiles
	if (traverseMode == TraverseMode::tmTile)
	{
		// go to next voxel
		if ( (TileTD.tMaxX < TileTD.tMaxY) && (TileTD.tMaxX < TileTD.tMaxZ) )
		{
			TileTD.T = TileTD.tMaxX;
			TileTD.X += TileTD.dx;
			TileTD.tMaxX += TileTD.tDeltaX;

			if (TileTD.X == TileTD.OutX)
			{
				TileTD.TraverseDone = true;
				return;
			}
		}
		else
		if (TileTD.tMaxY < TileTD.tMaxZ)
		{
			TileTD.T = TileTD.tMaxY;
			TileTD.Y += TileTD.dy;
			TileTD.tMaxY += TileTD.tDeltaY;

			if (TileTD.Y == TileTD.OutY)
			{
				TileTD.TraverseDone = true;
				return;
			}
		}
		else
		{
			TileTD.T = TileTD.tMaxZ;
			TileTD.Z += TileTD.dz;
			TileTD.tMaxZ += TileTD.tDeltaZ;

			if (TileTD.Z == TileTD.OutZ)
			{
				TileTD.TraverseDone = true;
				return;
			}
		}
	} else
	// traverse voxels
//	if (traverseMode == TraverseMode::tmVoxel)
	{
		// go to next voxel
		if ( (VoxelTD.tMaxX < VoxelTD.tMaxY) && (VoxelTD.tMaxX < VoxelTD.tMaxZ) )
		{
			VoxelTD.T = VoxelTD.tMaxX;
			VoxelTD.X += VoxelTD.dx;
			VoxelTD.tMaxX += VoxelTD.tDeltaX;

			if (VoxelTD.X == VoxelTD.OutX)
			{
				VoxelTD.TraverseDone = true;
				return;
			}
		}
		else
		if (VoxelTD.tMaxY < VoxelTD.tMaxZ)
		{
			VoxelTD.T = VoxelTD.tMaxY;
			VoxelTD.Y += VoxelTD.dy;
			VoxelTD.tMaxY += VoxelTD.tDeltaY;

			if (VoxelTD.Y == VoxelTD.OutY)
			{
				VoxelTD.TraverseDone = true;
				return;
			}
		}
		else
		{
			VoxelTD.T = VoxelTD.tMaxZ;
			VoxelTD.Z += VoxelTD.dz;
			VoxelTD.tMaxZ += VoxelTD.tDeltaZ;

			if (VoxelTD.Z == VoxelTD.OutZ)
			{
				VoxelTD.TraverseDone = true;
				return;
			}
		}
	}
}

// can be made in user code or I can write it here, but to keep it seperated from rest of code, can leave it to user code.
// user code could also change... requiring changes to this code, so let's shove that over to the user code ! ;) =DDDD
// little bit less user friendly in the sense that not all code is done, but implementing this should not be too hard
// however perhaps use this function to return some voxel or tile position information for traversal/retrieval of information
// purposes in user code that is a nice thing to do.
/*
bool VoxelRay::Collision()
{
	if (TraverseMode == tmTile)
	{
		if (!Tile[TileZ][TileY][TileX].IsEmpty)
		{
			// could setup voxel traverse here if really necessary


			// switch to TraverseMode tmVoxel

			return false;
		}
	} else
	{
		if (Voxel[VoxelZ][VoxelY][VoxelX])
		{
			return true;
		}
	}
	return false;
}
*/

// bla
void VoxelRay::GetTraverseTilePosition( int *ParaTileX, int *ParaTileY, int *ParaTileZ )
{
	*ParaTileX = TileTD.X;
	*ParaTileY = TileTD.Y;
	*ParaTileZ = TileTD.Z;
}

void VoxelRay::GetTraverseVoxelPosition( int *ParaVoxelX, int *ParaVoxelY, int *ParaVoxelZ )
{
	*ParaVoxelX = VoxelTD.X;
	*ParaVoxelY = VoxelTD.Y;
	*ParaVoxelZ = VoxelTD.Z;
}

} // close/de-associate OpenXcom namespace
