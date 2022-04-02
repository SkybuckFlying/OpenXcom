#include "GenericMap.h"

namespace OpenXcom
{


// constructor
template <class GenericType>
GenericMap<GenericType>::GenericMap()
{
	mWidth = 0;
	mHeight = 0;
	mData = 0;
}

// destructor
template <class GenericType>
GenericMap<GenericType>::~GenericMap()
{
	if (mData != 0)
	{
		delete[] mData;
	}
}

template <class GenericType>
void GenericMap<GenericType>::ReSize( int ParaWidth, int ParaHeight )
{
	if (mData != 0)
	{
		delete[] mData;
	}
	if ((ParaHeight * ParaWidth) > 0)
	{
		mData = new GenericType[ ParaHeight * ParaWidth ];
	}
}

template <class GenericType>
int GenericMap<GenericType>::GetWidth()
{
	return mWidth;
}

template <class GenericType>
void GenericMap<GenericType>::SetWidth( int ParaValue )
{
	ReSize( ParaValue, mHeight );
	mWidth = ParaValue;
}

template <class GenericType>
int GenericMap<GenericType>::GetHeight()
{
	return mHeight;
}

template <class GenericType>
void GenericMap<GenericType>::SetHeight( int ParaValue )
{
	ReSize( mWidth, ParaValue );
	mHeight = ParaValue;
}
template <class GenericType>
void GenericMap<GenericType>::SetData( int ParaX, int ParaY, GenericType ParaValue )
{
	// Skybuck: temporally for debugging purposes, stay within range blablablabal.
	if
	(
		(ParaX >= 0) && (ParaX < mWidth) &&
		(ParaY >= 0) && (ParaY < mHeight)
	)
	{
		mData[ ParaY * mWidth + ParaX ] = ParaValue;
	}
}

template <class GenericType>
GenericType GenericMap<GenericType>::GetData( int ParaX, int ParaY )
{
	return mData[ ParaY * mWidth + ParaX ];
}


}


