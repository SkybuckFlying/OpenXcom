
/*

Instead of computing start/stop coordinates for intersections, StartT and StopT could also be computed..

and then later start and stop points can be computed when necessary... because it might not always be necessary to compute
the end point or so or start point if going backward.

Plus the compute code can be re-used for other purposes... like making the ray longer and what not...

StartT could initially be zero... and then later changed if the line/ray needs to be clipped
StopT could initially be one... and then later changed if the line/ray needs to be clipped...

however this does change the algorithm a little bit...  this might becoming a little bit confusing...
is 1.0 now StopT or is 1.0 end of ray.... so it's a bit weird. haha

// maybe call it BeginT and EndT to disassociate it with the start and stop coordiantes... but those could eventually
also be modified... but if that happens then length could be re-computed and thus... there is somewhat
of a disconnect between these concepts... which is weird...

how about we call it TraceStart and TraceEnd... that might be more understandable... and let the rest be

TraceStartT and TraceStopT to somewhat associate it with T basically a distance on a line.

*/


template <typename FPT, typename IT> // FPT = Floating Point Type, IT = Integer Type
struct TraverseRay
{
	bool mHasStartPoint, mHasStopPoint;

	FPT mStartX, mStartY, mStartZ; 
	FPT mStopX, mStopY, mStopZ;
	FPT mDirectionX, mDirectionY, mDirectionZ;

	FPT T, TraceStartT, TraceStopT;

	IT mCellX, mCellY, mCellZ;

	IT mMinCellX, mMinCellY, mMinCellZ;
	IT mMaxCellX, mMaxCellY, mMaxCellZ;

};


TraverseRay::HasBegin()
{


}

template <typename FPT, typename IT>
bool TraverseRay<FPT,IT>::HasStartPoint()
{
	return mHasStartPoint;
}

template <typename FPT, typename IT>
bool TraverseRay<FPT,IT>::HasStopPoint()
{
	return mHasStopPoint;
}

template <typename FPT, typename IT>
bool TraverseRay<FPT,IT>::IsBeyond()
{
	if
	(
		(T < 0.0) || (T > 1.0)
	)
	{
		return true;
	}
	else
	{
		return false;
	}
}

template <typename FPT, typename IT>
bool TraverseRay<FPT,IT>::IsBeyondBegin()
{
	if (T < 0.0)
	{
		return true;
	} else
	{
		return false;
	}
}

template <typename FPT, typename IT>
bool TraverseRay<FPT,IT>::IsBeyondEnd()
{
	if (T > 1.0) 
	{
		return true;
	} else
	{
		return false;
	}
}

template <typename FPT, typename IT>
void TraverseRay<FPT,IT>::GoToNextCellX()
{
	T = tMaxX; // store previous T for X along ray
	mCellX += dx;   // step to next cell 
	tMaxX += tDeltaX; // move T forward along ray for DeltaX distance
}

template <typename FPT, typename IT>
void TraverseRay<FPT,IT>::GoToPrevCellX()
{
	T = tMaxX; // store previous T for X along ray
	mCellX -= dx;   // step to previous cell 
	tMaxX -= tDeltaX; // move T backward along ray for DeltaX distance
}

template <typename FPT, typename IT>
void TraverseRay<FPT,IT>::GoToNextCellY()
{
	T = tMaxY; // store previous T for Y along ray
	mCellY += dy;   // step to next cell 
	tMaxY += tDeltaY; // move T forward along ray for DeltaY distance
}

template <typename FPT, typename IT>
void TraverseRay<FPT,IT>::GoToPrevCellY()
{
	T = tMaxY; // store previous T for Y along ray
	mCellY -= dy;   // step to previous cell 
	tMaxY -= tDeltaY; // move T backward along ray for DeltaY distance
}

template <typename FPT, typename IT>
void TraverseRay<FPT,IT>::GoToNextCellZ()
{
	T = tMaxZ; // store previous T for Y along ray
	mCellZ += dz;   // step to next cell 
	tMaxZ += tDeltaZ; // move T forward along ray for DeltaZ distance
}

template <typename FPT, typename IT>
void TraverseRay<FPT,IT>::GoToPrevCellZ()
{
	T = tMaxZ; // store previous T for Z along ray
	mCellZ -= dz;   // step to previous cell 
	tMaxZ -= tDeltaZ; // move T backward along ray for DeltaZ distance
}

template <typename FPT, typename IT>
bool TraverseRay<FPT,IT>::IsCellXOutside()
{
	if
	(
		(mCellX < mMinCellX) || (mCellX > mMaxCellX)
	)
	{
		return true;
	} else
	{
		return false;
	}
}

