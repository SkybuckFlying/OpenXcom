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
#include "NewManufactureListState.h"
#include "../Interface/Window.h"
#include "../Interface/TextButton.h"
#include "../Interface/Text.h"
#include "../Interface/TextList.h"
#include "../Interface/ComboBox.h"
#include "../Engine/Game.h"
#include "../Engine/LocalizedText.h"
#include "../Engine/Options.h"
#include "../Mod/Mod.h"
#include "../Mod/RuleManufacture.h"
#include "../Savegame/SavedGame.h"
#include "../Savegame/ItemContainer.h"
#include "../Savegame/Base.h"
#include "ManufactureStartState.h"

namespace OpenXcom
{

/**
 * Initializes all the elements in the productions list screen.
 * @param game Pointer to the core game.
 * @param base Pointer to the base to get info from.
 */
NewManufactureListState::NewManufactureListState(Base *base) : _base(base)
{

	const int ITEM_WIDTH     = 160;
	const int CATEGORY_WIDTH = 76;
	const int STOCK_WIDTH = 32;

	_screen = false;

	_window = new Window(this, 320, 156, 0, 22, POPUP_BOTH);
	_btnOk = new TextButton(304, 16, 8, 154);
	_txtTitle = new Text(320, 17, 0, 30);
	_cbxCategory = new ComboBox(this, 146, 16, 166, 46);
	_txtItem = new Text(ITEM_WIDTH, 9, 10, 62);
	_txtCategory = new Text(CATEGORY_WIDTH, 9, 10 + ITEM_WIDTH, 62);
	_txtStock = new Text(STOCK_WIDTH, 9, 10 + ITEM_WIDTH + CATEGORY_WIDTH, 62);
	_lstManufacture = new TextList(280, 80, 8, 70);

	// Set palette
	setInterface("selectNewManufacture");

	add(_window, "window", "selectNewManufacture");
	add(_btnOk, "button", "selectNewManufacture");
	add(_txtTitle, "text", "selectNewManufacture");
	add(_txtItem, "text", "selectNewManufacture");
	add(_txtCategory, "text", "selectNewManufacture");
	add(_txtStock, "text", "selectNewManufacture");
	add(_lstManufacture, "list", "selectNewManufacture");
	add(_cbxCategory, "catBox", "selectNewManufacture");

	centerAllSurfaces();

	_window->setBackground(_game->getMod()->getSurface("BACK17.SCR"));

	_txtTitle->setText(tr("STR_PRODUCTION_ITEMS"));
	_txtTitle->setBig();
	_txtTitle->setAlign(ALIGN_CENTER);

	_txtItem->setText(tr("STR_ITEM"));
	_txtCategory->setText(tr("STR_CATEGORY"));
	_txtStock->setText(tr("STR_STOCK"));

	_lstManufacture->setColumns(3, ITEM_WIDTH, CATEGORY_WIDTH, STOCK_WIDTH);
	_lstManufacture->setSelectable(true);
	_lstManufacture->setBackground(_window);
	_lstManufacture->setMargin(2);
	_lstManufacture->onMouseClick((ActionHandler)&NewManufactureListState::lstProdClick);

	_btnOk->setText(tr("STR_OK"));
	_btnOk->onMouseClick((ActionHandler)&NewManufactureListState::btnOkClick);
	_btnOk->onKeyboardPress((ActionHandler)&NewManufactureListState::btnOkClick, Options::keyCancel);

	_possibleProductions.clear();
	_game->getSavedGame()->getAvailableProductions(_possibleProductions, _game->getMod(), _base);
	_catStrings.push_back("STR_ALL_ITEMS");

	for (std::vector<RuleManufacture *>::iterator it = _possibleProductions.begin(); it != _possibleProductions.end(); ++it)
	{
		bool addCategory = true;
		for (size_t x = 0; x < _catStrings.size(); ++x)
		{
			if ((*it)->getCategory() == _catStrings[x])
			{
				addCategory = false;
				break;
			}
		}
		if (addCategory)
		{
			_catStrings.push_back((*it)->getCategory());
		}
	}

	_cbxCategory->setOptions(_catStrings, true);
	_cbxCategory->onChange((ActionHandler)&NewManufactureListState::cbxCategoryChange);

}

/**
 * Initializes state (fills list of possible productions).
 */
void NewManufactureListState::init()
{
	State::init();
	fillProductionList();
}

/**
 * Returns to the previous screen.
 * @param action A pointer to an Action.
 */
void NewManufactureListState::btnOkClick(Action *)
{
	_game->popState();
}

/**
 * Opens the Production settings screen.
 * @param action A pointer to an Action.
 */
void NewManufactureListState::lstProdClick(Action *)
{
	RuleManufacture *rule = 0;
	for (std::vector<RuleManufacture *>::iterator it = _possibleProductions.begin(); it != _possibleProductions.end(); ++it)
	{
		if ((*it)->getName() == _displayedStrings[_lstManufacture->getSelectedRow()])
		{
			rule = (*it);
			break;
		}
	}
	_game->pushState(new ManufactureStartState(_base, rule));
}

/**
 * Updates the production list to match the category filter
 */

void NewManufactureListState::cbxCategoryChange(Action *)
{
	fillProductionList();
}


bool NewManufactureListState::productionPossible(RuleManufacture * item)
{
	const std::map<std::string, int> &requiredItems(item->getRequiredItems());
	int availableWorkSpace = _base->getFreeWorkshops();
	bool productionPossible = item->haveEnoughMoneyForOneMoreUnit(_game->getSavedGame()->getFunds());
	productionPossible &= (availableWorkSpace > 0);
	for (std::map<std::string, int>::const_iterator iter = requiredItems.begin();
		 iter != requiredItems.end();
		 ++iter)
	{
		std::ostringstream s1, s2;
		s1 << iter->second;
		if (_game->getMod()->getItem(iter->first) != 0)
		{
			s2 << _base->getStorageItems()->getItem(iter->first);
			productionPossible &= (_base->getStorageItems()->getItem(iter->first) >= iter->second);
		}
		else if (_game->getMod()->getCraft(iter->first) != 0)
		{
			s2 << _base->getCraftCount(iter->first);
			productionPossible &= (_base->getCraftCount(iter->first) >= iter->second);
		}
	}

	return productionPossible;
};

/**
 * Fills the list of possible productions.
 */
void NewManufactureListState::fillProductionList()
{
	_lstManufacture->clearList();
	_possibleProductions.clear();
	_game->getSavedGame()->getAvailableProductions(_possibleProductions, _game->getMod(), _base);
	_displayedStrings.clear();

	for (std::vector<RuleManufacture *>::iterator it = _possibleProductions.begin(); it != _possibleProductions.end(); ++it)
	{
		if (((*it)->getCategory() == _catStrings[_cbxCategory->getSelected()]) || (_catStrings[_cbxCategory->getSelected()] == "STR_ALL_ITEMS"))
		{
			_lstManufacture->addRow(3,
									tr((*it)->getName()).c_str(),
									tr((*it)->getCategory()).c_str(),
									std::to_string(_base->getStorageItems()->getItem((*it)->getName())));
			if (!productionPossible(*it))
			{
				_lstManufacture->setRowColor(_lstManufacture->getRows() - 1, _lstManufacture->getSecondaryColor());
			}

			_displayedStrings.push_back((*it)->getName());
		}
	}
}

}
