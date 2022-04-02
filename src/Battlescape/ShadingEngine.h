#pragma once
#include "GenericMap.h"
#include "GenericMap.cpp"
#include "Color.h"
#include "LightArray.h"
#include "..\Engine\Surface.h"

namespace OpenXcom
{

class Surface;

struct Pixel
{
	unsigned char Red, Green, Blue, alpha;
};

class ShadingEngine
{
	private:

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
		GenericMap<Surface*> *mSurfaceMap;

	public:
		ShadingEngine();
		~ShadingEngine();

		int GetWidth();
		int GetHeight();

		void SetWidth( int ParaWidth );
		void SetHeight( int ParaHeight );

		void CollectData( int x, int y, Surface *ParaSource );
};

}
