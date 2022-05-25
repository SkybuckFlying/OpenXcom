#pragma once
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
#include <map>
#include <vector>
#include <string>
#include <time.h>
#include <stdint.h>
#include "GameTime.h"

#include "Craft.h"

namespace OpenXcom
{

class Mod;
class GameTime;
class Country;
class Region;
class Ufo;
class Waypoint;
class SavedBattleGame;
class TextList;
class Language;
class RuleResearch;
class ResearchProject;
class Soldier;
class RuleManufacture;
class MissionSite;
class AlienBase;
class AlienStrategy;
class AlienMission;
class Target;
class Soldier;
class Craft;
struct MissionStatistics;
struct BattleUnitKills;

/**
 * Enumerator containing all the possible game difficulties.
 */
enum GameDifficulty { DIFF_BEGINNER = 0, DIFF_EXPERIENCED, DIFF_VETERAN, DIFF_GENIUS, DIFF_SUPERHUMAN };

/**
 * Enumerator for the various save types.
 */
enum SaveType { SAVE_DEFAULT, SAVE_QUICK, SAVE_AUTO_GEOSCAPE, SAVE_AUTO_BATTLESCAPE, SAVE_IRONMAN, SAVE_IRONMAN_END };

/**
 * Enumerator for the current game ending.
 */
enum GameEnding { END_NONE, END_WIN, END_LOSE };

/**
 * Container for savegame info displayed on listings.
 */
struct SaveInfo
{
	std::string fileName;
	std::string displayName;
	time_t timestamp;
	std::string isoDate, isoTime;
	std::string details;
	std::vector<std::string> mods;
	bool reserved;
};

struct PromotionInfo
{
	int totalCommanders;
	int totalColonels;
	int totalCaptains;
	int totalSergeants;
	PromotionInfo(): totalCommanders(0), totalColonels(0), totalCaptains(0), totalSergeants(0){}
};

/**
 * The game data that gets written to disk when the game is saved.
 * A saved game holds all the variable info in a game like funds,
 * game time, current bases and contents, world activities, score, etc.
 */
class SavedGame
{
public:
	std::string _name;
	GameDifficulty _difficulty;

	GameTime *_time;

	std::map<std::string, int> _ids;

	std::vector<Ufo*> _ufos;

	AlienStrategy *_alienStrategy;
	SavedBattleGame *_battleGame;

	bool _debug;

	std::vector<Soldier*> _deadSoldiers;

	std::string _lastselectedArmor; //contains the last selected armour

	static SaveInfo getSaveInfo(const std::string &file, Language *lang);
public:

	std::vector<Soldier*> _aliveSoldiers;

	static const std::string AUTOSAVE_GEOSCAPE, AUTOSAVE_BATTLESCAPE, QUICKSAVE;
	/// Creates a new saved game.
	SavedGame();
	/// Cleans up the saved game.
	~SavedGame();
	/// Sanitizes a mod name in a save.
	static std::string sanitizeModName(const std::string &name);
	/// Gets list of saves in the user directory.
	static std::vector<SaveInfo> getList(Language *lang, bool autoquick);
	/// Loads a saved game from YAML.
	void load(const std::string &filename, Mod *mod);
	/// Saves a saved game to YAML.
	void save(const std::string &filename) const;
	/// Gets the game name.
	std::string getName() const;
	/// Sets the game name.
	void setName(const std::string &name);
	/// Gets the game difficulty.
	GameDifficulty getDifficulty() const;
	/// Sets the game difficulty.
	void setDifficulty(GameDifficulty difficulty);
	/// Gets the game difficulty coefficient.
	int getDifficultyCoefficient() const;


	/// Gets the current game time.
	GameTime *getTime() const;
	/// Sets the current game time.
	void setTime(const GameTime& time);
	/// Gets the current ID for an object.
	int getId(const std::string &name);
	/// Resets the list of object IDs.
	const std::map<std::string, int> &getAllIds() const;
	/// Resets the list of object IDs.
	void setAllIds(const std::map<std::string, int> &ids);


	/// Gets the current battle game.
	SavedBattleGame *getSavedBattle();
	/// Sets the current battle game.
	void setBattleGame(SavedBattleGame *battleGame);



	/// Gets the soldier matching this ID.
	Soldier *getSoldier(int id) const;

	/// Processes a soldier's promotion.
	void processSoldier(Soldier *soldier, PromotionInfo &soldierData);
	/// Checks how many soldiers of a rank exist and which one has the highest score.
	Soldier *inspectSoldiers(std::vector<Soldier*> &soldiers, std::vector<Soldier*> &participants, int rank);

	/// Sets debug mode.
	void setDebugMode();
	/// Gets debug mode.
	bool getDebugMode() const;



	/// Full access to the alien strategy data.
	AlienStrategy &getAlienStrategy() { return *_alienStrategy; }
	/// Read-only access to the alien strategy data.
	const AlienStrategy &getAlienStrategy() const { return *_alienStrategy; }


	/// Gets the list of dead soldiers.
	std::vector<Soldier*> *getDeadSoldiers();

	/// Evaluate the score of a soldier based on all of his stats, missions and kills.
	int getSoldierScore(Soldier *soldier);
	/// Sets the last selected armour
	void setLastSelectedArmor(const std::string &value);
	/// Gets the last selected armour
	std::string getLastSelectedArmor() const;

	/// Handles a soldier's death.
//	std::vector<Soldier*>::iterator killSoldier(Soldier *soldier, BattleUnitKills *cause = 0);
};

}
