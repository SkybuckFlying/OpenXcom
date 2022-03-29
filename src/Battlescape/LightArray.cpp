#include "LightArray.h"

namespace OpenXcom
{


LightArray::LightArray()
{
	mCount = 0;
	mLight = nullptr;
}

LightArray::~LightArray()
{
	delete[] mLight;
}

int LightArray::GetCount()
{
	return mCount;
}

void LightArray::SetCount( int ParaCount )
{
	mLight = new Light[ParaCount];
	mCount = ParaCount;
}

Light* LightArray::GetLight( int ParaIndex )
{
	return &mLight[ ParaIndex ];
}

}
