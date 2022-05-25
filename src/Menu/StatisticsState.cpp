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
#include "StatisticsState.h"
#include <algorithm>
#include <string>
#include <sstream>
#include <vector>
#include <map>
#include "../Engine/Game.h"
#include "../Mod/Mod.h"
#include "../Engine/LocalizedText.h"
#include "../Interface/TextButton.h"
#include "../Interface/Window.h"
#include "../Interface/Text.h"
#include "../Interface/TextList.h"
#include "../Engine/Options.h"
#include "../Engine/Unicode.h"
#include "../Savegame/SavedGame.h"
#include "MainMenuState.h"
#include "../Savegame/MissionStatistics.h"

#include "../Savegame/SoldierDiary.h"
#include "../Savegame/SoldierDeath.h"
#include "../Savegame/BattleUnitStatistics.h"

#include "../Savegame/Region.h"


namespace OpenXcom
{

/**
 * Initializes all the elements in the Statistics window.
 * @param game Pointer to the core game.
 */
StatisticsState::StatisticsState()
{
	// Create objects
	_window = new Window(this, 320, 200, 0, 0, POPUP_BOTH);
	_btnOk = new TextButton(50, 12, 135, 180);
	_txtTitle = new Text(310, 25, 5, 8);
	_lstStats = new TextList(280, 136, 12, 36);

	// Set palette
	setInterface("endGameStatistics");

	add(_window, "window", "endGameStatistics");
	add(_btnOk, "button", "endGameStatistics");
	add(_txtTitle, "text", "endGameStatistics");
	add(_lstStats, "list", "endGameStatistics");

	centerAllSurfaces();

	// Set up objects
	_window->setBackground(_game->getMod()->getSurface("BACK01.SCR"));

	_btnOk->setText(tr("STR_OK"));
	_btnOk->onMouseClick((ActionHandler)&StatisticsState::btnOkClick);
	_btnOk->onKeyboardPress((ActionHandler)&StatisticsState::btnOkClick, Options::keyOk);

	_txtTitle->setBig();
	_txtTitle->setAlign(ALIGN_CENTER);

	_lstStats->setColumns(2, 200, 80);
	_lstStats->setDot(true);

	listStats();
}

/**
 *
 */
StatisticsState::~StatisticsState()
{

}

template <typename T>
T StatisticsState::sumVector(const std::vector<T> &vec) const
{
	T total = 0;
	for (typename std::vector<T>::const_iterator i = vec.begin(); i != vec.end(); ++i)
	{
		total += *i;
	}
	return total;
}

void StatisticsState::listStats()
{

}

/**
 * Returns to the previous screen.
 * @param action Pointer to an action.
 */
void StatisticsState::btnOkClick(Action *)
{
	_game->popState();
}

}
