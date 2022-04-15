#pragma once

enum TraverseMode { tmUnknown, tmDirect, tmTile, tmVoxel }; 

struct TraverseData
{
	float T;

	float x1, x2;
	float y1, y2;
	float z1, z2;

	float tMaxX, tMaxY, tMaxZ;
	float tDeltaX, tDeltaY, tDeltaZ;
	int dx, dy, dz;
	int X, Y, Z;
	int OutX, int OutY, int OutZ;

	float CellWidth, CellHeight, CellDepth;

	int BoundaryMinX, BoundaryMinY, BoundaryMinZ; 
	int BoundaryMaxX, BoundaryMaxY, BoundaryMaxZ;

	float SignSingle( float x )
	float Frac0Single( float x )
	float Frac1Single( float x )
	float MaxSingle(float A, float B)
	float MinSingle(float A, float B)
}

struct BoundaryData
{
	int MinX, int MinY, int MinZ;
	int MaxX, int MaxY, int MaxZ;



}

// macros for fast voxel traversal algoritm in code below
// original macros disabled, to not be reliant on macro language ! ;)
// #define SIGN(x) (x > 0 ? 1 : (x < 0 ? -1 : 0))
// #define FRAC0(x) (x - floorf(x))
// #define FRAC1(x) (1 - x + floorf(x))

// note: the floating point type below in these helper functions should match the floating point type in calculateLine
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


struct VoxelRay
{
	VoxelPosition Start;		
	VoxelPosition Stop;

	TraverseMode traverseMode;

	TraverseData TileTD;
	TraverseData VoxelTD;

	int CollisionTileX, CollisionTileY, CollisionTileZ;
	int CollisionVoxelX, CollisionVoxelY, CollisionVoxelZ;

	static float Epsilon = 0.1; // static ? ;)

	void SetupTileBoundary( int ParaMinX, int ParaMinY, int ParaMinZ, int ParaMaxX, int ParaMaxY, int ParaMaxZ );
	void SetupTileTraversal();

	void SetupVoxelBoundary( int ParaMinX, int ParaMinY, int ParaMinZ, int ParaMaxX, int ParaMaxY, int ParaMaxZ );
	void SetupVoxelTraversal();

	bool IsTileDirect();
	bool IsVoxelDirect();

	void Setup( VoxelPosition ParaStart, VoxelPosition ParaStop, int TileWidth, int TileHeight, int TileDepth  );

	void NextStep();
};


bool PointInBoxSingle
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

bool VoxelRay::IsTileDirect()
{

	// maybe use Tile coordinates to check if tile coordinates are inside grid would be better ?!????
	// could use real/voxel world coordinates, but let's do tile coordinates.

	// if original ray is a single point then

	// real/voxel coordinates, but not using this for now... 
//	if
//	(
//		(ParaStart.X == ParaStop.X) &&
//		(ParaStart.Y == ParaStop.Y) &&
//		(ParaStart.Z == ParaStop.Z)
//	)

	if
	(
		(TileTD.x1 == TileTD.x2) &&
		(TileTD.y1 == TileTD.y2) &&
		(TileTD.z1 == TileTD.z2)
	)
	{
		// check if single point is inside tile grid
		if
		(
/*
			PointInBoxSingle
			(
				TileTD.x1, TileTD.y1, TileTD.z1,

				TileTD.BoundaryMinX,
				TileTD.BoundaryMinY,
				TileTD.BoundaryMinZ,

				TileTD.BoundaryMaxX-Epsilon,
				TileTD.BoundaryMaxY-Epsilon,
				TileTD.BoundaryMaxZ-Epsilon
			) == true
*/

			// alternative more precision solution
			PointInBoxSingle
			(
				ParaStart.X, ParaStart.Y, ParaStart.Z,

				// convert back to real world/voxel coordinates to check more precisely
				TileTD.BoundaryMinX * TileTD.mCellWidth,
				TileTD.BoundaryMinY * 16,
				TileTD.BoundaryMinZ * 24,

				(TileTD.BoundaryMaxX * 16)-Epsilon,
				(TileTD.BoundaryMaxY * 16)-Epsilon,
				(TileTD.BoundaryMaxZ * 24)-Epsilon
			) == true
		)
		{
			// set traversal mode to tmDirect
			// could do a seperated tmTileDirect and tmVoxelDirect but for now I see no reason too
			// and it will just create an unnecessary branch and slow things down.
			traverseMode = tmDirect; 

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
			VoxelTD.X = ParaStart.X % 16;
			VoxelTD.Y = ParaStart.Y % 16;
			VoxelTD.Z = ParaStart.Z % 24;

			return true;
		}
	}

	return false;
}

