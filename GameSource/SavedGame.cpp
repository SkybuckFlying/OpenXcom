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
#include "SavedGame.h"
#include <fstream>
#include <sstream>
#include <iomanip>
#include <algorithm>
#include <yaml-cpp/yaml.h>
#include "version.h"
#include "Logger.h"
#include "Mod.h"
#include "RNG.h"
#include "Unicode.h"
#include "Exception.h"
#include "Options.h"
#include "CrossPlatform.h"
#include "SavedBattleGame.h"
#include "SerializationHelper.h"
#include "GameTime.h"

#include "Craft.h"
#include "Region.h"
#include "Ufo.h"
#include "Waypoint.h"

#include "ItemContainer.h"
#include "Soldier.h"

#include "MissionSite.h"

#include "AlienStrategy.h"

#include "MissionStatistics.h"
#include "SoldierDeath.h"

namespace OpenXcom
{

const std::string SavedGame::AUTOSAVE_GEOSCAPE = "_autogeo_.asav",
				  SavedGame::AUTOSAVE_BATTLESCAPE = "_autobattle_.asav",
				  SavedGame::QUICKSAVE = "_quick_.asav";


/**
 * Initializes a brand new saved game according to the specified difficulty.
 */
SavedGame::SavedGame() : _difficulty(DIFF_BEGINNER), _battleGame(0), _debug(false)
{
	_time = new GameTime(6, 1, 1, 1999, 12, 0, 0);
	_alienStrategy = new AlienStrategy();
	_lastselectedArmor="STR_NONE_UC";
}

/**
 * Deletes the game content from memory.
 */
SavedGame::~SavedGame()
{
	delete _time;


	for (std::vector<Ufo*>::iterator i = _ufos.begin(); i != _ufos.end(); ++i)
	{
		delete *i;
	}

	delete _alienStrategy;

	for (std::vector<Soldier*>::iterator i = _deadSoldiers.begin(); i != _deadSoldiers.end(); ++i)
	{
		delete *i;
	}

	delete _battleGame;
}

/**
 * Removes version number from a mod name, if any.
 * @param name Mod id from a savegame.
 * @return Sanitized mod name.
 */
std::string SavedGame::sanitizeModName(const std::string &name)
{
	size_t versionInfoBreakPoint = name.find(" ver: ");
	if (versionInfoBreakPoint == std::string::npos)
	{
		return name;
	}
	else
	{
		return name.substr(0, versionInfoBreakPoint);
	}
}

static bool _isCurrentGameType(const SaveInfo &saveInfo, const std::string &curMaster)
{
	bool matchMasterMod = false;
	if (saveInfo.mods.empty())
	{
		// if no mods listed in the savegame, this is an old-style
		// savegame.  assume "xcom1" as the game type.
		matchMasterMod = (curMaster == "xcom1");
	}
	else
	{
		for (std::vector<std::string>::const_iterator i = saveInfo.mods.begin(); i != saveInfo.mods.end(); ++i)
		{
			std::string name = SavedGame::sanitizeModName(*i);
			if (name == curMaster)
			{
				matchMasterMod = true;
				break;
			}
		}
	}

	if (!matchMasterMod)
	{
		Log(LOG_DEBUG) << "skipping save from inactive master: " << saveInfo.fileName;
	}

	return matchMasterMod;
}

/**
 * Gets all the info of the saves found in the user folder.
 * @param lang Loaded language.
 * @param autoquick Include autosaves and quicksaves.
 * @return List of saves info.
 */
std::vector<SaveInfo> SavedGame::getList(Language *lang, bool autoquick)
{
	std::vector<SaveInfo> info;
	std::string curMaster = Options::getActiveMaster();
	std::vector<std::string> saves = CrossPlatform::getFolderContents(Options::getMasterUserFolder(), "sav");

	if (autoquick)
	{
		std::vector<std::string> asaves = CrossPlatform::getFolderContents(Options::getMasterUserFolder(), "asav");
		saves.insert(saves.begin(), asaves.begin(), asaves.end());
	}
	for (std::vector<std::string>::iterator i = saves.begin(); i != saves.end(); ++i)
	{
		try
		{
			SaveInfo saveInfo = getSaveInfo(*i, lang);
			if (!_isCurrentGameType(saveInfo, curMaster))
			{
				continue;
			}
			info.push_back(saveInfo);
		}
		catch (Exception &e)
		{
			Log(LOG_ERROR) << (*i) << ": " << e.what();
			continue;
		}
		catch (YAML::Exception &e)
		{
			Log(LOG_ERROR) << (*i) << ": " << e.what();
			continue;
		}
	}

	return info;
}

/**
 * Gets the info of a specific save file.
 * @param file Save filename.
 * @param lang Loaded language.
 */
SaveInfo SavedGame::getSaveInfo(const std::string &file, Language *lang)
{
	std::string fullname = Options::getMasterUserFolder() + file;
	YAML::Node doc = YAML::LoadFile(fullname);
	SaveInfo save;

	save.fileName = file;

	if (save.fileName == QUICKSAVE)
	{
		save.displayName = lang->getString("STR_QUICK_SAVE_SLOT");
		save.reserved = true;
	}
	else if (save.fileName == AUTOSAVE_GEOSCAPE)
	{
		save.displayName = lang->getString("STR_AUTO_SAVE_GEOSCAPE_SLOT");
		save.reserved = true;
	}
	else if (save.fileName == AUTOSAVE_BATTLESCAPE)
	{
		save.displayName = lang->getString("STR_AUTO_SAVE_BATTLESCAPE_SLOT");
		save.reserved = true;
	}
	else
	{
		if (doc["name"])
		{
			save.displayName = doc["name"].as<std::string>();
		}
		else
		{
			save.displayName = Unicode::convPathToUtf8(CrossPlatform::noExt(file));
		}
		save.reserved = false;
	}

	save.timestamp = CrossPlatform::getDateModified(fullname);
	std::pair<std::string, std::string> str = CrossPlatform::timeToString(save.timestamp);
	save.isoDate = str.first;
	save.isoTime = str.second;
	save.mods = doc["mods"].as<std::vector< std::string> >(std::vector<std::string>());

	std::ostringstream details;
	if (doc["turn"])
	{
		details << lang->getString("STR_BATTLESCAPE") << ": " << lang->getString(doc["mission"].as<std::string>()) << ", ";
		details << lang->getString("STR_TURN").arg(doc["turn"].as<int>());
	}
	else
	{
		GameTime time = GameTime(6, 1, 1, 1999, 12, 0, 0);
		time.load(doc["time"]);
		details << lang->getString("STR_GEOSCAPE") << ": ";
		details << time.getDayString(lang) << " " << lang->getString(time.getMonthString()) << " " << time.getYear() << ", ";
		details << time.getHour() << ":" << std::setfill('0') << std::setw(2) << time.getMinute();
	}

	save.details = details.str();

	return save;
}

/**
 * Loads a saved game's contents from a YAML file.
 * @note Assumes the saved game is blank.
 * @param filename YAML filename.
 * @param mod Mod for the saved game.
 */
void SavedGame::load(const std::string &filename, Mod *mod)
{
	std::string s = Options::getMasterUserFolder() + filename;
	std::vector<YAML::Node> file = YAML::LoadAllFromFile(s);
	if (file.empty())
	{
		throw Exception(filename + " is not a vaild save file");
	}

	// Get brief save info
	YAML::Node brief = file[0];
	_time->load(brief["time"]);
	if (brief["name"])
	{
		_name = brief["name"].as<std::string>();
	}
	else
	{
		_name = Unicode::convPathToUtf8(filename);
	}

	// Get full save data
	YAML::Node doc = file[1];
	_difficulty = (GameDifficulty)doc["difficulty"].as<int>(_difficulty);

	_ids = doc["ids"].as< std::map<std::string, int> >(_ids);

	_alienStrategy->load(doc["alienStrategy"]);

	for (YAML::const_iterator i = doc["deadSoldiers"].begin(); i != doc["deadSoldiers"].end(); ++i)
	{
		std::string type = (*i)["type"].as<std::string>(mod->getSoldiersList().front());
		if (mod->getSoldier(type))
		{
			Soldier *soldier = new Soldier(mod->getSoldier(type), 0);
			soldier->load(*i, mod, this);
			_deadSoldiers.push_back(soldier);
		}
		else
		{
			Log(LOG_ERROR) << "Failed to load soldier " << type;
		}
	}

	if (const YAML::Node &battle = doc["battleGame"])
	{
		_battleGame = new SavedBattleGame();
		_battleGame->load(battle, mod, this);
	}
}

/**
 * Saves a saved game's contents to a YAML file.
 * @param filename YAML filename.
 */
void SavedGame::save(const std::string &filename) const
{
	std::string savPath = Options::getMasterUserFolder() + filename;
	std::string tmpPath = savPath + ".tmp";
	std::ofstream tmp(tmpPath.c_str());
	if (!tmp)
	{
		throw Exception("Failed to save " + filename);
	}

	YAML::Emitter out;

	// Saves the brief game info used in the saves list
	YAML::Node brief;
	brief["name"] = _name;
	brief["version"] = OPENXCOM_VERSION_SHORT;
	brief["engine"] = OPENXCOM_VERSION_ENGINE;
	std::string git_sha = OPENXCOM_VERSION_GIT;
	if (!git_sha.empty() && git_sha[0] ==  '.')
	{
		git_sha.erase(0,1);
	}
	brief["build"] = git_sha;
	brief["time"] = _time->save();
	if (_battleGame != 0)
	{
		brief["mission"] = _battleGame->getMissionType();
		brief["turn"] = _battleGame->getTurn();
	}

	// only save mods that work with the current master
	std::vector<const ModInfo*> activeMods = Options::getActiveMods();
	std::vector<std::string> modsList;
	for (std::vector<const ModInfo*>::const_iterator i = activeMods.begin(); i != activeMods.end(); ++i)
	{
		modsList.push_back((*i)->getId() + " ver: " + (*i)->getVersion());
	}
	brief["mods"] = modsList;

	out << brief;
	// Saves the full game data to the save
	out << YAML::BeginDoc;
	YAML::Node node;
	node["difficulty"] = (int)_difficulty;

	node["rng"] = RNG::getSeed();

	node["ids"] = _ids;


	node["alienStrategy"] = _alienStrategy->save();
	for (std::vector<Soldier*>::const_iterator i = _deadSoldiers.begin(); i != _deadSoldiers.end(); ++i)
	{
		node["deadSoldiers"].push_back((*i)->save());
	}

	if (_battleGame != 0)
	{
		node["battleGame"] = _battleGame->save();
	}
	out << node;

	// Save to temp
	// If this goes wrong, the original save will be safe
	tmp << out.c_str();
	tmp.close();
	if (!tmp)
	{
		throw Exception("Failed to save " + filename);
	}

	// If temp went fine, save for real
	// If this goes wrong, they will have the temp
	std::ofstream sav(savPath.c_str());
	if (!sav)
	{
		throw Exception("Failed to save " + filename);
	}
	sav << out.c_str();
	sav.close();
	if (!sav)
	{
		throw Exception("Failed to save " + filename);
	}

	// Everything went fine, delete the temp
	// We don't care if this fails
	CrossPlatform::deleteFile(tmpPath);
}

/**
 * Returns the game's name shown in Save screens.
 * @return Save name.
 */
std::string SavedGame::getName() const
{
	return _name;
}

/**
 * Changes the game's name shown in Save screens.
 * @param name New name.
 */
void SavedGame::setName(const std::string &name)
{
	_name = name;
}

/**
 * Returns the game's difficulty level.
 * @return Difficulty level.
 */
GameDifficulty SavedGame::getDifficulty() const
{
	return _difficulty;
}

/**
 * Changes the game's difficulty to a new level.
 * @param difficulty New difficulty.
 */
void SavedGame::setDifficulty(GameDifficulty difficulty)
{
	_difficulty = difficulty;
}

/**
 * Returns the game's difficulty coefficient based
 * on the current level.
 * @return Difficulty coefficient.
 */
int SavedGame::getDifficultyCoefficient() const
{
	return Mod::DIFFICULTY_COEFFICIENT[std::min((int)_difficulty, 4)];
}



/**
 * Returns the current time of the game.
 * @return Pointer to the game time.
 */
GameTime *SavedGame::getTime() const
{
	return _time;
}

/**
 * Changes the current time of the game.
 * @param time Game time.
 */
void SavedGame::setTime(const GameTime& time)
{
	_time = new GameTime(time);
}

/**
 * Returns the latest ID for the specified object
 * and increases it.
 * @param name Object name.
 * @return Latest ID number.
 */
int SavedGame::getId(const std::string &name)
{
	std::map<std::string, int>::iterator i = _ids.find(name);
	if (i != _ids.end())
	{
		return i->second++;
	}
	else
	{
		_ids[name] = 1;
		return _ids[name]++;
	}
}

/**
* Resets the list of unique object IDs.
* @param ids New ID list.
*/
const std::map<std::string, int> &SavedGame::getAllIds() const
{
	return _ids;
}

/**
 * Resets the list of unique object IDs.
 * @param ids New ID list.
 */
void SavedGame::setAllIds(const std::map<std::string, int> &ids)
{
	_ids = ids;
}

/**
 * Get pointer to the battleGame object.
 * @return Pointer to the battleGame object.
 */
SavedBattleGame *SavedGame::getSavedBattle()
{
	return _battleGame;
}

/**
 * Set battleGame object.
 * @param battleGame Pointer to the battleGame object.
 */
void SavedGame::setBattleGame(SavedBattleGame *battleGame)
{
	delete _battleGame;
	_battleGame = battleGame;
}


/**
 * Returns pointer to the Soldier given it's unique ID.
 * @param id A soldier's unique id.
 * @return Pointer to Soldier.
 */
Soldier *SavedGame::getSoldier(int id) const
{
	for (std::vector<Soldier*>::const_iterator j = _deadSoldiers.begin(); j != _deadSoldiers.end(); ++j)
	{
		if ((*j)->getId() == id)
		{
			return (*j);
		}
	}
	return 0;
}

/**
 * Processes a soldier, and adds their rank to the promotions data array.
 * @param soldier the soldier to process.
 * @param soldierData the data array to put their info into.
 */
void SavedGame::processSoldier(Soldier *soldier, PromotionInfo &soldierData)
{
	switch (soldier->getRank())
	{
	case RANK_COMMANDER:
		soldierData.totalCommanders++;
		break;
	case RANK_COLONEL:
		soldierData.totalColonels++;
		break;
	case RANK_CAPTAIN:
		soldierData.totalCaptains++;
		break;
	case RANK_SERGEANT:
		soldierData.totalSergeants++;
		break;
	default:
		break;
	}
}

/**
 * Checks how many soldiers of a rank exist and which one has the highest score.
 * @param soldiers full list of live soldiers.
 * @param participants list of participants on this mission.
 * @param rank Rank to inspect.
 * @return the highest ranked soldier
 */
Soldier *SavedGame::inspectSoldiers(std::vector<Soldier*> &soldiers, std::vector<Soldier*> &participants, int rank)
{
	int highestScore = 0;
	Soldier *highestRanked = 0;
	for (std::vector<Soldier*>::iterator i = soldiers.begin(); i != soldiers.end(); ++i)
	{
		if ((*i)->getRank() == rank)
		{
			int score = getSoldierScore(*i);
			if (score > highestScore && (!Options::fieldPromotions || std::find(participants.begin(), participants.end(), *i) != participants.end()))
			{
				highestScore = score;
				highestRanked = (*i);
			}
		}
	}
	return highestRanked;
}

/**
 * Evaluate the score of a soldier based on all of his stats, missions and kills.
 * @param soldier the soldier to get a score for.
 * @return this soldier's score.
 */
int SavedGame::getSoldierScore(Soldier *soldier)
{
	UnitStats *s = soldier->getCurrentStats();
	int v1 = 2 * s->health + 2 * s->stamina + 4 * s->reactions + 4 * s->bravery;
	int v2 = v1 + 3*( s->tu + 2*( s->firing ) );
	int v3 = v2 + s->melee + s->throwing + s->strength;
	if (s->psiSkill > 0) v3 += s->psiStrength + 2 * s->psiSkill;
	return v3 + 10 * ( soldier->getMissions() + soldier->getKills() );
}

/**
 * Toggles debug mode.
 */
void SavedGame::setDebugMode()
{
	_debug = !_debug;
}

/**
 * Gets the current debug mode.
 * @return Debug mode.
 */
bool SavedGame::getDebugMode() const
{
	return _debug;
}



/**
 * Returns the list of dead soldiers.
 * @return Pointer to soldier list.
 */
std::vector<Soldier*> *SavedGame::getDeadSoldiers()
{
	return &_deadSoldiers;
}

/**
 * Sets the last selected armour.
 * @param value The new value for last selected armor - Armor type string.
 */

void SavedGame::setLastSelectedArmor(const std::string &value)
{
	_lastselectedArmor = value;
}

/**
 * Gets the last selected armour
 * @return last used armor type string
 */
std::string SavedGame::getLastSelectedArmor() const
{
	return _lastselectedArmor;
}


}
