
SELECT
	v.id, v.first_name, v.last_name, v.house_number, v.street, v.apartment, v.zip,
	COUNT(fv.event_datestamp) as times_voted
 FROM voters v JOIN fact_vote fv ON fv.voter_id = v.id
    INNER JOIN dim_date_year ddy ON fv.dim_date_year_id = ddy.id
    INNER JOIN ref_party rp ON rp.id = v.ref_party_id
    WHERE fv.event_datestamp > '01-01-2019' 
    AND rp.id = 3 --libertarian
    GROUP BY v.id, v.first_name, v.last_name, v.house_number, v.street, v.apartment, v.zip
 ORDER BY
	times_voted DESC;
