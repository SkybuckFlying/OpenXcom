#pragma once

#include "xyzDouble.h"
#include "Color.h"

namespace OpenXcom
{

struct Light
{
		xyzDouble mPosition;
		xyzDouble mMovementDirection;
		Color mColor;

		// unsigned int Padding : longword; // wtf is this ?!?!

		double Power;
		double Range;
};

}
