/*
 * Copyright 2010-2016 OpenXcom Developers.
 *
 * This file is part of OpenXcom.
 *
 * OpenXcom is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * OpenXcom is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with OpenXcom.  If not, see <http://www.gnu.org/licenses/>.
 */
#include "Map.h"
#include "Camera.h"
#include "UnitSprite.h"
#include "Pathfinding.h"
#include "TileEngine.h"
#include "Projectile.h"
#include "Explosion.h"
#include "BattlescapeState.h"
#include "Particle.h"
#include "../Mod/Mod.h"
#include "../Engine/Action.h"
#include "../Engine/SurfaceSet.h"
#include "../Engine/Timer.h"
#include "../Engine/Language.h"
#include "../Engine/Palette.h"
#include "../Engine/Game.h"
#include "../Engine/Screen.h"
#include "../Savegame/SavedBattleGame.h"
#include "../Savegame/Tile.h"
#include "../Savegame/BattleUnit.h"
#include "../Savegame/BattleItem.h"
#include "../Mod/RuleItem.h"
#include "../Mod/RuleInterface.h"
#include "../Mod/MapDataSet.h"
#include "../Mod/MapData.h"
#include "../Mod/Armor.h"
#include "BattlescapeMessage.h"
#include "../Savegame/SavedGame.h"
#include "../Interface/NumberText.h"
#include "../Interface/Text.h"
#include "../fmath.h"


/*
  1) Map origin is top corner.
  2) X axis goes downright. (width of the map)
  3) Y axis goes downleft. (length of the map
  4) Z axis goes up (height of the map)

           0,0
			/\
	    y+ /  \ x+
		   \  /
		    \/
 */

