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
#include "ScreenVoxelFrame.h"
#include "ScreenRayBlocks.h"
#include <math.h> // for pi
#include "VoxelRay.h"


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

	_screenVoxelFrame = new ScreenVoxelFrame();
	_screenVoxelFrame->ReSize( width, height );

	_screenRayBlocks = new ScreenRayBlocks();
	_screenRayBlocks->ReSize( width, height );
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
	delete _screenVoxelFrame;
	delete _screenRayBlocks;
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
//		drawTerrain(this);
		drawTerrainHeavyModifiedBySkybuck(this);
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

void DrawSpriteVoxelFrame( Surface *Dst, int DstX, int DstY, Tile *ParaTile, Surface *ParaSprite )
{
//	VoxelPosition vVoxelPosition;
	signed char vVoxelPositionZ;
	int SpriteX, SpriteY;

	Uint8 SpriteColor;
	Uint8 VoxelColor;
	Uint8 SurfaceColor;
	Uint8 FinalColor;


	for (SpriteY=0; SpriteY < 40; SpriteY++)
	{
		for (SpriteX=0; SpriteX < 32; SpriteX++)
		{
			SpriteColor = ParaSprite->getPixel( SpriteX, SpriteY ); 

			if (SpriteColor != 0)
			{

				//	VoxelColor = SpriteX % 256;
				vVoxelPositionZ = ParaTile->getSpriteVoxelFrame()->_VoxelPosition[SpriteY][SpriteX].Z;
				if (vVoxelPositionZ >= 0)
				{
	//				VoxelColor = 48 + (vVoxelPositionZ  / 24.0 ) * 16;
					VoxelColor = 16 - ((vVoxelPositionZ  / 24.0 ) * 16);

					SurfaceColor = Dst->getPixel( DstX + SpriteX, DstY + SpriteY );

	//				SubtractColor = SurfaceColor & 15; // mod 16 = and 15
					SurfaceColor = SurfaceColor & 240; // inverted mask to clear lower 16 colors
					FinalColor = SurfaceColor + VoxelColor;

					Dst->setPixel( DstX + SpriteX, DstY + SpriteY, FinalColor );
				}
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

// NEW STUFF COMPLETE LATER
/*
Uint8 Map::Shade( Uint8 ParaColorIn,   


	//				SubtractColor = SurfaceColor & 15; // mod 16 = and 15
				SurfaceColor = SurfaceColor & 240; // inverted mask to clear lower 16 colors
				Uint8 FinalColor = SurfaceColor + VoxelColor;
*/


/**
 * Draw the terrain.
 * Keep this function as optimised as possible. It's big to minimise overhead of function calls.
 * @param surface The surface to draw on.
 */
void Map::drawTerrainHeavyModifiedBySkybuck(Surface *surface)
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

	EatShitAndDie++; // HAHAHAHAHA this still in there... hahaha cool, it's for ufo disco ! LOL. or shading experiment/whatever/animation frame number, cause you shits wrap it back to zero and I dont know how to deal with that or I dont want to deal with that, wrap it back at int64 and then maybe let users do custom wrapping back at animation frame 8 or something... just an idea so it can be used for others things too ok... where animation has to be more consistent/fluent time was... order wise... no wrapping back ! unless absolutely necessarya nd when you do wrap back make sure it was on a 8 frame boundary or so hehe.. cool idea bye.. this is probably the longest comment I ever wrote... now I am becoming curious if visual studio or the compiler will crash because of a line overflow... PIEEEEEE BYE maybe some synthax high lighter haha in another tool. KABOOOEEM ENJOY ! =D



	// ****************************************************************************************
	// Example code by Skybuck Flying ! =D the creator of voxelray.h and voxelray.cpp
	// ****************************************************************************************
	// *** EXAMPLE CODE HOW TO USE VOXELRAY.H TO TRACE/TRAVERSE A RAY THROUGH THE TILE GRID ***
	// ****************************************************************************************
	// So far VoxelRay.h has been debugged to produce correct Tile traversing.
	// Perhaps tomorrow I will debug the voxel part of it.
	// SO !!! ATTENTION !!! VOXELRAY.H NOT FULLY DEBUGGED YET, BUT IN A USUABLE STATE
	// SO BELOW FOR WORKING EXAMPLE CODE FOR TILE TRACING/TRAVERSING YEAH ! =D
	// ****************************************************************************************

	// reset traversed before traversing and before drawing the graphics ofcourse ! ;) :)
	for (int itZ = beginZ; itZ <= endZ; itZ = itZ + 1)
	{
		for (int itX = beginX; itX <= endX; itX = itX + 1)
		{
			for (int itY = beginY; itY <= endY; itY = itY + 1)
			{
				mapPosition = Position(itX, itY, itZ);
				tile = _save->getTile(mapPosition);
				if (!tile) continue;
				tile->setTraversed( false );
			}
		}
	}

	VoxelPosition vVoxelPositionStart;
	VoxelPosition vVoxelPositionStop;

	// this might have been problem code but Z was X by accident
	// set voxel position start to maximum x,y,z of the map
	// position center of last tile
	vVoxelPositionStart.X = (_save->getMapSizeX() * 16) - 1;
	vVoxelPositionStart.Y = (_save->getMapSizeY() * 16) - 1;
	vVoxelPositionStart.Z = (_save->getMapSizeZ() * 24) - 1;

	// set voxel position stop to minimum x,y,z of the map which is probably 0,0,0
	// position center of tile 0,0,0
	vVoxelPositionStop.X = 0; 
	vVoxelPositionStop.Y = 0;
	vVoxelPositionStop.Z = 0;

/*
	// Skybuck:
	// safe code in case traverse code can't handle when start/stop is right on first or last voxel
	// but traverse code in voxelray.h can handle it right now ! So don't worry/no worries ! ;) =D
	// set voxel position start to maximum x,y,z of the map
	// position center of last tile
	vVoxelPositionStart.X = (_save->getMapSizeX() * 16) - (16/2);
	vVoxelPositionStart.Y = (_save->getMapSizeY() * 16) - (16/2);
	vVoxelPositionStart.Z = (_save->getMapSizeZ() * 24) - (24/2);

	// set voxel position stop to minimum x,y,z of the map which is probably 0,0,0
	// position center of tile 0,0,0
	vVoxelPositionStop.X = 16/2; 
	vVoxelPositionStop.Y = 16/2;
	vVoxelPositionStop.Z = 24/2;
*/

	VoxelRay vVoxelRay;

	vVoxelRay.SetupVoxelDimensions( 1, 1, 1 ); // probably not necessary but do it anyway just in case.
	vVoxelRay.SetupTileDimensions( 16, 16, 24 );
	vVoxelRay.SetupGridData( 0, 0, 0, _save->getMapSizeX()-1, _save->getMapSizeY()-1, _save->getMapSizeZ()-1 );
	vVoxelRay.Setup( vVoxelPositionStart, vVoxelPositionStop, 16, 16, 24 ); 

	int TileTraverseX, TileTraverseY, TileTraverseZ;

	while (!vVoxelRay.IsTileTraverseDone())
	{
		vVoxelRay.GetTraverseTilePosition( &TileTraverseX, &TileTraverseY, &TileTraverseZ );
		mapPosition = Position(TileTraverseX, TileTraverseY, TileTraverseZ);
		tile = _save->getTile(mapPosition);
		if (!tile) continue;
		tile->setTraversed( true );

		vVoxelRay.NextStep();
	}

	// *******************************************************************************************
	// END OF VOXELRAY TRAVERSAL CODE EXAMPLE, HOWEVER BELOW IS ALSO SOME RENDERING ASSISTANCE...
	// IT USES a boolean per tile and getTraversed to known if a tile was traversed or not ! ;)
	// make sure to enable "z levels with game user interface to see the rest 
	// *******************************************************************************************

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

					// ***************************************************************
					// *** BEGIN OF DEBUG CODE FOR VOXEL RAY TRAVERSAL PART 1 OF 2 ***
					// ***************************************************************
					// Draw cursor back
					if (tile->getTraversed())
					{
						frameNumber = 2; // blue box
						tmpSurface = _game->getMod()->getSurfaceSet("CURSOR.PCK")->getFrame(frameNumber);
						tmpSurface->blitNShade(surface, screenPosition.x, screenPosition.y, 0);
					}
					// ************************************************************
					// *** END OF DEBUG CODE FOR VOXEL RAY TRAVERSAL PART 1 OF 2***
					// ************************************************************

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

						// draws a pre-computed sprite voxel frame

						// tile part doesn't really matter much except for animation frame,
						// all tile parts are merged together in a single voxel frame
						// they are seperated per animation though, each animation frame has it's own sprite voxel frame
//						DrawSpriteVoxelFrame( surface, screenPosition.x, screenPosition.y, tile, tmpSurface );



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

					// ***************************************************************
					// *** BEGIN OF DEBUG CODE FOR VOXEL RAY TRAVERSAL PART 2 OF 2 ***
					// ***************************************************************
					// Draw cursor front
					if (tile->getTraversed())
					{
							frameNumber = 5; // blue box
							tmpSurface = _game->getMod()->getSurfaceSet("CURSOR.PCK")->getFrame(frameNumber);
							tmpSurface->blitNShade(surface, screenPosition.x, screenPosition.y, 0);
//							FaggotShitDraw( surface, screenPosition.x, screenPosition.y, tmpSurface );
					}
					// ************************************************************
					// *** END OF DEBUG CODE FOR VOXEL RAY TRAVERSAL PART 2 OF 2***
					// ************************************************************

				}

/*

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

/*
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
//					DrawSpriteVoxelFrame( surface, screenPosition.x, screenPosition.y, tile, O_FLOOR );

//					LightCasting( _save, _save->getTileEngine(), surface, screenPosition.x, screenPosition.y, tile, mapPosition );  

//				}
			}
		}
	}

	surface->unlock();
}

// pasting these functions in here for now, maybe move later to shading unit or something:

void calc_normalize_3d( double *x, double *y, double *z )
{
	// very ugly c++ code INCOMING, TAKE COVER, KAAAABOOOOOooooMMMMM
	double temp_length;

	temp_length = sqrt
	(
		( *x * *x ) +
		( *y * *y ) +
		( *z * *z )
	);

//	if temp_length<>0 then
	// I like it better if it errors/bombs because of divide by zero
	// at least then I know where it "faults" :)
//	{
		*x = *x / temp_length;
		*y = *y / temp_length;
		*z = *z / temp_length;
//	}
}

double calc_dot_product_3d
(
	double x1, double y1, double z1,
	double x2, double y2, double z2
)
{
	return
	(
		(x1 * x2) +
		(y1 * y2) +
		(z1 * z2)
	);
}

double calc_angle_between_two_vectors_3d
(
	double x1, double y1, double z1,
	double x2, double y2, double z2
)
{
	calc_normalize_3d( &x1, &y1, &z1 );
	calc_normalize_3d( &x2, &y2, &z2 );

//	return arccos( calc_dot_product_3d( x1,y1,z1, x2,y2,z2 ) ); // delphi arccos
	return
	(
		acos
		(
			calc_dot_product_3d
			(
				x1,y1,z1,
				x2,y2,z2
			)
		)
	); // c++ acos ? Think so.
}

// slighty modified draw terrain to include "draw sprite voxel frame"
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

	// if we got bullet, get the highest x and y tiles to draw it on
	if (_projectile && _explosions.empty())
	{
		int part = _projectile->getItem() ? 0 : BULLET_SPRITES-1;
		for (int i = 0; i <= part; ++i)
		{
			if (_projectile->getPosition(1-i).x < bulletLowX)
				bulletLowX = _projectile->getPosition(1-i).x;
			if (_projectile->getPosition(1-i).y < bulletLowY)
				bulletLowY = _projectile->getPosition(1-i).y;
			if (_projectile->getPosition(1-i).z < bulletLowZ)
				bulletLowZ = _projectile->getPosition(1-i).z;
			if (_projectile->getPosition(1-i).x > bulletHighX)
				bulletHighX = _projectile->getPosition(1-i).x;
			if (_projectile->getPosition(1-i).y > bulletHighY)
				bulletHighY = _projectile->getPosition(1-i).y;
			if (_projectile->getPosition(1-i).z > bulletHighZ)
				bulletHighZ = _projectile->getPosition(1-i).z;
		}
		// divide by 16 to go from voxel to tile position
		bulletLowX = bulletLowX / 16;
		bulletLowY = bulletLowY / 16;
		bulletLowZ = bulletLowZ / 24;
		bulletHighX = bulletHighX / 16;
		bulletHighY = bulletHighY / 16;
		bulletHighZ = bulletHighZ / 24;

		// if the projectile is outside the viewport - center it back on it
		_camera->convertVoxelToScreen(_projectile->getPosition(), &bulletPositionScreen);

		if (_projectileInFOV)
		{
			Position newCam = _camera->getMapOffset();
			if (newCam.z != bulletHighZ) //switch level
			{
				newCam.z = bulletHighZ;
				if (_projectileInFOV)
				{
					_camera->setMapOffset(newCam);
					_camera->convertVoxelToScreen(_projectile->getPosition(), &bulletPositionScreen);
				}
			}
			if (_smoothCamera)
			{
				if (_launch)
				{
					_launch = false;
					if ((bulletPositionScreen.x < 1 || bulletPositionScreen.x > surface->getWidth() - 1 ||
						bulletPositionScreen.y < 1 || bulletPositionScreen.y > _visibleMapHeight - 1))
					{
						_camera->centerOnPosition(Position(bulletLowX, bulletLowY, bulletHighZ), false);
						_camera->convertVoxelToScreen(_projectile->getPosition(), &bulletPositionScreen);
					}
				}
				if (!_smoothingEngaged)
				{
					if (bulletPositionScreen.x < 1 || bulletPositionScreen.x > surface->getWidth() - 1 ||
						bulletPositionScreen.y < 1 || bulletPositionScreen.y > _visibleMapHeight - 1)
					{
						_smoothingEngaged = true;
					}
				}
				else
				{
					_camera->jumpXY(surface->getWidth() / 2 - bulletPositionScreen.x, _visibleMapHeight / 2 - bulletPositionScreen.y);
				}
			}
			else
			{
				bool enough;
				do
				{
					enough = true;
					if (bulletPositionScreen.x < 0)
					{
						_camera->jumpXY(+surface->getWidth(), 0);
						enough = false;
					}
					else if (bulletPositionScreen.x > surface->getWidth())
					{
						_camera->jumpXY(-surface->getWidth(), 0);
						enough = false;
					}
					else if (bulletPositionScreen.y < 0)
					{
						_camera->jumpXY(0, +_visibleMapHeight);
						enough = false;
					}
					else if (bulletPositionScreen.y > _visibleMapHeight)
					{
						_camera->jumpXY(0, -_visibleMapHeight);
						enough = false;
					}
					_camera->convertVoxelToScreen(_projectile->getPosition(), &bulletPositionScreen);
				}
				while (!enough);
			}
		}
	}

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

	_screenVoxelFrame->Clear();

	for (int itZ = beginZ; itZ <= endZ; itZ++)
	{
		bool topLayer = itZ == endZ;
		for (int itX = beginX; itX <= endX; itX++)
		{
			for (int itY = beginY; itY <= endY; itY++)
			{
				mapPosition = Position(itX, itY, itZ);
				_camera->convertMapToScreen(mapPosition, &screenPosition);
				screenPosition += _camera->getMapOffset();

				// only render cells that are inside the surface
				if (screenPosition.x > -_spriteWidth && screenPosition.x < surface->getWidth() + _spriteWidth &&
					screenPosition.y > -_spriteHeight && screenPosition.y < surface->getHeight() + _spriteHeight )
				{
					tile = _save->getTile(mapPosition);

					if (!tile) continue;

					if (tile->isDiscovered(2))
					{
						tileShade = tile->getShade();
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

//						DrawSpriteVoxelFrame( surface, screenPosition.x, screenPosition.y - tile->getMapData(O_FLOOR)->getYOffset(), tile, tmpSurface );
						_screenVoxelFrame->CollectSpriteVoxelFrame( screenPosition.x, screenPosition.y - tile->getMapData(O_FLOOR)->getYOffset(),  tile, tmpSurface );
//						_screenVoxelFrame->CollectSpriteVoxelFrame( screenPosition.x, screenPosition.y,  tile, tmpSurface );

					}
					unit = tile->getUnit();

					// Draw cursor back
					if (_cursorType != CT_NONE && _selectorX > itX - _cursorSize && _selectorY > itY - _cursorSize && _selectorX < itX+1 && _selectorY < itY+1 && !_save->getBattleState()->getMouseOverIcons())
					{
						if (_camera->getViewLevel() == itZ)
						{
							if (_cursorType != CT_AIM)
							{
								if (unit && (unit->getVisible() || _save->getDebugMode()))
									frameNumber = (_animFrame % 2); // yellow box
								else
									frameNumber = 0; // red box
							}
							else
							{
								if (unit && (unit->getVisible() || _save->getDebugMode()))
									frameNumber = 7 + (_animFrame / 2); // yellow animated crosshairs
								else
									frameNumber = 6; // red static crosshairs
							}
							tmpSurface = _game->getMod()->getSurfaceSet("CURSOR.PCK")->getFrame(frameNumber);
							tmpSurface->blitNShade(surface, screenPosition.x, screenPosition.y, 0);
						}
						else if (_camera->getViewLevel() > itZ)
						{
							frameNumber = 2; // blue box
							tmpSurface = _game->getMod()->getSurfaceSet("CURSOR.PCK")->getFrame(frameNumber);
							tmpSurface->blitNShade(surface, screenPosition.x, screenPosition.y, 0);
						}
					}

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

//							DrawSpriteVoxelFrame( surface, screenPosition.x, screenPosition.y - tile->getMapData(O_WESTWALL)->getYOffset(), tile, tmpSurface );
							_screenVoxelFrame->CollectSpriteVoxelFrame( screenPosition.x, screenPosition.y - tile->getMapData(O_WESTWALL)->getYOffset(),  tile, tmpSurface );
//							_screenVoxelFrame->CollectSpriteVoxelFrame( screenPosition.x, screenPosition.y,  tile, tmpSurface );


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

//							DrawSpriteVoxelFrame( surface, screenPosition.x, screenPosition.y - tile->getMapData(O_NORTHWALL)->getYOffset(), tile, tmpSurface );
							_screenVoxelFrame->CollectSpriteVoxelFrame( screenPosition.x, screenPosition.y - tile->getMapData(O_NORTHWALL)->getYOffset(),  tile, tmpSurface );
//							_screenVoxelFrame->CollectSpriteVoxelFrame( screenPosition.x, screenPosition.y,  tile, tmpSurface );

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

//								DrawSpriteVoxelFrame( surface, screenPosition.x, screenPosition.y - tile->getMapData(O_OBJECT)->getYOffset(), tile, tmpSurface );
								_screenVoxelFrame->CollectSpriteVoxelFrame( screenPosition.x, screenPosition.y - tile->getMapData(O_OBJECT)->getYOffset(),  tile, tmpSurface );
//								_screenVoxelFrame->CollectSpriteVoxelFrame( screenPosition.x, screenPosition.y,  tile, tmpSurface );

							}
						}


						// draws a pre-computed sprite voxel frame

						// tile part doesn't really matter much except for animation frame,
						// all tile parts are merged together in a single voxel frame
						// they are seperated per animation though, each animation frame has it's own sprite voxel frame
//						DrawSpriteVoxelFrame( surface, screenPosition.x, screenPosition.y, tile, tmpSurface );
//						_screenVoxelFrame->CollectSpriteVoxelFrame( screenPosition.x, screenPosition.y,  tile );


						// draw an item on top of the floor (if any)
						int sprite = tile->getTopItemSprite();
						if (sprite != -1)
						{
							tmpSurface = _game->getMod()->getSurfaceSet("FLOOROB.PCK")->getFrame(sprite);
							tmpSurface->blitNShade(surface, screenPosition.x, screenPosition.y + tile->getTerrainLevel(), tileShade, false);
						}

					}

					// check if we got bullet && it is in Field Of View
					if (_projectile && _projectileInFOV)
					{
						tmpSurface = 0;
						if (_projectile->getItem())
						{
							tmpSurface = _projectile->getSprite();

							Position voxelPos = _projectile->getPosition();
							// draw shadow on the floor
							voxelPos.z = _save->getTileEngine()->castedShade(voxelPos);
							if (voxelPos.x / 16 >= itX &&
								voxelPos.y / 16 >= itY &&
								voxelPos.x / 16 <= itX+1 &&
								voxelPos.y / 16 <= itY+1 &&
								voxelPos.z / 24 == itZ &&
								_save->getTileEngine()->isVoxelVisible(voxelPos))
							{
								_camera->convertVoxelToScreen(voxelPos, &bulletPositionScreen);
								tmpSurface->blitNShade(surface, bulletPositionScreen.x - 16, bulletPositionScreen.y - 26, 16);
							}

							voxelPos = _projectile->getPosition();
							// draw thrown object
							if (voxelPos.x / 16 >= itX &&
								voxelPos.y / 16 >= itY &&
								voxelPos.x / 16 <= itX+1 &&
								voxelPos.y / 16 <= itY+1 &&
								voxelPos.z / 24 == itZ &&
								_save->getTileEngine()->isVoxelVisible(voxelPos))
							{
								_camera->convertVoxelToScreen(voxelPos, &bulletPositionScreen);
								tmpSurface->blitNShade(surface, bulletPositionScreen.x - 16, bulletPositionScreen.y - 26, 0);
							}

						}
						else
						{
							// draw bullet on the correct tile
							if (itX >= bulletLowX && itX <= bulletHighX && itY >= bulletLowY && itY <= bulletHighY)
							{
								int begin = 0;
								int end = BULLET_SPRITES;
								int direction = 1;
								if (_projectile->isReversed())
								{
									begin = BULLET_SPRITES - 1;
									end = -1;
									direction = -1;
								}

								for (int i = begin; i != end; i += direction)
								{
									tmpSurface = _projectileSet->getFrame(_projectile->getParticle(i));
									if (tmpSurface)
									{
										Position voxelPos = _projectile->getPosition(1-i);
										// draw shadow on the floor
										voxelPos.z = _save->getTileEngine()->castedShade(voxelPos);
										if (voxelPos.x / 16 == itX &&
											voxelPos.y / 16 == itY &&
											voxelPos.z / 24 == itZ &&
											_save->getTileEngine()->isVoxelVisible(voxelPos))
										{
											_camera->convertVoxelToScreen(voxelPos, &bulletPositionScreen);
											bulletPositionScreen.x -= tmpSurface->getWidth() / 2;
											bulletPositionScreen.y -= tmpSurface->getHeight() / 2;
											tmpSurface->blitNShade(surface, bulletPositionScreen.x, bulletPositionScreen.y, 16);
										}

										// draw bullet itself
										voxelPos = _projectile->getPosition(1-i);
										if (voxelPos.x / 16 == itX &&
											voxelPos.y / 16 == itY &&
											voxelPos.z / 24 == itZ &&
											_save->getTileEngine()->isVoxelVisible(voxelPos))
										{
											_camera->convertVoxelToScreen(voxelPos, &bulletPositionScreen);
											bulletPositionScreen.x -= tmpSurface->getWidth() / 2;
											bulletPositionScreen.y -= tmpSurface->getHeight() / 2;
											tmpSurface->blitNShade(surface, bulletPositionScreen.x, bulletPositionScreen.y, 0);
										}
									}
								}
							}
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

					// Draw smoke/fire
					if (tile->getSmoke() && tile->isDiscovered(2))
					{
						frameNumber = 0;
						int shade = 0;
						if (!tile->getFire())
						{
							if (_save->getDepth() > 0)
							{
								frameNumber += Mod::UNDERWATER_SMOKE_OFFSET;
							}
							else
							{
								frameNumber += Mod::SMOKE_OFFSET;
							}
							frameNumber += int(floor((tile->getSmoke() / 6.0) - 0.1)); // see http://www.ufopaedia.org/images/c/cb/Smoke.gif
							shade = tileShade;
						}

						if ((_animFrame / 2) + tile->getAnimationOffset() > 3)
						{
							frameNumber += ((_animFrame / 2) + tile->getAnimationOffset() - 4);
						}
						else
						{
							frameNumber += (_animFrame / 2) + tile->getAnimationOffset();
						}
						tmpSurface = _game->getMod()->getSurfaceSet("SMOKE.PCK")->getFrame(frameNumber);
						tmpSurface->blitNShade(surface, screenPosition.x, screenPosition.y, shade);
					}

					//draw particle clouds
					for (std::list<Particle*>::const_iterator i = tile->getParticleCloud()->begin(); i != tile->getParticleCloud()->end(); ++i)
					{
						int vaporX = screenPosition.x + (*i)->getX();
						int vaporY = screenPosition.y + (*i)->getY();
						if ((int)(_transparencies->size()) >= ((*i)->getColor() + 1) * 1024)
						{
							switch ((*i)->getSize())
							{
							case 3:
								surface->setPixel(vaporX+1, vaporY+1, (*_transparencies)[((*i)->getColor() * 1024) + ((*i)->getOpacity() * 256) + surface->getPixel(vaporX+1, vaporY+1)]);
							case 2:
								surface->setPixel(vaporX + 1, vaporY, (*_transparencies)[((*i)->getColor() * 1024) + ((*i)->getOpacity() * 256) + surface->getPixel(vaporX + 1, vaporY)]);
							case 1:
								surface->setPixel(vaporX, vaporY + 1, (*_transparencies)[((*i)->getColor() * 1024) + ((*i)->getOpacity() * 256) + surface->getPixel(vaporX, vaporY + 1)]);
							default:
								surface->setPixel(vaporX, vaporY, (*_transparencies)[((*i)->getColor() * 1024) + ((*i)->getOpacity() * 256) + surface->getPixel(vaporX, vaporY)]);
								break;
							}
						}
					}

					// Draw Path Preview
					if (tile->getPreview() != -1 && tile->isDiscovered(0) && (_previewSetting & PATH_ARROWS))
					{
						if (itZ > 0 && tile->hasNoFloor(_save->getTile(tile->getPosition() + Position(0,0,-1))))
						{
							tmpSurface = _game->getMod()->getSurfaceSet("Pathfinding")->getFrame(11);
							if (tmpSurface)
							{
								tmpSurface->blitNShade(surface, screenPosition.x, screenPosition.y+2, 0, false, tile->getMarkerColor());
							}
						}
						tmpSurface = _game->getMod()->getSurfaceSet("Pathfinding")->getFrame(tile->getPreview());
						if (tmpSurface)
						{
							tmpSurface->blitNShade(surface, screenPosition.x, screenPosition.y + tile->getTerrainLevel(), 0, false, tileColor);
						}
					}
					if (!tile->isVoid())
					{
						// Draw object
						if (tile->getMapData(O_OBJECT) && tile->getMapData(O_OBJECT)->getBigWall() >= 6 && tile->getMapData(O_OBJECT)->getBigWall() != 9)
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
					}
					// Draw cursor front
					if (_cursorType != CT_NONE && _selectorX > itX - _cursorSize && _selectorY > itY - _cursorSize && _selectorX < itX+1 && _selectorY < itY+1 && !_save->getBattleState()->getMouseOverIcons())
					{
						if (_camera->getViewLevel() == itZ)
						{
							if (_cursorType != CT_AIM)
							{
								if (unit && (unit->getVisible() || _save->getDebugMode()))
									frameNumber = 3 + (_animFrame % 2); // yellow box
								else
									frameNumber = 3; // red box
							}
							else
							{
								if (unit && (unit->getVisible() || _save->getDebugMode()))
									frameNumber = 7 + (_animFrame / 2); // yellow animated crosshairs
								else
									frameNumber = 6; // red static crosshairs
							}
							tmpSurface = _game->getMod()->getSurfaceSet("CURSOR.PCK")->getFrame(frameNumber);
							tmpSurface->blitNShade(surface, screenPosition.x, screenPosition.y, 0);

							// UFO extender accuracy: display adjusted accuracy value on crosshair in real-time.
							if (_cursorType == CT_AIM && Options::battleUFOExtenderAccuracy)
							{
								BattleAction *action = _save->getBattleGame()->getCurrentAction();
								RuleItem *weapon = action->weapon->getRules();
								int accuracy = action->actor->getFiringAccuracy(action->type, action->weapon);
								int distanceSq = _save->getTileEngine()->distanceUnitToPositionSq(action->actor, Position (itX, itY,itZ), false);
								int distance = (int)std::ceil(sqrt(float(distanceSq)));
								int upperLimit = 200;
								int lowerLimit = weapon->getMinRange();
								switch (action->type)
								{
								case BA_AIMEDSHOT:
									upperLimit = weapon->getAimRange();
									break;
								case BA_SNAPSHOT:
									upperLimit = weapon->getSnapRange();
									break;
								case BA_AUTOSHOT:
									upperLimit = weapon->getAutoRange();
									break;
								default:
									break;
								}
								// at this point, let's assume the shot is adjusted and set the text amber.
								_txtAccuracy->setColor(Palette::blockOffset(Pathfinding::yellow - 1)-1);

								if (distance > upperLimit)
								{
									accuracy -= (distance - upperLimit) * weapon->getDropoff();
								}
								else if (distance < lowerLimit)
								{
									accuracy -= (lowerLimit - distance) * weapon->getDropoff();
								}
								else
								{
									// no adjustment made? set it to green.
									_txtAccuracy->setColor(Palette::blockOffset(Pathfinding::green - 1)-1);
								}

								bool outOfRange = distanceSq > weapon->getMaxRangeSq();
								// special handling for short ranges and diagonals
								if (outOfRange)
								{
									// special handling for maxRange 1: allow it to target diagonally adjacent tiles (one diagonal move)
									if (weapon->getMaxRange() == 1 && distanceSq <= 3)
									{
										outOfRange = false;
									}
									// special handling for maxRange 2: allow it to target diagonally adjacent tiles (one diagonal move + one straight move)
									else if (weapon->getMaxRange() == 2 && distanceSq <= 6)
									{
										outOfRange = false;
									}
								}
								// zero accuracy or out of range: set it red.
								if (accuracy <= 0 || outOfRange)
								{
									accuracy = 0;
									_txtAccuracy->setColor(Palette::blockOffset(Pathfinding::red - 1)-1);
								}
								_txtAccuracy->setText(Unicode::formatPercentage(accuracy));
								_txtAccuracy->draw();
								_txtAccuracy->blitNShade(surface, screenPosition.x, screenPosition.y, 0);
							}
						}
						else if (_camera->getViewLevel() > itZ)
						{
							frameNumber = 5; // blue box
							tmpSurface = _game->getMod()->getSurfaceSet("CURSOR.PCK")->getFrame(frameNumber);
							tmpSurface->blitNShade(surface, screenPosition.x, screenPosition.y, 0);
						}
						if (_cursorType > 2 && _camera->getViewLevel() == itZ)
						{
							int frame[6] = {0, 0, 0, 11, 13, 15};
							tmpSurface = _game->getMod()->getSurfaceSet("CURSOR.PCK")->getFrame(frame[_cursorType] + (_animFrame / 4));
							tmpSurface->blitNShade(surface, screenPosition.x, screenPosition.y, 0);
						}
					}

					// Draw waypoints if any on this tile
					int waypid = 1;
					int waypXOff = 2;
					int waypYOff = 2;

					for (std::vector<Position>::const_iterator i = _waypoints.begin(); i != _waypoints.end(); ++i)
					{
						if ((*i) == mapPosition)
						{
							if (waypXOff == 2 && waypYOff == 2)
							{
								tmpSurface = _game->getMod()->getSurfaceSet("CURSOR.PCK")->getFrame(7);
								tmpSurface->blitNShade(surface, screenPosition.x, screenPosition.y, 0);
							}
							if (_save->getBattleGame()->getCurrentAction()->type == BA_LAUNCH)
							{
								_numWaypid->setValue(waypid);
								_numWaypid->draw();
								_numWaypid->blitNShade(surface, screenPosition.x + waypXOff, screenPosition.y + waypYOff, 0);

								waypXOff += waypid > 9 ? 8 : 6;
								if (waypXOff >= 26)
								{
									waypXOff = 2;
									waypYOff += 8;
								}
							}
						}
						waypid++;
					}
				}
			}
		}
	}


/*
	// VOXEL FUN
	// mix surface color with voxel z position
	float vMaxZ = _save->getMapSizeZ() * 24;
	int ScreenPixelOffset = 0;
	for (int ScreenPixelY = 0; ScreenPixelY < _screenVoxelFrame->mHeight; ScreenPixelY++)
	{
		for (int ScreenPixelX = 0; ScreenPixelX < _screenVoxelFrame->mWidth; ScreenPixelX++)
		{
			
			int vVoxelPositionZ = _screenVoxelFrame->mVoxelPosition[ ScreenPixelOffset ].Z;

			if (vVoxelPositionZ > 0)
			{
				Uint8 SurfaceColor = *surface->getRaw( ScreenPixelX, ScreenPixelY );
	//
				Uint8 VoxelColor;

//				VoxelColor = 48 + (vVoxelPositionZ  / (24.0) ) * 16;
//				VoxelColor = 16 - ((vVoxelPositionZ  / (24.0) ) * 16);

				VoxelColor = 48 + (vVoxelPositionZ  / (vMaxZ) ) * 16;
				VoxelColor = 16 - ((vVoxelPositionZ  / (vMaxZ) ) * 16);

	//				SubtractColor = SurfaceColor & 15; // mod 16 = and 15
				SurfaceColor = SurfaceColor & 240; // inverted mask to clear lower 16 colors
				Uint8 FinalColor = SurfaceColor + VoxelColor;

				surface->setPixel( ScreenPixelX, ScreenPixelY, FinalColor );
			}

			ScreenPixelOffset++;
		}
	}
*/


	// **********************************************************************************
	// CONSIDER THIS EXPERIMENTAL CODE TO LEARN HOW TO SHADE 1 SUN IN OPENXCOM
	// ONCE THAT IS LEARNED HOW TO DO IT, MORE LIGHT SOURCES CAN BE ADDED
	// AND THUS THIS CODE CAN AND MAYBE/MOST LIKELY WILL BE REPLACED
	// WITH OTHER A LIGHT ARRAY LOOP, OR PERHAPS EVEN ALL CODE
	// SEPERATED INTO A "LIGHT/SHADING ENGINE" TO KEEP IT SOMEWHAT MORE SEPERATED
	// FROM ALL THIS CODE HERE.... FOR MORE NICE CODING ?!?
	// THEN AGAIN COULD ALSO KEEP THAT LIGHT ARRAY CODE IN HERE FOR SLIGHTLY MORE SPEED
	// BUT IT WON'T MATTER MUCH I THINK, THOSE FEW FUNCTION CALLS.
	// **********************************************************************************

	// further/later ideas that could be tried, sort the ray block array. maybe be replacing ray blocks
	// by just a vector of rays, and then sorting the rays somehow to keep them near each other
	// maybe even if they are from different lights.

	// another interesting idea just popped into my head... maybe delay certain lights/light/ray computations
	// until the rays are positionally literally near each other or at the start of other light sources
	// and moving in the same direction, to keep data access the same, in same tiles...
	// would be advance, not sure how to do it and if it's worth it... branch-wise/extra branch computations possibly
	// to detect this.

	// **********************************************
	// *** SCREEN RAY BLOCK TRAVERSAL SETUP PHASE ***
	// **********************************************

//	float SunX;
//	float SunY;
//	float SunZ;

/*
	float SunX;
	float SunY;
	float SunZ;

	SunX = 30*16;
	SunY = 40*16;
	SunZ = 3000;
*/

// TEMP DISABLED
/* 

	// should first check if there is a sun or a moon
	// also sun could be restricted but then again, the sun is everywhere so let it be...
	// for moon the light power could be lower.

	// but for now test with sun only, and later add moon code/branch perhaps use 'celestial body' position
	// funny thing is sometimes sun and moon are both visible, does this cast extra light onto earth ?! haha funny question.
	// do plants and creatures use the slightly extra light in these scenerios... wow...

	// I kinda like the idea of processing a light array, then the sun can just be added as a light, a really big light
	// with a big range...

	// we may also need to collect the ammount of light from each light source... yikes.
	// thus it makes sense to use "exposure" maps and such to accumilate this/these.

	VoxelPosition vSunPosition;
	vSunPosition.X = 30*16;
	vSunPosition.Y = 40*16;
	vSunPosition.Z = 3000;

	double vLightPower = 3000;
	double vLightRange = 300;

	// use screen blocks in an attempt to keep tile/sprite data localized/in l1/l2 data cache.

	// compute estimated screen blocks
	int ScreenBlocksHorizontal = _screenVoxelFrame->mWidth / 32; // / sprite width
	int ScreenBlocksVertical = _screenVoxelFrame->mHeight / 40; // / sprite height

	// keep same level of indentation... just because.
	{
		// screen block look
		for (int ScreenBlockY = 0; ScreenBlockY < ScreenBlocksVertical; ScreenBlockY++)
		{
			int ScreenBlockStartY = ScreenBlockY * 40; // * sprite height

			for (int ScreenBlockX = 0; ScreenBlockX < ScreenBlocksHorizontal; ScreenBlockX++)
			{
				int ScreenBlockStartX = ScreenBlockX * 32; // * sprite width

				for (int ScreenBlockPixelY = 0; ScreenBlockPixelY < 40; ScreenBlockPixelY++)
				{
					int FinalPixelY = ScreenBlockStartY + ScreenBlockPixelY;
					for (int ScreenBlockPixelX = 0; ScreenBlockPixelX < 32; ScreenBlockPixelX++)
					{
						int FinalPixelX = ScreenBlockStartX + ScreenBlockPixelX;

						// where shall we store ray information ? hmmmm...... how aobut just per pixel...
						// I think wil lbe ok ?hmmm maybe not... because of bad memory access positions
						// maybe make special screen block data structure
						// let's do that.

						// compute for now, optimize later
						int ScreenPixelOffset = FinalPixelY * _screenVoxelFrame->mWidth + FinalPixelX;

						VoxelPosition vScreenVoxelPosition = _screenVoxelFrame->mVoxelPosition[ScreenPixelOffset];

						VoxelRay *vVoxelRay = _screenRayBlocks->getVoxelRay( ScreenBlockX, ScreenBlockY, ScreenBlockPixelX, ScreenBlockPixelY );

						// let's first "try" straight from sun to screen voxel, if it looks bad because of missing pixels
						// then invert it later.
						vVoxelRay->Setup( vSunPosition, vScreenVoxelPosition, 16, 16, 24 ); // tile width, height, depth
					}

				}
			}
		}
	}


	// *************************************************
	// *** SCREEN RAY BLOCK TRAVERSAL TRAVERSE PHASE ***
	// *************************************************

	// keep processing rays until they are all done
	bool AllRaysDone = true;

	while (!AllRaysDone)
	{
		// screen block look
		for (int ScreenBlockY = 0; ScreenBlockY < ScreenBlocksVertical; ScreenBlockY++)
		{
			int ScreenBlockStartY = ScreenBlockY * 40; // * sprite height

			for (int ScreenBlockX = 0; ScreenBlockX < ScreenBlocksHorizontal; ScreenBlockX++)
			{
				int ScreenBlockStartX = ScreenBlockX * 32; // * sprite width

				for (int ScreenBlockPixelY = 0; ScreenBlockPixelY < 40; ScreenBlockPixelY++)
				{
					int FinalPixelY = ScreenBlockStartY + ScreenBlockPixelY;
					for (int ScreenBlockPixelX = 0; ScreenBlockPixelX < 32; ScreenBlockPixelX++)
					{
						int FinalPixelX = ScreenBlockStartX + ScreenBlockPixelX;

						// where shall we store ray information ? hmmmm...... how aobut just per pixel...
						// I think wil lbe ok ?hmmm maybe not... because of bad memory access positions
						// maybe make special screen block data structure
						// let's do that.
						VoxelRay *vVoxelRay = _screenRayBlocks.getVoxelRay( ScreenBlockX, ScreenBlockY, ScreenBlockPixelX, ScreenBlockPixelY );

						if (!vVoxelRay->IsDone())
						{
							int vTileX, vTileY, vTileZ;
							int vVoxelX, vVoxelY, vVoxelZ;

							AllRaysDone = false;

							// kinda expensive to use another branch but ok for now, can integrate code later maybe in voxel ray
							// for automatic collision detection.

							// it could also be in direct mode oh my god another branch ;)
							if (vVoxelRay->traverseMode == tmDirect) // I could probably illimate tmDirect and just store it/set it to tmVoxel
							{
								// process single voxel

							} else
							// if in tile traverse mode look at tiles
							if (vVoxelRay->traverseMode == tmTile)
							{
								// process tile
								vVoxelRay->getTraverseTilePosition( vTileX, vTileY, vTileZ );

								// check if tile is "full" if so proceed towards traverse mode voxel

								// possibly set TileCollisionX,Y,Z for later usage perhaps, like shading maybe.

								// tile engine or map get Tile whatever

								getTile( vTile, tile position etc );

								if vTile.isEmpty or isVoid or whatever. then
								begin
									traverseMode = tmVoxel;

								end


							} else
							// if in voxel traverse mode look at voxels
							if (vVoxelRay->traverseMode == tmVoxel)
							{
								// process voxel
								vVoxelRay->getTraverseVoxelPosition( vVoxelX, vVoxelY, vVoxelZ );

								// check if voxel is "set" if so then done and use it for further computation
								// possibly set VoxelCollisionX,Y,Z for later usage most likely, like shading

								// good question, put screen pixel in darkness or wait till it exits and hits nothing
								// and then shade it based on sun distance, most likely this... wowe ;)

//								Shade( SunX, SunY, SunZ, VoxelX, VoxelY, VoxelZ ); // ?!?
								// computing it directly for now in here below:

								// use doubles are floats, not sure, sticking with doubles for now, though floats is tempting too.

								double vLightX = vSunPosition.X;
								double vLightY = vSunPosition.Y;
								double vLightZ = vSunPosition.Z;


								// calculate distance from pixel/depth position to light position and use this as a factor to modify the intensity/exposure amount that will be summed.
								double vDistanceToLightDeltaX = (vLightX - vVoxelX);
								double vDistanceToLightDeltaY = (vLightY - vVoxelY);
								double vDistanceToLightDeltaZ = (vLightZ - vVoxelZ);

					//			vDistanceToLight := mDistanceMap[vPixelX,vPixelY];
								double vDistanceToLightSquared =
								(
									(vDistanceToLightDeltaX * vDistanceToLightDeltaX) +
									(vDistanceToLightDeltaY * vDistanceToLightDeltaY) +
									(vDistanceToLightDeltaZ * vDistanceToLightDeltaZ)
								);

{
								vPixelZ := mDepthMap[vPixelX,vPixelY];

								// angle between surface normal/roof tops and light source.
			//					vAngle := calc_angle_between_two_vectors_3d( vPixelX - (mWidth div 2),vPixelY - (mHeight div 2),vPixelZ - 500, vLightX - vPixelX, vLightY - vPixelY, vLightZ - vPixelZ );

								// what is 0,0,1 is that a normal ? wow... probably depth map normal... might have to change this for OpenXcom
								// SEE comment: angle between surface normal/roof tops and light source.
								// OH-OH EMERGENCY ! ;) =D
								// might have to, and probably have to detect which side of the voxel is hit ! oh my god yeah !
								// to get a really good normal ? or very normal I can just "pretend" the top side was hit
								// cause we looking down on it anyway somewhat ! ;)
								double vAngle = calc_angle_between_two_vectors_3d
								(
									0,0,1,

									vLightX - vVoxelX,
									vLightY - vVoxelY,
									vLightZ - vVoxelZ
								);

								// mExposureMap[vPixelX,vPixelY] := mExposureMap[vPixelX,vPixelY] + ( ((pi - vAngle)/pi) * vLightPower ) / vDistanceToLightSquared;
								double vExposure =
								(
									(
										(M_PI  - vAngle) / M_PI 
									) * vLightPower
								) / vDistanceToLightSquared;

								// calculate pixel/surface color using exposure value

								// clamp exposure value for safety, maybe not necessary but maybe it is don't know yet
								// do it anyway for safety, cause original code does it as well
								// and later if we add more lights it can definetly overflow, so CLAMP IT ! >=D



								if (vExposure > 1.0) vExposure = 1.0;
								if (vExposure < 0.0) vExposure = 0;

								vColor = // get surface color... not gonna bother writing this code now fix it later.

								// OH OH, we don't have a red, green and blue channel !
								// but what we do have is a SHADE level capability...
								// so use that ! problem nicely solved...
								// use some "and" code and such to set surface color to minimum
								// and then "scale" up depending on exposure ! Very cool and nice ! =D

								// oh interestingly enough we can keep 25 procent of original color/shade
								// and then only use the exposure as 75 procent of the shade, that cool.
								// keep this code idea in here for now in case 24 bit or 32 bit or even higher color bit mode becomes available.
//								vRed := vColor.Red * 0.25 + vExposure * (vColor.Red * 0.75);
//								vGreen := vColor.Green * 0.25 + vExposure * (vColor.Green * 0.75);
//								vBlue := vColor.Blue * 0.25 + vExposure * (vColor.Blue * 0.75);

					//			vRed := mExposureMap[vPixelX,vPixelY] * 255;
					//			vGreen := mExposureMap[vPixelX,vPixelY] * 255;
					//			vBlue := mExposureMap[vPixelX,vPixelY] * 255;

								// something like this...
								// test it first with some vExposure set to 0.0 to 1.0 to see if computations are correct.
								vShadeMaxLevel = 15;
								vShadeExposure = vExposure * vShadeMaxLevel;

								// to lazy to write shade code now...
								// but it's something like color % 15 and such... 
								ComputeShade( vSurfaceColor, vExposure );

								 
								vShadeLevel = vColor * 0.25 + vColor * vShadeExposure * 0.75; 

								// hmm not yet sure
								vFinalColor = vColor * 0.25 + vColor * vShadeExposure * 0.75;

								// cap color if absolutely necessary but probably not necessary
								// as long as it stayed in range of 0..15 when adding to color
								// however color could be anything so maybe good to cap it
								// to it's shade/color palette entry/range and such.... hmmm
								// must know first in what palette range it lies...

//								if vRed > 255 then vRed := 255;
//								if vGreen > 255 then vGreen := 255;
//								if vBlue > 255 then vBlue := 255;

//								if vRed < 0 then vRed := 0;
//								if vGreen < 0 then vGreen := 0;
//								if vBlue < 0 then vBlue := 0;
//


//								vPixel.Red := Round( vRed );
//								vPixel.Green :=  Round( vGreen );
//								vPixel.Blue := Round( vBlue );
//								vPixel.Alpha := 0;

//								mPixelMap[vPixelX,vPixelY] := vPixel;

								// set final screen pixel color
								surface dst -> set pixel etc....

							}

							vVoxelRay->NextStep();

						}
					}

				}
			}
		}
	}

	// old code sketch
/*
	int ScreenPixelOffset = 0;
	for (int ScreenPixelY = 0; ScreenPixelY < _screenVoxelFrame->mHeight; ScreenPixelY++)
	{
		for (int ScreenPixelX = 0; ScreenPixelX < _screenVoxelFrame->mWidth; ScreenPixelX++)
		{
			VoxelPosition vVoxelPosition = _screenVoxelFrame->mVoxelPosition[ ScreenPixelOffset ];

			if (vVoxelPosition.Z > 0)
			{
				VoxelRay[ScreenPixelOffset].Setup( SunX, SunY, SunZ, vVoxelPosition.X, vVoxelPosition.Y, vVoxelPosition.Z );
			}

			ScreenPixelOffset++;
		}
	}

	bool AllRaysDone = true;

	while (!AllRaysDone)
	{
		int ScreenPixelOffset = 0;
		for (int ScreenPixelY = 0; ScreenPixelY < _screenVoxelFrame->mHeight; ScreenPixelY++)
		{
			for (int ScreenPixelX = 0; ScreenPixelX < _screenVoxelFrame->mWidth; ScreenPixelX++)
			{
				if (!VoxelRay[ScreenPixelOffset].Done)
				{
					AllRaysDone = false;

					VoxelRay[ScreenPixelOffset].NextStep;

					if (VoxelRay[ScreenPixelOffset].TraverseMode == tmTile)
					{
						// check if collission with tile.


						// if collission then set traverse mode to tmVoxel



					};


					if (VoxelRay[ScreenPixelOffset].Collision)
					{
						CollisionTilePosition = VoxelRay[ScreenPixelOffset].TilePosition;
						CollisionVoxelPosition = VoxelRay[ScreenPixelOffset].VoxelPosition;

						// some kind of distance or angle shading or whatever..
						// but for now, it's just lit or dark.


					}

				}

				ScreenPixelOffset++;
			}
		}
	}
*/


	if (pathfinderTurnedOn)
	{
		if (_numWaypid)
		{
			_numWaypid->setBordered(true); // give it a border for the pathfinding display, makes it more visible on snow, etc.
		}
		for (int itZ = beginZ; itZ <= endZ; itZ++)
		{
			for (int itX = beginX; itX <= endX; itX++)
			{
				for (int itY = beginY; itY <= endY; itY++)
				{
					mapPosition = Position(itX, itY, itZ);
					_camera->convertMapToScreen(mapPosition, &screenPosition);
					screenPosition += _camera->getMapOffset();

					// only render cells that are inside the surface
					if (screenPosition.x > -_spriteWidth && screenPosition.x < surface->getWidth() + _spriteWidth &&
						screenPosition.y > -_spriteHeight && screenPosition.y < surface->getHeight() + _spriteHeight )
					{
						tile = _save->getTile(mapPosition);
						Tile *tileBelow = _save->getTile(mapPosition - Position(0,0,1));
						if (!tile || !tile->isDiscovered(0) || tile->getPreview() == -1)
							continue;
						int adjustment = -tile->getTerrainLevel();
						if (_previewSetting & PATH_ARROWS)
						{
							if (itZ > 0 && tile->hasNoFloor(tileBelow))
							{
								tmpSurface = _game->getMod()->getSurfaceSet("Pathfinding")->getFrame(23);
								if (tmpSurface)
								{
									tmpSurface->blitNShade(surface, screenPosition.x, screenPosition.y+2, 0, false, tile->getMarkerColor());
								}
							}
							int overlay = tile->getPreview() + 12;
							tmpSurface = _game->getMod()->getSurfaceSet("Pathfinding")->getFrame(overlay);
							if (tmpSurface)
							{
								tmpSurface->blitNShade(surface, screenPosition.x, screenPosition.y - adjustment, 0, false, tile->getMarkerColor());
							}
						}

						if (_previewSetting & PATH_TU_COST && tile->getTUMarker() > -1)
						{
							int off = tile->getTUMarker() > 9 ? 5 : 3;
							if (_save->getSelectedUnit() && _save->getSelectedUnit()->getArmor()->getSize() > 1)
							{
								adjustment += 1;
								if (!(_previewSetting & PATH_ARROWS))
								{
									adjustment += 7;
								}
							}
							_numWaypid->setValue(tile->getTUMarker());
							_numWaypid->draw();
							if ( !(_previewSetting & PATH_ARROWS) )
							{
								_numWaypid->blitNShade(surface, screenPosition.x + 16 - off, screenPosition.y + (29-adjustment), 0, false, tile->getMarkerColor() );
							}
							else
							{
								_numWaypid->blitNShade(surface, screenPosition.x + 16 - off, screenPosition.y + (22-adjustment), 0);
							}
						}
					}
				}
			}
		}
		if (_numWaypid)
		{
			_numWaypid->setBordered(false); // make sure we remove the border in case it's being used for missile waypoints.
		}
	}
	unit = (BattleUnit*)_save->getSelectedUnit();
	if (unit && (_save->getSide() == FACTION_PLAYER || _save->getDebugMode()) && unit->getPosition().z <= _camera->getViewLevel())
	{
		_camera->convertMapToScreen(unit->getPosition(), &screenPosition);
		screenPosition += _camera->getMapOffset();
		Position offset;
		calculateWalkingOffset(unit, &offset);
		if (unit->getArmor()->getSize() > 1)
		{
			offset.y += 4;
		}
		offset.y += 24 - (unit->getHeight() + unit->getFloatHeight());
		if (unit->isKneeled())
		{
			offset.y -= 2;
		}
		if (this->getCursorType() != CT_NONE)
		{
			_arrow->blitNShade(surface, screenPosition.x + offset.x + (_spriteWidth / 2) - (_arrow->getWidth() / 2), screenPosition.y + offset.y - _arrow->getHeight() + arrowBob[_animFrame], 0);
		}
	}
	delete _numWaypid;

	// check if we got big explosions
	if (_explosionInFOV)
	{
		// big explosions cause the screen to flash as bright as possible before any explosions are actually drawn.
		// this causes everything to look like EGA for a single frame.
		if (_flashScreen)
		{
			for (int x = 0, y = 0; x < surface->getWidth() && y < surface->getHeight();)
			{
				Uint8 pixel = surface->getPixel(x, y);
				pixel = (pixel / 16) * 16;
				surface->setPixelIterative(&x, &y, pixel);
			}
			_flashScreen = false;
		}
		else
		{
			for (std::list<Explosion*>::const_iterator i = _explosions.begin(); i != _explosions.end(); ++i)
			{
				_camera->convertVoxelToScreen((*i)->getPosition(), &bulletPositionScreen);
				if ((*i)->isBig())
				{
					if ((*i)->getCurrentFrame() >= 0)
					{
						tmpSurface = _game->getMod()->getSurfaceSet("X1.PCK")->getFrame((*i)->getCurrentFrame());
						tmpSurface->blitNShade(surface, bulletPositionScreen.x - (tmpSurface->getWidth() / 2), bulletPositionScreen.y - (tmpSurface->getHeight() / 2), 0);
					}
				}
				else if ((*i)->isHit())
				{
					tmpSurface = _game->getMod()->getSurfaceSet("HIT.PCK")->getFrame((*i)->getCurrentFrame());
					tmpSurface->blitNShade(surface, bulletPositionScreen.x - 15, bulletPositionScreen.y - 25, 0);
				}
				else
				{
					tmpSurface = _game->getMod()->getSurfaceSet("SMOKE.PCK")->getFrame((*i)->getCurrentFrame());
					tmpSurface->blitNShade(surface, bulletPositionScreen.x - 15, bulletPositionScreen.y - 15, 0);
				}
			}
		}
	}
	surface->unlock();
}


/**
 * Draw the terrain.
 * Keep this function as optimised as possible. It's big to minimise overhead of function calls.
 * @param surface The surface to draw on.
 */

/*
// original DrawTerrain
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

	// if we got bullet, get the highest x and y tiles to draw it on
	if (_projectile && _explosions.empty())
	{
		int part = _projectile->getItem() ? 0 : BULLET_SPRITES-1;
		for (int i = 0; i <= part; ++i)
		{
			if (_projectile->getPosition(1-i).x < bulletLowX)
				bulletLowX = _projectile->getPosition(1-i).x;
			if (_projectile->getPosition(1-i).y < bulletLowY)
				bulletLowY = _projectile->getPosition(1-i).y;
			if (_projectile->getPosition(1-i).z < bulletLowZ)
				bulletLowZ = _projectile->getPosition(1-i).z;
			if (_projectile->getPosition(1-i).x > bulletHighX)
				bulletHighX = _projectile->getPosition(1-i).x;
			if (_projectile->getPosition(1-i).y > bulletHighY)
				bulletHighY = _projectile->getPosition(1-i).y;
			if (_projectile->getPosition(1-i).z > bulletHighZ)
				bulletHighZ = _projectile->getPosition(1-i).z;
		}
		// divide by 16 to go from voxel to tile position
		bulletLowX = bulletLowX / 16;
		bulletLowY = bulletLowY / 16;
		bulletLowZ = bulletLowZ / 24;
		bulletHighX = bulletHighX / 16;
		bulletHighY = bulletHighY / 16;
		bulletHighZ = bulletHighZ / 24;

		// if the projectile is outside the viewport - center it back on it
		_camera->convertVoxelToScreen(_projectile->getPosition(), &bulletPositionScreen);

		if (_projectileInFOV)
		{
			Position newCam = _camera->getMapOffset();
			if (newCam.z != bulletHighZ) //switch level
			{
				newCam.z = bulletHighZ;
				if (_projectileInFOV)
				{
					_camera->setMapOffset(newCam);
					_camera->convertVoxelToScreen(_projectile->getPosition(), &bulletPositionScreen);
				}
			}
			if (_smoothCamera)
			{
				if (_launch)
				{
					_launch = false;
					if ((bulletPositionScreen.x < 1 || bulletPositionScreen.x > surface->getWidth() - 1 ||
						bulletPositionScreen.y < 1 || bulletPositionScreen.y > _visibleMapHeight - 1))
					{
						_camera->centerOnPosition(Position(bulletLowX, bulletLowY, bulletHighZ), false);
						_camera->convertVoxelToScreen(_projectile->getPosition(), &bulletPositionScreen);
					}
				}
				if (!_smoothingEngaged)
				{
					if (bulletPositionScreen.x < 1 || bulletPositionScreen.x > surface->getWidth() - 1 ||
						bulletPositionScreen.y < 1 || bulletPositionScreen.y > _visibleMapHeight - 1)
					{
						_smoothingEngaged = true;
					}
				}
				else
				{
					_camera->jumpXY(surface->getWidth() / 2 - bulletPositionScreen.x, _visibleMapHeight / 2 - bulletPositionScreen.y);
				}
			}
			else
			{
				bool enough;
				do
				{
					enough = true;
					if (bulletPositionScreen.x < 0)
					{
						_camera->jumpXY(+surface->getWidth(), 0);
						enough = false;
					}
					else if (bulletPositionScreen.x > surface->getWidth())
					{
						_camera->jumpXY(-surface->getWidth(), 0);
						enough = false;
					}
					else if (bulletPositionScreen.y < 0)
					{
						_camera->jumpXY(0, +_visibleMapHeight);
						enough = false;
					}
					else if (bulletPositionScreen.y > _visibleMapHeight)
					{
						_camera->jumpXY(0, -_visibleMapHeight);
						enough = false;
					}
					_camera->convertVoxelToScreen(_projectile->getPosition(), &bulletPositionScreen);
				}
				while (!enough);
			}
		}
	}

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
	for (int itZ = beginZ; itZ <= endZ; itZ++)
	{
		bool topLayer = itZ == endZ;
		for (int itX = beginX; itX <= endX; itX++)
		{
			for (int itY = beginY; itY <= endY; itY++)
			{
				mapPosition = Position(itX, itY, itZ);
				_camera->convertMapToScreen(mapPosition, &screenPosition);
				screenPosition += _camera->getMapOffset();

				// only render cells that are inside the surface
				if (screenPosition.x > -_spriteWidth && screenPosition.x < surface->getWidth() + _spriteWidth &&
					screenPosition.y > -_spriteHeight && screenPosition.y < surface->getHeight() + _spriteHeight )
				{
					tile = _save->getTile(mapPosition);

					if (!tile) continue;

					if (tile->isDiscovered(2))
					{
						tileShade = tile->getShade();
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
					if (_cursorType != CT_NONE && _selectorX > itX - _cursorSize && _selectorY > itY - _cursorSize && _selectorX < itX+1 && _selectorY < itY+1 && !_save->getBattleState()->getMouseOverIcons())
					{
						if (_camera->getViewLevel() == itZ)
						{
							if (_cursorType != CT_AIM)
							{
								if (unit && (unit->getVisible() || _save->getDebugMode()))
									frameNumber = (_animFrame % 2); // yellow box
								else
									frameNumber = 0; // red box
							}
							else
							{
								if (unit && (unit->getVisible() || _save->getDebugMode()))
									frameNumber = 7 + (_animFrame / 2); // yellow animated crosshairs
								else
									frameNumber = 6; // red static crosshairs
							}
							tmpSurface = _game->getMod()->getSurfaceSet("CURSOR.PCK")->getFrame(frameNumber);
							tmpSurface->blitNShade(surface, screenPosition.x, screenPosition.y, 0);
						}
						else if (_camera->getViewLevel() > itZ)
						{
							frameNumber = 2; // blue box
							tmpSurface = _game->getMod()->getSurfaceSet("CURSOR.PCK")->getFrame(frameNumber);
							tmpSurface->blitNShade(surface, screenPosition.x, screenPosition.y, 0);
						}
					}

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

					// check if we got bullet && it is in Field Of View
					if (_projectile && _projectileInFOV)
					{
						tmpSurface = 0;
						if (_projectile->getItem())
						{
							tmpSurface = _projectile->getSprite();

							Position voxelPos = _projectile->getPosition();
							// draw shadow on the floor
							voxelPos.z = _save->getTileEngine()->castedShade(voxelPos);
							if (voxelPos.x / 16 >= itX &&
								voxelPos.y / 16 >= itY &&
								voxelPos.x / 16 <= itX+1 &&
								voxelPos.y / 16 <= itY+1 &&
								voxelPos.z / 24 == itZ &&
								_save->getTileEngine()->isVoxelVisible(voxelPos))
							{
								_camera->convertVoxelToScreen(voxelPos, &bulletPositionScreen);
								tmpSurface->blitNShade(surface, bulletPositionScreen.x - 16, bulletPositionScreen.y - 26, 16);
							}

							voxelPos = _projectile->getPosition();
							// draw thrown object
							if (voxelPos.x / 16 >= itX &&
								voxelPos.y / 16 >= itY &&
								voxelPos.x / 16 <= itX+1 &&
								voxelPos.y / 16 <= itY+1 &&
								voxelPos.z / 24 == itZ &&
								_save->getTileEngine()->isVoxelVisible(voxelPos))
							{
								_camera->convertVoxelToScreen(voxelPos, &bulletPositionScreen);
								tmpSurface->blitNShade(surface, bulletPositionScreen.x - 16, bulletPositionScreen.y - 26, 0);
							}

						}
						else
						{
							// draw bullet on the correct tile
							if (itX >= bulletLowX && itX <= bulletHighX && itY >= bulletLowY && itY <= bulletHighY)
							{
								int begin = 0;
								int end = BULLET_SPRITES;
								int direction = 1;
								if (_projectile->isReversed())
								{
									begin = BULLET_SPRITES - 1;
									end = -1;
									direction = -1;
								}

								for (int i = begin; i != end; i += direction)
								{
									tmpSurface = _projectileSet->getFrame(_projectile->getParticle(i));
									if (tmpSurface)
									{
										Position voxelPos = _projectile->getPosition(1-i);
										// draw shadow on the floor
										voxelPos.z = _save->getTileEngine()->castedShade(voxelPos);
										if (voxelPos.x / 16 == itX &&
											voxelPos.y / 16 == itY &&
											voxelPos.z / 24 == itZ &&
											_save->getTileEngine()->isVoxelVisible(voxelPos))
										{
											_camera->convertVoxelToScreen(voxelPos, &bulletPositionScreen);
											bulletPositionScreen.x -= tmpSurface->getWidth() / 2;
											bulletPositionScreen.y -= tmpSurface->getHeight() / 2;
											tmpSurface->blitNShade(surface, bulletPositionScreen.x, bulletPositionScreen.y, 16);
										}

										// draw bullet itself
										voxelPos = _projectile->getPosition(1-i);
										if (voxelPos.x / 16 == itX &&
											voxelPos.y / 16 == itY &&
											voxelPos.z / 24 == itZ &&
											_save->getTileEngine()->isVoxelVisible(voxelPos))
										{
											_camera->convertVoxelToScreen(voxelPos, &bulletPositionScreen);
											bulletPositionScreen.x -= tmpSurface->getWidth() / 2;
											bulletPositionScreen.y -= tmpSurface->getHeight() / 2;
											tmpSurface->blitNShade(surface, bulletPositionScreen.x, bulletPositionScreen.y, 0);
										}
									}
								}
							}
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

					// Draw smoke/fire
					if (tile->getSmoke() && tile->isDiscovered(2))
					{
						frameNumber = 0;
						int shade = 0;
						if (!tile->getFire())
						{
							if (_save->getDepth() > 0)
							{
								frameNumber += Mod::UNDERWATER_SMOKE_OFFSET;
							}
							else
							{
								frameNumber += Mod::SMOKE_OFFSET;
							}
							frameNumber += int(floor((tile->getSmoke() / 6.0) - 0.1)); // see http://www.ufopaedia.org/images/c/cb/Smoke.gif
							shade = tileShade;
						}

						if ((_animFrame / 2) + tile->getAnimationOffset() > 3)
						{
							frameNumber += ((_animFrame / 2) + tile->getAnimationOffset() - 4);
						}
						else
						{
							frameNumber += (_animFrame / 2) + tile->getAnimationOffset();
						}
						tmpSurface = _game->getMod()->getSurfaceSet("SMOKE.PCK")->getFrame(frameNumber);
						tmpSurface->blitNShade(surface, screenPosition.x, screenPosition.y, shade);
					}

					//draw particle clouds
					for (std::list<Particle*>::const_iterator i = tile->getParticleCloud()->begin(); i != tile->getParticleCloud()->end(); ++i)
					{
						int vaporX = screenPosition.x + (*i)->getX();
						int vaporY = screenPosition.y + (*i)->getY();
						if ((int)(_transparencies->size()) >= ((*i)->getColor() + 1) * 1024)
						{
							switch ((*i)->getSize())
							{
							case 3:
								surface->setPixel(vaporX+1, vaporY+1, (*_transparencies)[((*i)->getColor() * 1024) + ((*i)->getOpacity() * 256) + surface->getPixel(vaporX+1, vaporY+1)]);
							case 2:
								surface->setPixel(vaporX + 1, vaporY, (*_transparencies)[((*i)->getColor() * 1024) + ((*i)->getOpacity() * 256) + surface->getPixel(vaporX + 1, vaporY)]);
							case 1:
								surface->setPixel(vaporX, vaporY + 1, (*_transparencies)[((*i)->getColor() * 1024) + ((*i)->getOpacity() * 256) + surface->getPixel(vaporX, vaporY + 1)]);
							default:
								surface->setPixel(vaporX, vaporY, (*_transparencies)[((*i)->getColor() * 1024) + ((*i)->getOpacity() * 256) + surface->getPixel(vaporX, vaporY)]);
								break;
							}
						}
					}

					// Draw Path Preview
					if (tile->getPreview() != -1 && tile->isDiscovered(0) && (_previewSetting & PATH_ARROWS))
					{
						if (itZ > 0 && tile->hasNoFloor(_save->getTile(tile->getPosition() + Position(0,0,-1))))
						{
							tmpSurface = _game->getMod()->getSurfaceSet("Pathfinding")->getFrame(11);
							if (tmpSurface)
							{
								tmpSurface->blitNShade(surface, screenPosition.x, screenPosition.y+2, 0, false, tile->getMarkerColor());
							}
						}
						tmpSurface = _game->getMod()->getSurfaceSet("Pathfinding")->getFrame(tile->getPreview());
						if (tmpSurface)
						{
							tmpSurface->blitNShade(surface, screenPosition.x, screenPosition.y + tile->getTerrainLevel(), 0, false, tileColor);
						}
					}
					if (!tile->isVoid())
					{
						// Draw object
						if (tile->getMapData(O_OBJECT) && tile->getMapData(O_OBJECT)->getBigWall() >= 6 && tile->getMapData(O_OBJECT)->getBigWall() != 9)
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
					}
					// Draw cursor front
					if (_cursorType != CT_NONE && _selectorX > itX - _cursorSize && _selectorY > itY - _cursorSize && _selectorX < itX+1 && _selectorY < itY+1 && !_save->getBattleState()->getMouseOverIcons())
					{
						if (_camera->getViewLevel() == itZ)
						{
							if (_cursorType != CT_AIM)
							{
								if (unit && (unit->getVisible() || _save->getDebugMode()))
									frameNumber = 3 + (_animFrame % 2); // yellow box
								else
									frameNumber = 3; // red box
							}
							else
							{
								if (unit && (unit->getVisible() || _save->getDebugMode()))
									frameNumber = 7 + (_animFrame / 2); // yellow animated crosshairs
								else
									frameNumber = 6; // red static crosshairs
							}
							tmpSurface = _game->getMod()->getSurfaceSet("CURSOR.PCK")->getFrame(frameNumber);
							tmpSurface->blitNShade(surface, screenPosition.x, screenPosition.y, 0);

							// UFO extender accuracy: display adjusted accuracy value on crosshair in real-time.
							if (_cursorType == CT_AIM && Options::battleUFOExtenderAccuracy)
							{
								BattleAction *action = _save->getBattleGame()->getCurrentAction();
								RuleItem *weapon = action->weapon->getRules();
								int accuracy = action->actor->getFiringAccuracy(action->type, action->weapon);
								int distanceSq = _save->getTileEngine()->distanceUnitToPositionSq(action->actor, Position (itX, itY,itZ), false);
								int distance = (int)std::ceil(sqrt(float(distanceSq)));
								int upperLimit = 200;
								int lowerLimit = weapon->getMinRange();
								switch (action->type)
								{
								case BA_AIMEDSHOT:
									upperLimit = weapon->getAimRange();
									break;
								case BA_SNAPSHOT:
									upperLimit = weapon->getSnapRange();
									break;
								case BA_AUTOSHOT:
									upperLimit = weapon->getAutoRange();
									break;
								default:
									break;
								}
								// at this point, let's assume the shot is adjusted and set the text amber.
								_txtAccuracy->setColor(Palette::blockOffset(Pathfinding::yellow - 1)-1);

								if (distance > upperLimit)
								{
									accuracy -= (distance - upperLimit) * weapon->getDropoff();
								}
								else if (distance < lowerLimit)
								{
									accuracy -= (lowerLimit - distance) * weapon->getDropoff();
								}
								else
								{
									// no adjustment made? set it to green.
									_txtAccuracy->setColor(Palette::blockOffset(Pathfinding::green - 1)-1);
								}

								bool outOfRange = distanceSq > weapon->getMaxRangeSq();
								// special handling for short ranges and diagonals
								if (outOfRange)
								{
									// special handling for maxRange 1: allow it to target diagonally adjacent tiles (one diagonal move)
									if (weapon->getMaxRange() == 1 && distanceSq <= 3)
									{
										outOfRange = false;
									}
									// special handling for maxRange 2: allow it to target diagonally adjacent tiles (one diagonal move + one straight move)
									else if (weapon->getMaxRange() == 2 && distanceSq <= 6)
									{
										outOfRange = false;
									}
								}
								// zero accuracy or out of range: set it red.
								if (accuracy <= 0 || outOfRange)
								{
									accuracy = 0;
									_txtAccuracy->setColor(Palette::blockOffset(Pathfinding::red - 1)-1);
								}
								_txtAccuracy->setText(Unicode::formatPercentage(accuracy));
								_txtAccuracy->draw();
								_txtAccuracy->blitNShade(surface, screenPosition.x, screenPosition.y, 0);
							}
						}
						else if (_camera->getViewLevel() > itZ)
						{
							frameNumber = 5; // blue box
							tmpSurface = _game->getMod()->getSurfaceSet("CURSOR.PCK")->getFrame(frameNumber);
							tmpSurface->blitNShade(surface, screenPosition.x, screenPosition.y, 0);
						}
						if (_cursorType > 2 && _camera->getViewLevel() == itZ)
						{
							int frame[6] = {0, 0, 0, 11, 13, 15};
							tmpSurface = _game->getMod()->getSurfaceSet("CURSOR.PCK")->getFrame(frame[_cursorType] + (_animFrame / 4));
							tmpSurface->blitNShade(surface, screenPosition.x, screenPosition.y, 0);
						}
					}

					// Draw waypoints if any on this tile
					int waypid = 1;
					int waypXOff = 2;
					int waypYOff = 2;

					for (std::vector<Position>::const_iterator i = _waypoints.begin(); i != _waypoints.end(); ++i)
					{
						if ((*i) == mapPosition)
						{
							if (waypXOff == 2 && waypYOff == 2)
							{
								tmpSurface = _game->getMod()->getSurfaceSet("CURSOR.PCK")->getFrame(7);
								tmpSurface->blitNShade(surface, screenPosition.x, screenPosition.y, 0);
							}
							if (_save->getBattleGame()->getCurrentAction()->type == BA_LAUNCH)
							{
								_numWaypid->setValue(waypid);
								_numWaypid->draw();
								_numWaypid->blitNShade(surface, screenPosition.x + waypXOff, screenPosition.y + waypYOff, 0);

								waypXOff += waypid > 9 ? 8 : 6;
								if (waypXOff >= 26)
								{
									waypXOff = 2;
									waypYOff += 8;
								}
							}
						}
						waypid++;
					}
				}
			}
		}
	}
	if (pathfinderTurnedOn)
	{
		if (_numWaypid)
		{
			_numWaypid->setBordered(true); // give it a border for the pathfinding display, makes it more visible on snow, etc.
		}
		for (int itZ = beginZ; itZ <= endZ; itZ++)
		{
			for (int itX = beginX; itX <= endX; itX++)
			{
				for (int itY = beginY; itY <= endY; itY++)
				{
					mapPosition = Position(itX, itY, itZ);
					_camera->convertMapToScreen(mapPosition, &screenPosition);
					screenPosition += _camera->getMapOffset();

					// only render cells that are inside the surface
					if (screenPosition.x > -_spriteWidth && screenPosition.x < surface->getWidth() + _spriteWidth &&
						screenPosition.y > -_spriteHeight && screenPosition.y < surface->getHeight() + _spriteHeight )
					{
						tile = _save->getTile(mapPosition);
						Tile *tileBelow = _save->getTile(mapPosition - Position(0,0,1));
						if (!tile || !tile->isDiscovered(0) || tile->getPreview() == -1)
							continue;
						int adjustment = -tile->getTerrainLevel();
						if (_previewSetting & PATH_ARROWS)
						{
							if (itZ > 0 && tile->hasNoFloor(tileBelow))
							{
								tmpSurface = _game->getMod()->getSurfaceSet("Pathfinding")->getFrame(23);
								if (tmpSurface)
								{
									tmpSurface->blitNShade(surface, screenPosition.x, screenPosition.y+2, 0, false, tile->getMarkerColor());
								}
							}
							int overlay = tile->getPreview() + 12;
							tmpSurface = _game->getMod()->getSurfaceSet("Pathfinding")->getFrame(overlay);
							if (tmpSurface)
							{
								tmpSurface->blitNShade(surface, screenPosition.x, screenPosition.y - adjustment, 0, false, tile->getMarkerColor());
							}
						}

						if (_previewSetting & PATH_TU_COST && tile->getTUMarker() > -1)
						{
							int off = tile->getTUMarker() > 9 ? 5 : 3;
							if (_save->getSelectedUnit() && _save->getSelectedUnit()->getArmor()->getSize() > 1)
							{
								adjustment += 1;
								if (!(_previewSetting & PATH_ARROWS))
								{
									adjustment += 7;
								}
							}
							_numWaypid->setValue(tile->getTUMarker());
							_numWaypid->draw();
							if ( !(_previewSetting & PATH_ARROWS) )
							{
								_numWaypid->blitNShade(surface, screenPosition.x + 16 - off, screenPosition.y + (29-adjustment), 0, false, tile->getMarkerColor() );
							}
							else
							{
								_numWaypid->blitNShade(surface, screenPosition.x + 16 - off, screenPosition.y + (22-adjustment), 0);
							}
						}
					}
				}
			}
		}
		if (_numWaypid)
		{
			_numWaypid->setBordered(false); // make sure we remove the border in case it's being used for missile waypoints.
		}
	}
	unit = (BattleUnit*)_save->getSelectedUnit();
	if (unit && (_save->getSide() == FACTION_PLAYER || _save->getDebugMode()) && unit->getPosition().z <= _camera->getViewLevel())
	{
		_camera->convertMapToScreen(unit->getPosition(), &screenPosition);
		screenPosition += _camera->getMapOffset();
		Position offset;
		calculateWalkingOffset(unit, &offset);
		if (unit->getArmor()->getSize() > 1)
		{
			offset.y += 4;
		}
		offset.y += 24 - (unit->getHeight() + unit->getFloatHeight());
		if (unit->isKneeled())
		{
			offset.y -= 2;
		}
		if (this->getCursorType() != CT_NONE)
		{
			_arrow->blitNShade(surface, screenPosition.x + offset.x + (_spriteWidth / 2) - (_arrow->getWidth() / 2), screenPosition.y + offset.y - _arrow->getHeight() + arrowBob[_animFrame], 0);
		}
	}
	delete _numWaypid;

	// check if we got big explosions
	if (_explosionInFOV)
	{
		// big explosions cause the screen to flash as bright as possible before any explosions are actually drawn.
		// this causes everything to look like EGA for a single frame.
		if (_flashScreen)
		{
			for (int x = 0, y = 0; x < surface->getWidth() && y < surface->getHeight();)
			{
				Uint8 pixel = surface->getPixel(x, y);
				pixel = (pixel / 16) * 16;
				surface->setPixelIterative(&x, &y, pixel);
			}
			_flashScreen = false;
		}
		else
		{
			for (std::list<Explosion*>::const_iterator i = _explosions.begin(); i != _explosions.end(); ++i)
			{
				_camera->convertVoxelToScreen((*i)->getPosition(), &bulletPositionScreen);
				if ((*i)->isBig())
				{
					if ((*i)->getCurrentFrame() >= 0)
					{
						tmpSurface = _game->getMod()->getSurfaceSet("X1.PCK")->getFrame((*i)->getCurrentFrame());
						tmpSurface->blitNShade(surface, bulletPositionScreen.x - (tmpSurface->getWidth() / 2), bulletPositionScreen.y - (tmpSurface->getHeight() / 2), 0);
					}
				}
				else if ((*i)->isHit())
				{
					tmpSurface = _game->getMod()->getSurfaceSet("HIT.PCK")->getFrame((*i)->getCurrentFrame());
					tmpSurface->blitNShade(surface, bulletPositionScreen.x - 15, bulletPositionScreen.y - 25, 0);
				}
				else
				{
					tmpSurface = _game->getMod()->getSurfaceSet("SMOKE.PCK")->getFrame((*i)->getCurrentFrame());
					tmpSurface->blitNShade(surface, bulletPositionScreen.x - 15, bulletPositionScreen.y - 15, 0);
				}
			}
		}
	}
	surface->unlock();
}


*/


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
	_screenVoxelFrame->SetHeight( height );
	_screenRayBlocks->SetHeight( height );

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
	_screenVoxelFrame->SetWidth( width );
	_screenRayBlocks->SetWidth( width );
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