template <typename FPT, typename IT>
bool TraverseRay<FPT,IT>::IsCellYOutside()
{
	if
	(
		(mCellY < mMinCellY) || (mCellY > mMaxCellY)
	)
	{
		return true;
	} else
	{
		return false;
	}
}

template <typename FPT, typename IT>
bool TraverseRay<FPT,IT>::IsCellZOutside()
{
	if
	(
		(mCellZ < mMinCellZ) || (mCellZ > mMaxCellZ)
	)
	{
		return true;
	} else
	{
		return false;
	}
}

template <typename FPT, typename IT>
void TraverseRay<FPT,IT>::StepForward()
{
	if
	(
		(tMaxX < tMaxY) &&
		(tMaxX < tMaxZ)
	)
	{
		GoToNextCellX();

		if (IsCellXOutside())
		{
			ForwardDone = true;
			return;
		}
	}
	else
	if (tMaxY < tMaxZ)
	{
		GoToNextCellY();

		if (IsCellYOutside())
		{
			ForwardDone = true;
			return;
		}
	}
	else
	{
		GoToNextCellZ();

		if (IsCellZOutside())
		{
			ForwardDone = true;
			return;
		}
	}
}

template <typename FPT, typename IT>
void TraverseRay<FPT,IT>::StepBackward()
{
	if
	(
		(tMaxX > tMaxY) &&
		(tMaxX > tMaxZ)
	)
	{
		GoToPrevCellX();

		if (IsCellXOutside())
		{
			BackwardDone = true;
			return;
		}
	}
	else
	if (tMaxY > tMaxZ)
	{
		GoToPrevCellY();

		if (IsCellYOutside())
		{
			BackwardDone = true;
			return;
		}
	}
	else
	{
		GoToPrevCellZ();

		if (IsCellZOutside())
		{
			BackwardDone = true;
			return;
		}
	}
}

template <typename FPT, typename IT>
void TraverseRay<FPT,IT>::SetStartPoint( FPT ParaX, FPT ParaY, FPT ParaZ )
{
	mHasStartPoint = true;
	mStartX = ParaX;
	mStartY = ParaY;
	mStartZ = ParaZ;
}

template <typename FPT, typename IT>
void TraverseRay<FPT,IT>::SetStopPoint( FPT ParaX, FPT ParaY, FPT ParaZ )
{
	mHasStopPoint = true;
	mStopX = ParaX;
	mStopY = ParaY;
	mStopZ = ParaZ;
}

template <typename FPT, typename IT>
void TraverseRay<FPT,IT>::SetDirection( FPT ParaX, FPT ParaY, FPT ParaZ )
{
	mDirectionX = ParaX;
	mDirectionY = ParaY;
	mDirectionZ = ParaZ;
}

template <typename FPT, typename IT>
void TraverseRay<FPT,IT>::IsSinglePoint()
{
	if
	(
		(mHasStartPoint) && (mHasStopPoint)
	)
	{
		if 
		(
			(mStartX == mStopX) &&
			(mStartY == mStopY) &&
			(mStartZ == mStopZ)

		)
		{
			return true;
		}
		else
		{
			return false;
		}
	}
}

template <typename FPT, typename IT>
void TraverseRay<FPT,IT>::GetCell( IT *ParaCellX, IT *ParaCellY, IT *ParaCellZ )
{
	*ParaCellX = mCellX;
	*ParaCellY = mCellY;
	*ParaCellZ = mCellZ;

	// I could actually also write:
//	*ParaCellX = CellX + GridStartX; // if I wanted to offset the cells from some kind of starting position
//	*ParaCellY = CellY + GridMinY; // or some kind of min Y.. maybe I will do it have not yet made a decision but it would be fully complete then. sort of
//	*ParaCellZ = CellZ;


}




// I don't know yet about this... overwriting nice fields, could be dangerous
// but I also don't want to use extra fields for speeeeed, but this code is alread ya little bit slower than usual.. hmm
// but lets not degrade it anyfurther.
template <typename FPT, typename IT>
void TraverseRay<FPT,IT>::ScaleDown( const TraverseCell ParaTraverseCell )
{
	mStartX /= ParaTraverseCell.mCellWidth;
	mStartY /= ParaTraverseCell.mCellHeight;
	mStartZ /= ParaTraverseCell.mCellDepth;

	mStopX /= ParaTraverseCell.mCellWidth;
	mStopY /= ParaTraverseCell.mCellHeight;
	mStopZ /= ParaTraverseCell.mCellDepth;
}
