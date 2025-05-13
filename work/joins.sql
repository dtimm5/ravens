----sample joins that i've done

----simple left
select count(distinct(g.gr_id)), zd.county, zd.state from helix.grrecords g 
left join helix.tags t on t.gr_id = g.gr_id
left join (select zd.zip, zd.county, zd.state, zd.hma_ind from custom.zipcode_db zd) zd on g.zip = right('0'+cast(zd.zip as varchar(5)), 5)
where t.tag_name = 'psl-owners-2024'
and g.gr_id not in (select distinct(t2.gr_id) from helix.tags t2 where t2.tag_name in ('psl-owners-2023', 'psl-owners-2022', 'psl-owners-2021', 'psl-owners-2019'))
group by zd.county, zd.state

----left join with zip code simplifier
select count(distinct(g.gr_id)), zd.county, zd.state from helix.grrecords g 
left join helix.tags t on t.gr_id = g.gr_id
left join (select zd.zip, zd.county, zd.state, zd.hma_ind from custom.zipcode_db zd) zd on g.zip = right('0'+cast(zd.zip as varchar(5)), 5)
where t.tag_name = 'psl-owners-2024'
group by zd.county, zd.state

----union
select zd.county, zd.state, count(distinct(vsgt.attended_crmid)) from custom_2.vw_seatgeek_gameday_ticketing vsgt
left join (select * from helix.mappings m where m.helix_source = 'seatgeek') m on m.helix_sourceid = vsgt.attended_crmid
left join helix.grrecords g on m.gr_id = g.gr_id
left join custom.zipcode_db zd on substring(g.zip, 1, 5) = right('0'+cast(zd.zip as varchar(5)), 5)
where g.gr_id not in (select t.gr_id from helix.tags t where t.tag_name = 'psl-owners-2024')
and vsgt.show_type in ('2024 Home Season', '2024 Playoff Tickets')
and lower(g.email) not in (
  select distinct(lower(da.emailaddress)) from dwa.fact_attendance_transaction fat
left join dwa.dim_account da on da.accountsid = fat.accountsid
left join dwa.dim_product dp on dp.productsid = fat.productsid
left join (select * from helix.mappings m where m.helix_source = 'archtics') m on m.helix_sourceid = fat.accountsid
left join helix.grrecords g on m.gr_id = g.gr_id
where dp.venue_desc  = 'M&T Bank Stadium'
and dp.manifest_desc = 'Stadium Master'
and dp.season_year in ('2019', '2020', '2021', '2022') and da.emailaddress is not null
and dp.event_desc not in ('Arsenal v. Everton', 'Navy ND 2022')
union
(select distinct(lower(g.email)) from custom_2.vw_seatgeek_gameday_ticketing vsgt
  left join (select * from helix.mappings m where m.helix_source = 'seatgeek') m on m.helix_sourceid = vsgt.attended_crmid
  left join helix.grrecords g on m.gr_id = g.gr_id
  left join custom.zipcode_db zd on substring(g.zip, 1, 5) = right('0'+cast(zd.zip as varchar(5)), 5)
  where g.gr_id not in (select t.gr_id from helix.tags t where t.tag_name = 'psl-owners-2023')
  and vsgt.show_type in ('2023 Ravens Home', '2023 Ravens Postseason') and g.email is not null))
group by zd.county, zd.state

----union with demographics
select vsgt.attended_crmid, substring(g.zip, 1, 5) as zip_code, zd.county, zd.state, 
 dt.adv_hh_marital_status, dt.nfl_fan_id, dt.gender_prsn, dt.age_rng_prsn, dt.adv_indiv_marital_stat_prsn, dt.adv_target_income_3, dt.occupation, dt.adv_hh_education, 
    dt.niches_3, dt.hh_type_family_comp, 
    case 
        when dt.age_rng_prsn between 18 and 25 then '18-25'
        when dt.age_rng_prsn between 26 and 35 then '26-35'
        when dt.age_rng_prsn between 36 and 45 then '36-45'
        when dt.age_rng_prsn between 46 and 55 then '46-55'
        when dt.age_rng_prsn between 56 and 65 then '56-65'
        when dt.age_rng_prsn >= 66 then '66+'
        else 'Unknown'
    end as age_bucket
 from custom_2.vw_seatgeek_gameday_ticketing vsgt 
left join (select * from helix.mappings m where m.helix_source = 'seatgeek') m on m.helix_sourceid = vsgt.attended_crmid
left join helix.grrecords g on m.gr_id = g.gr_id
left join custom.zipcode_db zd on substring(g.zip, 1, 5) = right('0'+cast(zd.zip as varchar(5)), 5)
 left join nfl_import.fan_unified fu on lower(fu.email_addr) = lower(g.email)
 left join nfl_import.demographic_tsp dt on dt.nfl_fan_id = fu.nfl_fan_id
