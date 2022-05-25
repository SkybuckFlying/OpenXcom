

namespace OpenXcom
{

void GenerateSoldier( Soldier *ParaSoldier )
{
		int randomType = RNG::generate(0, 16);

		// allocate new soldier :P
		ParaSoldier = new Soldier
		(
			getSoldier(randomType, true),
			getArmor
			(
				getSoldier(randomType, true)->getArmor(),
				true
			),
			newId
		);

		// calculate new statString
		ParaSoldier->calcStatString(getStatStrings(), (Options::psiStrengthEval));

		for (int n = 0; n < 5; ++n)
		{
			if (RNG::percent(70))
				continue;
			soldier->promoteRank();

			UnitStats* stats = soldier->getCurrentStats();
			stats->tu 			+= RNG::generate(0, 5);
			stats->stamina		+= RNG::generate(0, 5);
			stats->health		+= RNG::generate(0, 5);
			stats->bravery		+= RNG::generate(0, 5);
			stats->reactions	+= RNG::generate(0, 5);
			stats->firing		+= RNG::generate(0, 5);
			stats->throwing		+= RNG::generate(0, 5);
			stats->strength		+= RNG::generate(0, 5);
			stats->psiStrength	+= RNG::generate(0, 5);
			stats->melee		+= RNG::generate(0, 5);
			stats->psiSkill		+= RNG::generate(0, 20);
		}

	re
}

void GenerateSoldiers( Mod *ParaMod 
{

	// Generate soldiers
	for (int i = 0; i < 30; ++i)
	{
		GenerateSoldier();






		UnitStats* stats = soldier->getCurrentStats();
		stats->bravery = (int)ceil(stats->bravery / 10.0) * 10; // keep it a multiple of 10

		save->_aliveSoldiers->push_back( soldier );

	}

}


Soldier *Mod::genSoldier(SavedGame *save, std::string type) const
{
	Soldier *soldier = 0;
	int newId = save->getId("STR_SOLDIER");
	if (type.empty())
	{
		type = _soldiersIndex.front();
	}

	delete soldier;
	soldier = new Soldier(getSoldier(type, true), getArmor(getSoldier(type, true)->getArmor(), true), newId);

	// calculate new statString
	soldier->calcStatString(getStatStrings(), (Options::psiStrengthEval));

	return soldier;
}

}
