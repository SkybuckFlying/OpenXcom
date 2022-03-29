#include "GenericMap.h"

namespace OpenXcom
{


// constructor
template <class GenericType>
GenericMap<GenericType>::GenericMap()
{

}

// destructor
template <class GenericType>
GenericMap<GenericType>::~GenericMap()
{
	delete[] mData;
}

template <class GenericType>
void GenericMap<GenericType>::ReSize( int ParaWidth, int ParaHeight )
{
	delete[] mData;
	mData = new GenericType[ ParaHeight * ParaWidth ]; 
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
	mData[ ParaY * mWidth + ParaX ] = ParaValue;
}

template <class GenericType>
GenericType GenericMap<GenericType>::GetData( int ParaX, int ParaY )
{
	return mData[ ParaY * mWidth + ParaX ];
}


}


