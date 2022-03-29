#pragma once

namespace OpenXcom
{

template <class GenericType>
class GenericMap
{
	private:
		int mWidth;
		int mHeight;
		GenericType *mData;

		void ReSize( int ParaWidth, int ParaHeight  );

	public:
		GenericMap();
		~GenericMap();

		int GetWidth();
		void SetWidth( int ParaValue );

		int GetHeight();
		void SetHeight( int ParaValue );

		void SetData( int ParaX, int ParaY, GenericType ParaValue ); 
		GenericType GetData( int ParaX, int ParaY );
};


}
