#include "AdvancedPalette.h"
#include <fstream>
#include "SkybucksAdvancedPaletteFileFormat_version_001.h"

// struct AdvancedPalette8bit GlobalAdvancedPalette8bit;

AdvancedPalette8bit::AdvancedPalette8bit()
{
	mEntry = 0;
	mEntryCount = 0;
	mEntryCount = 0;
	mShift = 0;
	mRowCount = 0;
	mColumnCount = 0;
	mIntermediateCount = 0;
}

AdvancedPalette8bit::~AdvancedPalette8bit()
{
	delete[] mEntry;
}

bool AdvancedPalette8bit::SanityCheckPaletteInfo()
{
	bool vResult = false;

	if (mEntryCount > 0)
	{
		if (mColumnCount < mEntryCount)
		{
			if (mIntermediateCount < mColumnCount)
			{
				vResult = true;
			}
		}
	}
	return vResult;
}

bool AdvancedPalette8bit::LoadFromFile( std::string ParaFilename )
{
	bool vResult = false;
	struct TSkybucksPaletteFileFormatHeader vHeader;
	struct TSkybucksPaletteFileFormatPaletteInfoV1 vPaletteInfoV1;
	struct TSkybucksPaletteFileFormatRGBV1 vRGBV1;
	int vIndex;

	// Load file and put colors in palette
	std::ifstream vFileStream(ParaFilename.c_str(), std::ios::in | std::ios::binary);

	if (vFileStream)
	{
		vFileStream.seekg( 0, std::ios::beg);

		// read header
		vFileStream.read( (char *)(&vHeader), sizeof(TSkybucksPaletteFileFormatHeader) );

		if (vHeader.mVersion == 1)
		{
			// read palette info v1
			vFileStream.read( (char *)(&vPaletteInfoV1), sizeof(TSkybucksPaletteFileFormatPaletteInfoV1) );

			// assign values to structure fields
			mEntryCount = vPaletteInfoV1.mEntryCount;
			mShift = vPaletteInfoV1.mShift;
			mRowCount = vPaletteInfoV1.mRowCount;
			mColumnCount = vPaletteInfoV1.mColumnCount;
			mIntermediateCount = vPaletteInfoV1.mIntermediateCount;

			// perform sanity checking
			if (SanityCheckPaletteInfo())
			{
				// extra check just in case
				if (mEntryCount > 0)
				{
					// re-create array
					// delete old one
					delete mEntry;

					// create new one
					mEntry = new AdvancedColor8bit[mEntryCount]; 

					// loop all entries
					for (vIndex=0; vIndex<mEntryCount; vIndex++)
					{
						// read RGB version 1 values
						vFileStream.read( (char *)(&vRGBV1), sizeof(TSkybucksPaletteFileFormatRGBV1) );	

						// store RGB values in entry
						mEntry[vIndex].mRed = vRGBV1.mRed;
						mEntry[vIndex].mGreen = vRGBV1.mGreen;
						mEntry[vIndex].mBlue = vRGBV1.mBlue;
					}

					// if everything went ok and code reaches here the result is true
					vResult = true;
				}
			}
		}
	}

	vFileStream.close();

	return vResult;
}

AdvancedColor8bit AdvancedPalette8bit::ConvertToAdvancedColor( int ParaOriginalColor )
{
	int vAdvancedIndex;
	AdvancedColor8bit vAdvancedColor;

	vAdvancedIndex = ParaOriginalColor << mShift;
	vAdvancedColor = mEntry[vAdvancedIndex];

	return vAdvancedColor;

}

