#include "AdvancedColor.h"

unsigned int AdvancedColor8bit::ConvertToUint32()
{
	// return ((Uint32) mRed << 24) | ((Uint32) mGreen << 16) | ((Uint32) mBlue << 8) | (Uint32) 0xFF;

	return ((unsigned int) mRed << 24) | ((unsigned int) mGreen << 16) | ((unsigned int) mBlue << 8) | (unsigned int) 0xFF;
}
