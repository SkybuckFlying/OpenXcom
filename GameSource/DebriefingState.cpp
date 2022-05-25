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
#include "DebriefingState.h"
#include <algorithm>
#include "CannotReequipState.h"
#include "Action.h"
#include "Game.h"
#include "LocalizedText.h"
#include "TextButton.h"
#include "Text.h"
#include "TextList.h"
#include "Window.h"

#include "CommendationState.h"
#include "CommendationLateState.h"
#include "Mod.h"

#include "RuleCraft.h"
#include "RuleItem.h"

#include "RuleUfo.h"
#include "Armor.h"


#include "BattleItem.h"

#include "Craft.h"
#include "ItemContainer.h"
#include "Region.h"
#include "SavedBattleGame.h"
#include "Soldier.h"
#include "SoldierDiary.h"
#include "MissionSite.h"
#include "Tile.h"
#include "Ufo.h"
#include "Vehicle.h"

#include <sstream>
#include "ErrorMessageState.h"
#include "MainMenuState.h"
#include "Cursor.h"
#include "Options.h"
#include "Screen.h"
#include "SaveGameState.h"
#include "AlienDeployment.h"
#include "RuleInterface.h"
#include "MissionStatistics.h"
#include "BattleUnitStatistics.h"

namespace OpenXcom
{

/**
 * Initializes all the elements in the Debriefing screen.
 * @param game Pointer to the core game.
 */
DebriefingState::DebriefingState() : _region(0), _country(0), _positiveScore(true), _noContainment(false), _manageContainment(false), _destroyBase(false), _showSoldierStats(false), _initDone(false)
{
	_missionStatistics = new MissionStatistics();

	Options::baseXResolution = Options::baseXGeoscape;
	Options::baseYResolution = Options::baseYGeoscape;
	_game->getScreen()->resetDisplay(false);

	// Restore the cursor in case something weird happened
	_game->getCursor()->setVisible(true);
	_limitsEnforced = Options::storageLimitsEnforced ? 1 : 0;

	// Create objects
	_window = new Window(this, 320, 200, 0, 0);
	_btnOk = new TextButton(40, 12, 16, 180);
	_btnStats = new TextButton(40, 12, 264, 180);
	_txtTitle = new Text(300, 17, 16, 8);
	_txtItem = new Text(180, 9, 16, 24);
	_txtQuantity = new Text(60, 9, 200, 24);
	_txtScore = new Text(55, 9, 270, 24);
	_txtRecovery = new Text(180, 9, 16, 60);
	_txtRating = new Text(200, 9, 64, 180);
	_lstStats = new TextList(290, 80, 16, 32);
	_lstRecovery = new TextList(290, 80, 16, 32);
	_lstTotal = new TextList(290, 9, 16, 12);

	// Second page (soldier stats)
	_txtSoldier     = new Text(90, 9,  16, 24); //16..106 = 90
	_txtTU          = new Text(18, 9, 106, 24); //106
	_txtStamina     = new Text(18, 9, 124, 24); //124
	_txtHealth      = new Text(18, 9, 142, 24); //142
	_txtBravery     = new Text(18, 9, 160, 24); //160
	_txtReactions   = new Text(18, 9, 178, 24); //178
	_txtFiring      = new Text(18, 9, 196, 24); //196
	_txtThrowing    = new Text(18, 9, 214, 24); //214
	_txtMelee       = new Text(18, 9, 232, 24); //232
	_txtStrength    = new Text(18, 9, 250, 24); //250
	_txtPsiStrength = new Text(18, 9, 268, 24); //268
	_txtPsiSkill    = new Text(18, 9, 286, 24); //286..304 = 18

	_lstSoldierStats = new TextList(288, 128, 16, 32);

	_txtTooltip = new Text(200, 9, 64, 180);

	applyVisibility();

	// Set palette
	setInterface("debriefing");

	add(_window, "window", "debriefing");
	add(_btnOk, "button", "debriefing");
	add(_btnStats, "button", "debriefing");
	add(_txtTitle, "heading", "debriefing");
	add(_txtItem, "text", "debriefing");
	add(_txtQuantity, "text", "debriefing");
	add(_txtScore, "text", "debriefing");
	add(_txtRecovery, "text", "debriefing");
	add(_txtRating, "text", "debriefing");
	add(_lstStats, "list", "debriefing");
	add(_lstRecovery, "list", "debriefing");
	add(_lstTotal, "totals", "debriefing");

	add(_txtSoldier, "text", "debriefing");
	add(_txtTU, "text", "debriefing");
	add(_txtStamina, "text", "debriefing");
	add(_txtHealth, "text", "debriefing");
	add(_txtBravery, "text", "debriefing");
	add(_txtReactions, "text", "debriefing");
	add(_txtFiring, "text", "debriefing");
	add(_txtThrowing, "text", "debriefing");
	add(_txtMelee, "text", "debriefing");
	add(_txtStrength, "text", "debriefing");
	add(_txtPsiStrength, "text", "debriefing");
	add(_txtPsiSkill, "text", "debriefing");
	add(_lstSoldierStats, "list", "debriefing");
	add(_txtTooltip, "text", "debriefing");

	centerAllSurfaces();

	// Set up objects
	_window->setBackground(_game->getMod()->getSurface("BACK01.SCR"));

	_btnOk->setText(tr("STR_OK"));
	_btnOk->onMouseClick((ActionHandler)&DebriefingState::btnOkClick);
	_btnOk->onKeyboardPress((ActionHandler)&DebriefingState::btnOkClick, Options::keyOk);
	_btnOk->onKeyboardPress((ActionHandler)&DebriefingState::btnOkClick, Options::keyCancel);

	_btnStats->onMouseClick((ActionHandler)&DebriefingState::btnStatsClick);

	_txtTitle->setBig();

	_txtItem->setText(tr("STR_LIST_ITEM"));

	_txtQuantity->setText(tr("STR_QUANTITY_UC"));
	_txtQuantity->setAlign(ALIGN_RIGHT);

	_txtScore->setText(tr("STR_SCORE"));

	_lstStats->setColumns(3, 224, 30, 64);
	_lstStats->setDot(true);

	_lstRecovery->setColumns(3, 224, 30, 64);
	_lstRecovery->setDot(true);

	_lstTotal->setColumns(2, 254, 64);
	_lstTotal->setDot(true);

	// Second page
	_txtSoldier->setText(tr("STR_NAME_UC"));

	_txtTU->setAlign(ALIGN_CENTER);
	_txtTU->setText(tr("STR_TIME_UNITS_ABBREVIATION"));
	_txtTU->setTooltip("STR_TIME_UNITS");
	_txtTU->onMouseIn((ActionHandler)&DebriefingState::txtTooltipIn);
	_txtTU->onMouseOut((ActionHandler)&DebriefingState::txtTooltipOut);

	_txtStamina->setAlign(ALIGN_CENTER);
	_txtStamina->setText(tr("STR_STAMINA_ABBREVIATION"));
	_txtStamina->setTooltip("STR_STAMINA");
	_txtStamina->onMouseIn((ActionHandler)&DebriefingState::txtTooltipIn);
	_txtStamina->onMouseOut((ActionHandler)&DebriefingState::txtTooltipOut);

	_txtHealth->setAlign(ALIGN_CENTER);
	_txtHealth->setText(tr("STR_HEALTH_ABBREVIATION"));
	_txtHealth->setTooltip("STR_HEALTH");
	_txtHealth->onMouseIn((ActionHandler)&DebriefingState::txtTooltipIn);
	_txtHealth->onMouseOut((ActionHandler)&DebriefingState::txtTooltipOut);

	_txtBravery->setAlign(ALIGN_CENTER);
	_txtBravery->setText(tr("STR_BRAVERY_ABBREVIATION"));
	_txtBravery->setTooltip("STR_BRAVERY");
	_txtBravery->onMouseIn((ActionHandler)&DebriefingState::txtTooltipIn);
	_txtBravery->onMouseOut((ActionHandler)&DebriefingState::txtTooltipOut);

	_txtReactions->setAlign(ALIGN_CENTER);
	_txtReactions->setText(tr("STR_REACTIONS_ABBREVIATION"));
	_txtReactions->setTooltip("STR_REACTIONS");
	_txtReactions->onMouseIn((ActionHandler)&DebriefingState::txtTooltipIn);
	_txtReactions->onMouseOut((ActionHandler)&DebriefingState::txtTooltipOut);

	_txtFiring->setAlign(ALIGN_CENTER);
	_txtFiring->setText(tr("STR_FIRING_ACCURACY_ABBREVIATION"));
	_txtFiring->setTooltip("STR_FIRING_ACCURACY");
	_txtFiring->onMouseIn((ActionHandler)&DebriefingState::txtTooltipIn);
	_txtFiring->onMouseOut((ActionHandler)&DebriefingState::txtTooltipOut);

	_txtThrowing->setAlign(ALIGN_CENTER);
	_txtThrowing->setText(tr("STR_THROWING_ACCURACY_ABBREVIATION"));
	_txtThrowing->setTooltip("STR_THROWING_ACCURACY");
	_txtThrowing->onMouseIn((ActionHandler)&DebriefingState::txtTooltipIn);
	_txtThrowing->onMouseOut((ActionHandler)&DebriefingState::txtTooltipOut);

	_txtMelee->setAlign(ALIGN_CENTER);
	_txtMelee->setText(tr("STR_MELEE_ACCURACY_ABBREVIATION"));
	_txtMelee->setTooltip("STR_MELEE_ACCURACY");
	_txtMelee->onMouseIn((ActionHandler)&DebriefingState::txtTooltipIn);
	_txtMelee->onMouseOut((ActionHandler)&DebriefingState::txtTooltipOut);

	_txtStrength->setAlign(ALIGN_CENTER);
	_txtStrength->setText(tr("STR_STRENGTH_ABBREVIATION"));
	_txtStrength->setTooltip("STR_STRENGTH");
	_txtStrength->onMouseIn((ActionHandler)&DebriefingState::txtTooltipIn);
	_txtStrength->onMouseOut((ActionHandler)&DebriefingState::txtTooltipOut);

	_txtPsiStrength->setAlign(ALIGN_CENTER);
	_txtPsiStrength->setText(tr("STR_PSIONIC_STRENGTH_ABBREVIATION"));
	_txtPsiStrength->setTooltip("STR_PSIONIC_STRENGTH");
	_txtPsiStrength->onMouseIn((ActionHandler)&DebriefingState::txtTooltipIn);
	_txtPsiStrength->onMouseOut((ActionHandler)&DebriefingState::txtTooltipOut);

	_txtPsiSkill->setAlign(ALIGN_CENTER);
	_txtPsiSkill->setText(tr("STR_PSIONIC_SKILL_ABBREVIATION"));
	_txtPsiSkill->setTooltip("STR_PSIONIC_SKILL");
	_txtPsiSkill->onMouseIn((ActionHandler)&DebriefingState::txtTooltipIn);
	_txtPsiSkill->onMouseOut((ActionHandler)&DebriefingState::txtTooltipOut);

	_lstSoldierStats->setColumns(13, 90, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 0);
	_lstSoldierStats->setAlign(ALIGN_CENTER);
	_lstSoldierStats->setAlign(ALIGN_LEFT, 0);
	_lstSoldierStats->setDot(true);
}

/**
 *
 */
DebriefingState::~DebriefingState()
{
	for (std::vector<DebriefingStat*>::iterator i = _stats.begin(); i != _stats.end(); ++i)
	{
		delete *i;
	}
	for (std::map<int, RecoveryItem*>::iterator i = _recoveryStats.begin(); i != _recoveryStats.end(); ++i)
	{
		delete i->second;
	}
	_recoveryStats.clear();
	_rounds.clear();
}

std::string DebriefingState::makeSoldierString(int stat)
{
	if (stat == 0) return "";

	std::ostringstream ss;
	ss << Unicode::TOK_COLOR_FLIP << '+' << stat << Unicode::TOK_COLOR_FLIP;
	return ss.str();
}

void DebriefingState::applyVisibility()
{
	// First page (scores)
	_txtItem->setVisible(!_showSoldierStats);
	_txtQuantity->setVisible(!_showSoldierStats);
	_txtScore->setVisible(!_showSoldierStats);
	_txtRecovery->setVisible(!_showSoldierStats);
	_txtRating->setVisible(!_showSoldierStats);
	_lstStats->setVisible(!_showSoldierStats);
	_lstRecovery->setVisible(!_showSoldierStats);
	_lstTotal->setVisible(!_showSoldierStats);

	// Second page (soldier stats)
	_txtSoldier->setVisible(_showSoldierStats);
	_txtTU->setVisible(_showSoldierStats);
	_txtStamina->setVisible(_showSoldierStats);
	_txtHealth->setVisible(_showSoldierStats);
	_txtBravery->setVisible(_showSoldierStats);
	_txtReactions->setVisible(_showSoldierStats);
	_txtFiring->setVisible(_showSoldierStats);
	_txtThrowing->setVisible(_showSoldierStats);
	_txtMelee->setVisible(_showSoldierStats);
	_txtStrength->setVisible(_showSoldierStats);
	_txtPsiStrength->setVisible(_showSoldierStats);
	_txtPsiSkill->setVisible(_showSoldierStats);
	_lstSoldierStats->setVisible(_showSoldierStats);
	_txtTooltip->setVisible(_showSoldierStats);

	// Set text on toggle button accordingly
	_btnStats->setText(_showSoldierStats ? tr("STR_SCORE") : tr("STR_STATS"));

}

void DebriefingState::init()
{
	State::init();	

	if (_initDone)
	{
		return;
	}
	_initDone = true;

	prepareDebriefing();

	for (std::vector<SoldierStatsEntry>::iterator i = _soldierStats.begin(); i != _soldierStats.end(); ++i)
	{
		_lstSoldierStats->addRow(13, (*i).first.c_str(),
				makeSoldierString((*i).second.tu).c_str(),
				makeSoldierString((*i).second.stamina).c_str(),
				makeSoldierString((*i).second.health).c_str(),
				makeSoldierString((*i).second.bravery).c_str(),
				makeSoldierString((*i).second.reactions).c_str(),
				makeSoldierString((*i).second.firing).c_str(),
				makeSoldierString((*i).second.throwing).c_str(),
				makeSoldierString((*i).second.melee).c_str(),
				makeSoldierString((*i).second.strength).c_str(),
				makeSoldierString((*i).second.psiStrength).c_str(),
				makeSoldierString((*i).second.psiSkill).c_str(),
				L"");
		// note: final dummy element to cause dot filling until the end of the line
	}

	int total = 0, statsY = 0, recoveryY = 0;
	int civiliansSaved = 0, civiliansDead = 0;
	int aliensKilled = 0, aliensStunned = 0;
	for (std::vector<DebriefingStat*>::iterator i = _stats.begin(); i != _stats.end(); ++i)
	{
		if ((*i)->qty == 0)
			continue;

		std::ostringstream ss, ss2;
		ss << Unicode::TOK_COLOR_FLIP << (*i)->qty << Unicode::TOK_COLOR_FLIP;
		ss2 << Unicode::TOK_COLOR_FLIP << (*i)->score;
		total += (*i)->score;
		if ((*i)->recovery)
		{
			_lstRecovery->addRow(3, tr((*i)->item).c_str(), ss.str().c_str(), ss2.str().c_str());
			recoveryY += 8;
		}
		else
		{
			_lstStats->addRow(3, tr((*i)->item).c_str(), ss.str().c_str(), ss2.str().c_str());
			statsY += 8;
		}
		if ((*i)->item == "STR_CIVILIANS_SAVED")
		{
			civiliansSaved = (*i)->qty;
		}
		if ((*i)->item == "STR_CIVILIANS_KILLED_BY_XCOM_OPERATIVES" || (*i)->item == "STR_CIVILIANS_KILLED_BY_ALIENS")
		{
			civiliansDead += (*i)->qty;
		}
		if ((*i)->item == "STR_ALIENS_KILLED")
		{
			aliensKilled += (*i)->qty;
		}
		if ((*i)->item == "STR_LIVE_ALIENS_RECOVERED")
		{
			aliensStunned += (*i)->qty;
		}
	}
	if (civiliansSaved && !civiliansDead && _missionStatistics->success == true)
	{
		_missionStatistics->valiantCrux = true;
	}

	std::ostringstream ss3;
	ss3 << total;
	_lstTotal->addRow(2, tr("STR_TOTAL_UC").c_str(), ss3.str().c_str());

	// add the points to our activity score
	if (_region)
	{
		_region->addActivityXcom(total);
	}

	if (recoveryY > 0)
	{
		_txtRecovery->setY(_lstStats->getY() + statsY + 5);
		_lstRecovery->setY(_txtRecovery->getY() + 8);
		_lstTotal->setY(_lstRecovery->getY() + recoveryY + 5);
	}
	else
	{
		_txtRecovery->setText("");
		_lstTotal->setY(_lstStats->getY() + statsY + 5);
	}

	// Calculate rating
	std::string rating;
	if (total <= -200)
	{
		rating = "STR_RATING_TERRIBLE";
	}
	else if (total <= 0)
	{
		rating = "STR_RATING_POOR";
	}
	else if (total <= 200)
	{
		rating = "STR_RATING_OK";
	}
	else if (total <= 500)
	{
		rating = "STR_RATING_GOOD";
	}
	else
	{
		rating = "STR_RATING_EXCELLENT";
	}
	_missionStatistics->rating = rating;
	_missionStatistics->score = total;
	_txtRating->setText(tr("STR_RATING").arg(tr(rating)));

	SavedGame *save = _game->getSavedGame();
	SavedBattleGame *battle = save->getSavedBattle();

	_missionStatistics->daylight = save->getSavedBattle()->getGlobalShade();

	// Award Best-of commendations.
	int bestScoreID[7] = {0, 0, 0, 0, 0, 0, 0};
	int bestScore[7] = {0, 0, 0, 0, 0, 0, 0};
	int bestOverallScorersID = 0;
	int bestOverallScore = 0;

	// Check to see if any of the dead soldiers were exceptional.
	for (std::vector<BattleUnit*>::iterator deadUnit = battle->getUnits()->begin(); deadUnit != battle->getUnits()->end(); ++deadUnit)
	{
		if (!(*deadUnit)->getGeoscapeSoldier() || (*deadUnit)->getStatus() != STATUS_DEAD)
		{
			continue;
		}

		/// Post-mortem kill award
		int killTurn = -1;
		for (std::vector<BattleUnit*>::iterator killerUnit = battle->getUnits()->begin(); killerUnit != battle->getUnits()->end(); ++killerUnit)
		{
			for(std::vector<BattleUnitKills*>::iterator kill = (*killerUnit)->getStatistics()->kills.begin(); kill != (*killerUnit)->getStatistics()->kills.end(); ++kill)
			{
				if ((*kill)->id == (*deadUnit)->getId())
				{
					killTurn = (*kill)->turn;
					break;
				}
			}
			if (killTurn != -1)
			{
				break;
			}
		}
		int postMortemKills = 0;
		if (killTurn != -1)
		{
			for(std::vector<BattleUnitKills*>::iterator deadUnitKill = (*deadUnit)->getStatistics()->kills.begin(); deadUnitKill != (*deadUnit)->getStatistics()->kills.end(); ++deadUnitKill)
			{
				if ((*deadUnitKill)->turn > killTurn && (*deadUnitKill)->faction == FACTION_HOSTILE)
				{
					postMortemKills++;
				}
			}
		}
		(*deadUnit)->getGeoscapeSoldier()->getDiary()->awardPostMortemKill(postMortemKills);

		SoldierRank rank = (*deadUnit)->getGeoscapeSoldier()->getRank();
		// Rookies don't get this next award. No one likes them.
		if (rank == RANK_ROOKIE)
		{
			continue;
		}

	}
	// Now award those soldiers commendations!
	for (std::vector<BattleUnit*>::iterator deadUnit = battle->getUnits()->begin(); deadUnit != battle->getUnits()->end(); ++deadUnit)
	{
		if (!(*deadUnit)->getGeoscapeSoldier() || (*deadUnit)->getStatus() != STATUS_DEAD)
		{
			continue;
		}
		if ((*deadUnit)->getId() == bestScoreID[(*deadUnit)->getGeoscapeSoldier()->getRank()])
		{
			(*deadUnit)->getGeoscapeSoldier()->getDiary()->awardBestOfRank(bestScore[(*deadUnit)->getGeoscapeSoldier()->getRank()]);
		}
		if ((*deadUnit)->getId() == bestOverallScorersID)
		{
			(*deadUnit)->getGeoscapeSoldier()->getDiary()->awardBestOverall(bestOverallScore);
		}
	}

	for (std::vector<BattleUnit*>::iterator j = battle->getUnits()->begin(); j != battle->getUnits()->end(); ++j)
	{
		if ((*j)->getGeoscapeSoldier())
		{
			int soldierAlienKills = 0;
			int soldierAlienStuns = 0;
			for (std::vector<BattleUnitKills*>::const_iterator k = (*j)->getStatistics()->kills.begin(); k != (*j)->getStatistics()->kills.end(); ++k)
			{
				if ((*k)->faction == FACTION_HOSTILE && (*k)->status == STATUS_DEAD)
				{
					soldierAlienKills++;
				}
				if ((*k)->faction == FACTION_HOSTILE && (*k)->status == STATUS_UNCONSCIOUS)
				{
					soldierAlienStuns++;
				}
			}

			if (aliensKilled != 0 && aliensKilled == soldierAlienKills && _missionStatistics->success == true && aliensStunned == soldierAlienStuns)
			{
				(*j)->getStatistics()->nikeCross = true;
			}
			if (aliensStunned != 0 && aliensStunned == soldierAlienStuns && _missionStatistics->success == true && aliensKilled == 0)
			{
				(*j)->getStatistics()->mercyCross = true;
			}
			(*j)->getStatistics()->daysWounded = (*j)->getGeoscapeSoldier()->getWoundRecovery();
			_missionStatistics->injuryList[(*j)->getGeoscapeSoldier()->getId()] = (*j)->getGeoscapeSoldier()->getWoundRecovery();

			// Award Martyr Medal
			if ((*j)->getMurdererId() == (*j)->getId() && (*j)->getStatistics()->kills.size() != 0)
			{
				int martyrKills = 0; // How many aliens were killed on the same turn?
				int martyrTurn = -1;
				for (std::vector<BattleUnitKills*>::iterator unitKill = (*j)->getStatistics()->kills.begin(); unitKill != (*j)->getStatistics()->kills.end(); ++unitKill)
				{
					if ( (*unitKill)->id == (*j)->getId() )
					{
						martyrTurn = (*unitKill)->turn;
						break;
					}
				}
				for (std::vector<BattleUnitKills*>::iterator unitKill = (*j)->getStatistics()->kills.begin(); unitKill != (*j)->getStatistics()->kills.end(); ++unitKill)
				{
					if ((*unitKill)->turn == martyrTurn && (*unitKill)->faction == FACTION_HOSTILE)
					{
						martyrKills++;
					}
				}
				if (martyrKills > 0)
				{
					if (martyrKills > 10)
					{
						martyrKills = 10;
					}
					(*j)->getStatistics()->martyr = martyrKills;
				}
			}

		}
	}

	_positiveScore = (total > 0);

	std::vector<Soldier*> participants;
	for (std::vector<BattleUnit*>::const_iterator i = _game->getSavedGame()->getSavedBattle()->getUnits()->begin();
		i != _game->getSavedGame()->getSavedBattle()->getUnits()->end(); ++i)
	{
		if ((*i)->getGeoscapeSoldier())
		{
			participants.push_back((*i)->getGeoscapeSoldier());
		}
	}

	_game->getSavedGame()->setBattleGame(0);

	if (_positiveScore)
	{
		_game->getMod()->playMusic(Mod::DEBRIEF_MUSIC_GOOD);
	}
	else
	{
		_game->getMod()->playMusic(Mod::DEBRIEF_MUSIC_BAD);
	}
	if (_noContainment)
	{
		_game->pushState(new ErrorMessageState(tr("STR_ALIEN_DIES_NO_ALIEN_CONTAINMENT_FACILITY"), _palette, _game->getMod()->getInterface("debriefing")->getElement("errorMessage")->color, "BACK01.SCR", _game->getMod()->getInterface("debriefing")->getElement("errorPalette")->color));
		_noContainment = false;
	}
}

/**
* Shows a tooltip for the appropriate text.
* @param action Pointer to an action.
*/
void DebriefingState::txtTooltipIn(Action *action)
{
	_currentTooltip = action->getSender()->getTooltip();
	_txtTooltip->setText(tr(_currentTooltip));}

/**
* Clears the tooltip text.
* @param action Pointer to an action.
*/
void DebriefingState::txtTooltipOut(Action *action)
{
	if (_currentTooltip == action->getSender()->getTooltip())
	{
		_txtTooltip->setText("");
	}
}

/**
 * Displays soldiers' stat increases.
 * @param action Pointer to an action.
 */
void DebriefingState::btnStatsClick(Action *)
{
	_showSoldierStats = !_showSoldierStats;
	applyVisibility();
}

/**
 * Returns to the previous screen.
 * @param action Pointer to an action.
 */
void DebriefingState::btnOkClick(Action *)
{
	_game->popState();
	_game->setState(new MainMenuState);
}

/**
 * Adds to the debriefing stats.
 * @param name The untranslated name of the stat.
 * @param quantity The quantity to add.
 * @param score The score to add.
 */
void DebriefingState::addStat(const std::string &name, int quantity, int score)
{
	for (std::vector<DebriefingStat*>::iterator i = _stats.begin(); i != _stats.end(); ++i)
	{
		if ((*i)->item == name)
		{
			(*i)->qty = (*i)->qty + quantity;
			(*i)->score = (*i)->score + score;
			break;
		}
	}
}

/**
 * Clears the alien base from supply missions that use it.
 */
class ClearAlienBase: public std::unary_function<AlienMission *, void>
{
public:
	/// Remembers the base.
	ClearAlienBase(const AlienBase *base) : _base(base) { /* Empty by design. */ }
	/// Clears the base if required.
	void operator()(AlienMission *am) const;
private:
	const AlienBase *_base;
};

/**
 * Removes the association between the alien mission and the alien base,
 * if one existed.
 * @param am Pointer to the alien mission.
 */
void ClearAlienBase::operator()(AlienMission *am) const
{

}

/**
 * Prepares debriefing: gathers Aliens, Corpses, Artefacts, UFO Components.
 * Adds the items to the craft.
 * Also calculates the soldiers experience, and possible promotions.
 * If aborted, only the things on the exit area are recovered.
 */
void DebriefingState::prepareDebriefing()
{

}

/**
 * Reequips a craft after a mission.
 * @param base Base to reequip from.
 * @param craft Craft to reequip.
 * @param vehicleItemsCanBeDestroyed Whether we can destroy the vehicles on the craft.
 */
void DebriefingState::reequipCraft(Base *base, Craft *craft, bool vehicleItemsCanBeDestroyed)
{

}

/**
 * Recovers items from the battlescape.
 *
 * Converts the battlescape inventory into a geoscape itemcontainer.
 * @param from Items recovered from the battlescape.
 * @param base Base to add items to.
 */
void DebriefingState::recoverItems(std::vector<BattleItem*> *from, Base *base)
{

}

/**
 * Recovers a live alien from the battlescape.
 * @param from Battle unit to recover.
 * @param base Base to add items to.
 */
void DebriefingState::recoverAlien(BattleUnit *from, Base *base)
{

}

}