bool VoxelRay::IsVoxelDirect()
{
	if
	(
		(VoxelTD.x1 == VoxelTD.x2) &&
		(VoxelTD.y1 == VoxelTD.y2) &&
		(VoxelTD.z1 == VoxelTD.z2)
	)
	{
		// check if single point is inside tile grid
		if
		(
			PointInBoxSingle
			(
				VoxelTD.x1, TileTD.y1, TileTD.z1,

				VoxelTD.BoundaryMinX,
				VoxelTD.BoundaryMinY,
				VoxelTD.BoundaryMinZ,

				VoxelTD.BoundaryMaxX-Epsilon,
				VoxelTD.BoundaryMaxY-Epsilon,
				VoxelTD.BoundaryMaxZ-Epsilon
			) == true
		)
		{
			// set traversal mode to tmDirect
			traverseMode = tmDirect;

			// setup voxel coordinate for processing later.

			// most likely these voxel coordinates are not modded yet to stay within voxel range of a tile so let's also
			// apply mod here.
			// however these coordinates could be modified/clipped against the tile that they lie in... so must use
			// VoxelTD coordinates

			VoxelTD.X = VoxelTD.x1 % 16;
			VoxelTD.Y = VoxelTD.y1 % 16;
			VoxelTD.Z = VoxelTD.z1 % 24;

			return true;
		}
	}

	return false;
}


