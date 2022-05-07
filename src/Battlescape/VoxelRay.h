#pragma once

//
// VoxelRay.h
//
// VoxelRay design/header/implementation by Skybuck Flying
//
// version 0.01 created on 15 april 2022 by Skybuck Flying
// for any questions, comments, feedback, improvements: skybuck2000@hotmail.com
//

namespace OpenXcom
{ // open/associate OpenXcom namespace

// scoped enum
enum struct TraverseMode { tmUnknown, tmDirect, tmTile, tmVoxel }; 


struct VoxelPosition
{
	int X, Y, Z;
};

struct VoxelPositionFloat
{
	float X, Y, Z;
};

struct TraverseData
{
	float T;

	// probably not going to use this anymore ?!?
/*
	float x1, x2;
	float y1, y2;
	float z1, z2;
*/
	bool TraverseDone;

	float TraverseX1, TraverseY1, TraverseZ1;
	float TraverseX2, TraverseY2, TraverseZ2;

	float tMaxX, tMaxY, tMaxZ;
	float tDeltaX, tDeltaY, tDeltaZ;
	int dx, dy, dz;
	int X, Y, Z;

	// this is definetly per ray, cause rays can exit at different cell/grid position/indexes
	int OutX, OutY, OutZ;

	bool mHasBegin;
	bool mHasEnd;

	// macros for fast voxel traversal algoritm in code below
	// original macros disabled, to not be reliant on macro language ! ;)
	// #define SIGN(x) (x > 0 ? 1 : (x < 0 ? -1 : 0))
	// #define FRAC0(x) (x - floorf(x))
	// #define FRAC1(x) (1 - x + floorf(x))

	// note: the floating point type below in these helper functions should match the floating point type in calculateLine
	//       for maximum accuracy and correctness, otherwise problems will occur !
	static float SignSingle( float x );
	static float Frac0Single( float x );
	static float Frac1Single( float x );
	static float MaxSingle( float A, float B );
	static float MinSingle( float A, float B );
};

struct GridData
{
	int MinX, MinY, MinZ;
	int MaxX, MaxY, MaxZ;
};

struct BoundaryData
{
	float MinX, MinY, MinZ;
	float MaxX, MaxY, MaxZ;
};

struct CellData
{
	float Width, Height, Depth;
};

// Skybuck: note using pointers to these data structures might be faster, to make tile traversal more compact in memory/l1/l2 data cache.
// Skybuck: or seperating them into two different data structures.
// Skybuck: for now keeping it together to test this light/shadow casting idea, spent already enough time on it, time to get some good/intersting hopefully cool visuals/renders !
// Skybuck: then maybe optimize and/or restructure later ! ;) =D
// Skybuck: however some performance is necessary to look at it and evaluate it, so I think/hope I have now reached this point
// Skybuck: A level of code quality/data structure quality that will allow me and others to evaluate it and have some ok performance.
struct VoxelRay
{
	VoxelPosition Start;		
	VoxelPosition Stop;

	// Skybuck: accuracy/epsilon experiment for ray stop and voxel corner traversal
	VoxelPositionFloat StopVersion2;




	// Skybuck: not absolutely necessary to store this maybe but doing it anyway for now.
	VoxelPositionFloat TileStartScaled;
	VoxelPositionFloat TileStopScaled;

	TraverseMode traverseMode;
	bool traverseDone;

	TraverseData TileTD;
	TraverseData VoxelTD;

	// maybe fix this later through a TileVoxelTraverseEngine class or struct or something but for now I am gonna let it be
	// because I already spent so much time on restructuring things... I want to debug it and see if it works and how it looks
	// like, yes I know performance is important but it should have some performance already to be able to look at it.
	GridData TileGD;		// this could and should be moved outside to some "engine" so there is only one copy instead of multiple/each time... BOEHOE :(........
	GridData VoxelGD;

	BoundaryData TileBD;
	BoundaryData VoxelBD;

	BoundaryData TileBDScaled;

	CellData TileCD;
	CellData VoxelCD;

	// not used for now.
//	int CollisionTileX, CollisionTileY, CollisionTileZ;
//	int CollisionVoxelX, CollisionVoxelY, CollisionVoxelZ;

	static float Epsilon; // static ? ;)

	bool PointInBoxSingle
	(
		float X, float Y, float Z,
		float BoxX1, float BoxY1, float BoxZ1,
		float BoxX2, float BoxY2, float BoxZ2
	);

	// void ComputeVoxelPosition( float ParaStartX, float ParaStartY, float ParaStartZ, int ParaVoxelX, int ParaVoxelY, int ParaVoxelZ )

