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
#include "StoresState.h"
#include <sstream>
#include <iomanip>
#include "../Engine/Game.h"
#include "../Mod/Mod.h"
#include "../Engine/LocalizedText.h"
#include "../Engine/Options.h"
#include "../Interface/TextButton.h"
#include "../Interface/Window.h"
#include "../Interface/Text.h"
#include "../Interface/TextList.h"
#include "../Savegame/Base.h"
#include "../Mod/RuleItem.h"
#include "../Savegame/ItemContainer.h"


namespace OpenXcom
{


struct compareSpace
{

	bool operator()(const StoredItem &a, const StoredItem &b) const
	{
		if (a.storageSize == b.storageSize)
		{
			return Unicode::naturalCompare(a.displayName, b.displayName);
		}
		else
		{
			return (a.storageSize > b.storageSize);
		}
	}
};


/**
 * Initializes all the elements in the Stores window.
 * @param game Pointer to the core game.
 * @param base Pointer to the base to get info from.
 */
StoresState::StoresState(Base *base) : _base(base)
{
	// Create objects
	_window = new Window(this, 320, 200, 0, 0);
	_btnOk = new TextButton(300, 16, 10, 176);
	_txtTitle = new Text(310, 17, 5, 8);
	_txtItem = new Text(162, 9, 10, 32);
	_txtQuantity = new Text(57, 9, 172, 32);
	_txtSpaceUsed = new Text(57, 9, 229, 32);
	_lstStores = new TextList(288, 128, 8, 40);

	// Set palette
	setInterface("storesInfo");

	add(_window, "window", "storesInfo");
	add(_btnOk, "button", "storesInfo");
	add(_txtTitle, "text", "storesInfo");
	add(_txtItem, "text", "storesInfo");
	add(_txtQuantity, "text", "storesInfo");
	add(_txtSpaceUsed, "text", "storesInfo");
	add(_lstStores, "list", "storesInfo");

	centerAllSurfaces();

	// Set up objects
	_window->setBackground(_game->getMod()->getSurface("BACK13.SCR"));

	_btnOk->setText(tr("STR_OK"));
	_btnOk->onMouseClick((ActionHandler)&StoresState::btnOkClick);
	_btnOk->onKeyboardPress((ActionHandler)&StoresState::btnOkClick, Options::keyOk);
	_btnOk->onKeyboardPress((ActionHandler)&StoresState::btnOkClick, Options::keyCancel);

	_txtTitle->setBig();
	_txtTitle->setAlign(ALIGN_CENTER);
	_txtTitle->setText(tr("STR_STORES"));

	_txtItem->setText(tr("STR_ITEM"));

	_txtQuantity->setAlign(ALIGN_RIGHT);
	_txtQuantity->setText(tr("STR_QUANTITY_UC"));

	_txtSpaceUsed->setAlign(ALIGN_RIGHT);
	_txtSpaceUsed->setText(tr("STR_SPACE_USED_UC"));

	_lstStores->setColumns(3, 162, 57, 57);
	_lstStores->setAlign(ALIGN_RIGHT, 1);
	_lstStores->setAlign(ALIGN_RIGHT, 2);
	_lstStores->setSelectable(true);
	_lstStores->setBackground(_window);
	_lstStores->setMargin(2);

	const std::vector<std::string> &items = _game->getMod()->getItemsList();
	std::vector<StoredItem> storedItems;
	for (std::vector<std::string>::const_iterator item = items.begin(); item != items.end(); ++item)
	{
		int qty = _base->getStorageItems()->getItem(*item);
		if (qty > 0)
		{
			RuleItem *rule = _game->getMod()->getItem(*item, true);
			storedItems.push_back(StoredItem());
			storedItems[storedItems.size() - 1].item = *item;
			storedItems[storedItems.size() - 1].displayName = tr(*item);
			storedItems[storedItems.size() - 1].qty = qty;
			storedItems[storedItems.size() - 1].storageSize = qty * rule->getSize();

		}
	}
	std::sort(storedItems.begin(), storedItems.end(), compareSpace());

	for (std::vector<StoredItem>::const_iterator storedItem = storedItems.begin(); storedItem != storedItems.end(); ++storedItem)
	{
		std::ostringstream quantity, storageSize;
		quantity << (*storedItem).qty;
		storageSize << std::fixed << std::setprecision(1) << (*storedItem).storageSize;
		_lstStores->addRow(3, (*storedItem).displayName.c_str(), quantity.str().c_str(), storageSize.str().c_str());
	}
}

/**
 *
 */
StoresState::~StoresState()
{

}

/**
 * Returns to the previous screen.
 * @param action Pointer to an action.
 */
void StoresState::btnOkClick(Action *)
{
	_game->popState();
}

}
