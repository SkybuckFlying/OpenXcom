#pragma once

template <typename type>
struct TraverseDimension
{
	<type> mMin, mMax;
};

template <typename type>
bool TraverseDimension<type>.IsOutside( type ParaValue )
{
	if
	(
		(ParaValue < mMin) && (ParaValue > mMax)
	)
	{
		return true;
	}
	else
	{
		return false;
	}
}