	bool IsSinglePoint();
	bool IsSinglePointInTileBoundary();
	void ComputeVoxelPosition( float ParaX, float ParaY, float ParaZ );

	bool VoxelTraverseIsSinglePoint();

	bool IsTileDirect();
	bool IsTileDirectScaled();

	bool IsVoxelDirect();

	bool AreBothPointsInTileBoundary();

	bool IsInsideTileBoundaryScaled();

	bool IsInsideVoxelBoundary();

	bool LineCollidesWithBox
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
	);

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
	);
	bool IsIntersectingTileBoundary();

	bool IsIntersectingTileBoundaryScaled();

	bool IsIntersectingVoxelBoundary();

	void SetupTileDimensions( int ParaTileWidth, int ParaTileHeight, int ParaTileDepth );

	void SetupVoxelDimensions( int ParaVoxelWidth, int ParaVoxelHeight, int ParaVoxelDepth );

	// in grid index coordates, much cooler. can start at a different offset min basically.
	void SetupTileGridData( int ParaMinX, int ParaMinY, int ParaMinZ, int ParaMaxX, int ParaMaxY, int ParaMaxZ );

	void SetupVoxelGridData( int ParaMinX, int ParaMinY, int ParaMinZ, int ParaMaxX, int ParaMaxY, int ParaMaxZ );

	// in some kind of world/voxel coordinates or so...
	void SetupTileBoundary( float ParaMinX, float ParaMinY, float ParaMinZ, float ParaMaxX, float ParaMaxY, float ParaMaxZ );

	// computes tile boundary based on grid data, this can be used as an alternative to setup tile boundary
	void ComputeTileBoundary();

	void ComputeTileBoundaryScaled();

	void ComputeTileStartScaled();

	void ComputeTileStopScaled();
	void ComputeTileStopScaledVersion2();

	void ComputeVoxelBoundary( int ParaTileX, int ParaTileY, int ParaTileZ );

	void SetupTileTraversal();

	void SetupVoxelBoundary( float ParaMinX, float ParaMinY, float ParaMinZ, float ParaMaxX, float ParaMaxY, float ParaMaxZ );

	void SetupVoxelTraversal();

	// maybe do this different with x,y,z individual parameters, would make code usage more independent from these
	// data struvctures, I will probably do that.

	// when the TilevoxelTraverseEngine is created then these tile properties width,height depth can be setup
	// just once... makes it easier to create all kinds of rays in all kinds of positions
	// HEY it could also be usefull to create a setup routine, that can create a ray into a certain direction
	// maybe make the code inside optional so it doesn't check for ending conditions of ray
	// or even better it can compute an almost infite ray... but just extending it outside of the boundary
	// and then clipping it for faster ray ending/exit condition... though it will bounce against
	// the border / boundary anyway if the algorithm/code is working properly ! but it's still a bit risky
	// because of floating point instability but that should be solved mostly, though I cannot 100% garantuee it right now
	// because of fmod... I know complex mambo jambo talk but it might help me later in the future to diagnose problems.
	// or to improve code.

	// version 2 uses a floating point for the stop parameter for hopefull more accuracy inside the (ending) voxel itself.

	// Tile Width, HEight Depth not used for now... use the SetupTileDimension routine to set it up.
	void Setup( VoxelPosition ParaStart, VoxelPosition ParaStop, int TileWidth, int TileHeight, int TileDepth );
	void SetupVersion2( VoxelPosition ParaStart, VoxelPositionFloat ParaStop, int TileWidth, int TileHeight, int TileDepth );

	void QuickSetup();

	void ComputeVoxelGridData( int ParaTileX, int ParaTileY, int ParaTileZ );
	void SetupVoxelTraversal( VoxelPosition ParaStart, VoxelPosition ParaStop, int TileX, int TileY, int TileZ );
	void SetupVoxelTraversalVersion2( VoxelPosition ParaStart, VoxelPositionFloat ParaStop, int TileX, int TileY, int TileZ );

	bool IsTileTraverseDone();
	bool IsVoxelTraverseDone();

	bool IsTraverseDone();

	void NextStep();

	// bool Collision()

	void GetTraverseTilePosition( int *ParaTileX, int *ParaTileY, int *ParaTileZ );

	void GetTraverseVoxelPosition( int *ParaVoxelX, int *ParaVoxelY, int *ParaVoxelZ );

	bool HasTileBegin();
	bool HasVoxelBegin();
};

} // close/de-associate OpenXcom namespace
