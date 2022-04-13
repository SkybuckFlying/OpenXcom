#pragma once

struct VoxelRay
{
	float TileT, VoxelT;

	float TiletMaxX, TiletMaxY, TiletMaxZ;
	float TiletDeltaX, TiletDeltaY, TiletDeltaZ;
	int Tiledx, Tiledy, Tiledz;
	int OutTileX, int OutTileY, int OutTileZ;

	float VoxeltMaxX, VoxeltMaxY, VoxeltMaxZ;
	float VoxeltDeltaX, VoxeltDeltaY, VoxeltDeltaZ;
	int Voxeldx, Voxeldy, Voxeldz;
	int OutVoxelX, int OutVoxelY, int OutVoxelZ;

	int CollisionTileX, CollisionTileY, CollisionTileZ;
	int CollisionVoxelX, CollisionVoxelY, CollisionVoxelZ;



	void NextStep();

};


void VoxelRay::Setup()
{






	TraverseMode = tmTile;

	TileT = 0;
	VoxelT = 0;



}


void VoxelRay::SetupTileTraversal()
{
	// traverse code, fast voxel traversal algorithm
	int Tiledx = SignSingle(Tilex2 - Tilex1);
	if (Tiledx != 0) TiletDeltaX = fmin(Tiledx / (Tilex2 - Tilex1), 10000000.0f); else TiletDeltaX = 10000000.0f;
	if (Tiledx > 0) TiletMaxX = TiletDeltaX * Frac1Single(Tilex1); else TiletMaxX = TiletDeltaX * Frac0Single(Tilex1);
	TileX = (int) Tilex1;

	int Tiledy = SignSingle(Tiley2 - Tiley1);
	if (Tiledy != 0) TiletDeltaY = fmin(Tiledy / (Tiley2 - Tiley1), 10000000.0f); else TiletDeltaY = 10000000.0f;
	if (Tiledy > 0) TiletMaxY = TiletDeltaY * Frac1Single(Tiley1); else TiletMaxY = TiletDeltaY * Frac0Single(Tiley1);
	TileY = (int) Tiley1;

	int Tiledz = SignSingle(Tilez2 - Tilez1);
	if (Tiledz != 0) TiletDeltaZ = fmin(Tiledz / (Tilez2 - Tilez1), 10000000.0f); else TiletDeltaZ = 10000000.0f;
	if (Tiledz > 0) TiletMaxZ = TiletDeltaZ * Frac1Single(Tilez1); else TiletMaxZ = TiletDeltaZ * Frac0Single(Tilez1);
	TileZ = (int) Tilez1;

	if (Tiledx > 0) OutTileX = TileBoundaryMaxX+1; else OutTileX = TileBoundaryMinX-1;
	if (Tiledy > 0) OutTileY = TileBoundaryMaxY+1; else OutTileY = TileBoundaryMinY-1;
	if (Tiledz > 0) OutTileZ = TileBoundaryMaxZ+1; else OutTileZ = TileBoundaryMinZ-1;
}

void VoxelRay:SetupTileBoundary( int ParaMinX, int ParaMinY, int ParaMinZ, int ParaMaxX, int ParaMaxY, int ParaMaxZ )
{
	TileBoundaryMinX = ParaMinX;
	TileBoundaryMinY = ParaMinY;
	TileBoundaryMinZ = ParaMinZ;

	TileBoundaryMaxX = ParaMaxX;
	TileBoundaryMaxY = ParaMaxY;
	TileBoundaryMaxZ = ParaMaxZ;
}

