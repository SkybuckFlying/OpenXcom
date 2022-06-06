#pragma once

struct AdvancedColor8bit
{
	unsigned char mRed;
	unsigned char mGreen;
	unsigned char mBlue;

	unsigned int ConvertToUint32();
};

struct AdvancedColor16bit
{
	unsigned short mRed;
	unsigned short mGreen;
	unsigned short mBlue;
};



