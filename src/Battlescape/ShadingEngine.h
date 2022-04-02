#pragma once
#include "GenericMap.h"
#include "GenericMap.cpp"
#include "Color.h"
#include "LightArray.h"
#include "..\Engine\Surface.h"

namespace OpenXcom
{

class Surface;

struct MapPosition
{
	int X, Y, Z;
};

struct Pixel
{
	unsigned char Red, Green, Blue, Alpha;
};

class ShadingEngine
{
	// private:
	public:

		int mWidth;
		int mHeight;

		GenericMap<Color> *mColorMap; // holds input colors to be shaded ;)
		GenericMap<int> *mDepthMap;
		LightArray *mLightArray;
		GenericMap<Pixel> *mPixelMap;
		GenericMap<int> *mHitMap;
		GenericMap<bool> *mLitMap;
		GenericMap<double> *mDistanceMap;
		GenericMap<double> *mExposureMap;
		GenericMap<MapPosition> *mMapPosition;

	// public:
		ShadingEngine();
		~ShadingEngine();

		int GetWidth();
		int GetHeight();

		void SetWidth( int ParaWidth );
		void SetHeight( int ParaHeight );

		void CollectMapPosition( int x, int y, MapPosition ParaMapPosition );
		void CollectColor( int x, int y, Color ParaColor );
};

}