void VoxelRay:SetupVoxelTraversal()
{
	// traverse code, fast voxel traversal algorithm
	int Voxeldx = SignSingle(Voxelx2 - Voxelx1);
	if (Voxeldx != 0) tDeltaX = fmin(Voxeldx / (Voxelx2 - Voxelx1), 10000000.0f); else VoxeltDeltaX = 10000000.0f;
	if (Voxeldx > 0) VoxeltMaxX = VoxeltDeltaX * Frac1Single(Voxelx1); else VoxeltMaxX = VoxeltDeltaX * Frac0Single(Voxelx1);
	VoxelX = (int) Voxelx1;

	int Voxeldy = SignSingle(Voxely2 - Voxely1);
	if (Voxeldy != 0) VoxeltDeltaY = fmin(Voxeldy / (Voxely2 - Voxely1), 10000000.0f); else VoxeltDeltaY = 10000000.0f;
	if (Voxeldy > 0) VoxeltMaxY = tDeltaY * Frac1Single(Voxely1); else VoxeltMaxY = VoxeltDeltaY * Frac0Single(Voxely1);
	VoxelY = (int) Voxely1;

	int Voxeldz = SignSingle(Voxelz2 - Voxelz1);
	if (Voxeldz != 0) VoxeltDeltaZ = fmin(Voxeldz / (Voxelz2 - Voxelz1), 10000000.0f); else VoxeltDeltaZ = 10000000.0f;
	if (Voxeldz > 0) VoxeltMaxZ = VoxeltDeltaZ * Frac1Single(Voxelz1); else VoxeltMaxZ = VoxeltDeltaZ * Frac0Single(Voxelz1);
	VoxelZ = (int) Voxelz1;

	if (Voxeldx > 0) OutVoxelX = vVoxelBoundaryMaxX+1; else OutVoxelX = vVoxelBoundaryMinX-1;
	if (Voxeldy > 0) OutVoxelY = vVoxelBoundaryMaxY+1; else OutVoxelY = vVoxelBoundaryMinY-1;
	if (Voxeldz > 0) OutVoxelZ = vVoxelBoundaryMaxZ+1; else OutVoxelZ = vVoxelBoundaryMinZ-1;
}

void VoxelRay:SetupVoxelBoundary( int ParaMinX, int ParaMinY, int ParaMinZ, int ParaMaxX, int ParaMaxY, int ParaMaxZ )
{
	VoxelBoundaryMinX = ParaMinX;
	VoxelBoundaryMinY = ParaMinY;
	VoxelBoundaryMinZ = ParaMinZ;

	VoxelBoundaryMaxX = ParaMaxX;
	VoxelBoundaryMaxY = ParaMaxY;
	VoxelBoundaryMaxZ = ParaMaxZ;
}



bool VoxelRay::Done()
{
	if (TraverseMode == tmTile)
	{
		if (TileT <= 1.0)
		{
			return false;
		} else
		{
			return true;
		}
	)
	else
	{
		if (VoxelT <= 1.0)
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
	if TraverseMode == tmDirect


	// traverse tiles
	if (TraverseMode == tmTile)
	{
		// go to next voxel
		if ( (TiletMaxX < TiletMaxY) && (TiletMaxX < TiletMaxZ) )
		{
			TileT = TiletMaxX;
			TileX += Tiledx;
			TiletMaxX += TiletDeltaX;

			if (TileX == OutTileX) break;
		}
		else
		if (TiletMaxY < TiletMaxZ)
		{
			TileT = TiletMaxY;
			TileY += Tiledy;
			TiletMaxY += TiletDeltaY;

			if (TileY == OutTileY) break;
		}
		else
		{
			TileT = TiletMaxZ;
			TileZ += Tiledz;
			TiletMaxZ += TiletDeltaZ;

			if (TileZ == OutTileZ) break;
		}


	} else
	// traverse voxels
	{
		// go to next voxel
		if ( (VoxeltMaxX < VoxeltMaxY) && (VoxeltMaxX < VoxeltMaxZ) )
		{
			VoxelT = VoxeltMaxX;
			VoxelX += Voxeldx;
			VoxeltMaxX += VoxeltDeltaX;

			if (VoxelX == OutVoxelX) break;
		}
		else
		if (VoxeltMaxY < VoxeltMaxZ)
		{
			VoxelT = VoxeltMaxY;
			VoxelY += Voxeldy;
			VoxeltMaxY += VoxeltDeltaY;

			if (VoxelY == OutVoxelY) break;
		}
		else
		{
			VoxelT = VoxeltMaxZ;
			VoxelZ += Voxeldz;
			VoxeltMaxZ += VoxeltDeltaZ;

			if (VoxelZ == OutVoxelZ) break;
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

	// if single point then
	if ( (x1==x2) && (y1==y2) && (z1==z2) )
	{
		// check if point in grid
		if
		(
			PointInBoxSingle
			(
				x1, y1, z1,

				vMapVoxelBoundaryMinX,
				vMapVoxelBoundaryMinY,
				vMapVoxelBoundaryMinZ,

				vMapVoxelBoundaryMaxX-Epsilon,
				vMapVoxelBoundaryMaxY-Epsilon,
				vMapVoxelBoundaryMaxZ-Epsilon
			) == true
		)
		{
			// process voxel
			VoxelX = x1;
			VoxelY = y1;
			VoxelZ = z1;

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
	else
	{
		// check if both points are in grid
		if
		(
			PointInBoxSingle
			(
				x1, y1, z1,

				vMapVoxelBoundaryMinX,
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