where g.gr_id not in (select t.gr_id from helix.tags t where t.tag_name = 'psl-owners-2024')
and vsgt.show_type in ('2024 Home Season', '2024 Playoff Tickets')
and lower(g.email) not in (
  select distinct(lower(da.emailaddress)) from dwa.fact_attendance_transaction fat
left join dwa.dim_account da on da.accountsid = fat.accountsid
left join dwa.dim_product dp on dp.productsid = fat.productsid
left join (select * from helix.mappings m where m.helix_source = 'archtics') m on m.helix_sourceid = fat.accountsid
left join helix.grrecords g on m.gr_id = g.gr_id
where dp.venue_desc  = 'M&T Bank Stadium'
and dp.manifest_desc = 'Stadium Master'
and dp.season_year in ('2019', '2020', '2021', '2022') and da.emailaddress is not null
and dp.event_desc not in ('Arsenal v. Everton', 'Navy ND 2022')
union
(select distinct(lower(g.email)) from custom_2.vw_seatgeek_gameday_ticketing vsgt
  left join (select * from helix.mappings m where m.helix_source = 'seatgeek') m on m.helix_sourceid = vsgt.attended_crmid
  left join helix.grrecords g on m.gr_id = g.gr_id
  left join custom.zipcode_db zd on substring(g.zip, 1, 5) = right('0'+cast(zd.zip as varchar(5)), 5)
  where g.gr_id not in (select t.gr_id from helix.tags t where t.tag_name = 'psl-owners-2023')
  and vsgt.show_type in ('2023 Ravens Home', '2023 Ravens Postseason') and g.email is not null))
  
  ----double union
  with sg_att as (((
(select distinct (lower(g.email)) as email from custom_2.vw_seatgeek_gameday_ticketing vsgt 
left join (select * from helix.mappings m where m.helix_source = 'seatgeek') m on m.helix_sourceid = vsgt.attended_crmid
 left join helix.grrecords g on m.gr_id = g.gr_id
 where g.gr_id not in (select t.gr_id from helix.tags t where t.tag_name = 'psl-owners-2024')
and vsgt.show_type in ('2024 Home Season', '2024 Playoff Tickets')))
union
(select distinct(lower(g.email)) as email from custom_2.vw_seatgeek_gameday_ticketing vsgt
  left join (select * from helix.mappings m where m.helix_source = 'seatgeek') m on m.helix_sourceid = vsgt.attended_crmid
  left join helix.grrecords g on m.gr_id = g.gr_id
  left join custom.zipcode_db zd on substring(g.zip, 1, 5) = right('0'+cast(zd.zip as varchar(5)), 5)
  where g.gr_id not in (select t.gr_id from helix.tags t where t.tag_name = 'psl-owners-2023')
  and vsgt.show_type in ('2023 Ravens Home', '2023 Ravens Postseason') and g.email is not null))
union 
(select distinct(lower(da.emailaddress)) as email from dwa.fact_attendance_transaction fat 
 left join dwa.dim_account da on da.accountsid = fat.accountsid 
 left join dwa.dim_product dp on dp.productsid = fat.productsid 
 left join (select * from helix.mappings m where m.helix_source = 'archtics') m on m.helix_sourceid = fat.accountsid 
 left join helix.grrecords g on m.gr_id = g.gr_id
 where g.gr_id not in (select t.gr_id from helix.tags t where t.tag_name in ('psl-owners-2019', 'psl-owners-2021', 'psl-owners-2022'))
 and dp.venue_desc  = 'M&T Bank Stadium'
 and dp.manifest_desc = 'Stadium Master'
 and dp.season_year in ('2019', '2020', '2021', '2022') and da.emailaddress is not null
 and dp.event_desc not in ('Arsenal v. Everton', 'Navy ND 2022')))
select count(distinct (sg_att.email)) from sg_att

----partition join
select distinct(a.helix_source), count(*) from helix.grrecords g
	left join (select m.gr_id, m.helix_source, a.source_created_on as create_date, pg_catalog.row_number()
	OVER(
         PARTITION BY m.gr_id
         ORDER BY a.source_created_on) AS map_order
    from helix.mappings m
	join helix.allsources a on a.id = m.helix_sourceid) a on g.gr_id = a.gr_id
	where a.map_order = 1 and g.source_created_on >= '2024-02-01'
	group by a.helix_source