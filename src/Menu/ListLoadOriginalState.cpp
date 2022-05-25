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
#include "ListLoadOriginalState.h"
#include <sstream>

#include "../Savegame/SavedGame.h"
#include "../Savegame/SavedBattleGame.h"
#include "../Engine/Game.h"
#include "../Engine/Screen.h"
#include "../Engine/Action.h"
#include "../Mod/Mod.h"
#include "../Engine/LocalizedText.h"
#include "../Engine/Options.h"
#include "../Interface/TextButton.h"
#include "../Interface/Window.h"
#include "../Interface/Text.h"
#include "../Battlescape/BattlescapeState.h"
#include "ErrorMessageState.h"
#include "../Mod/RuleInterface.h"

namespace OpenXcom
{

/**
 * Initializes all the elements in the Saved Game screen.
 * @param game Pointer to the core game.
 * @param origin Game section that originated this state.
 */
ListLoadOriginalState::ListLoadOriginalState(OptionsOrigin origin) : _origin(origin)
{
	_screen = false;

	// Create objects
	_window = new Window(this, 320, 200, 0, 0);
	_btnNew = new TextButton(80, 16, 60, 172);
	_btnCancel = new TextButton(80, 16, 180, 172);
	_txtTitle = new Text(310, 17, 5, 7);
	_txtName = new Text(160, 9, 36, 24);
	_txtTime = new Text(30, 9, 195, 24);
	_txtDate = new Text(90, 9, 225, 24);

	// Set palette
	setInterface("geoscape", true, _game->getSavedGame() ? _game->getSavedGame()->getSavedBattle() : 0);

	add(_window, "window", "saveMenus");
	add(_btnNew, "button", "saveMenus");
	add(_btnCancel, "button", "saveMenus");
	add(_txtTitle, "text", "saveMenus");
	add(_txtName, "text", "saveMenus");
	add(_txtTime, "text", "saveMenus");
	add(_txtDate, "text", "saveMenus");

	centerAllSurfaces();

	// Set up objects
	_window->setBackground(_game->getMod()->getSurface("BACK01.SCR"));

	_btnNew->setText(tr("STR_OPENXCOM"));
	_btnNew->onMouseClick((ActionHandler)&ListLoadOriginalState::btnNewClick);
	_btnNew->onKeyboardPress((ActionHandler)&ListLoadOriginalState::btnNewClick, Options::keyCancel);

	_btnCancel->setText(tr("STR_CANCEL"));
	_btnCancel->onMouseClick((ActionHandler)&ListLoadOriginalState::btnCancelClick);
	_btnCancel->onKeyboardPress((ActionHandler)&ListLoadOriginalState::btnCancelClick, Options::keyCancel);

	_txtTitle->setBig();
	_txtTitle->setAlign(ALIGN_CENTER);
	_txtTitle->setText(tr("STR_SELECT_GAME_TO_LOAD"));

	_txtName->setText(tr("STR_NAME"));

	_txtTime->setText(tr("STR_TIME"));

	_txtDate->setText(tr("STR_DATE"));

}

/**
 *
 */
ListLoadOriginalState::~ListLoadOriginalState()
{

}

/**
* Refreshes the saves list.
*/
void ListLoadOriginalState::init()
{
	State::init();

	if (_origin == OPT_BATTLESCAPE)
	{
		applyBattlescapeTheme();
	}
}

/**
 * Switches to OpenXcom saves.
 * @param action Pointer to an action.
 */
void ListLoadOriginalState::btnNewClick(Action *)
{
	_game->popState();
}

/**
 * Returns to the previous screen.
 * @param action Pointer to an action.
 */
void ListLoadOriginalState::btnCancelClick(Action *action)
{
	_game->popState();
	_game->popState();
	action->getDetails()->type = SDL_NOEVENT;
}

/**
 * Loads the specified save.
 * @param action Pointer to an action.
 */
void ListLoadOriginalState::btnSlotClick(Action *action)
{


}

}
