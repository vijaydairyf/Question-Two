(SELECT vw_surveys.village_name, vw_survey_mother.question,  COUNT(vw_survey_mother.mother_info_def_id) AS no_per_indicator
	FROM vw_survey_mother
	INNER JOIN vw_surveys ON vw_surveys.survey_id = vw_survey_mother.survey_id
	WHERE for_515 = true
		AND vw_survey_mother.response = 1
        AND vw_surveys.village_id = '$P!{village_id}'
        AND vw_surveys.survey_time::date BETWEEN '$P!{start_date}'::date AND  '$P!{end_date}'::date
	GROUP BY vw_surveys.village_id, vw_surveys.village_name, vw_survey_mother.mother_info_def_id, vw_survey_mother.question)
UNION
    (SELECT vw_surveys.village_name, vw_survey_child.question,  COUNT( vw_survey_child.child_info_def_id) AS no_per_indicator
    	FROM vw_survey_child
    	INNER JOIN vw_surveys ON vw_surveys.survey_id = vw_survey_child.survey_id
    	WHERE for_515 = true
    		AND vw_survey_child.response = 1
            AND vw_surveys.village_id = '$P!{village_id}'
            AND vw_surveys.survey_time::date BETWEEN '$P!{start_date}'::date AND  '$P!{end_date}'::date
    	GROUP BY vw_surveys.village_id, vw_surveys.village_name, vw_survey_child.child_info_def_id, vw_survey_child.question)

UNION
    (SELECT vw_surveys.village_name, vw_survey_referrals.question,  COUNT( vw_survey_referrals.referral_info_def_id) AS no_per_indicator
    	FROM vw_survey_referrals
    	INNER JOIN vw_surveys ON vw_surveys.survey_id = vw_survey_referrals.survey_id
    	WHERE for_515 = true
    		AND vw_survey_referrals.response = '1'::varchar
            AND vw_surveys.village_id = '$P!{village_id}'
            AND vw_surveys.survey_time::date BETWEEN '$P!{start_date}'::date AND  '$P!{end_date}'::date
    	GROUP BY vw_surveys.village_id, vw_surveys.village_name, vw_survey_referrals.referral_info_def_id, vw_survey_referrals.question)
UNION
    (SELECT vw_surveys.village_name, vw_survey_defaulters.question,  COUNT( vw_survey_defaulters.defaulters_info_def_id) AS no_per_indicator
    	FROM vw_survey_defaulters
    	INNER JOIN vw_surveys ON vw_surveys.survey_id = vw_survey_defaulters.survey_id
    	WHERE for_515 = true
    		AND vw_survey_defaulters.response = 1
            AND vw_surveys.village_id = '$P!{village_id}'
            AND vw_surveys.survey_time::date BETWEEN '$P!{start_date}'::date AND  '$P!{end_date}'::date
    	GROUP BY vw_surveys.village_id, vw_surveys.village_name, vw_survey_defaulters.defaulters_info_def_id, vw_survey_defaulters.question)
UNION
    (SELECT vw_surveys.village_name, vw_survey_death.question, SUM(vw_survey_death.response::integer) AS no_per_indicator
        FROM vw_survey_death
        INNER JOIN vw_surveys ON vw_surveys.survey_id = vw_survey_death.survey_id
        WHERE for_515 = true
            AND  vw_survey_death.death_info_def_id != 5
            AND vw_surveys.village_id = '$P!{village_id}'
            AND vw_surveys.survey_time::date BETWEEN '$P!{start_date}'::date AND  '$P!{end_date}'::date
        GROUP BY vw_surveys.village_id, vw_surveys.village_name, vw_survey_death.death_info_def_id, vw_survey_death.question)
UNION
    (SELECT vw_surveys.village_name, vw_survey_household.question,  COUNT(vw_survey_household.household_info_def_id) AS no_per_indicator
    	FROM vw_survey_household
    	INNER JOIN vw_surveys ON vw_surveys.survey_id = vw_survey_household.survey_id
    	WHERE for_515 = true
    		AND vw_survey_household.response = 1
            AND vw_surveys.village_id = '$P!{village_id}'
            AND vw_surveys.survey_time::date BETWEEN '$P!{start_date}'::date AND  '$P!{end_date}'::date
    	GROUP BY vw_surveys.village_id, vw_surveys.village_name, vw_survey_household.household_info_def_id, vw_survey_household.question)
