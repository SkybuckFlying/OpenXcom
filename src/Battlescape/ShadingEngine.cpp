#include "ShadingEngine.h"
#include "GenericMap.h"


namespace OpenXcom
{


ShadingEngine::ShadingEngine()
{
	mWidth = 0;
	mHeight = 0;

	mColorMap = new GenericMap<Color>();
	mDepthMap = new GenericMap<int>();
	mLightArray = new LightArray();
	mPixelMap = new GenericMap<Pixel>();
	mHitMap = new GenericMap<int>();
	mLitMap = new GenericMap<bool>();
	mDistanceMap = new GenericMap<double>();
	mExposureMap = new GenericMap<double>();
	mMapPosition = new GenericMap<MapPosition>();
}

ShadingEngine::~ShadingEngine()
{
	delete mMapPosition;
	delete mExposureMap;
	delete mDistanceMap;
	delete mLitMap;
	delete mHitMap;
	delete mPixelMap;
	delete mLightArray;
	delete mDepthMap;
	delete mColorMap;
}

int ShadingEngine::GetWidth()
{
	return mWidth;
}

int ShadingEngine::GetHeight()
{
	return mHeight;
}

void ShadingEngine::SetWidth( int ParaWidth )
{
	// setup depth map and screen stuff
	mColorMap->SetWidth( ParaWidth );
	mDepthMap->SetWidth( ParaWidth );
	mPixelMap->SetWidth( ParaWidth );
	mHitMap->SetWidth( ParaWidth );
	mLitMap->SetWidth( ParaWidth );
	mDistanceMap->SetWidth( ParaWidth );
	mExposureMap->SetWidth( ParaWidth );
	mMapPosition->SetWidth( ParaWidth );
	mWidth = ParaWidth;
}

void ShadingEngine::SetHeight( int ParaHeight )
{
	mColorMap->SetHeight( ParaHeight );
	mDepthMap->SetHeight( ParaHeight );
	mPixelMap->SetHeight( ParaHeight );
	mHitMap->SetHeight( ParaHeight );
	mLitMap->SetHeight( ParaHeight );
	mDistanceMap->SetHeight( ParaHeight );
	mExposureMap->SetHeight( ParaHeight );
	mMapPosition->SetHeight( ParaHeight );
	mHeight = ParaHeight;
}

void ShadingEngine::CollectMapPosition( int x, int y, MapPosition ParaMapPosition )
{
	mMapPosition->SetData( x, y, ParaMapPosition );
}

void ShadingEngine::CollectColor( int x, int y, Color ParaColor )
{
	mColorMap->SetData( x, y, ParaColor );
}

}