bool VoxelRay::AreBothInTileGrid()
{

{
	// check if both world points are in tile grid, but multiple boundary by tile size to get world voxel coordinates for good check.
	if
	(
		PointInBoxSingle
		(
			ParaStart.X, ParaStart.Y, ParaStart.Z,

			TileTD.BoundaryMinX * TileWidth,
			vMapVoxelBoundaryMinY,
			vMapVoxelBoundaryMinZ,

			vMapVoxelBoundaryMaxX-Epsilon,
			vMapVoxelBoundaryMaxY-Epsilon,
			vMapVoxelBoundaryMaxZ-Epsilon
		)
		&&
		PointInBoxSingle
		(
			x2, y2, z2,

			vMapVoxelBoundaryMinX,
			vMapVoxelBoundaryMinY,
			vMapVoxelBoundaryMinZ,

			vMapVoxelBoundaryMaxX-Epsilon,
			vMapVoxelBoundaryMaxY-Epsilon,
			vMapVoxelBoundaryMaxZ-Epsilon
		)
	)
	{
		// just fall through to next code below
		// traverse
	}
	else
	// check if line intersects box
	if
	(
		LineSegmentIntersectsBoxSingle
		(
			x1,y1,z1,
			x2,y2,z2,

			vMapVoxelBoundaryMinX,
			vMapVoxelBoundaryMinY,
			vMapVoxelBoundaryMinZ,

			vMapVoxelBoundaryMaxX-Epsilon,
			vMapVoxelBoundaryMaxY-Epsilon,
			vMapVoxelBoundaryMaxZ-Epsilon,

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
			TraverseX1 = IntersectionPointX1;
			TraverseY1 = IntersectionPointY1;
			TraverseZ1 = IntersectionPointZ1;
		}
		else
		{
			TraverseX1 = x1;
			TraverseY1 = y1;
			TraverseZ1 = z1;
		}

		// compensate for any floating point errors (inaccuracies)
		TraverseX1 = MaxSingle( TraverseX1, vMapVoxelBoundaryMinX );
		TraverseY1 = MaxSingle( TraverseY1, vMapVoxelBoundaryMinY );
		TraverseZ1 = MaxSingle( TraverseZ1, vMapVoxelBoundaryMinZ );

		TraverseX1 = MinSingle( TraverseX1, vMapVoxelBoundaryMaxX-Epsilon );
		TraverseY1 = MinSingle( TraverseY1, vMapVoxelBoundaryMaxY-Epsilon );
		TraverseZ1 = MinSingle( TraverseZ1, vMapVoxelBoundaryMaxZ-Epsilon );

		if (IntersectionPoint2 == true)
		{
			TraverseX2 = IntersectionPointX2;
			TraverseY2 = IntersectionPointY2;
			TraverseZ2 = IntersectionPointZ2;
		}
		else
		{
			TraverseX2 = x2;
			TraverseY2 = y2;
			TraverseZ2 = z2;
		}

		// compensate for any floating point errors (inaccuracies)
		TraverseX2 = MaxSingle( TraverseX2, vMapVoxelBoundaryMinX );
		TraverseY2 = MaxSingle( TraverseY2, vMapVoxelBoundaryMinY );
		TraverseZ2 = MaxSingle( TraverseZ2, vMapVoxelBoundaryMinZ );

		TraverseX2 = MinSingle( TraverseX2, vMapVoxelBoundaryMaxX-Epsilon );
		TraverseY2 = MinSingle( TraverseY2, vMapVoxelBoundaryMaxY-Epsilon );
		TraverseZ2 = MinSingle( TraverseZ2, vMapVoxelBoundaryMaxZ-Epsilon );

		// it is possible that after intersection testing the line is just a dot
		// on the intersection box so check for this and then process voxel
		// seperately.
		if
		(
			(TraverseX1==TraverseX2) &&
			(TraverseY1==TraverseY2) &&
			(TraverseZ1==TraverseZ2)
		)
		{
			// process voxel
			VoxelX = TraverseX1; 
			VoxelY = TraverseY1; 
			VoxelZ = TraverseZ1;

			// store trajectory even if outside of voxel boundary, other code must solve it, otherwise trajectory empty
			if (storeTrajectory && trajectory)
			{
				trajectory->push_back(Position(VoxelX, VoxelY, VoxelZ));
			}

			//passes through this point?
			if (doVoxelCheck)
			{
		//		result = voxelCheck(Position(VoxelX, VoxelY, VoxelZ), excludeUnit, false, onlyVisible, excludeAllBut);
				result = voxelCheck(Position(VoxelX, VoxelY, VoxelZ), excludeUnit, excludeAllUnits, onlyVisible, excludeAllBut); // skybuck: Not sure which call is better

				if (result != V_EMPTY)
				{
					if (trajectory)
					{ // store the position of impact
						trajectory->push_back(Position(VoxelX, VoxelY, VoxelZ));
					}
					return result;
				}
			}
			else
			{
				int temp_res = verticalBlockage(_save->getTile(LastPoint), _save->getTile(Position(VoxelX, VoxelY, VoxelZ)), DT_NONE);
				result = horizontalBlockage(_save->getTile(LastPoint), _save->getTile(Position(VoxelX, VoxelY, VoxelZ)), DT_NONE, steps<2);
				steps++;
				if (result == -1)
				{
					if (temp_res > 127)
					{
						result = 0;
					}
					else
					{
						return result; // We hit a big wall
					}
				}
				result += temp_res;
				if (result > 127)
				{
					return result;
				}

				LastPoint = Position(VoxelX, VoxelY, VoxelZ);
			}

			return result;
		}
		else
		{
			// just fall through below
			// traverse
			x1 = TraverseX1; 
			y1 = TraverseY1;
			z1 = TraverseZ1; 

			x2 = TraverseX2; 
			y2 = TraverseY2;
			z2 = TraverseZ2; 
		}
	}
}

void VoxelRay.SetupTileDimensions( int ParaTileWidth, int ParaTileHeight, int ParaTileWidth )
{
	TileTD.m



}

void VoxelRay:SetupTileBoundary( int ParaMinX, int ParaMinY, int ParaMinZ, int ParaMaxX, int ParaMaxY, int ParaMaxZ )
{
	TileTD.BoundaryMinX = ParaMinX;
	TileTD.BoundaryMinY = ParaMinY;
	TileTD.BoundaryMinZ = ParaMinZ;

	TileTD.BoundaryMaxX = ParaMaxX;
	TileTD.BoundaryMaxY = ParaMaxY;
	TileTD.BoundaryMaxZ = ParaMaxZ;
}


void VoxelRay::SetupTileTraversal()
{
	// traverse code, fast voxel traversal algorithm
	int TileTD.dx = TileTD.SignSingle(TileTD.x2 - TileTD.x1);
	if (TileTD.dx != 0) TileTD.tDeltaX = TileTD.fmin(TileTD.dx / (TileTD.x2 - TileTD.x1), 10000000.0f); else TileTD.tDeltaX = 10000000.0f;
	if (TileTD.dx > 0) TileTD.tMaxX = TileTD.tDeltaX * TileTD.Frac1Single(TileTD.x1); else TileTD.tMaxX = TileTD.tDeltaX * TileTD.Frac0Single(TileTD.x1);
	TileTD.X = (int) Tilex1;

	int TileTD.dy = TileTD.SignSingle(TileTD.y2 - TileTD.y1);
	if (TileTD.dy != 0) TiletDeltaY = TileTD.fmin(TileTD.dy / (TileTD.y2 - TileTD.y1), 10000000.0f); else TileTD.tDeltaY = 10000000.0f;
	if (TileTD.dy > 0) TileTD.tMaxY = TileTD.tDeltaY * TileTD.Frac1Single(TileTD.y1); else TileTD.tMaxY = TileTD.tDeltaY * Frac0Single(TileTD.y1);
	TileTD.Y = (int) TileTD.y1;

	int TileTD.dz = TileTD.SignSingle(TileTD.z2 - TileTD.z1);
	if (TileTD.dz != 0) TileTD.tDeltaZ = TileTD.fmin(TileTD.dz / (TileTD.z2 - TileTD.z1), 10000000.0f); else TileTD.tDeltaZ = 10000000.0f;
	if (TileTD.dz > 0) TileTD.tMaxZ = TileTD.tDeltaZ * TileTD.Frac1Single(TileTD.z1); else TiletMaxZ = TileTD.tDeltaZ * TileTD.Frac0Single(TileTD.z1);
	TileTD.Z = (int) TileTD.z1;

	if (TileTD.dx > 0) TileTD.OutX = TileTD.BoundaryMaxX+1; else TileTD.OutX = TileTD.BoundaryMinX-1;
	if (TileTD.dy > 0) TileTD.OutY = TileTD.BoundaryMaxY+1; else TileTD.OutY = TileTD.BoundaryMinY-1;
	if (TileTD.dz > 0) TileTD.OutZ = TileTD.BoundaryMaxZ+1; else TileTD.OutZ = TileTD.BoundaryMinZ-1;
}


void VoxelRay:SetupVoxelBoundary( int ParaMinX, int ParaMinY, int ParaMinZ, int ParaMaxX, int ParaMaxY, int ParaMaxZ )
{
	VoxelTD.BoundaryMinX = ParaMinX;
	VoxelTD.BoundaryMinY = ParaMinY;
	VoxelTD.BoundaryMinZ = ParaMinZ;

	VoxelTD.BoundaryMaxX = ParaMaxX;
	VoxelTD.BoundaryMaxY = ParaMaxY;
	VoxelTD.BoundaryMaxZ = ParaMaxZ;
}

void VoxelRay:SetupVoxelTraversal()
{
	// traverse code, fast voxel traversal algorithm
	int VoxelTD.dx = VoxelTD.SignSingle(VoxelTD.x2 - VoxelTD.x1);
	if (VoxelTD.dx != 0) VoxelTD.tDeltaX = VoxelTD.fmin(VoxelTD.dx / (VoxelTD.x2 - VoxelTD.x1), 10000000.0f); else VoxelTD.tDeltaX = 10000000.0f;
	if (VoxelTD.dx > 0) VoxelTD.tMaxX = VoxelTD.tDeltaX * VoxelTD.Frac1Single(VoxelTD.x1); else VoxelTD.tMaxX = VoxelTD.tDeltaX * VoxelTD.Frac0Single(VoxelTD.x1);
	VoxelTD.X = (int) VoxelTD.x1;

	int VoxelTD.dy = VoxelTD.SignSingle(VoxelTD.y2 - VoxelTD.y1);
	if (VoxelTD.dy != 0) VoxelTD.tDeltaY = VoxelTD.fmin(Voxeldy / (VoxelTD.y2 - VoxelTD.y1), 10000000.0f); else VoxelTD.tDeltaY = 10000000.0f;
	if (VoxelTD.dy > 0) VoxelTD.tMaxY = tDeltaY * VoxelTD.Frac1Single(VoxelTD.y1); else VoxelTD.tMaxY = VoxelTD.tDeltaY * VoxelTD.Frac0Single(VoxelTD.y1);
	VoxelTD.Y = (int) VoxelTD.y1;

	int VoxelTD.dz = VoxelTD.SignSingle(VoxelTD.z2 - VoxelTD.z1);
	if (VoxelTD.dz != 0) VoxelTD.tDeltaZ = VoxelTD.fmin(VoxelTD.dz / (VoxelTD.z2 - VoxelTD.z1), 10000000.0f); else VoxelTD.tDeltaZ = 10000000.0f;
	if (VoxelTD.dz > 0) VoxeltMaxZ = VoxelTD.tDeltaZ * VoxelTD.Frac1Single(VoxelTD.z1); else VoxelTD.tMaxZ = VoxelTD.tDeltaZ * VoxelTD.Frac0Single(VoxelTD.z1);
	VoxelTD.Z = (int) Voxelz1;

	if (VoxelTD.dx > 0) VoxelTD.OutX = VoxelTD.BoundaryMaxX+1; else VoxelTD.OutX = VoxelTD.BoundaryMinX-1;
	if (VoxelTD.dy > 0) VoxelTD.OutY = VoxelTD.BoundaryMaxY+1; else VoxelTD.OutY = VoxelTD.BoundaryMinY-1;
	if (VoxelTD.dz > 0) VoxelTD.OutZ = VoxelTD.BoundaryMaxZ+1; else VoxelTD.OutZ = VoxelTD.BoundaryMinZ-1;
}




void VoxelRay::Setup( VoxelPosition ParaStart, VoxelPosition ParaStop, int TileWidth, int TileHeight, int TileDepth )
{
	TileTD.x1 = ParaStart.X / TileWidth;
	TileTD.y1 = ParaStart.Y / TileHeight;
	TileTD.z1 = ParaStart.Z / TileDepth;

	TileTD.x2 = ParaStop.X / TileWidth;
	TileTD.y2 = ParaStop.Y / TileHeight;
	TileTD.z2 = ParaStop.Z / TileDepth;

	traverseMode = tmUnknown;

	SetupTileBoundary();

	if (!IsTileDirect())
	{





	}


	// maybe do this later/dynamicallu
/*
	VoxelTD.x1 = ParaStart.X; // divide by voxel width but there are 1 anyway so not necessary to divide.
	VoxelTD.y1 = ParaStart.Y;
	VoxelTD.z1 = ParaStart.Z;

	VoxelTD.x2 = ParaStop.X;
	VoxelTD.y2 = ParaStop.Y;
	VoxelTD.z2 = ParaStop.Z;
*/


	SetupTileTraversal();

//	SetupVoxelTraversal();

	TraverseMode = tmTile;

	TileTD.T = 0;
//	VoxelTD.T = 0;

}

bool VoxelRay::Done()
{
	if (TraverseMode == tmTile)
	{
		if (TileTD.T <= 1.0)
		{
			return false;
		} else
		{
			return true;
		}
	)
	else
	{
		if (VoxelTD.T <= 1.0)
		{
			return false;
		} else
		{
			return true;
		}
	}
}

void VoxelRay::NextStep()
{
	// direct end result
	if (TraverseMode == tmDirect)
	{



	} else
	// traverse tiles
	if (TraverseMode == tmTile)
	{
		// go to next voxel
		if ( (TileTD.tMaxX < TileTD.tMaxY) && (TileTD.tMaxX < TileTD.tMaxZ) )
		{
			TileTD.T = TileTD.tMaxX;
			TileTD.X += TileTD.dx;
			TiletTD.MaxX += TileTD.tDeltaX;

			if (TileTD.X == TileTD.OutX) break;
		}
		else
		if (TileTD.tMaxY < TiletMaxZ)
		{
			TileTD.T = TileTD.tMaxY;
			TileTD.Y += TileTD.dy;
			TileTD.tMaxY += TileTD.tDeltaY;

			if (TileTD.Y == TileTD.OutY) break;
		}
		else
		{
			TileTD.T = TileTD.tMaxZ;
			TileTD.Z += TileTD.dz;
			TileTD.tMaxZ += TileTD.tDeltaZ;

			if (TileTD.Z == TileTD.OutZ) break;
		}


	} else
	// traverse voxels
//	if (TraverseMode == tmVoxel)
	{
		// go to next voxel
		if ( (VoxelTD.tMaxX < VoxeltMaxY) && (VoxeltMaxX < VoxeltMaxZ) )
		{
			VoxelTD.T = VoxelTD.tMaxX;
			VoxelTD.X += VoxelTD.dx;
			VoxelTD.tMaxX += VoxelTD.tDeltaX;

			if (VoxelTD.X == VoxelTD.OutX) break;
		}
		else
		if (VoxelTD.tMaxY < VoxeltMaxZ)
		{
			VoxelTD.T = VoxelTD.tMaxY;
			VoxelTD.Y += VoxelTD.dy;
			VoxelTD.tMaxY += VoxelTD.tDeltaY;

			if (VoxelTD.Y == VoxelTD.OutY) break;
		}
		else
		{
			VoxelTD.T = VoxelTD.tMaxZ;
			VoxelTD.Z += VoxelTD.dz;
			VoxelTD.tMaxZ += VoxelTD.tDeltaZ;

			if (VoxelTD.Z == VoxelTD.OutZ) break;
		}
	}
}

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


bool LineSegmentIntersectsBoxSingle
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
	if ( (LineMinDistanceToBox > 0) && (LineMinDistanceToBox < 1) )
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

	if ( (LineMaxDistanceToBox > 0) && (LineMaxDistanceToBox < 1) )
	{
		*MaxIntersectionPoint = true;
		*MaxIntersectionPointX = LineX1 + LineMaxDistanceToBox * LineDeltaX;
		*MaxIntersectionPointY = LineY1 + LineMaxDistanceToBox * LineDeltaY;
		*MaxIntersectionPointZ = LineZ1 + LineMaxDistanceToBox * LineDeltaZ;

		result = true;
	}

	return result;
}

