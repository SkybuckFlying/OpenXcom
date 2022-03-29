#pragma once

#include "Light.h"

namespace OpenXcom
{

class LightArray
{
private:

protected:
		int mCount;
		Light *mLight; // array of Light

public:
		LightArray();
		~LightArray();

		int GetCount();
		void SetCount( int ParaCount );

		Light* GetLight( int ParaIndex );
};

}
