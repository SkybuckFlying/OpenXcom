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
#include "HealedSoldiersState.h"
#include "../Engine/Game.h"
#include "../Mod/Mod.h"
#include "../Engine/LocalizedText.h"
#include "../Engine/Options.h"
#include "../Interface/TextButton.h"
#include "../Interface/Window.h"
#include "../Interface/Text.h"
#include "../Interface/TextList.h"
#include "../Basescape/SoldierInfoState.h"
#include "../Basescape/CraftsState.h"

namespace OpenXcom
{

/**
 * Initializes all the elements in the Soldiers screen.
 * @param game Pointer to the core game.
 * @param base Pointer to the base to get info from.
 */
HealedSoldiersState::HealedSoldiersState(std::vector<SoldierAtBase> healedSoldiers) : _healedSoldiers(healedSoldiers)
{

	// Create objects
	_window = new Window(this, 320, 200, 0, 0);
	_btnOk = new TextButton(148, 16, 164, 176);

	_txtTitle = new Text(310, 17, 5, 8);
	_txtName = new Text(114, 9, 16, 32);
	_txtRank = new Text(102, 9, 130, 32);
	_txtCraft = new Text(82, 9, 222, 32);
	_lstSoldiers = new TextList(288, 128, 8, 40);

	// Set palette
	setInterface("soldierList");

	add(_window, "window", "soldierList");
	add(_btnOk, "button", "soldierList");
	add(_txtTitle, "text1", "soldierList");
	add(_txtName, "text2", "soldierList");
	add(_txtRank, "text2", "soldierList");
	add(_txtCraft, "text2", "soldierList");
	add(_lstSoldiers, "list", "soldierList");

	centerAllSurfaces();

	// Set up objects
	_window->setBackground(_game->getMod()->getSurface("BACK02.SCR"));

	_btnOk->setText(tr("STR_OK"));
	_btnOk->onMouseClick((ActionHandler)&HealedSoldiersState::btnOkClick);
	_btnOk->onKeyboardPress((ActionHandler)&HealedSoldiersState::btnOkClick, Options::keyCancel);

	_txtTitle->setBig();
	_txtTitle->setAlign(ALIGN_CENTER);
	_txtTitle->setText(tr("STR_HEALED_SOLDIERS"));

	_txtName->setText(tr("STR_NAME_UC"));

	_txtRank->setText(tr("STR_RANK"));

	_txtCraft->setText(tr("STR_BASE"));

	_lstSoldiers->setColumns(3, 114, 92, 74);
	_lstSoldiers->setSelectable(true);
	_lstSoldiers->setBackground(_window);
	_lstSoldiers->setMargin(8);
	_lstSoldiers->onMouseClick((ActionHandler)&HealedSoldiersState::lstSoldiersClick);
}

/**
 *
 */
HealedSoldiersState::~HealedSoldiersState()
{

}

/**
 * Updates the soldiers list
 * after going to other screens.
 */
void HealedSoldiersState::init()
{
	State::init();
	unsigned int row = 0;
	_lstSoldiers->clearList();

	for (std::vector<SoldierAtBase>::iterator soldierAtBase = _healedSoldiers.begin(); soldierAtBase != _healedSoldiers.end(); ++soldierAtBase)
	{
		_lstSoldiers->addRow(3, soldierAtBase->soldier->getName(true).c_str(), tr(soldierAtBase->soldier->getRankString()).c_str(), soldierAtBase->base->getName());
		row++;
	}
	if (row > 0 && _lstSoldiers->getScroll() >= row)
	{
		_lstSoldiers->scrollTo(0);
	}
}

/**
 * Returns to the previous screen.
 * @param action Pointer to an action.
 */
void HealedSoldiersState::btnOkClick(Action *)
{
	_game->popState();
}

/**
 * Opens the equip Craft state for the base of the soldier
 * @param action Pointer to an action.
 */
void HealedSoldiersState::lstSoldiersClick(Action *)
{
	_game->pushState(new CraftsState(_healedSoldiers[_lstSoldiers->getSelectedRow()].base));
}

}