int TileEngine::calculateLine
(
	Position origin, Position target,
	bool storeTrajectory, std::vector<Position> *trajectory,
	BattleUnit *excludeUnit, bool doVoxelCheck, bool onlyVisible, BattleUnit *excludeAllBut
)
{
	int result;
	float x1, y1, z1; // start point
	float x2, y2, z2; // end point

	float tMaxX, tMaxY, tMaxZ, t, tDeltaX, tDeltaY, tDeltaZ;

	int VoxelX, VoxelY, VoxelZ;

	int OutX, OutY, OutZ;

	bool IntersectionPoint1;
	bool IntersectionPoint2;

	float IntersectionPointX1, IntersectionPointY1, IntersectionPointZ1;
	float IntersectionPointX2, IntersectionPointY2, IntersectionPointZ2;

	float TraverseX1, TraverseY1, TraverseZ1;
	float TraverseX2, TraverseY2, TraverseZ2;

	float Epsilon;

	Position LastPoint(origin);
	bool excludeAllUnits = false;

	int steps = 0;

	//	Epsilon := 0.001;
	Epsilon = 0.1;

	float TileWidth = 16.0;
	float TileHeight = 16.0;
	float TileDepth = 24.0;

	// calculate max voxel position
	int vMapVoxelBoundaryMinX = 0;
	int vMapVoxelBoundaryMinY = 0;
	int vMapVoxelBoundaryMinZ = 0;

	int vLastMapTileX = (_save->getMapSizeX()-1);
	int vLastMapTileY = (_save->getMapSizeY()-1);
	int vLastMapTileZ = (_save->getMapSizeZ()-1);

	int vLastTileVoxelX = TileWidth-1;
	int vLastTileVoxelY = TileHeight-1;
	int vLastTileVoxelZ = TileDepth-1;

	int vMapVoxelBoundaryMaxX = (vLastMapTileX*TileWidth) + vLastTileVoxelX;
	int vMapVoxelBoundaryMaxY = (vLastMapTileY*TileHeight) + vLastTileVoxelY;
	int vMapVoxelBoundaryMaxZ = (vLastMapTileZ*TileDepth) + vLastTileVoxelZ;

	//start and end points
	x1 = origin.x;	 x2 = target.x;
	y1 = origin.y;	 y2 = target.y;
	z1 = origin.z;	 z2 = target.z;


			// store trajectory even if outside of voxel boundary, other code must solve it, otherwise trajectory empty
			if (storeTrajectory && trajectory)
			{
				trajectory->push_back(Position(VoxelX, VoxelY, VoxelZ));
			}

			//passes through this point?
			if (doVoxelCheck)
			{
		//		result = voxelCheck(Position(VoxelX, VoxelY, VoxelZ), excludeUnit, false, onlyVisible, excludeAllBut);
				result = voxelCheck(Position(VoxelX, VoxelY, VoxelZ), excludeUnit, excludeAllUnits, onlyVisible, excludeAllBut); // skybuck: Not sure which call is better

				if (result != V_EMPTY)
				{
					if (trajectory)
					{ // store the position of impact
						trajectory->push_back(Position(VoxelX, VoxelY, VoxelZ));
					}
					return result;
				}
			}
			else
			{
				int temp_res = verticalBlockage(_save->getTile(LastPoint), _save->getTile(Position(VoxelX, VoxelY, VoxelZ)), DT_NONE);
				result = horizontalBlockage(_save->getTile(LastPoint), _save->getTile(Position(VoxelX, VoxelY, VoxelZ)), DT_NONE, steps<2);
				steps++;
				if (result == -1)
				{
					if (temp_res > 127)
					{
						result = 0;
					}
					else
					{
						return result; // We hit a big wall
					}
				}
				result += temp_res;
				if (result > 127)
				{
					return result;
				}

				LastPoint = Position(VoxelX, VoxelY, VoxelZ);
			}

			return result;
		}
	}

	// traverse code, fast voxel traversal algorithm
	int dx = SignSingle(x2 - x1);
	if (dx != 0) tDeltaX = fmin(dx / (x2 - x1), 10000000.0f); else tDeltaX = 10000000.0f;
	if (dx > 0) tMaxX = tDeltaX * Frac1Single(x1); else tMaxX = tDeltaX * Frac0Single(x1);
	VoxelX = (int) x1;

	int dy = SignSingle(y2 - y1);
	if (dy != 0) tDeltaY = fmin(dy / (y2 - y1), 10000000.0f); else tDeltaY = 10000000.0f;
	if (dy > 0) tMaxY = tDeltaY * Frac1Single(y1); else tMaxY = tDeltaY * Frac0Single(y1);
	VoxelY = (int) y1;

	int dz = SignSingle(z2 - z1);
	if (dz != 0) tDeltaZ = fmin(dz / (z2 - z1), 10000000.0f); else tDeltaZ = 10000000.0f;
	if (dz > 0) tMaxZ = tDeltaZ * Frac1Single(z1); else tMaxZ = tDeltaZ * Frac0Single(z1);
	VoxelZ = (int) z1;

	if (doVoxelCheck) voxelCheckFlush();

	if (dx > 0) OutX = vMapVoxelBoundaryMaxX+1; else OutX = -1;
	if (dy > 0) OutY = vMapVoxelBoundaryMaxY+1; else OutY = -1;
	if (dz > 0) OutZ = vMapVoxelBoundaryMaxZ+1; else OutZ = -1;

	t = 0;
	while (t <= 1.0)
	{
		// process voxel

		// store trajectory even if outside of voxel boundary, other code must solve it, otherwise trajectory empty
		if (storeTrajectory && trajectory)
		{
			trajectory->push_back(Position(VoxelX, VoxelY, VoxelZ));
		}

		//passes through this point?
		if (doVoxelCheck)
		{
	//		result = voxelCheck(Position(VoxelX, VoxelY, VoxelZ), excludeUnit, false, onlyVisible, excludeAllBut);
			result = voxelCheck(Position(VoxelX, VoxelY, VoxelZ), excludeUnit, excludeAllUnits, onlyVisible, excludeAllBut); // skybuck: Not sure which call is better

			if (result != V_EMPTY)
			{
				if (trajectory)
				{ // store the position of impact
					trajectory->push_back(Position(VoxelX, VoxelY, VoxelZ));
				}
				return result;
			}
		}
		else
		{
			int temp_res = verticalBlockage(_save->getTile(LastPoint), _save->getTile(Position(VoxelX, VoxelY, VoxelZ)), DT_NONE);
			result = horizontalBlockage(_save->getTile(LastPoint), _save->getTile(Position(VoxelX, VoxelY, VoxelZ)), DT_NONE, steps<2);
			steps++;
			if (result == -1)
			{
				if (temp_res > 127)
				{
					result = 0;
				}
				else
				{
					return result; // We hit a big wall
				}
			}
			result += temp_res;
			if (result > 127)
			{
				return result;
			}

			LastPoint = Position(VoxelX, VoxelY, VoxelZ);
		}


	}

	return V_EMPTY;
}

