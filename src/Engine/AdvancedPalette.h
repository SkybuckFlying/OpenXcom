#pragma once

// Skybuck's Advanced Palette
//
// version 0.01 created on 6 june 2022 by Skybuck Flying
//
// only the 8 bit version is implemented.
// 8 bit in this case means the r,g,b components are 8 bit each
// the number of entries can be much more than just vga 0..63 or modern vga 0..255
// current plan is to use 7000+ colors to make game look more beautifull when shaded.
// later when 48 bit monitor support is desired, perhaps colors can be further increased
// however this would result in major Level1 cache usage and maybe overflow,
// in that case a "real-time" computational solution would have to be found.
// currently this is a bit difficult, due to the shift operation producing non-power of 2
// results for 0..15 the original row count. For example 15 << 5.

#include <string>
#include "AdvancedColor.h"

struct AdvancedPalette8bit
{
	AdvancedColor8bit *mEntry; // array

	int mEntryCount;
	int mShift;
	int mRowCount;
	int mColumnCount;
	int mIntermediateCount;

	AdvancedPalette8bit();
	~AdvancedPalette8bit();

	bool SanityCheckPaletteInfo();
	bool LoadFromFile( std::string ParaFilename );
};

// extern struct AdvancedPalette8bit GlobalAdvancedPalette8bit;

// for the future
struct AdvcancedPalette16bit
{
	AdvancedColor16bit *mEntry; // array

	int mEntryCount;
	int mShift;
	int mRowCount;
	int mColumnCount;
	int mIntermediateCount;
};