namespace OpenXcom
{

/**
 * Sets up a map with the specified size and position.
 * @param game Pointer to the core game.
 * @param width Width in pixels.
 * @param height Height in pixels.
 * @param x X position in pixels.
 * @param y Y position in pixels.
 * @param visibleMapHeight Current visible map height.
 */
Map::Map(Game *game, int width, int height, int x, int y, int visibleMapHeight) : InteractiveSurface(width, height, x, y), _game(game), _arrow(0), _selectorX(0), _selectorY(0), _mouseX(0), _mouseY(0), _cursorType(CT_NORMAL), _cursorSize(1), _animFrame(0), _projectile(0), _projectileInFOV(false), _explosionInFOV(false), _launch(false), _visibleMapHeight(visibleMapHeight), _unitDying(false), _smoothingEngaged(false), _flashScreen(false), _projectileSet(0), _showObstacles(false)
{
	_iconHeight = _game->getMod()->getInterface("battlescape")->getElement("icons")->h;
	_iconWidth = _game->getMod()->getInterface("battlescape")->getElement("icons")->w;
	_messageColor = _game->getMod()->getInterface("battlescape")->getElement("messageWindows")->color;

	_previewSetting = Options::battleNewPreviewPath;
	_smoothCamera = Options::battleSmoothCamera;
	if (Options::traceAI)
	{
		// turn everything on because we want to see the markers.
		_previewSetting = PATH_FULL;
	}
	_save = _game->getSavedGame()->getSavedBattle();
	if ((int)(_game->getMod()->getLUTs()->size()) > _save->getDepth())
	{
		_transparencies = &_game->getMod()->getLUTs()->at(_save->getDepth());
	}

	_spriteWidth = _game->getMod()->getSurfaceSet("BLANKS.PCK")->getFrame(0)->getWidth();
	_spriteHeight = _game->getMod()->getSurfaceSet("BLANKS.PCK")->getFrame(0)->getHeight();
	_message = new BattlescapeMessage(320, (visibleMapHeight < 200)? visibleMapHeight : 200, 0, 0);
	_message->setX(_game->getScreen()->getDX());
	_message->setY((visibleMapHeight - _message->getHeight()) / 2);
	_message->setTextColor(_messageColor);
	_camera = new Camera(_spriteWidth, _spriteHeight, _save->getMapSizeX(), _save->getMapSizeY(), _save->getMapSizeZ(), this, visibleMapHeight);
	_scrollMouseTimer = new Timer(SCROLL_INTERVAL);
	_scrollMouseTimer->onTimer((SurfaceHandler)&Map::scrollMouse);
	_scrollKeyTimer = new Timer(SCROLL_INTERVAL);
	_scrollKeyTimer->onTimer((SurfaceHandler)&Map::scrollKey);
	_camera->setScrollTimer(_scrollMouseTimer, _scrollKeyTimer);
	_obstacleTimer = new Timer(2500);
	_obstacleTimer->stop();
	_obstacleTimer->onTimer((SurfaceHandler)&Map::disableObstacles);

	_txtAccuracy = new Text(24, 9, 0, 0);
	_txtAccuracy->setSmall();
	_txtAccuracy->setPalette(_game->getScreen()->getPalette());
	_txtAccuracy->setHighContrast(true);
	_txtAccuracy->initText(_game->getMod()->getFont("FONT_BIG"), _game->getMod()->getFont("FONT_SMALL"), _game->getLanguage());
}

/**
 * Deletes the map.
 */
Map::~Map()
{
	delete _scrollMouseTimer;
	delete _scrollKeyTimer;
	delete _obstacleTimer;
	delete _arrow;
	delete _message;
	delete _camera;
	delete _txtAccuracy;
}

/**
 * Initializes the map.
 */
void Map::init()
{
	// load the tiny arrow into a surface
	int f = Palette::blockOffset(1); // yellow
	int b = 15; // black
	int pixels[81] = { 0, 0, b, b, b, b, b, 0, 0,
					   0, 0, b, f, f, f, b, 0, 0,
					   0, 0, b, f, f, f, b, 0, 0,
					   b, b, b, f, f, f, b, b, b,
					   b, f, f, f, f, f, f, f, b,
					   0, b, f, f, f, f, f, b, 0,
					   0, 0, b, f, f, f, b, 0, 0,
					   0, 0, 0, b, f, b, 0, 0, 0,
					   0, 0, 0, 0, b, 0, 0, 0, 0 };

	_arrow = new Surface(9, 9);
	_arrow->setPalette(this->getPalette());
	_arrow->lock();
	for (int y = 0; y < 9;++y)
		for (int x = 0; x < 9; ++x)
			_arrow->setPixel(x, y, pixels[x+(y*9)]);
	_arrow->unlock();

	_projectile = 0;
	if (_save->getDepth() == 0)
	{
		_projectileSet = _game->getMod()->getSurfaceSet("Projectiles");
	}
	else
	{
		_projectileSet = _game->getMod()->getSurfaceSet("UnderwaterProjectiles");
	}
}

/**
 * Keeps the animation timers running.
 */
void Map::think()
{
	_scrollMouseTimer->think(0, this);
	_scrollKeyTimer->think(0, this);
	_obstacleTimer->think(0, this);
}

/**
 * Draws the whole map, part by part.
 */
void Map::draw()
{
	if (!_redraw)
	{
		return;
	}

	// normally we'd call for a Surface::draw();
	// but we don't want to clear the background with colour 0, which is transparent (aka black)
	// we use colour 15 because that actually corresponds to the colour we DO want in all variations of the xcom and tftd palettes.
	_redraw = false;
	clear(Palette::blockOffset(0)+15);

	Tile *t;

	_projectileInFOV = _save->getDebugMode();
	if (_projectile)
	{
		t = _save->getTile(Position(_projectile->getPosition(0).x/16, _projectile->getPosition(0).y/16, _projectile->getPosition(0).z/24));
		if (_save->getSide() == FACTION_PLAYER || (t && t->getVisible()))
		{
			_projectileInFOV = true;
		}
	}
	_explosionInFOV = _save->getDebugMode();
	if (!_explosions.empty())
	{
		for (std::list<Explosion*>::iterator i = _explosions.begin(); i != _explosions.end(); ++i)
		{
			t = _save->getTile(Position((*i)->getPosition().x/16, (*i)->getPosition().y/16, (*i)->getPosition().z/24));
			if (t && ((*i)->isBig() || t->getVisible()))
			{
				_explosionInFOV = true;
				break;
			}
		}
	}

	if ((_save->getSelectedUnit() && _save->getSelectedUnit()->getVisible()) || _unitDying || _save->getSelectedUnit() == 0 || _save->getDebugMode() || _projectileInFOV || _explosionInFOV)
	{
		drawTerrain(this);
	}
	else
	{
		_message->blit(this);
	}
}

/**
 * Replaces a certain amount of colors in the surface's palette.
 * @param colors Pointer to the set of colors.
 * @param firstcolor Offset of the first color to replace.
 * @param ncolors Amount of colors to replace.
 */
void Map::setPalette(SDL_Color *colors, int firstcolor, int ncolors)
{
	Surface::setPalette(colors, firstcolor, ncolors);
	for (std::vector<MapDataSet*>::const_iterator i = _save->getMapDataSets()->begin(); i != _save->getMapDataSets()->end(); ++i)
	{
		(*i)->getSurfaceset()->setPalette(colors, firstcolor, ncolors);
	}
	_message->setPalette(colors, firstcolor, ncolors);
	_message->setBackground(_game->getMod()->getSurface("TAC00.SCR"));
	_message->initText(_game->getMod()->getFont("FONT_BIG"), _game->getMod()->getFont("FONT_SMALL"), _game->getLanguage());
	_message->setText(_game->getLanguage()->getString("STR_HIDDEN_MOVEMENT"));
}

/**
 * Check two positions if have same XY cords
 */
static bool positionHaveSameXY(Position a, Position b)
{
	return a.x == b.x && a.y == b.y;
}

/**
 * Draw part of unit graphic that overlap current tile.
 * @param surface
 * @param unitTile
 * @param currTile
 * @param currTileScreenPosition
 * @param shade
 * @param obstacleShade unitShade override for no LOF obstacle indicator
 * @param topLayer
 */
void Map::drawUnit(Surface *surface, Tile *unitTile, Tile *currTile, Position currTileScreenPosition, int shade, int obstacleShade, bool topLayer)
{
	const int tileFoorWidth = 32;
	const int tileFoorHeight = 16;
	const int tileHeight = 40;

	if (!unitTile)
	{
		return;
	}
	BattleUnit* bu = unitTile->getUnit();
	Position unitOffset;
	bool unitFromBelow = false;
	if (!bu)
	{
		Tile *below = _save->getTile(unitTile->getPosition() + Position(0,0,-1));
		if (below && unitTile->hasNoFloor(below))
		{
			bu = below->getUnit();
			if (!bu)
			{
				return;
			}
			unitFromBelow = true;
		}
		else
		{
			return;
		}
	}

	if (!(bu->getVisible() || _save->getDebugMode()))
	{
		return;
	}

	unitOffset.x = unitTile->getPosition().x - bu->getPosition().x;
	unitOffset.y = unitTile->getPosition().y - bu->getPosition().y;
	int part = unitOffset.x + unitOffset.y*2;
	Surface *tmpSurface = bu->getCache(part);
	if (!tmpSurface)
	{
		return;
	}

	bool moving = bu->getStatus() == STATUS_WALKING || bu->getStatus() == STATUS_FLYING;
	int bonusWidth = moving ? 0 : tileFoorWidth;
	int topMargin = 0;
	int bottomMargin = 0;

	//if unit is from below then we draw only part that in in tile
	if (unitFromBelow)
	{
		bottomMargin = -tileFoorHeight / 2;
		topMargin = tileFoorHeight;
	}
	else if (topLayer)
	{
		topMargin = 2 * tileFoorHeight;
	}
	else
	{
		Tile *top = _save->getTile(unitTile->getPosition() + Position(0, 0, +1));
		if (top && top->hasNoFloor(unitTile))
		{
			topMargin = -tileFoorHeight / 2;
		}
		else
		{
			topMargin = tileFoorHeight;
		}
	}

	GraphSubset mask = GraphSubset(tileFoorWidth + bonusWidth, tileHeight + topMargin + bottomMargin).offset(currTileScreenPosition.x - bonusWidth / 2, currTileScreenPosition.y - topMargin);

	if (moving)
	{
		GraphSubset leftMask = mask.offset(-tileFoorWidth/2, 0);
		GraphSubset rightMask = mask.offset(+tileFoorWidth/2, 0);
		int direction = bu->getDirection();
		Position partCurr = currTile->getPosition();
		Position partDest = bu->getDestination() + unitOffset;
		Position partLast = bu->getLastPosition() + unitOffset;
		bool isTileDestPos = positionHaveSameXY(partDest, partCurr);
		bool isTileLastPos = positionHaveSameXY(partLast, partCurr);

		//adjusting mask
		if (positionHaveSameXY(partLast, partDest))
		{
			if (currTile == unitTile)
			{
				//no change
			}
			else
			{
				//nothing to draw
				return;
			}
		}
		else if (isTileDestPos)
		{
			//unit is moving to this tile
			switch (direction)
			{
			case 0:
			case 1:
				mask = GraphSubset::intersection(mask, rightMask);
				break;
			case 2:
				//no change
				break;
			case 3:
				//no change
				break;
			case 4:
				//no change
				break;
			case 5:
			case 6:
				mask = GraphSubset::intersection(mask, leftMask);
				break;
			case 7:
				//nothing to draw
				return;
			}
		}
		else if (isTileLastPos)
		{
			//unit is exiting this tile
			switch (direction)
			{
			case 0:
				//no change
				break;
			case 1:
			case 2:
				mask = GraphSubset::intersection(mask, leftMask);
				break;
			case 3:
				//nothing to draw
				return;
			case 4:
			case 5:
				mask = GraphSubset::intersection(mask, rightMask);
				break;
			case 6:
				//no change
				break;
			case 7:
				//no change
				break;
			}
		}
		else
		{
			Position leftPos = partCurr + Position(-1, 0, 0);
			Position rightPos = partCurr + Position(0, -1, 0);
			if (!topLayer && (partDest.z > partCurr.z || partLast.z > partCurr.z))
			{
				//unit change layers, it will be drawn by upper layer not lower.
				return;
			}
			else if (
				(direction == 1 && (partDest == rightPos || partLast == leftPos)) ||
				(direction == 5 && (partDest == leftPos || partLast == rightPos)))
			{
				mask = GraphSubset(tileFoorWidth, tileHeight + 2 * tileFoorHeight).offset(currTileScreenPosition.x, currTileScreenPosition.y - 2 * tileFoorHeight);
			}
			else
			{
				//unit is not moving close to tile
				return;
			}
		}
	}
	else if (unitTile != currTile)
	{
		return;
	}

	Position tileScreenPosition;
	_camera->convertMapToScreen(unitTile->getPosition() + Position(0,0, unitFromBelow ? -1 : 0), &tileScreenPosition);
	tileScreenPosition += _camera->getMapOffset();

	// draw unit
	Position offset;
	int shadeOffset;
	calculateWalkingOffset(bu, &offset, &shadeOffset);
	int tileShade = currTile->isDiscovered(2) ? currTile->getShade() : 16;
	int unitShade = (tileShade * (16 - shadeOffset) + shade * shadeOffset) / 16;
	if (!moving && unitTile->getObstacle(4))
	{
		unitShade = obstacleShade;
	}
	tmpSurface->blitNShade(surface, tileScreenPosition.x + offset.x - _spriteWidth / 2, tileScreenPosition.y + offset.y, unitShade, mask);
	// draw fire
	if (bu->getFire() > 0)
	{
		int frameNumber = 4 + (_animFrame / 2);
		tmpSurface = _game->getMod()->getSurfaceSet("SMOKE.PCK")->getFrame(frameNumber);
		tmpSurface->blitNShade(surface, tileScreenPosition.x + offset.x, tileScreenPosition.y + offset.y, 0, mask);
	}
	if (bu->getBreathFrame() > 0)
	{
		tmpSurface = _game->getMod()->getSurfaceSet("BREATH-1.PCK")->getFrame(bu->getBreathFrame() - 1);
		// lower the bubbles for shorter or kneeling units.
		offset.y += (22 - bu->getHeight());
		if (tmpSurface)
		{
			tmpSurface->blitNShade(surface, tileScreenPosition.x + offset.x, tileScreenPosition.y + offset.y - 30, tileShade, mask);
		}
	}
}

int EatShitAndDie = 0;


void DrawSprite( Surface *Dst, int DstX, int DstY, Surface *Src)
{
	int x, y;
	Uint8 SourceColor;
	int SpriteWidth, SpriteHeight;

	/*
	for (y=0; y<Dst->getHeight()-1; y++)
	{
		for (x=0; x<Dst->getWidth()-1; x++)
		{
			Dst->setPixel( x, y, 200 );
		}
	}
	*/

	SpriteWidth = Src->getWidth(); // 32
	SpriteHeight = Src->getHeight(); // 40

	for (y=0; y<SpriteHeight-1; y++)
	{
		for (x=0; x<SpriteWidth-1; x++)
		{
			SourceColor = Src->getPixel(x,y);  
			if
			(
				(SourceColor > 0)
			)
			{
				Dst->setPixel( DstX + x, DstY + y, SourceColor );
			}
		}
	}

}

void DrawLoft( TileEngine *Te, Surface *Dst, int DstX, int DstY, Tile *Src)
{
	int x, y;
	Position Here;
	Uint8 VoxelColor;

	for (y=0; y<16; y++) 
	{
		for (x=0; x<16; x++)
		{
			// for z try this later
			Here.x = DstX + x;
			Here.y = DstY + y;
			Here.z = 0;
			switch (Te->voxelCheck( Here, 0, false, false, 0 ))
			{
				case V_EMPTY:
					VoxelColor = 25;
					break;
				case V_FLOOR:
					VoxelColor = 50;
					break;
				case V_WESTWALL:
					VoxelColor = 75;
					break;
				case V_NORTHWALL:
					VoxelColor = 100;
					break;
				case V_OBJECT:
					VoxelColor = 125;
					break;
				case V_UNIT:
					VoxelColor = 150;
					break;
				case V_OUTOFBOUNDS:
					VoxelColor = 175;
					break;
				default:
					VoxelColor = 0;
			}
			Dst->setPixel( DstX + x, DstY + y, VoxelColor );					
	
		}
	}
}

/*

	// for z try this later
	Here.x = DstX + x;
	Here.y = DstY + y;
	Here.z = 0;
	switch (Te->voxelCheck( Here, 0, false, false, 0 ))
	{
		case V_EMPTY:
					VoxelColor = 25;
					break;
				case V_FLOOR:
					VoxelColor = 50;
					break;
				case V_WESTWALL:
					VoxelColor = 75;
					break;
				case V_NORTHWALL:
					VoxelColor = 100;
					break;
				case V_OBJECT:
					VoxelColor = 125;
					break;
				case V_UNIT:
					VoxelColor = 150;
					break;
				case V_OUTOFBOUNDS:
					VoxelColor = 175;
					break;
				default:
					VoxelColor = 0;
			}
			Dst->setPixel( DstX + x, DstY + y, VoxelColor );					
	
		}
		*/


// Skybuck:
// pre-compute which loft voxel is visible for the sprite.
// cause this will be too slow
// the relation between sprite color/pixel and sprite voxel/loft needs to be determined, and can be pre-computed
// to save computation time.
// for now I try real-time.

void DrawSpriteVoxelFrame( Surface *Dst, int DstX, int DstY, Tile *ParaTile, TilePart ParaTilePart )
{
//	VoxelPosition vVoxelPosition;
	signed char vVoxelPositionZ;
	int SpriteX, SpriteY;

	Uint8 VoxelColor;


	for (SpriteY=0; SpriteY < 40; SpriteY++)
	{
		for (SpriteX=0; SpriteX < 32; SpriteX++)
		{
			//	VoxelColor = SpriteX % 256;

			vVoxelPositionZ = ParaTile->getSpriteVoxelFrame( ParaTilePart )->_VoxelPosition[SpriteY][SpriteX].Z;
			if (vVoxelPositionZ >= 0)
			{
				VoxelColor = (vVoxelPositionZ  / 24.0 ) * 16;

				Dst->setPixel( DstX + SpriteX, DstY + SpriteY, VoxelColor );
			}
		}
	}
}


void ProcessSpriteVoxel( Surface *Dst, int DstX, int DstY, int VoxelX, int VoxelY, int VoxelZ, int SpriteX, int SpriteY, Uint8 TestColor )
{
	Uint8 VoxelColor;

//	VoxelColor = SpriteX % 256;
	Dst->setPixel( DstX + SpriteX, DstY + SpriteY, TestColor );
}

void DrawVoxelDataInsteadOfSprite( TileEngine *Te, Surface *Dst, int DstX, int DstY, Tile *Src)
{
	int x, y;
	Position Here;
	Uint8 VoxelColor;

	int SpriteStartX, SpriteStartY;
	int SpriteX;
	float SpriteY;

	int VoxelX, VoxelY, VoxelZ;
	Uint8 TestColor;

	float ComponentX, ComponentY;

	SpriteStartX = 16; // tile width
	SpriteStartY = 24; // tile depth

	for (VoxelZ=0; VoxelZ < 24; VoxelZ++)
	{
		for (VoxelX=0; VoxelX < 16; VoxelX++)
		{
			for (VoxelY=0; VoxelY < 16; VoxelY++)
			{

				// TestColor = VoxelX + VoxelY + VoxelZ;

				if
				(
					(
						(VoxelX == 0) && (VoxelY == 0) 
					)
					||
					(
						(VoxelX == 0) && (VoxelY == 15) 
					)
					||
					(
						(VoxelX == 15) && (VoxelY == 0) 
					)
					||
					(
						(VoxelX == 15) && (VoxelY == 15) 
					)
					||

					(
						(VoxelZ == 0) && (VoxelY == 0) 
					)
					||
					(
						(VoxelZ == 0) && (VoxelY == 15) 
					)
					||
					(
						(VoxelZ == 23) && (VoxelY == 0) 
					)
					||
					(
						(VoxelZ == 23) && (VoxelY == 15) 
					)
					||

					(
						(VoxelZ == 0) && (VoxelX == 0) 
					)
					||
					(
						(VoxelZ == 0) && (VoxelX == 15) 
					)
					||
					(
						(VoxelZ == 23) && (VoxelX == 0) 
					)
					||
					(
						(VoxelZ == 23) && (VoxelX == 15) 
					)
				)
				{
					TestColor = 200;
				}
				else
				{
					TestColor = 0;

				}

				SpriteX = (SpriteStartX + VoxelX) - VoxelY;
//				SpriteY = ((SpriteStartY + (VoxelX / 2)) + (VoxelY / 2)) - VoxelZ;

				ComponentX = VoxelX / 2.0;
				ComponentY = VoxelY / 2.0;

				SpriteY = (SpriteStartY + (ComponentX + ComponentY)) - VoxelZ;

				if (TestColor > 0)
				{
					ProcessSpriteVoxel( Dst, DstX, DstY, VoxelX, VoxelY, VoxelZ, SpriteX, SpriteY, TestColor );
				}
			}
		}
	}
}

VoxelType WhoreOfAVoxelCheck(TileEngine *Te, Position voxel, Tile *tile )
{
	// first we check terrain voxel data, not to allow 2x2 units stick through walls
	for (int i = V_FLOOR; i <= V_OBJECT; ++i)
	{
		TilePart tp = (TilePart)i;
		MapData *mp = tile->getMapData(tp);

//		if (((tp == O_WESTWALL) || (tp == O_NORTHWALL)) && tile->isUfoDoorOpen(tp))
//			continue;
		if (mp != 0)
		{
			int x = 15 - (voxel.x%16);
			int y = voxel.y%16;
			int idx =
			(
				mp->getLoftID
				(
					(voxel.z%24)/2
				) * 16
			) + y;
			if (Te->_voxelData->at(idx) & (1 << x))
			{
				return (VoxelType)i;
			}
		}
	}

	return V_EMPTY;
}


void DrawLoftInsteadOfSprite( TileEngine *Te, Surface *Dst, int DstX, int DstY, Tile *Src )
{
/*
	static const int VoxelXtoSpriteX[16] =
	{1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16};

	static const int VoxelXtoSpriteY[16] =
	{0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7};

	static const int VoxelYtoSpriteX[16] =
	{0,-1,-2,-3,-4,-5,-6,-7,-8,-9,-10,-11,-12,-13,-14,-15};

	static const int VoxelYtoSpriteY[16] =
	{0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7};
*/

	bool Computed[40 * 32];

	int x, y;
	Uint8 VoxelColor;
	Uint8 FinalColor;

	int SpriteStartX, SpriteStartY;
	int SpriteX;
	float SpriteY;

	int VoxelX, VoxelY, VoxelZ;
	Uint8 TestColor;

//	double ComponentX, ComponentY;
	float ComponentX, ComponentY;
	int Component;

	Position VoxelPosition;
	VoxelType VoxelCheckResult;

	int vIndex;

	for ( vIndex = 0; vIndex < (40*32); vIndex++ )
	{
		Computed[vIndex] = false;
	}

	SpriteStartX = 15; // tile width
	SpriteStartY = 24; // tile depth

	Te->voxelCheckFlush();

//	for (VoxelZ=0; VoxelZ < 24; VoxelZ++)
//		for (VoxelY=0; VoxelY < 16; VoxelY++)
//			for (VoxelX=0; VoxelX < 16; VoxelX++)


	for (VoxelZ=23; VoxelZ >= 0; VoxelZ--)
	{
		for (VoxelY=15; VoxelY >= 0; VoxelY--)
//		VoxelY = 0;
		{
			for (VoxelX=15; VoxelX >= 0; VoxelX--)
//			VoxelX = 0;
			{
				SpriteX = (SpriteStartX + VoxelX) - VoxelY;


//				SpriteX = (SpriteStartX - VoxelY) + (1+VoxelX);
//				SpriteY = ((SpriteStartY + (VoxelX / 2)) + (VoxelY / 2)) - VoxelZ;

//				ComponentX = VoxelX / 2;
//				ComponentY = VoxelY / 2;

//				SpriteY = (SpriteStartY + (ComponentX  + ComponentY)) - VoxelZ;

				Component = VoxelX + VoxelY;
				Component = Component >> 1;

				SpriteY = (SpriteStartY + Component) - VoxelZ;

//				SpriteX = SpriteStartX + VoxelXtoSpriteX[VoxelX] + VoxelYtoSpriteX[VoxelY];
//				SpriteY = SpriteStartY + VoxelXtoSpriteY[VoxelX] + VoxelXtoSpriteY[VoxelY] - VoxelZ;


				vIndex = (SpriteY * 32) + SpriteX;

				if (!Computed[vIndex])
				{
					VoxelPosition.x = VoxelX;
					VoxelPosition.y = VoxelY;
					VoxelPosition.z = VoxelZ;

					VoxelCheckResult = WhoreOfAVoxelCheck( Te, VoxelPosition, Src );

					FinalColor = 0;

					/*
					VoxelColor = 225;

					switch(VoxelCheckResult)
					{
						case V_EMPTY:
							VoxelColor = 0;
							break;
						case V_FLOOR:
							VoxelColor = 50;
							break;
						case V_WESTWALL:
							VoxelColor = 75;
							break;
						case V_NORTHWALL:
							VoxelColor = 100;
							break;
						case V_OBJECT:
							VoxelColor = 125;
							break;
						case V_UNIT:
							VoxelColor = 150;
							break;
						case V_OUTOFBOUNDS:
							VoxelColor = 175;
							break;
						default:
							VoxelColor = 200;
					}
					*/

					if (VoxelCheckResult != V_EMPTY)
					{
						FinalColor = 16 + (VoxelZ % 24);
					}

					if (FinalColor > 0)
					{
						ProcessSpriteVoxel( Dst, DstX, DstY, VoxelX, VoxelY, VoxelZ, SpriteX, SpriteY, FinalColor );
						Computed[vIndex] = true;
					}
				}
			}
		}
	}
}


// why is this fucked.
void DrawLoftInsteadOfSpriteFuckMeBaby( TileEngine *Te, Surface *Dst, int DstX, int DstY, Tile *Src )
{
	bool Computed[40 * 32];

	int x, y;
	Uint8 VoxelColor;
	Uint8 FinalColor;

	int SpriteStartX, SpriteStartY;
	int SpriteX;
	float SpriteY;

	int VoxelX, VoxelY, VoxelZ;
	Uint8 TestColor;

	float ComponentX, ComponentY;
	int Component;

	Position VoxelPosition;
	VoxelType VoxelCheckResult;

	int vIndex;

	for ( vIndex = 0; vIndex < (40*16); vIndex++ )
	{
		Computed[vIndex] = false;
	}

	SpriteStartX = 15; // tile width
	SpriteStartY = 24; // tile depth

	Te->voxelCheckFlush();

	for (VoxelZ=23; VoxelZ >= 0; VoxelZ--)
	{
		for (VoxelY=15; VoxelY >= 0; VoxelY--)
//		VoxelY = 0;
		{
			for (VoxelX=15; VoxelX >= 0; VoxelX--)
//			VoxelX = 0;
			{
				SpriteX = (SpriteStartX + VoxelX) - VoxelY;

				Component = VoxelX + VoxelY;
				Component = Component >> 1;

				SpriteY = (SpriteStartY + Component) - VoxelZ;

				if (SpriteX <= 14)
				{

					vIndex = (SpriteY * 32) + SpriteX;

					if (!Computed[vIndex])
					{
						FinalColor = 116 + (VoxelZ % 24);

						ProcessSpriteVoxel( Dst, DstX, DstY, VoxelX, VoxelY, VoxelZ, SpriteX, SpriteY, FinalColor );
						Computed[vIndex] = true;
					}
				}
				else
				if (SpriteX == 15)
				{
					vIndex = (SpriteY * 32) + SpriteX;
					if (!Computed[vIndex])
					{
						FinalColor = 116 + (VoxelZ % 24);

						ProcessSpriteVoxel( Dst, DstX, DstY, VoxelX, VoxelY, VoxelZ, SpriteX, SpriteY, FinalColor );
						Computed[vIndex] = true;
					}

					SpriteX = 16;
					vIndex = (SpriteY * 32) + SpriteX;
					if (!Computed[vIndex])
					{
						FinalColor = 116 + (VoxelZ % 24);

						ProcessSpriteVoxel( Dst, DstX, DstY, VoxelX, VoxelY, VoxelZ, SpriteX, SpriteY, FinalColor );
						Computed[vIndex] = true;
					}
				}
				else
				if (SpriteX >= 16)
				{
					SpriteX = SpriteX + 1;

					vIndex = (SpriteY * 32) + SpriteX;
					if (!Computed[vIndex])
					{
						FinalColor = 116 + (VoxelZ % 24);

						ProcessSpriteVoxel( Dst, DstX, DstY, VoxelX, VoxelY, VoxelZ, SpriteX, SpriteY, FinalColor );
						Computed[vIndex] = true;
					}

				}
			}
		}
	}
}






void DrawCombinedSurfaceAndLoft( TileEngine *Te, Surface *Dst, int DstX, int DstY, Tile *Src )
{
/*
	static const int VoxelXtoSpriteX[16] =
	{1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16};

	static const int VoxelXtoSpriteY[16] =
	{0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7};

	static const int VoxelYtoSpriteX[16] =
	{0,-1,-2,-3,-4,-5,-6,-7,-8,-9,-10,-11,-12,-13,-14,-15};

	static const int VoxelYtoSpriteY[16] =
	{0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7};
*/

	bool Computed[40 * 32];

	int x, y;
	Uint8 VoxelColor;
	Uint8 FinalColor;

	int SpriteStartX, SpriteStartY;
	int SpriteX;
	float SpriteY;

	int VoxelX, VoxelY, VoxelZ;
	Uint8 TestColor;

//	double ComponentX, ComponentY;
	float ComponentX, ComponentY;
	int Component;

	Position VoxelPosition;
	VoxelType VoxelCheckResult;

	int vIndex;

	for ( vIndex = 0; vIndex < (40*32); vIndex++ )
	{
		Computed[vIndex] = false;
	}

	SpriteStartX = 15; // tile width
	SpriteStartY = 24; // tile depth

	Te->voxelCheckFlush();

//	for (VoxelZ=0; VoxelZ < 24; VoxelZ++)
//		for (VoxelY=0; VoxelY < 16; VoxelY++)
//			for (VoxelX=0; VoxelX < 16; VoxelX++)


	for (VoxelZ=23; VoxelZ >= 0; VoxelZ--)
	{
		for (VoxelY=15; VoxelY >= 0; VoxelY--)
//		VoxelY = 0;
		{
			for (VoxelX=15; VoxelX >= 0; VoxelX--)
//			VoxelX = 0;
			{
				SpriteX = (SpriteStartX + VoxelX) - VoxelY;


//				SpriteX = (SpriteStartX - VoxelY) + (1+VoxelX);
//				SpriteY = ((SpriteStartY + (VoxelX / 2)) + (VoxelY / 2)) - VoxelZ;

//				ComponentX = VoxelX / 2;
//				ComponentY = VoxelY / 2;

//				SpriteY = (SpriteStartY + (ComponentX  + ComponentY)) - VoxelZ;

				Component = VoxelX + VoxelY;
				Component = Component >> 1;

				SpriteY = (SpriteStartY + Component) - VoxelZ;

//				SpriteX = SpriteStartX + VoxelXtoSpriteX[VoxelX] + VoxelYtoSpriteX[VoxelY];
//				SpriteY = SpriteStartY + VoxelXtoSpriteY[VoxelX] + VoxelXtoSpriteY[VoxelY] - VoxelZ;


				vIndex = (SpriteY * 32) + SpriteX;

				if (!Computed[vIndex])
				{
					VoxelPosition.x = VoxelX;
					VoxelPosition.y = VoxelY;
					VoxelPosition.z = VoxelZ;

					VoxelCheckResult = WhoreOfAVoxelCheck( Te, VoxelPosition, Src );

					FinalColor = 0;

					/*
					VoxelColor = 225;

					switch(VoxelCheckResult)
					{
						case V_EMPTY:
							VoxelColor = 0;
							break;
						case V_FLOOR:
							VoxelColor = 50;
							break;
						case V_WESTWALL:
							VoxelColor = 75;
							break;
						case V_NORTHWALL:
							VoxelColor = 100;
							break;
						case V_OBJECT:
							VoxelColor = 125;
							break;
						case V_UNIT:
							VoxelColor = 150;
							break;
						case V_OUTOFBOUNDS:
							VoxelColor = 175;
							break;
						default:
							VoxelColor = 200;
					}
					*/

					if (VoxelCheckResult != V_EMPTY)
					{
						FinalColor = (Dst->getPixel( DstX + SpriteX, DstY + SpriteY ) + (VoxelZ % 24))%256;
					}

					if (FinalColor > 0)
					{
						ProcessSpriteVoxel( Dst, DstX, DstY, VoxelX, VoxelY, VoxelZ, SpriteX, SpriteY, FinalColor );
						Computed[vIndex] = true;
					}
				}
			}
		}
	}
}


void DrawLoftInsteadOfSpriteFatVoxels( TileEngine *Te, Surface *Dst, int DstX, int DstY, Tile *Src )
{
/*
	static const int VoxelXtoSpriteX[16] =
	{1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16};

	static const int VoxelXtoSpriteY[16] =
	{0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7};

	static const int VoxelYtoSpriteX[16] =
	{0,-1,-2,-3,-4,-5,-6,-7,-8,-9,-10,-11,-12,-13,-14,-15};

	static const int VoxelYtoSpriteY[16] =
	{0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7};
*/

	bool Computed[40 * 32];

	int x, y;
	Uint8 VoxelColor;
	Uint8 FinalColor;

	int SpriteStartX, SpriteStartY;
	int SpriteX;
	float SpriteY;

	int VoxelX, VoxelY, VoxelZ;
	Uint8 TestColor;

//	double ComponentX, ComponentY;
	float ComponentX, ComponentY;
	int Component;

	Position VoxelPosition;
	VoxelType VoxelCheckResult;

	int vIndex;

	for ( vIndex = 0; vIndex < (40*32); vIndex++ )
	{
		Computed[vIndex] = false;
	}

	SpriteStartX = 15; // tile width
	SpriteStartY = 24; // tile depth

	Te->voxelCheckFlush();

//	for (VoxelZ=0; VoxelZ < 24; VoxelZ++)
//		for (VoxelY=0; VoxelY < 16; VoxelY++)
//			for (VoxelX=0; VoxelX < 16; VoxelX++)


	for (VoxelZ=23; VoxelZ >= 0; VoxelZ--)
	{
		for (VoxelY=15; VoxelY >= 0; VoxelY--)
//		VoxelY = 0;
		{
			for (VoxelX=15; VoxelX >= 0; VoxelX--)
//			VoxelX = 0;
			{
				SpriteX = (SpriteStartX + VoxelX) - VoxelY;


//				SpriteX = (SpriteStartX - VoxelY) + (1+VoxelX);
//				SpriteY = ((SpriteStartY + (VoxelX / 2)) + (VoxelY / 2)) - VoxelZ;

//				ComponentX = VoxelX / 2;
//				ComponentY = VoxelY / 2;

//				SpriteY = (SpriteStartY + (ComponentX  + ComponentY)) - VoxelZ;

				Component = VoxelX + VoxelY;
				Component = Component >> 1;

				SpriteY = (SpriteStartY + Component) - VoxelZ;

//				SpriteX = SpriteStartX + VoxelXtoSpriteX[VoxelX] + VoxelYtoSpriteX[VoxelY];
//				SpriteY = SpriteStartY + VoxelXtoSpriteY[VoxelX] + VoxelXtoSpriteY[VoxelY] - VoxelZ;


				vIndex = (SpriteY * 32) + SpriteX;

				if (!Computed[vIndex])
				{
					VoxelPosition.x = VoxelX;
					VoxelPosition.y = VoxelY;
					VoxelPosition.z = VoxelZ;

					VoxelCheckResult = WhoreOfAVoxelCheck( Te, VoxelPosition, Src );

					FinalColor = 0;

					/*
					VoxelColor = 225;

					switch(VoxelCheckResult)
					{
						case V_EMPTY:
							VoxelColor = 0;
							break;
						case V_FLOOR:
							VoxelColor = 50;
							break;
						case V_WESTWALL:
							VoxelColor = 75;
							break;
						case V_NORTHWALL:
							VoxelColor = 100;
							break;
						case V_OBJECT:
							VoxelColor = 125;
							break;
						case V_UNIT:
							VoxelColor = 150;
							break;
						case V_OUTOFBOUNDS:
							VoxelColor = 175;
							break;
						default:
							VoxelColor = 200;
					}
					*/

					if (VoxelCheckResult != V_EMPTY)
					{
						FinalColor = 16 + ((VoxelZ/24.0)*15);
					}

					if (FinalColor > 0)
					{
						ProcessSpriteVoxel( Dst, DstX, DstY, VoxelX, VoxelY, VoxelZ, SpriteX, SpriteY, FinalColor );

//						if (SpriteX < 31)
						{
							ProcessSpriteVoxel( Dst, DstX, DstY, VoxelX, VoxelY, VoxelZ, SpriteX+1, SpriteY, FinalColor );
						}
						Computed[vIndex] = true;
					}
				}
			}
		}
	}
}

void DrawLoftAndSurfaceCombinedFatVoxels( TileEngine *Te, Surface *Dst, int DstX, int DstY, Tile *Src )
{
/*
	static const int VoxelXtoSpriteX[16] =
	{1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16};

	static const int VoxelXtoSpriteY[16] =
	{0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7};

	static const int VoxelYtoSpriteX[16] =
	{0,-1,-2,-3,-4,-5,-6,-7,-8,-9,-10,-11,-12,-13,-14,-15};

	static const int VoxelYtoSpriteY[16] =
	{0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7};
*/

	bool Computed[40 * 32];

	int x, y;
	Uint8 SurfaceColor;
	Uint8 VoxelColor;
	Uint8 FinalColor;

	int SpriteStartX, SpriteStartY;
	int SpriteX;
	float SpriteY;

	int VoxelX, VoxelY, VoxelZ;
	Uint8 TestColor;

//	double ComponentX, ComponentY;
	float ComponentX, ComponentY;
	int Component;

	Position VoxelPosition;
	VoxelType VoxelCheckResult;

	float CrazyDistance;

	int vIndex;

	for ( vIndex = 0; vIndex < (40*32); vIndex++ )
	{
		Computed[vIndex] = false;
	}

	SpriteStartX = 15; // tile width
	SpriteStartY = 24; // tile depth

	Te->voxelCheckFlush();

//	for (VoxelZ=0; VoxelZ < 24; VoxelZ++)
//		for (VoxelY=0; VoxelY < 16; VoxelY++)
//			for (VoxelX=0; VoxelX < 16; VoxelX++)


	for (VoxelZ=23; VoxelZ >= 0; VoxelZ--)
	{
		for (VoxelY=15; VoxelY >= 0; VoxelY--)
//		VoxelY = 0;
		{
			for (VoxelX=15; VoxelX >= 0; VoxelX--)
//			VoxelX = 0;
			{
				CrazyDistance = sqrt( ((VoxelX-7) * (VoxelX-7)) + ((VoxelY-7) * (VoxelY-7)) + ((VoxelZ-12) * (VoxelZ-12)) ); 


				SpriteX = (SpriteStartX + VoxelX) - VoxelY;


//				SpriteX = (SpriteStartX - VoxelY) + (1+VoxelX);
//				SpriteY = ((SpriteStartY + (VoxelX / 2)) + (VoxelY / 2)) - VoxelZ;

//				ComponentX = VoxelX / 2;
//				ComponentY = VoxelY / 2;

//				SpriteY = (SpriteStartY + (ComponentX  + ComponentY)) - VoxelZ;

				Component = VoxelX + VoxelY;
				Component = Component >> 1;

				SpriteY = (SpriteStartY + Component) - VoxelZ;

//				SpriteX = SpriteStartX + VoxelXtoSpriteX[VoxelX] + VoxelYtoSpriteX[VoxelY];
//				SpriteY = SpriteStartY + VoxelXtoSpriteY[VoxelX] + VoxelXtoSpriteY[VoxelY] - VoxelZ;


				vIndex = (SpriteY * 32) + SpriteX;

				if (!Computed[vIndex])
				{
					VoxelPosition.x = VoxelX;
					VoxelPosition.y = VoxelY;
					VoxelPosition.z = VoxelZ;

					VoxelCheckResult = WhoreOfAVoxelCheck( Te, VoxelPosition, Src );

					FinalColor = 0;

					/*
					VoxelColor = 225;

					switch(VoxelCheckResult)
					{
						case V_EMPTY:
							VoxelColor = 0;
							break;
						case V_FLOOR:
							VoxelColor = 50;
							break;
						case V_WESTWALL:
							VoxelColor = 75;
							break;
						case V_NORTHWALL:
							VoxelColor = 100;
							break;
						case V_OBJECT:
							VoxelColor = 125;
							break;
						case V_UNIT:
							VoxelColor = 150;
							break;
						case V_OUTOFBOUNDS:
							VoxelColor = 175;
							break;
						default:
							VoxelColor = 200;
					}
					*/

					if (VoxelCheckResult != V_EMPTY)
					{
						SurfaceColor = Dst->getPixel( DstX + SpriteX, DstY + SpriteY );
						SurfaceColor = SurfaceColor / 16;
						SurfaceColor = SurfaceColor * 16;

						FinalColor = SurfaceColor + ((CrazyDistance/16.0)*15);
					}

					if (FinalColor > 0)
					{
						ProcessSpriteVoxel( Dst, DstX, DstY, VoxelX, VoxelY, VoxelZ, SpriteX, SpriteY, FinalColor );

//						if (SpriteX < 31)
						{
							ProcessSpriteVoxel( Dst, DstX, DstY, VoxelX, VoxelY, VoxelZ, SpriteX+1, SpriteY, FinalColor );
						}
						Computed[vIndex] = true;
					}
				}
			}
		}
	}
}

// macros for fast voxel traversal algoritm in code below
// original macros disabled, to not be reliant on macro language ! ;)
// #define SIGN(x) (x > 0 ? 1 : (x < 0 ? -1 : 0))
// #define FRAC0(x) (x - floorf(x))
// #define FRAC1(x) (1 - x + floorf(x))

// note: the floating point type below in these helper functions should match the floating point type in calculateLine
//       for maximum accuracy and correctness, otherwise problems will occur !
float NoShitSignSingle( float x )
{
	return (x > 0 ? 1 : (x < 0 ? -1 : 0));
}

float NoShitFrac0Single( float x )
{
	return (x - floorf(x));
}

float NoShitFrac1Single( float x )
{
	return (1 - x + floorf(x));
}

float NoShitMaxSingle(float A, float B)
{
	if (A > B) return A; else return B;
}

float NoShitMinSingle(float A, float B)
{
	if (A < B) return A; else return B;
}

bool NoShitPointInBoxSingle
(
	float X, float Y, float Z,
	float BoxX1, float BoxY1, float BoxZ1,
	float BoxX2, float BoxY2, float BoxZ2
)
{
	float MinX, MinY, MinZ;
	float MaxX, MaxY, MaxZ;

	bool result = false;

	if (BoxX1 < BoxX2)
	{
		MinX = BoxX1;
		MaxX = BoxX2;
	} else
	{
		MinX = BoxX2;
		MaxX = BoxX1;
	}

	if (BoxY1 < BoxY2)
	{
		MinY = BoxY1;
		MaxY = BoxY2;
	} else
	{
		MinY = BoxY2;
		MaxY = BoxY1;
	}

	if (BoxZ1 < BoxZ2)
	{
		MinZ = BoxZ1;
		MaxZ = BoxZ2;
	} else
	{
		MinZ = BoxZ2;
		MaxZ = BoxZ1;
	}

	if
	(
		(X >= MinX) && (Y >= MinY) && (Z >= MinZ) &&
		(X <= MaxX) && (Y <= MaxY) && (Z <= MaxZ)
	)
	{
		result = true;
	}
	return result;
}

bool NoShitLineSegmentIntersectsBoxSingle
(
	float LineX1, float LineY1, float LineZ1,
	float LineX2, float LineY2, float LineZ2,

	float BoxX1, float BoxY1, float BoxZ1,
	float BoxX2, float BoxY2, float BoxZ2,

	// nearest to line origin, doesn't necessarily mean closes to box...
	bool *MinIntersectionPoint,
	float *MinIntersectionPointX, float *MinIntersectionPointY, float *MinIntersectionPointZ,

	// farthest to line origin, doesn't necessarily mean farthest from box...
	bool *MaxIntersectionPoint,
	float *MaxIntersectionPointX, float *MaxIntersectionPointY, float *MaxIntersectionPointZ
)
{
	float LineDeltaX;
	float LineDeltaY;
	float LineDeltaZ;

	float LineDistanceToBoxX1;
	float LineDistanceToBoxX2;

	float LineDistanceToBoxY1;
	float LineDistanceToBoxY2;

	float LineDistanceToBoxZ1;
	float LineDistanceToBoxZ2;

	float LineMinDistanceToBoxX;
	float LineMaxDistanceToBoxX;

	float LineMinDistanceToBoxY;
	float LineMaxDistanceToBoxY;

	float LineMinDistanceToBoxZ;
	float LineMaxDistanceToBoxZ;

	float LineMaxMinDistanceToBox;
	float LineMinMaxDistanceToBox;

	float LineMinDistanceToBox;
	float LineMaxDistanceToBox;

	bool result = false;
	*MinIntersectionPoint = false;
	*MaxIntersectionPoint = false;

	LineDeltaX = LineX2 - LineX1;
	LineDeltaY = LineY2 - LineY1;
	LineDeltaZ = LineZ2 - LineZ1;

	// T (distance along line) calculations which will be used to figure out Tmins and Tmaxs:
	// t = (LocationX - x0) / (DeltaX)
	if (LineDeltaX != 0)
	{
		LineDistanceToBoxX1 = (BoxX1 - LineX1) / LineDeltaX;
		LineDistanceToBoxX2 = (BoxX2 - LineX1) / LineDeltaX;
	} else
	{
		LineDistanceToBoxX1 = (BoxX1 - LineX1);
		LineDistanceToBoxX2 = (BoxX2 - LineX1);
	}

	// now we take the minimum's and maximum's
	if (LineDistanceToBoxX1 < LineDistanceToBoxX2)
	{
		LineMinDistanceToBoxX = LineDistanceToBoxX1;
		LineMaxDistanceToBoxX = LineDistanceToBoxX2;
	} else
	{
		LineMinDistanceToBoxX = LineDistanceToBoxX2;
		LineMaxDistanceToBoxX = LineDistanceToBoxX1;
	}

	if (LineDeltaY != 0)
	{
		LineDistanceToBoxY1 = (BoxY1 - LineY1) / LineDeltaY;
		LineDistanceToBoxY2 = (BoxY2 - LineY1) / LineDeltaY;
	} else
	{
		LineDistanceToBoxY1 = BoxY1 - LineY1;
		LineDistanceToBoxY2 = BoxY2 - LineY1;
	}

	if (LineDistanceToBoxY1 < LineDistanceToBoxY2)
	{
		LineMinDistanceToBoxY = LineDistanceToBoxY1;
		LineMaxDistanceToBoxY = LineDistanceToBoxY2;
	} else
	{
		LineMinDistanceToBoxY = LineDistanceToBoxY2;
		LineMaxDistanceToBoxY = LineDistanceToBoxY1;
	}

	if (LineDeltaZ != 0)
	{
		LineDistanceToBoxZ1 = (BoxZ1 - LineZ1) / LineDeltaZ;
		LineDistanceToBoxZ2 = (BoxZ2 - LineZ1) / LineDeltaZ;
	} else
	{
		LineDistanceToBoxZ1 = (BoxZ1 - LineZ1);
		LineDistanceToBoxZ2 = (BoxZ2 - LineZ1);
	}

	if (LineDistanceToBoxZ1 < LineDistanceToBoxZ2)
	{
		LineMinDistanceToBoxZ = LineDistanceToBoxZ1;
		LineMaxDistanceToBoxZ = LineDistanceToBoxZ2;
	} else
	{
		LineMinDistanceToBoxZ = LineDistanceToBoxZ2;
		LineMaxDistanceToBoxZ = LineDistanceToBoxZ1;
	}

	// these 6 distances all represent distances on a line.
	// we want to clip this line to the box.
	// so the } points of the line which are outside the box need to be clipped.
	// so we clipping the line to the box.
	// this means we are interested in the most minimum minimum
	// and the most maximum, maximum.
	// these min's and max's represent the outer intersections.
	// if for whatever reason the minimum is larger than the maximum
	// then the line misses the box ! ;)
	// nooooooooooooooooooooooooooooooooo
	// we want the maximum of the minimums
	// and we want the minimum of the maximums
	// that should give us the bounding intersections ! ;)


	// find the maximum minimum
	LineMaxMinDistanceToBox = LineMinDistanceToBoxX;

	if (LineMinDistanceToBoxY > LineMaxMinDistanceToBox)
	{
		LineMaxMinDistanceToBox = LineMinDistanceToBoxY;
	}

	if (LineMinDistanceToBoxZ > LineMaxMinDistanceToBox)
	{
		LineMaxMinDistanceToBox = LineMinDistanceToBoxZ;
	}

	// find the minimum maximum
	LineMinMaxDistanceToBox = LineMaxDistanceToBoxX;

	if (LineMaxDistanceToBoxY < LineMinMaxDistanceToBox)
	{
		LineMinMaxDistanceToBox = LineMaxDistanceToBoxY;
	}

	if (LineMaxDistanceToBoxZ < LineMinMaxDistanceToBox)
	{
		LineMinMaxDistanceToBox = LineMaxDistanceToBoxZ;
	}

	// these two points are now the minimum and maximum distance to box
	LineMinDistanceToBox = LineMaxMinDistanceToBox;
	LineMaxDistanceToBox = LineMinMaxDistanceToBox;

	// now check if the max distance is smaller than the minimum distance
	// if so then the line segment does not intersect the box.
	if (LineMaxDistanceToBox < LineMinDistanceToBox)
	{
		return result;
	}

	// if distances are within the line then there is an intersection
	if ( (LineMinDistanceToBox > 0) && (LineMinDistanceToBox < 1) )
	{
		// else the min and max are the intersection points so calculate
		// those using the parametric equation and return true.
		// x = x0 + t(x1 - x0)
		// y = y0 + t(y1 - y0)
		// z = z0 + t(z1 - z0)

		*MinIntersectionPoint = true;
		*MinIntersectionPointX = LineX1 + LineMinDistanceToBox * LineDeltaX;
		*MinIntersectionPointY = LineY1 + LineMinDistanceToBox * LineDeltaY;
		*MinIntersectionPointZ = LineZ1 + LineMinDistanceToBox * LineDeltaZ;

		result = true;
	}

	if ( (LineMaxDistanceToBox > 0) && (LineMaxDistanceToBox < 1) )
	{
		*MaxIntersectionPoint = true;
		*MaxIntersectionPointX = LineX1 + LineMaxDistanceToBox * LineDeltaX;
		*MaxIntersectionPointY = LineY1 + LineMaxDistanceToBox * LineDeltaY;
		*MaxIntersectionPointZ = LineZ1 + LineMaxDistanceToBox * LineDeltaZ;

		result = true;
	}

	return result;
}

int TraverseSecondHit
(
	SavedBattleGame *ParaSave,
	TileEngine *Te,
	Tile *Src, 
	float StartX, float StartY, float StartZ,
	float StopX, float StopY, float StopZ
)
{
	int result;
	float x1, y1, z1; // start point
	float x2, y2, z2; // end point

	float tMaxX, tMaxY, tMaxZ, t, tDeltaX, tDeltaY, tDeltaZ;

	int VoxelX, VoxelY, VoxelZ;

	int OutX, OutY, OutZ;

	bool IntersectionPoint1;
	bool IntersectionPoint2;

	float IntersectionPointX1, IntersectionPointY1, IntersectionPointZ1;
	float IntersectionPointX2, IntersectionPointY2, IntersectionPointZ2;

	float TraverseX1, TraverseY1, TraverseZ1;
	float TraverseX2, TraverseY2, TraverseZ2;

	float Epsilon;

	VoxelType VoxelCheckResult;

	//	Epsilon := 0.001;
	Epsilon = 0.1;

	float TileWidth = 16.0;
	float TileHeight = 16.0;
	float TileDepth = 24.0;

	// calculate max voxel position
	int vMapVoxelBoundaryMinX = 0;
	int vMapVoxelBoundaryMinY = 0;
	int vMapVoxelBoundaryMinZ = 0;

	int vLastMapTileX = (ParaSave->getMapSizeX()-1);
	int vLastMapTileY = (ParaSave->getMapSizeY()-1);
	int vLastMapTileZ = (ParaSave->getMapSizeZ()-1);

	int vLastTileVoxelX = TileWidth-1;
	int vLastTileVoxelY = TileHeight-1;
	int vLastTileVoxelZ = TileDepth-1;

	int vMapVoxelBoundaryMaxX = (vLastMapTileX*TileWidth) + vLastTileVoxelX;
	int vMapVoxelBoundaryMaxY = (vLastMapTileY*TileHeight) + vLastTileVoxelY;
	int vMapVoxelBoundaryMaxZ = (vLastMapTileZ*TileDepth) + vLastTileVoxelZ;

	int TileVoxelX, TileVoxelY, TileVoxelZ;

	//start and end points
	x1 = StartX;	 x2 = StopX;
	y1 = StartY;	 y2 = StopY;
	z1 = StartZ;	 z2 = StopZ;

	{
		// check if both points are in grid
		if
		(
			NoShitPointInBoxSingle
			(
				x1, y1, z1,

				vMapVoxelBoundaryMinX,
				vMapVoxelBoundaryMinY,
				vMapVoxelBoundaryMinZ,

				vMapVoxelBoundaryMaxX-Epsilon,
				vMapVoxelBoundaryMaxY-Epsilon,
				vMapVoxelBoundaryMaxZ-Epsilon
			)
			&&
			NoShitPointInBoxSingle
			(
				x2, y2, z2,

				vMapVoxelBoundaryMinX,
				vMapVoxelBoundaryMinY,
				vMapVoxelBoundaryMinZ,

				vMapVoxelBoundaryMaxX-Epsilon,
				vMapVoxelBoundaryMaxY-Epsilon,
				vMapVoxelBoundaryMaxZ-Epsilon
			)
		)
		{
			// just fall through to next code below
			// traverse
		}
		else
		// check if line intersects box
		if
		(
			NoShitLineSegmentIntersectsBoxSingle
			(
				x1,y1,z1,
				x2,y2,z2,

				vMapVoxelBoundaryMinX,
				vMapVoxelBoundaryMinY,
				vMapVoxelBoundaryMinZ,

				vMapVoxelBoundaryMaxX-Epsilon,
				vMapVoxelBoundaryMaxY-Epsilon,
				vMapVoxelBoundaryMaxZ-Epsilon,

				&IntersectionPoint1,
				&IntersectionPointX1,
				&IntersectionPointY1,
				&IntersectionPointZ1,

				&IntersectionPoint2,
				&IntersectionPointX2,
				&IntersectionPointY2,
				&IntersectionPointZ2
			) == true
		)
		{
			if (IntersectionPoint1 == true)
			{
				TraverseX1 = IntersectionPointX1;
				TraverseY1 = IntersectionPointY1;
				TraverseZ1 = IntersectionPointZ1;
			}
			else
			{
				TraverseX1 = x1;
				TraverseY1 = y1;
				TraverseZ1 = z1;
			}

			// compensate for any floating point errors (inaccuracies)
			TraverseX1 = NoShitMaxSingle( TraverseX1, vMapVoxelBoundaryMinX );
			TraverseY1 = NoShitMaxSingle( TraverseY1, vMapVoxelBoundaryMinY );
			TraverseZ1 = NoShitMaxSingle( TraverseZ1, vMapVoxelBoundaryMinZ );

			TraverseX1 = NoShitMinSingle( TraverseX1, vMapVoxelBoundaryMaxX-Epsilon );
			TraverseY1 = NoShitMinSingle( TraverseY1, vMapVoxelBoundaryMaxY-Epsilon );
			TraverseZ1 = NoShitMinSingle( TraverseZ1, vMapVoxelBoundaryMaxZ-Epsilon );

			if (IntersectionPoint2 == true)
			{
				TraverseX2 = IntersectionPointX2;
				TraverseY2 = IntersectionPointY2;
				TraverseZ2 = IntersectionPointZ2;
			}
			else
			{
				TraverseX2 = x2;
				TraverseY2 = y2;
				TraverseZ2 = z2;
			}

			// compensate for any floating point errors (inaccuracies)
			TraverseX2 = NoShitMaxSingle( TraverseX2, vMapVoxelBoundaryMinX );
			TraverseY2 = NoShitMaxSingle( TraverseY2, vMapVoxelBoundaryMinY );
			TraverseZ2 = NoShitMaxSingle( TraverseZ2, vMapVoxelBoundaryMinZ );

			TraverseX2 = NoShitMinSingle( TraverseX2, vMapVoxelBoundaryMaxX-Epsilon );
			TraverseY2 = NoShitMinSingle( TraverseY2, vMapVoxelBoundaryMaxY-Epsilon );
			TraverseZ2 = NoShitMinSingle( TraverseZ2, vMapVoxelBoundaryMaxZ-Epsilon );

			{
				// just fall through below
				// traverse
				x1 = TraverseX1; 
				y1 = TraverseY1;
				z1 = TraverseZ1; 

				x2 = TraverseX2; 
				y2 = TraverseY2;
				z2 = TraverseZ2; 
			}
		}
	}

	// traverse code, fast voxel traversal algorithm
	int dx = NoShitSignSingle(x2 - x1);
	if (dx != 0) tDeltaX = fmin(dx / (x2 - x1), 10000000.0f); else tDeltaX = 10000000.0f;
	if (dx > 0) tMaxX = tDeltaX * NoShitFrac1Single(x1); else tMaxX = tDeltaX * NoShitFrac0Single(x1);
	VoxelX = (int) x1;

	int dy = NoShitSignSingle(y2 - y1);
	if (dy != 0) tDeltaY = fmin(dy / (y2 - y1), 10000000.0f); else tDeltaY = 10000000.0f;
	if (dy > 0) tMaxY = tDeltaY * NoShitFrac1Single(y1); else tMaxY = tDeltaY * NoShitFrac0Single(y1);
	VoxelY = (int) y1;

	int dz = NoShitSignSingle(z2 - z1);
	if (dz != 0) tDeltaZ = fmin(dz / (z2 - z1), 10000000.0f); else tDeltaZ = 10000000.0f;
	if (dz > 0) tMaxZ = tDeltaZ * NoShitFrac1Single(z1); else tMaxZ = tDeltaZ * NoShitFrac0Single(z1);
	VoxelZ = (int) z1;

	if (dx > 0) OutX = vMapVoxelBoundaryMaxX+1; else OutX = -1;
	if (dy > 0) OutY = vMapVoxelBoundaryMaxY+1; else OutY = -1;
	if (dz > 0) OutZ = vMapVoxelBoundaryMaxZ+1; else OutZ = -1;

	bool Hits = 0;
	t = 0;
	while (t <= 1.0)
	{
		// process voxel
		int TileX = VoxelX / 16;
		int TileY = VoxelY / 16;
		int TileZ = VoxelZ / 24;

		Tile *CheckTile = ParaSave->getTile(Position(TileX,TileY,TileZ));

		TileVoxelX = VoxelX % 16;
		TileVoxelY = VoxelY % 16;
		TileVoxelZ = VoxelZ % 24;

		VoxelCheckResult = WhoreOfAVoxelCheck( Te, Position(TileVoxelX,TileVoxelY,TileVoxelZ), CheckTile );

		if (VoxelCheckResult != V_EMPTY)
		{
			Hits = Hits + 1;
		}

		// go to next voxel
		if ( (tMaxX < tMaxY) && (tMaxX < tMaxZ) )
		{
			t = tMaxX;
			VoxelX += dx;
			tMaxX += tDeltaX;

			if (VoxelX == OutX) break;
		}
		else
		if (tMaxY < tMaxZ)
		{
			t = tMaxY;
			VoxelY += dy;
			tMaxY += tDeltaY;

			if (VoxelY == OutY) break;
		}
		else
		{
			t = tMaxZ;
			VoxelZ += dz;
			tMaxZ += tDeltaZ;

			if (VoxelZ == OutZ) break;
		}
	}

	return Hits;
}


bool VoxelTraverseHit
(
	SavedBattleGame *ParaSave,

	float StartX, float StartY, float StartZ,
	float StopX, float StopY, float StopZ,

	int CollisionTileX, int CollisionTileY, int CollisionTileZ,
	int *CollisionVoxelX, int *CollisionVoxelY, int *CollisionVoxelZ
)
{
	int result;
	float x1, y1, z1; // start point
	float x2, y2, z2; // end point

	float tMaxX, tMaxY, tMaxZ, t, tDeltaX, tDeltaY, tDeltaZ;

	int VoxelX, VoxelY, VoxelZ;

	int OutX, OutY, OutZ;

	bool IntersectionPoint1;
	bool IntersectionPoint2;

	float IntersectionPointX1, IntersectionPointY1, IntersectionPointZ1;
	float IntersectionPointX2, IntersectionPointY2, IntersectionPointZ2;

	float TraverseX1, TraverseY1, TraverseZ1;
	float TraverseX2, TraverseY2, TraverseZ2;

	float Epsilon;

	VoxelType VoxelCheckResult;

	//	Epsilon := 0.001;
	Epsilon = 0.1;

	float TileWidth = 16.0;
	float TileHeight = 16.0;
	float TileDepth = 24.0;

	// calculate max voxel position
	int vFirstMapTileX = CollisionTileX;
	int vFirstMapTileY = CollisionTileY;
	int vFirstMapTileZ = CollisionTileZ;

	int vMapVoxelBoundaryMinX = vFirstMapTileX * TileWidth;
	int vMapVoxelBoundaryMinY = vFirstMapTileY * TileHeight;
	int vMapVoxelBoundaryMinZ = vFirstMapTileZ * TileDepth;

	int vLastMapTileX = CollisionTileX;
	int vLastMapTileY = CollisionTileY;
	int vLastMapTileZ = CollisionTileZ;

	int vLastTileVoxelX = TileWidth-1;
	int vLastTileVoxelY = TileHeight-1;
	int vLastTileVoxelZ = TileDepth-1;

	int vMapVoxelBoundaryMaxX = (vLastMapTileX*TileWidth) + vLastTileVoxelX;
	int vMapVoxelBoundaryMaxY = (vLastMapTileY*TileHeight) + vLastTileVoxelY;
	int vMapVoxelBoundaryMaxZ = (vLastMapTileZ*TileDepth) + vLastTileVoxelZ;

	int TileVoxelX, TileVoxelY, TileVoxelZ;

	//start and end points
	x1 = StartX;	 x2 = StopX;
	y1 = StartY;	 y2 = StopY;
	z1 = StartZ;	 z2 = StopZ;

	{
		// check if both points are in grid
		if
		(
			NoShitPointInBoxSingle
			(
				x1, y1, z1,

				vMapVoxelBoundaryMinX,
				vMapVoxelBoundaryMinY,
				vMapVoxelBoundaryMinZ,

				vMapVoxelBoundaryMaxX-Epsilon,
				vMapVoxelBoundaryMaxY-Epsilon,
				vMapVoxelBoundaryMaxZ-Epsilon
			)
			&&
			NoShitPointInBoxSingle
			(
				x2, y2, z2,

				vMapVoxelBoundaryMinX,
				vMapVoxelBoundaryMinY,
				vMapVoxelBoundaryMinZ,

				vMapVoxelBoundaryMaxX-Epsilon,
				vMapVoxelBoundaryMaxY-Epsilon,
				vMapVoxelBoundaryMaxZ-Epsilon
			)
		)
		{
			// just fall through to next code below
			// traverse
		}
		else
		// check if line intersects box
		if
		(
			NoShitLineSegmentIntersectsBoxSingle
			(
				x1,y1,z1,
				x2,y2,z2,

				vMapVoxelBoundaryMinX,
				vMapVoxelBoundaryMinY,
				vMapVoxelBoundaryMinZ,

				vMapVoxelBoundaryMaxX-Epsilon,
				vMapVoxelBoundaryMaxY-Epsilon,
				vMapVoxelBoundaryMaxZ-Epsilon,

				&IntersectionPoint1,
				&IntersectionPointX1,
				&IntersectionPointY1,
				&IntersectionPointZ1,

				&IntersectionPoint2,
				&IntersectionPointX2,
				&IntersectionPointY2,
				&IntersectionPointZ2
			) == true
		)
		{
			if (IntersectionPoint1 == true)
			{
				TraverseX1 = IntersectionPointX1;
				TraverseY1 = IntersectionPointY1;
				TraverseZ1 = IntersectionPointZ1;
			}
			else
			{
				TraverseX1 = x1;
				TraverseY1 = y1;
				TraverseZ1 = z1;
			}

			// compensate for any floating point errors (inaccuracies)
			TraverseX1 = NoShitMaxSingle( TraverseX1, vMapVoxelBoundaryMinX );
			TraverseY1 = NoShitMaxSingle( TraverseY1, vMapVoxelBoundaryMinY );
			TraverseZ1 = NoShitMaxSingle( TraverseZ1, vMapVoxelBoundaryMinZ );

			TraverseX1 = NoShitMinSingle( TraverseX1, vMapVoxelBoundaryMaxX-Epsilon );
			TraverseY1 = NoShitMinSingle( TraverseY1, vMapVoxelBoundaryMaxY-Epsilon );
			TraverseZ1 = NoShitMinSingle( TraverseZ1, vMapVoxelBoundaryMaxZ-Epsilon );

			if (IntersectionPoint2 == true)
			{
				TraverseX2 = IntersectionPointX2;
				TraverseY2 = IntersectionPointY2;
				TraverseZ2 = IntersectionPointZ2;
			}
			else
			{
				TraverseX2 = x2;
				TraverseY2 = y2;
				TraverseZ2 = z2;
			}

			// compensate for any floating point errors (inaccuracies)
			TraverseX2 = NoShitMaxSingle( TraverseX2, vMapVoxelBoundaryMinX );
			TraverseY2 = NoShitMaxSingle( TraverseY2, vMapVoxelBoundaryMinY );
			TraverseZ2 = NoShitMaxSingle( TraverseZ2, vMapVoxelBoundaryMinZ );

			TraverseX2 = NoShitMinSingle( TraverseX2, vMapVoxelBoundaryMaxX-Epsilon );
			TraverseY2 = NoShitMinSingle( TraverseY2, vMapVoxelBoundaryMaxY-Epsilon );
			TraverseZ2 = NoShitMinSingle( TraverseZ2, vMapVoxelBoundaryMaxZ-Epsilon );

			{
				// just fall through below
				// traverse
				x1 = TraverseX1; 
				y1 = TraverseY1;
				z1 = TraverseZ1; 

				x2 = TraverseX2; 
				y2 = TraverseY2;
				z2 = TraverseZ2; 
			}
		}
	}

	// traverse code, fast voxel traversal algorithm
	int dx = NoShitSignSingle(x2 - x1);
	if (dx != 0) tDeltaX = fmin(dx / (x2 - x1), 10000000.0f); else tDeltaX = 10000000.0f;
	if (dx > 0) tMaxX = tDeltaX * NoShitFrac1Single(x1); else tMaxX = tDeltaX * NoShitFrac0Single(x1);
	VoxelX = (int) x1;

	int dy = NoShitSignSingle(y2 - y1);
	if (dy != 0) tDeltaY = fmin(dy / (y2 - y1), 10000000.0f); else tDeltaY = 10000000.0f;
	if (dy > 0) tMaxY = tDeltaY * NoShitFrac1Single(y1); else tMaxY = tDeltaY * NoShitFrac0Single(y1);
	VoxelY = (int) y1;

	int dz = NoShitSignSingle(z2 - z1);
	if (dz != 0) tDeltaZ = fmin(dz / (z2 - z1), 10000000.0f); else tDeltaZ = 10000000.0f;
	if (dz > 0) tMaxZ = tDeltaZ * NoShitFrac1Single(z1); else tMaxZ = tDeltaZ * NoShitFrac0Single(z1);
	VoxelZ = (int) z1;

	if (dx > 0) OutX = vMapVoxelBoundaryMaxX+1; else OutX = vMapVoxelBoundaryMinX-1;
	if (dy > 0) OutY = vMapVoxelBoundaryMaxY+1; else OutY = vMapVoxelBoundaryMinY-1;
	if (dz > 0) OutZ = vMapVoxelBoundaryMaxZ+1; else OutZ = vMapVoxelBoundaryMinZ-1;

	bool Hits = 0;
	t = 0;
	while (t <= 1.0)
	{
		// process voxel

		Tile *CheckTile = ParaSave->getTile(Position(CollisionTileX,CollisionTileY,CollisionTileZ));

		VoxelCheckResult = WhoreOfAVoxelCheck( ParaSave->getTileEngine(), Position(VoxelX,VoxelY,VoxelZ), CheckTile );

		if (VoxelCheckResult != V_EMPTY)
		{
			*CollisionVoxelX = VoxelX;
			*CollisionVoxelY = VoxelY;
			*CollisionVoxelZ = VoxelZ;
			return true;
		}

		// go to next voxel
		if ( (tMaxX < tMaxY) && (tMaxX < tMaxZ) )
		{
			t = tMaxX;
			VoxelX += dx;
			tMaxX += tDeltaX;

			if (VoxelX == OutX) break;
		}
		else
		if (tMaxY < tMaxZ)
		{
			t = tMaxY;
			VoxelY += dy;
			tMaxY += tDeltaY;

			if (VoxelY == OutY) break;
		}
		else
		{
			t = tMaxZ;
			VoxelZ += dz;
			tMaxZ += tDeltaZ;

			if (VoxelZ == OutZ) break;
		}
	}

	return false;
}

bool TileTraverseCollision
(
	SavedBattleGame *ParaSave,
	float StartX, float StartY, float StartZ,
	float StopX, float StopY, float StopZ,
	int *CollisionTileX, int *CollisionTileY, int *CollisionTileZ
)
{
	int result;
	float x1, y1, z1; // start point
	float x2, y2, z2; // end point

	float tMaxX, tMaxY, tMaxZ, t, tDeltaX, tDeltaY, tDeltaZ;

	int TileX, TileY, TileZ;

	int OutX, OutY, OutZ;

	bool IntersectionPoint1;
	bool IntersectionPoint2;

	float IntersectionPointX1, IntersectionPointY1, IntersectionPointZ1;
	float IntersectionPointX2, IntersectionPointY2, IntersectionPointZ2;

	float TraverseX1, TraverseY1, TraverseZ1;
	float TraverseX2, TraverseY2, TraverseZ2;

	float Epsilon;

	VoxelType VoxelCheckResult;

	//	Epsilon := 0.001;
	Epsilon = 0.1;

	float TileWidth = 16.0;
	float TileHeight = 16.0;
	float TileDepth = 24.0;

	// calculate max voxel position
	int vMapVoxelBoundaryMinX = 0;
	int vMapVoxelBoundaryMinY = 0;
	int vMapVoxelBoundaryMinZ = 0;

	int vFirstMapTileX = 0;
	int vFirstMapTileY = 0;
	int vFirstMapTileZ = 0;

	int vLastMapTileX = (ParaSave->getMapSizeX()-1);
	int vLastMapTileY = (ParaSave->getMapSizeY()-1);
	int vLastMapTileZ = (ParaSave->getMapSizeZ()-1);

	//start and end points
	x1 = StartX;	 x2 = StopX;
	y1 = StartY;	 y2 = StopY;
	z1 = StartZ;	 z2 = StopZ;

	{
		// check if both points are in grid
		if
		(
			NoShitPointInBoxSingle
			(
				x1, y1, z1,

				vFirstMapTileX,
				vFirstMapTileY,
				vFirstMapTileZ,

				vLastMapTileX-Epsilon,
				vLastMapTileY-Epsilon,
				vLastMapTileZ-Epsilon
			)
			&&
			NoShitPointInBoxSingle
			(
				x2, y2, z2,

				vFirstMapTileX,
				vFirstMapTileY,
				vFirstMapTileZ,

				vLastMapTileX-Epsilon,
				vLastMapTileY-Epsilon,
				vLastMapTileZ-Epsilon
			)
		)
		{
			// just fall through to next code below
			// traverse
		}
		else
		// check if line intersects box
		if
		(
			NoShitLineSegmentIntersectsBoxSingle
			(
				x1,y1,z1,
				x2,y2,z2,

				vFirstMapTileX,
				vFirstMapTileY,
				vFirstMapTileZ,

				vLastMapTileX-Epsilon,
				vLastMapTileY-Epsilon,
				vLastMapTileZ-Epsilon,

				&IntersectionPoint1,
				&IntersectionPointX1,
				&IntersectionPointY1,
				&IntersectionPointZ1,

				&IntersectionPoint2,
				&IntersectionPointX2,
				&IntersectionPointY2,
				&IntersectionPointZ2
			) == true
		)
		{
			if (IntersectionPoint1 == true)
			{
				TraverseX1 = IntersectionPointX1;
				TraverseY1 = IntersectionPointY1;
				TraverseZ1 = IntersectionPointZ1;
			}
			else
			{
				TraverseX1 = x1;
				TraverseY1 = y1;
				TraverseZ1 = z1;
			}

			// compensate for any floating point errors (inaccuracies)
			TraverseX1 = NoShitMaxSingle( TraverseX1, vFirstMapTileX );
			TraverseY1 = NoShitMaxSingle( TraverseY1, vFirstMapTileY );
			TraverseZ1 = NoShitMaxSingle( TraverseZ1, vFirstMapTileZ );

			TraverseX1 = NoShitMinSingle( TraverseX1, vLastMapTileX-Epsilon );
			TraverseY1 = NoShitMinSingle( TraverseY1, vLastMapTileY-Epsilon );
			TraverseZ1 = NoShitMinSingle( TraverseZ1, vLastMapTileZ-Epsilon );

			if (IntersectionPoint2 == true)
			{
				TraverseX2 = IntersectionPointX2;
				TraverseY2 = IntersectionPointY2;
				TraverseZ2 = IntersectionPointZ2;
			}
			else
			{
				TraverseX2 = x2;
				TraverseY2 = y2;
				TraverseZ2 = z2;
			}

			// compensate for any floating point errors (inaccuracies)
			TraverseX2 = NoShitMaxSingle( TraverseX2, vFirstMapTileX );
			TraverseY2 = NoShitMaxSingle( TraverseY2, vFirstMapTileY );
			TraverseZ2 = NoShitMaxSingle( TraverseZ2, vFirstMapTileZ );

			TraverseX2 = NoShitMinSingle( TraverseX2, vLastMapTileX-Epsilon );
			TraverseY2 = NoShitMinSingle( TraverseY2, vLastMapTileY-Epsilon );
			TraverseZ2 = NoShitMinSingle( TraverseZ2, vLastMapTileZ-Epsilon );

			{
				// just fall through below
				// traverse
				x1 = TraverseX1; 
				y1 = TraverseY1;
				z1 = TraverseZ1; 

				x2 = TraverseX2; 
				y2 = TraverseY2;
				z2 = TraverseZ2; 
			}
		}
	}

	// traverse code, fast voxel traversal algorithm
	int dx = NoShitSignSingle(x2 - x1);
	if (dx != 0) tDeltaX = fmin(dx / (x2 - x1), 10000000.0f); else tDeltaX = 10000000.0f;
	if (dx > 0) tMaxX = tDeltaX * NoShitFrac1Single(x1); else tMaxX = tDeltaX * NoShitFrac0Single(x1);
	TileX = (int) x1;

	int dy = NoShitSignSingle(y2 - y1);
	if (dy != 0) tDeltaY = fmin(dy / (y2 - y1), 10000000.0f); else tDeltaY = 10000000.0f;
	if (dy > 0) tMaxY = tDeltaY * NoShitFrac1Single(y1); else tMaxY = tDeltaY * NoShitFrac0Single(y1);
	TileY = (int) y1;

	int dz = NoShitSignSingle(z2 - z1);
	if (dz != 0) tDeltaZ = fmin(dz / (z2 - z1), 10000000.0f); else tDeltaZ = 10000000.0f;
	if (dz > 0) tMaxZ = tDeltaZ * NoShitFrac1Single(z1); else tMaxZ = tDeltaZ * NoShitFrac0Single(z1);
	TileZ = (int) z1;

	if (dx > 0) OutX = vLastMapTileX+1; else OutX = vFirstMapTileX-1;
	if (dy > 0) OutY = vLastMapTileY+1; else OutY = vFirstMapTileY-1;
	if (dz > 0) OutZ = vLastMapTileZ+1; else OutZ = vFirstMapTileZ-1;

	bool Hits = 0;
	t = 0;
	while (t <= 1.0)
	{
		Tile *CheckTile = ParaSave->getTile(Position(TileX,TileY,TileZ));

		if (!(CheckTile->isVoid()))
		{
			*CollisionTileX = TileX;
			*CollisionTileY = TileY;
			*CollisionTileZ = TileZ;
			return true;
		}

		// go to next voxel
		if ( (tMaxX < tMaxY) && (tMaxX < tMaxZ) )
		{
			t = tMaxX;
			TileX += dx;
			tMaxX += tDeltaX;

			if (TileX == OutX) break;
		}
		else
		if (tMaxY < tMaxZ)
		{
			t = tMaxY;
			TileY += dy;
			tMaxY += tDeltaY;

			if (TileY == OutY) break;
		}
		else
		{
			t = tMaxZ;
			TileZ += dz;
			tMaxZ += tDeltaZ;

			if (TileZ == OutZ) break;
		}
	}

	return false;
}





void LightCasting( SavedBattleGame *ParaSave, TileEngine *Te, Surface *Dst, int DstX, int DstY, Tile *Src, Position MapPosition )
{
/*
	static const int VoxelXtoSpriteX[16] =
	{1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16};

	static const int VoxelXtoSpriteY[16] =
	{0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7};

	static const int VoxelYtoSpriteX[16] =
	{0,-1,-2,-3,-4,-5,-6,-7,-8,-9,-10,-11,-12,-13,-14,-15};

	static const int VoxelYtoSpriteY[16] =
	{0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7};
*/

	int ComputedX[40 * 32];
	int ComputedY[40 * 32];
	int ComputedZ[40 * 32];

	int x, y;
	Uint8 VoxelColor;
	Uint8 FinalColor;

	int SpriteStartX, SpriteStartY;
	int SpriteX;
	float SpriteY;

	int VoxelX, VoxelY, VoxelZ;
	int MapVoxelX, MapVoxelY, MapVoxelZ;
	Uint8 TestColor;

//	double ComponentX, ComponentY;
	float ComponentX, ComponentY;
	int Component;

	Position VoxelPosition;
	VoxelType VoxelCheckResult;

	int SunX, SunY, SunZ;

	int vIndex;

	int Hits;

	bool TileCollision;
	bool VoxelHit;

	int CollisionTileX, CollisionTileY, CollisionTileZ;
	int CollisionVoxelX, CollisionVoxelY, CollisionVoxelZ;


	for ( vIndex = 0; vIndex < (40*32); vIndex++ )
	{
		ComputedZ[vIndex] = -1;
	}

	SpriteStartX = 15; // tile width
	SpriteStartY = 24; // tile depth

	Te->voxelCheckFlush();

	for (VoxelZ=23; VoxelZ >= 0; VoxelZ--)
	{
		for (VoxelY=15; VoxelY >= 0; VoxelY--)
		{
			for (VoxelX=15; VoxelX >= 0; VoxelX--)
			{
				SpriteX = (SpriteStartX + VoxelX) - VoxelY;


				// original:
//				SpriteY = ((SpriteStartY + (VoxelX / 2)) + (VoxelY / 2)) - VoxelZ;

				// more accurate:
//				ComponentX = VoxelX / 2;
//				ComponentY = VoxelY / 2;
//				SpriteY = (SpriteStartY + (ComponentX  + ComponentY)) - VoxelZ;

				// speed up:
				Component = VoxelX + VoxelY;
				Component = Component >> 1;

				SpriteY = (SpriteStartY + Component) - VoxelZ;

				// look up table version, not usefull
//				SpriteX = SpriteStartX + VoxelXtoSpriteX[VoxelX] + VoxelYtoSpriteX[VoxelY];
//				SpriteY = SpriteStartY + VoxelXtoSpriteY[VoxelX] + VoxelXtoSpriteY[VoxelY] - VoxelZ;

				vIndex = (SpriteY * 32) + SpriteX;

				if (ComputedZ[vIndex]==-1)
				{
					VoxelPosition.x = VoxelX;
					VoxelPosition.y = VoxelY;
					VoxelPosition.z = VoxelZ;

					VoxelCheckResult = WhoreOfAVoxelCheck( Te, VoxelPosition, Src );

					if (VoxelCheckResult != V_EMPTY)
					{
						ComputedX[vIndex] = VoxelX;
						ComputedY[vIndex] = VoxelY;
						ComputedZ[vIndex] = VoxelZ;
					}


				}
			}
		}
	}

//	SunX = 25 * 16;
//	SunY = 25 * 16;
//	SunZ = 10 * 24;

	SunX = 25;
	SunY = 25;
	SunZ = 10;


//	SunX = 10;
//	SunY = 13;
//	SunZ = 20;

	for (SpriteY = 0; SpriteY < 40; SpriteY++)
	{
		for (SpriteX = 0; SpriteX < 32; SpriteX++)
		{
			vIndex = (SpriteY * 32) + SpriteX;
			if (ComputedZ[vIndex]!=-1)
			{
				MapVoxelX = ComputedX[vIndex] + MapPosition.x * 16;
				MapVoxelY = ComputedY[vIndex] + MapPosition.y * 16;
				MapVoxelZ = ComputedZ[vIndex] + MapPosition.z * 24;

				TileCollision = TileTraverseCollision
				(
					ParaSave,
					SunX, SunY, SunZ,
					MapPosition.x,MapPosition.y,MapPosition.z,
					&CollisionTileX, &CollisionTileY, &CollisionTileZ
				);

				/*
				// tile voxel boundary in total voxel coordinates
				CollisionTileBoundaryMinX = CollisionTileX * 16;
				CollisionTileBoundaryMinY = CollisionTileY * 16;
				CollisionTileBoundaryMinZ = CollisionTileZ * 16;

				CollisionTileBoundaryMaxX = CollisionTileBoundaryMinX + 15;
				CollisionTileBoundaryMaxY = CollisionTileBoundaryMinY + 15;
				CollisionTileBoundaryMaxZ = CollisionTileBoundaryMinZ + 23;
				*/

				if (TileCollision)
				{
					VoxelHit = VoxelTraverseHit
					(
						ParaSave,
						SunX, SunY, SunZ,
						MapVoxelX, MapVoxelY, MapVoxelZ,
						CollisionTileX, CollisionTileY, CollisionTileZ,
						&CollisionVoxelX,&CollisionVoxelY,&CollisionVoxelZ
					);	

					if (VoxelHit)
					{
						if
						(
							(
								(CollisionVoxelX == VoxelX) &&
								(CollisionVoxelY == VoxelY) &&
								(CollisionVoxelZ == VoxelZ)
							) == false
						)
						{
							Dst->setPixel( DstX + SpriteX, DstY + SpriteY, 0);
						}
					}

				}


			}
		}
	}

}











/*


void rotate( float OldX, float OldY, float *NewX, float *NewY, float Radians )
{
    *NewX = (OldX * cos( Radians )) - (OldX * sin( Radians ));
    *NewY = (OldX * sin( Radians )) + (OldX * cos( Radians ));
}

void FullRetardModeOn( TileEngine *Te, Surface *Dst, int DstX, int DstY, Tile *Src )
{
	int x, y;
	int VoxelX, VoxelY, VoxelZ;
	int SpriteX, SpriteY;

	for (SpriteY=0; SpriteY<40; SpriteY++)
	{
		for (SpriteX=15; SpriteX>=0; SpriteX--)
		{
			// shoot ray into voxel cube ???? yes...

			VoxelY = VoxelY 


		}

		for (SpriteX=16; SpriteX<32; SpriteX++)
		{
			// shoot ray into voxel cube... where SpriteX-1 ?!
		}
	}
}

*/

/**
 * Draw the terrain.
 * Keep this function as optimised as possible. It's big to minimise overhead of function calls.
 * @param surface The surface to draw on.
 */
void Map::drawTerrain(Surface *surface)
{
	int frameNumber = 0;
	Surface *tmpSurface;
	Tile *tile;
	int beginX = 0, endX = _save->getMapSizeX() - 1;
	int beginY = 0, endY = _save->getMapSizeY() - 1;
	int beginZ = 0, endZ = _camera->getShowAllLayers()?_save->getMapSizeZ() - 1:_camera->getViewLevel();
	Position mapPosition, screenPosition, bulletPositionScreen;
	int bulletLowX=16000, bulletLowY=16000, bulletLowZ=16000, bulletHighX=0, bulletHighY=0, bulletHighZ=0;
	int dummy;
	BattleUnit *unit = 0;
	int tileShade, wallShade, tileColor, obstacleShade;
	static const int arrowBob[8] = {0,1,2,1,0,1,2,1};

	NumberText *_numWaypid = 0;

	// get corner map coordinates to give rough boundaries in which tiles to redraw are
	_camera->convertScreenToMap(0, 0, &beginX, &dummy);
	_camera->convertScreenToMap(surface->getWidth(), 0, &dummy, &beginY);
	_camera->convertScreenToMap(surface->getWidth() + _spriteWidth, surface->getHeight() + _spriteHeight, &endX, &dummy);
	_camera->convertScreenToMap(0, surface->getHeight() + _spriteHeight, &dummy, &endY);
	beginY -= (_camera->getViewLevel() * 2);
	beginX -= (_camera->getViewLevel() * 2);
	if (beginX < 0)
		beginX = 0;
	if (beginY < 0)
		beginY = 0;

	bool pathfinderTurnedOn = _save->getPathfinding()->isPathPreviewed();

	if (!_waypoints.empty() || (pathfinderTurnedOn && (_previewSetting & PATH_TU_COST)))
	{
		_numWaypid = new NumberText(15, 15, 20, 30);
		_numWaypid->setPalette(getPalette());
		_numWaypid->setColor(pathfinderTurnedOn ? _messageColor + 1 : Palette::blockOffset(1));
	}

	surface->lock();

	EatShitAndDie++;


	for (int itZ = beginZ; itZ <= endZ; itZ = itZ + 1)
	{
		bool topLayer = itZ == endZ;
		for (int itX = beginX; itX <= endX; itX = itX + 1)
		{
			for (int itY = beginY; itY <= endY; itY = itY + 1)
			{
				mapPosition = Position(itX, itY, itZ);
				_camera->convertMapToScreen(mapPosition, &screenPosition);
				screenPosition += _camera->getMapOffset();
/*
				// only render cells that are inside the surface
				if
				(
					(screenPosition.x > -_spriteWidth) && (screenPosition.x < surface->getWidth() + _spriteWidth) &&
					(screenPosition.y > -_spriteHeight) && (screenPosition.y < surface->getHeight() + _spriteHeight)
				)
				{
					tile = _save->getTile(mapPosition);

					if (!tile) continue;


					if (tile->isDiscovered(2))
					{
						tileShade = tile->getShade();
//						tileShade = double(7.5 + cos( (itX/30.0) * (3.14 * 2) )  * 7.5);
//						tileShade = double(7.5 + cos( ((_animFrame+itX)/30.0) * (3.14 * 2) )  * 7.5);
//						tileShade = double(7.5 + cos( ((EatShitAndDie+itX)/30.0) * (3.14 * 2) )  * 7.5); // cool UFO DISCO

						obstacleShade = tileShade;
						if (_showObstacles)
						{
							if (tile->isObstacle())
							{
								if (tileShade > 7) obstacleShade = 7;
								if (tileShade < 2) obstacleShade = 2;
								obstacleShade += (arrowBob[_animFrame] * 2 - 2);
							}
						}
					}
					else
					{
						tileShade = 16;
						obstacleShade = 16;
						unit = 0;
					}

					tileColor = tile->getMarkerColor();

					// Draw floor
					tmpSurface = tile->getSprite(O_FLOOR);
					if (tmpSurface)
					{
						if (tile->getObstacle(O_FLOOR))
							tmpSurface->blitNShade(surface, screenPosition.x, screenPosition.y - tile->getMapData(O_FLOOR)->getYOffset(), obstacleShade, false);
						else
							tmpSurface->blitNShade(surface, screenPosition.x, screenPosition.y - tile->getMapData(O_FLOOR)->getYOffset(), tileShade, false);
					}
					unit = tile->getUnit();

					// Draw cursor back
//					frameNumber = 2; // blue box
//					tmpSurface = _game->getMod()->getSurfaceSet("CURSOR.PCK")->getFrame(frameNumber);
//					tmpSurface->blitNShade(surface, screenPosition.x, screenPosition.y, 0);


					// special handling for a moving unit in background of tile.
					const int backPosSize = 3;
					Position backPos[backPosSize] =
					{
						Position(0, -1, 0),
						Position(-1, -1, 0),
						Position(-1, 0, 0),
					};

					for (int b = 0; b < backPosSize; ++b)
					{
						drawUnit(surface, _save->getTile(mapPosition + backPos[b]), tile, screenPosition, tileShade, obstacleShade, topLayer);
					}

					// Draw walls
					if (!tile->isVoid())
					{
						// Draw west wall
						tmpSurface = tile->getSprite(O_WESTWALL);
						if (tmpSurface)
						{
							if ((tile->getMapData(O_WESTWALL)->isDoor() || tile->getMapData(O_WESTWALL)->isUFODoor())
								 && tile->isDiscovered(0))
								wallShade = tile->getShade();
							else
								wallShade = tileShade;
							if (tile->getObstacle(O_WESTWALL))
								tmpSurface->blitNShade(surface, screenPosition.x, screenPosition.y - tile->getMapData(O_WESTWALL)->getYOffset(), obstacleShade, false);
							else
								tmpSurface->blitNShade(surface, screenPosition.x, screenPosition.y - tile->getMapData(O_WESTWALL)->getYOffset(), wallShade, false);
						}
						// Draw north wall
						tmpSurface = tile->getSprite(O_NORTHWALL);
						if (tmpSurface)
						{
							if ((tile->getMapData(O_NORTHWALL)->isDoor() || tile->getMapData(O_NORTHWALL)->isUFODoor())
								 && tile->isDiscovered(1))
								wallShade = tile->getShade();
							else
								wallShade = tileShade;
							if (tile->getObstacle(O_NORTHWALL))
								tmpSurface->blitNShade(surface, screenPosition.x, screenPosition.y - tile->getMapData(O_NORTHWALL)->getYOffset(), obstacleShade, tile->getMapData(O_WESTWALL) != 0);
							else
								tmpSurface->blitNShade(surface, screenPosition.x, screenPosition.y - tile->getMapData(O_NORTHWALL)->getYOffset(), wallShade, tile->getMapData(O_WESTWALL) != 0);
						}


						// Draw object
						if (tile->getMapData(O_OBJECT) && (tile->getMapData(O_OBJECT)->getBigWall() < 6 || tile->getMapData(O_OBJECT)->getBigWall() == 9))
						{
							tmpSurface = tile->getSprite(O_OBJECT);
							if (tmpSurface)
							{
								if (tile->getObstacle(O_OBJECT))
									tmpSurface->blitNShade(surface, screenPosition.x, screenPosition.y - tile->getMapData(O_OBJECT)->getYOffset(), obstacleShade, false);
								else
									tmpSurface->blitNShade(surface, screenPosition.x, screenPosition.y - tile->getMapData(O_OBJECT)->getYOffset(), tileShade, false);
							}
						}
						// draw an item on top of the floor (if any)
						int sprite = tile->getTopItemSprite();
						if (sprite != -1)
						{
							tmpSurface = _game->getMod()->getSurfaceSet("FLOOROB.PCK")->getFrame(sprite);
							tmpSurface->blitNShade(surface, screenPosition.x, screenPosition.y + tile->getTerrainLevel(), tileShade, false);
						}

					}


					unit = tile->getUnit();
					// Draw soldier from this tile or below
					drawUnit(surface, tile, tile, screenPosition, tileShade, obstacleShade, topLayer);

					// special handling for a moving unit in forground of tile.
					const int frontPosSize = 5;
					Position frontPos[frontPosSize] =
					{
						Position(-1, +1, 0),
						Position(0, +1, 0),
						Position(+1, +1, 0),
						Position(+1, 0, 0),
						Position(+1, -1, 0),
					};

					for (int f = 0; f < frontPosSize; ++f)
					{
						drawUnit(surface, _save->getTile(mapPosition + frontPos[f]), tile, screenPosition, tileShade, obstacleShade, topLayer);
					}





					// Draw cursor front
					{
							frameNumber = 5; // blue box
							tmpSurface = _game->getMod()->getSurfaceSet("CURSOR.PCK")->getFrame(frameNumber);
//							tmpSurface->blitNShade(surface, screenPosition.x, screenPosition.y, 0);
							FaggotShitDraw( surface, screenPosition.x, screenPosition.y, tmpSurface );
					}


				}
*/

				if
				(
					(screenPosition.x > -_spriteWidth) && (screenPosition.x < surface->getWidth() + _spriteWidth) &&
					(screenPosition.y > -_spriteHeight) && (screenPosition.y < surface->getHeight() + _spriteHeight)
				)
				{
					tile = _save->getTile(mapPosition);

					if (!tile) continue;


					if (tile->isDiscovered(2))
					{
						tileShade = tile->getShade();
//						tileShade = double(7.5 + cos( (itX/30.0) * (3.14 * 2) )  * 7.5);
//						tileShade = double(7.5 + cos( ((_animFrame+itX)/30.0) * (3.14 * 2) )  * 7.5);
//						tileShade = double(7.5 + cos( ((EatShitAndDie+itX)/30.0) * (3.14 * 2) )  * 7.5); // cool UFO DISCO

						obstacleShade = tileShade;
						if (_showObstacles)
						{
							if (tile->isObstacle())
							{
								if (tileShade > 7) obstacleShade = 7;
								if (tileShade < 2) obstacleShade = 2;
								obstacleShade += (arrowBob[_animFrame] * 2 - 2);
							}
						}
					}
					else
					{
						tileShade = 16;
						obstacleShade = 16;
						unit = 0;
					}

					tileColor = tile->getMarkerColor();

					// Draw floor
					tmpSurface = tile->getSprite(O_FLOOR);
					if (tmpSurface)
					{
						if (tile->getObstacle(O_FLOOR))
							DrawSprite(surface, screenPosition.x, screenPosition.y - tile->getMapData(O_FLOOR)->getYOffset(), tmpSurface );
						else
							DrawSprite(surface, screenPosition.x, screenPosition.y - tile->getMapData(O_FLOOR)->getYOffset(), tmpSurface );
					}
					unit = tile->getUnit();

/*
					// Draw cursor back
					frameNumber = 2; // blue box
					tmpSurface = _game->getMod()->getSurfaceSet("CURSOR.PCK")->getFrame(frameNumber);
					tmpSurface->blitNShade(surface, screenPosition.x, screenPosition.y, 0);
*/

/*
					// special handling for a moving unit in background of tile.
					const int backPosSize = 3;
					Position backPos[backPosSize] =
					{
						Position(0, -1, 0),
						Position(-1, -1, 0),
						Position(-1, 0, 0),
					};

					for (int b = 0; b < backPosSize; ++b)
					{
						drawUnit(surface, _save->getTile(mapPosition + backPos[b]), tile, screenPosition, tileShade, obstacleShade, topLayer);
					}
*/
					// Draw walls
					if (!tile->isVoid())
					{
						// Draw west wall
						tmpSurface = tile->getSprite(O_WESTWALL);
						if (tmpSurface)
						{
							if ((tile->getMapData(O_WESTWALL)->isDoor() || tile->getMapData(O_WESTWALL)->isUFODoor())
								 && tile->isDiscovered(0))
								wallShade = tile->getShade();
							else
								wallShade = tileShade;
							if (tile->getObstacle(O_WESTWALL))
								DrawSprite(surface, screenPosition.x, screenPosition.y - tile->getMapData(O_WESTWALL)->getYOffset(), tmpSurface );
							else
								DrawSprite(surface, screenPosition.x, screenPosition.y - tile->getMapData(O_WESTWALL)->getYOffset(), tmpSurface );;
						}
						// Draw north wall
						tmpSurface = tile->getSprite(O_NORTHWALL);
						if (tmpSurface)
						{
							if ((tile->getMapData(O_NORTHWALL)->isDoor() || tile->getMapData(O_NORTHWALL)->isUFODoor())
								 && tile->isDiscovered(1))
								wallShade = tile->getShade();
							else
								wallShade = tileShade;
							if (tile->getObstacle(O_NORTHWALL))
								DrawSprite(surface, screenPosition.x, screenPosition.y - tile->getMapData(O_NORTHWALL)->getYOffset(), tmpSurface );
							else
								DrawSprite(surface, screenPosition.x, screenPosition.y - tile->getMapData(O_NORTHWALL)->getYOffset(), tmpSurface );
						}


						// Draw object
						if (tile->getMapData(O_OBJECT) && (tile->getMapData(O_OBJECT)->getBigWall() < 6 || tile->getMapData(O_OBJECT)->getBigWall() == 9))
						{
							tmpSurface = tile->getSprite(O_OBJECT);
							if (tmpSurface)
							{
								if (tile->getObstacle(O_OBJECT))
									DrawSprite(surface, screenPosition.x, screenPosition.y - tile->getMapData(O_OBJECT)->getYOffset(), tmpSurface );
								else
									DrawSprite(surface, screenPosition.x, screenPosition.y - tile->getMapData(O_OBJECT)->getYOffset(), tmpSurface );
							}
						}
						// draw an item on top of the floor (if any)
						int sprite = tile->getTopItemSprite();
						if (sprite != -1)
						{
							tmpSurface = _game->getMod()->getSurfaceSet("FLOOROB.PCK")->getFrame(sprite);
							DrawSprite(surface, screenPosition.x, screenPosition.y + tile->getTerrainLevel(), tmpSurface );
						}

					}

/*

					unit = tile->getUnit();
					// Draw soldier from this tile or below
					drawUnit(surface, tile, tile, screenPosition, tileShade, obstacleShade, topLayer);
*/

/*
					// special handling for a moving unit in forground of tile.
					const int frontPosSize = 5;
					Position frontPos[frontPosSize] =
					{
						Position(-1, +1, 0),
						Position(0, +1, 0),
						Position(+1, +1, 0),
						Position(+1, 0, 0),
						Position(+1, -1, 0),
					};

					for (int f = 0; f < frontPosSize; ++f)
					{
						drawUnit(surface, _save->getTile(mapPosition + frontPos[f]), tile, screenPosition, tileShade, obstacleShade, topLayer);
					}

*/


/*
					// Draw cursor front
					{
							frameNumber = 5; // blue box
							tmpSurface = _game->getMod()->getSurfaceSet("CURSOR.PCK")->getFrame(frameNumber);
//							tmpSurface->blitNShade(surface, screenPosition.x, screenPosition.y, 0);
							DrawSprite( surface, screenPosition.x, screenPosition.y, tmpSurface );
					}
*/

//					DrawVoxelDataInsteadOfSprite( _save->getTileEngine(), surface, screenPosition.x, screenPosition.y, tile );  
//					DrawLoftInsteadOfSprite( _save->getTileEngine(), surface, screenPosition.x, screenPosition.y, tile );  


//					DrawCombinedSurfaceAndLoft( _save->getTileEngine(), surface, screenPosition.x, screenPosition.y, tile );  

//					DrawLoftInsteadOfSpriteFatVoxels( _save->getTileEngine(), surface, screenPosition.x, screenPosition.y, tile ); 
//					DrawLoftAndSurfaceCombinedFatVoxels( _save->getTileEngine(), surface, screenPosition.x, screenPosition.y, tile );

					// draws a pre-computed sprite voxel frame

					// tile part doesn't really matter much except for animation frame,
					// all tile parts are merged together in a single voxel frame
					// they are seperated per animation though, each animation frame has it's own sprite voxel frame
					DrawSpriteVoxelFrame( surface, screenPosition.x, screenPosition.y, tile, O_FLOOR );

//					LightCasting( _save, _save->getTileEngine(), surface, screenPosition.x, screenPosition.y, tile, mapPosition );  

				}
			}
		}
	}

	surface->unlock();
}

/**
 * Handles mouse presses on the map.
 * @param action Pointer to an action.
 * @param state State that the action handlers belong to.
 */
void Map::mousePress(Action *action, State *state)
{
	InteractiveSurface::mousePress(action, state);
	_camera->mousePress(action, state);
}

/**
 * Handles mouse releases on the map.
 * @param action Pointer to an action.
 * @param state State that the action handlers belong to.
 */
void Map::mouseRelease(Action *action, State *state)
{
	InteractiveSurface::mouseRelease(action, state);
	_camera->mouseRelease(action, state);
}

/**
 * Handles keyboard presses on the map.
 * @param action Pointer to an action.
 * @param state State that the action handlers belong to.
 */
void Map::keyboardPress(Action *action, State *state)
{
	InteractiveSurface::keyboardPress(action, state);
	_camera->keyboardPress(action, state);
}

/**
 * Handles keyboard releases on the map.
 * @param action Pointer to an action.
 * @param state State that the action handlers belong to.
 */
void Map::keyboardRelease(Action *action, State *state)
{
	InteractiveSurface::keyboardRelease(action, state);
	_camera->keyboardRelease(action, state);
}

/**
 * Handles mouse over events on the map.
 * @param action Pointer to an action.
 * @param state State that the action handlers belong to.
 */
void Map::mouseOver(Action *action, State *state)
{
	InteractiveSurface::mouseOver(action, state);
	_camera->mouseOver(action, state);
	_mouseX = (int)action->getAbsoluteXMouse();
	_mouseY = (int)action->getAbsoluteYMouse();
	setSelectorPosition(_mouseX, _mouseY);
}


/**
 * Sets the selector to a certain tile on the map.
 * @param mx mouse x position.
 * @param my mouse y position.
 */
void Map::setSelectorPosition(int mx, int my)
{
	int oldX = _selectorX, oldY = _selectorY;

	_camera->convertScreenToMap(mx, my + _spriteHeight/4, &_selectorX, &_selectorY);

	if (oldX != _selectorX || oldY != _selectorY)
	{
		_redraw = true;
	}
}

/**
 * Handles animating tiles. 8 Frames per animation.
 * @param redraw Redraw the battlescape?
 */
void Map::animate(bool redraw)
{
	_animFrame++;
	if (_animFrame == 8) _animFrame = 0;

	// animate tiles
	for (int i = 0; i < _save->getMapSizeXYZ(); ++i)
	{
		_save->getTiles()[i]->animate();
	}

	// animate certain units (large flying units have a propulsion animation)
	for (std::vector<BattleUnit*>::iterator i = _save->getUnits()->begin(); i != _save->getUnits()->end(); ++i)
	{
		if (_save->getDepth() > 0 && !(*i)->getFloorAbove())
		{
			(*i)->breathe();
		}
		if (!(*i)->isOut())
		{
			if ((*i)->getArmor()->getConstantAnimation())
			{
				(*i)->setCache(0);
				cacheUnit(*i);
			}
		}
	}

	if (redraw) _redraw = true;
}

/**
 * Draws the rectangle selector.
 * @param pos Pointer to a position.
 */
void Map::getSelectorPosition(Position *pos) const
{
	pos->x = _selectorX;
	pos->y = _selectorY;
	pos->z = _camera->getViewLevel();
}

/**
 * Calculates the offset of a soldier, when it is walking in the middle of 2 tiles.
 * @param unit Pointer to BattleUnit.
 * @param offset Pointer to the offset to return the calculation.
 */
void Map::calculateWalkingOffset(BattleUnit *unit, Position *offset, int *shadeOffset)
{
	int offsetX[8] = { 1, 1, 1, 0, -1, -1, -1, 0 };
	int offsetY[8] = { 1, 0, -1, -1, -1, 0, 1, 1 };
	int phase = unit->getWalkingPhase() + unit->getDiagonalWalkingPhase();
	int dir = unit->getDirection();
	int midphase = 4 + 4 * (dir % 2);
	int endphase = 8 + 8 * (dir % 2);
	int size = unit->getArmor()->getSize();

	if (shadeOffset)
	{
		*shadeOffset = endphase == 16 ? phase : phase * 2;
	}

	if (size > 1)
	{
		if (dir < 1 || dir > 5)
			midphase = endphase;
		else if (dir == 5)
			midphase = 12;
		else if (dir == 1)
			midphase = 5;
		else
			midphase = 1;
	}
	if (unit->getVerticalDirection())
	{
		midphase = 4;
		endphase = 8;
	}
	else
	if ((unit->getStatus() == STATUS_WALKING || unit->getStatus() == STATUS_FLYING))
	{
		if (phase < midphase)
		{
			offset->x = phase * 2 * offsetX[dir];
			offset->y = - phase * offsetY[dir];
		}
		else
		{
			offset->x = (phase - endphase) * 2 * offsetX[dir];
			offset->y = - (phase - endphase) * offsetY[dir];
		}
	}

	// If we are walking in between tiles, interpolate it's terrain level.
	if (unit->getStatus() == STATUS_WALKING || unit->getStatus() == STATUS_FLYING)
	{
		if (phase < midphase)
		{
			int fromLevel = getTerrainLevel(unit->getPosition(), size);
			int toLevel = getTerrainLevel(unit->getDestination(), size);
			if (unit->getPosition().z > unit->getDestination().z)
			{
				// going down a level, so toLevel 0 becomes +24, -8 becomes  16
				toLevel += 24*(unit->getPosition().z - unit->getDestination().z);
			}else if (unit->getPosition().z < unit->getDestination().z)
			{
				// going up a level, so toLevel 0 becomes -24, -8 becomes -16
				toLevel = -24*(unit->getDestination().z - unit->getPosition().z) + abs(toLevel);
			}
			offset->y += ((fromLevel * (endphase - phase)) / endphase) + ((toLevel * (phase)) / endphase);
		}
		else
		{
			// from phase 4 onwards the unit behind the scenes already is on the destination tile
			// we have to get it's last position to calculate the correct offset
			int fromLevel = getTerrainLevel(unit->getLastPosition(), size);
			int toLevel = getTerrainLevel(unit->getDestination(), size);
			if (unit->getLastPosition().z > unit->getDestination().z)
			{
				// going down a level, so fromLevel 0 becomes -24, -8 becomes -32
				fromLevel -= 24*(unit->getLastPosition().z - unit->getDestination().z);
			}else if (unit->getLastPosition().z < unit->getDestination().z)
			{
				// going up a level, so fromLevel 0 becomes +24, -8 becomes 16
				fromLevel = 24*(unit->getDestination().z - unit->getLastPosition().z) - abs(fromLevel);
			}
			offset->y += ((fromLevel * (endphase - phase)) / endphase) + ((toLevel * (phase)) / endphase);
		}
	}
	else
	{
		offset->y += getTerrainLevel(unit->getPosition(), size);
		if (_save->getDepth() > 0)
		{
			unit->setFloorAbove(false);

			// make sure this unit isn't obscured by the floor above him, otherwise it looks weird.
			if (_camera->getViewLevel() > unit->getPosition().z)
			{
				for (int z = std::min(_camera->getViewLevel(), _save->getMapSizeZ() - 1); z != unit->getPosition().z; --z)
				{
					if (!_save->getTile(Position(unit->getPosition().x, unit->getPosition().y, z))->hasNoFloor(0))
					{
						unit->setFloorAbove(true);
						break;
					}
				}
			}
		}
	}
}


/**
  * Terrainlevel goes from 0 to -24. For a larger sized unit, we need to pick the highest terrain level, which is the lowest number...
  * @param pos Position.
  * @param size Size of the unit we want to get the level from.
  * @return terrainlevel.
  */
int Map::getTerrainLevel(const Position& pos, int size) const
{
	int lowestlevel = 0;

	for (int x = 0; x < size; x++)
	{
		for (int y = 0; y < size; y++)
		{
			int l = _save->getTile(pos + Position(x,y,0))->getTerrainLevel();
			if (l < lowestlevel)
				lowestlevel = l;
		}
	}

	return lowestlevel;
}

/**
 * Sets the 3D cursor to selection/aim mode.
 * @param type Cursor type.
 * @param size Size of cursor.
 */
void Map::setCursorType(CursorType type, int size)
{
	_cursorType = type;
	if (_cursorType == CT_NORMAL)
		_cursorSize = size;
	else
		_cursorSize = 1;
}

/**
 * Gets the cursor type.
 * @return cursortype.
 */
CursorType Map::getCursorType() const
{
	return _cursorType;
}

/**
 * Checks all units for if they need to be redrawn.
 */
void Map::cacheUnits()
{
	for (std::vector<BattleUnit*>::iterator i = _save->getUnits()->begin(); i != _save->getUnits()->end(); ++i)
	{
		cacheUnit(*i);
	}
}

/**
 * Check if a certain unit needs to be redrawn.
 * @param unit Pointer to battleUnit.
 */
void Map::cacheUnit(BattleUnit *unit)
{
	UnitSprite *unitSprite = new UnitSprite(_spriteWidth * 2, _spriteHeight, 0, 0, _save->getDepth() != 0);
	unitSprite->setPalette(this->getPalette());
	int numOfParts = unit->getArmor()->getSize() * unit->getArmor()->getSize();

	if (unit->isCacheInvalid())
	{
		// 1 or 4 iterations, depending on unit size
		for (int i = 0; i < numOfParts; i++)
		{
			Surface *cache = unit->getCache(i);
			if (!cache) // no cache created yet
			{
				cache = new Surface(_spriteWidth * 2, _spriteHeight);
				cache->setPalette(this->getPalette());
			}

			unitSprite->setBattleUnit(unit, i);
			unitSprite->setSurfaces(_game->getMod()->getSurfaceSet(unit->getArmor()->getSpriteSheet()),
									_game->getMod()->getSurfaceSet("HANDOB.PCK"),
									_game->getMod()->getSurfaceSet("HANDOB2.PCK"));
			unitSprite->setAnimationFrame(_animFrame);
			cache->clear();
			unitSprite->blit(cache);
			unit->setCache(cache, i);
		}
	}
	delete unitSprite;
}

/**
 * Puts a projectile sprite on the map.
 * @param projectile Projectile to place.
 */
void Map::setProjectile(Projectile *projectile)
{
	_projectile = projectile;
	if (projectile && Options::battleSmoothCamera)
	{
		_launch = true;
	}
}

/**
 * Gets the current projectile sprite on the map.
 * @return Projectile or 0 if there is no projectile sprite on the map.
 */
Projectile *Map::getProjectile() const
{
	return _projectile;
}

/**
 * Gets a list of explosion sprites on the map.
 * @return A list of explosion sprites.
 */
std::list<Explosion*> *Map::getExplosions()
{
	return &_explosions;
}

/**
 * Gets the pointer to the camera.
 * @return Pointer to camera.
 */
Camera *Map::getCamera()
{
	return _camera;
}

/**
 * Timers only work on surfaces so we have to pass this on to the camera object.
 */
void Map::scrollMouse()
{
	_camera->scrollMouse();
}

/**
 * Timers only work on surfaces so we have to pass this on to the camera object.
 */
void Map::scrollKey()
{
	_camera->scrollKey();
}

/**
 * Gets a list of waypoints on the map.
 * @return A list of waypoints.
 */
std::vector<Position> *Map::getWaypoints()
{
	return &_waypoints;
}

/**
 * Sets mouse-buttons' pressed state.
 * @param button Index of the button.
 * @param pressed The state of the button.
 */
void Map::setButtonsPressed(Uint8 button, bool pressed)
{
	setButtonPressed(button, pressed);
}

/**
 * Sets the unitDying flag.
 * @param flag True if the unit is dying.
 */
void Map::setUnitDying(bool flag)
{
	_unitDying = flag;
}

/**
 * Updates the selector to the last-known mouse position.
 */
void Map::refreshSelectorPosition()
{
	setSelectorPosition(_mouseX, _mouseY);
}

/**
 * Special handling for setting the height of the map viewport.
 * @param height the new base screen height.
 */
void Map::setHeight(int height)
{
	Surface::setHeight(height);
	_visibleMapHeight = height - _iconHeight;
	_message->setHeight((_visibleMapHeight < 200)? _visibleMapHeight : 200);
	_message->setY((_visibleMapHeight - _message->getHeight()) / 2);
}

/**
 * Special handling for setting the width of the map viewport.
 * @param width the new base screen width.
 */
void Map::setWidth(int width)
{
	int dX = width - getWidth();
	Surface::setWidth(width);
	_message->setX(_message->getX() + dX / 2);
}

/**
 * Get the hidden movement screen's vertical position.
 * @return the vertical position of the hidden movement window.
 */
int Map::getMessageY() const
{
	return _message->getY();
}

/**
 * Get the icon height.
 */
int Map::getIconHeight() const
{
	return _iconHeight;
}

/**
 * Get the icon width.
 */
int Map::getIconWidth() const
{
	return _iconWidth;
}

/**
 * Returns the angle(left/right balance) of a sound effect,
 * based off a map position.
 * @param pos the map position to calculate the sound angle from.
 * @return the angle of the sound (280 to 440).
 */
int Map::getSoundAngle(const Position& pos) const
{
	int midPoint = getWidth() / 2;
	Position relativePosition;

	_camera->convertMapToScreen(pos, &relativePosition);
	// cap the position to the screen edges relative to the center,
	// negative values indicating a left-shift, and positive values shifting to the right.
	relativePosition.x = Clamp((relativePosition.x + _camera->getMapOffset().x) - midPoint, -midPoint, midPoint);

	// convert the relative distance to a relative increment of an 80 degree angle
	// we use +- 80 instead of +- 90, so as not to go ALL the way left or right
	// which would effectively mute the sound out of one speaker.
	// since Mix_SetPosition uses modulo 360, we can't feed it a negative number, so add 360 instead.
	return 360 + (relativePosition.x / (midPoint / 80.0));
}

/**
 * Reset the camera smoothing bool.
 */
void Map::resetCameraSmoothing()
{
	_smoothingEngaged = false;
}

/**
 * Set the "explosion flash" bool.
 * @param flash should the screen be rendered in EGA this frame?
 */
void Map::setBlastFlash(bool flash)
{
	_flashScreen = flash;
}

/**
 * Checks if the screen is still being rendered in EGA.
 * @return if we are still in EGA mode.
 */
bool Map::getBlastFlash() const
{
	return _flashScreen;
}

/**
 * Resets obstacle markers.
 */
void Map::resetObstacles(void)
{
	for (int z = 0; z < _save->getMapSizeZ(); z++)
		for (int y = 0; y < _save->getMapSizeY(); y++)
			for (int x = 0; x < _save->getMapSizeX(); x++)
			{
				Tile *tile = _save->getTile(Position(x, y, z));
				if (tile) tile->resetObstacle();
			}
	_showObstacles = false;
}

/**
 * Enables obstacle markers.
 */
void Map::enableObstacles(void)
{
	_showObstacles = true;
	if (_obstacleTimer)
	{
		_obstacleTimer->stop();
		_obstacleTimer->start();
	}
}

/**
 * Disables obstacle markers.
 */
void Map::disableObstacles(void)
{
	_showObstacles = false;
	if (_obstacleTimer)
	{
		_obstacleTimer->stop();
	}
}

}
