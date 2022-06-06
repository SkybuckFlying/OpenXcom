#pragma once

// Skybuck's Advanced Palette File Format
//
// version 0.01 created on 6 june 2022 by Skybuck Flying
//
// File Format version 1 is limited to 32 bit applications.
//

#pragma pack( push, SkybucksPaletteFileFormatHeader, 1 )

// all structures should be "packed", no padding in between

struct TSkybucksPaletteFileFormatHeader
{
	int mVersion; // 32 bits
};

// all 32 bits
struct TSkybucksPaletteFileFormatPaletteInfoV1
{
	int mEntryCount;   
	int mShift;
	int mRowCount; 
	int mColumnCount;
	int mIntermediateCount;
};

// all 16 bits
struct TSkybucksPaletteFileFormatRGBV1
{
	unsigned short mRed;
	unsigned short mGreen;
	unsigned short mBlue;
};

#pragma pack( pop, SkybucksPaletteFileFormatHeader )
