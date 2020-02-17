 -- get all distinct value in the highway field
--  service/ living_street / residential
-- footway/steps
-- / primary/trunk/ secondary/tertiary/residential

-- current version  
DROP TABLE IF EXISTS subset_all_highway; 
CREATE TABLE subset_all_highway as (
 SELECT *
 FROM 
	osm_160101_line
 WHERE
	osm_160101_line.highway is not null 
);

CREATE INDEX subset_all_highway_inx
  ON public.subset_all_highway
  USING gist
  (way);

-- get centroid of moa 
DROP TABLE IF EXISTS moa_centroid;
CREATE TABLE moa_centroid as (
 SELECT ST_Centroid(geom) as centroid_geom, gid
	 FROM moa
);
-- distance to prime way
-- subset of prime lines
DROP TABLE IF EXISTS subset_all_primeway; 
CREATE TABLE subset_all_primeway as (
 SELECT st_union(way) as union_way
 FROM 
	subset_all_highway
 WHERE
	subset_all_highway.highway in ('primary','trunk')
);
 ALTER TABLE subset_all_primeway ADD COLUMN gid SERIAL PRIMARY KEY;
 
Alter table moa drop column if exists short_prime_dis;
Alter table moa Add column short_prime_dis double precision DEFAULT 0.00;
UPDATE moa SET short_prime_dis = completenessPoly.short_prime_dis 
from (
select st_length(ST_ShortestLine(ST_Centroid(moa.geom),union_way)) as short_prime_dis, moa.gid
from subset_all_primeway, moa
  )  as completenessPoly
WHERE moa.gid = completenessPoly.gid;
 --UPDATE 983
 
 -- get the distinct value of highway
select COUNT(*) as distin_highway_number, highway
from (
	SELECT highway
	 FROM subset_all_highway) as foo
group by highway
ORDER BY distin_highway_number DESC;


 -- distance to secondary way
-- subset of secondary lines
DROP TABLE IF EXISTS subset_all_secondaryway; 
CREATE TABLE subset_all_secondaryway as (
 SELECT st_union(way) as union_way
 FROM 
	subset_all_highway
 WHERE
	subset_all_highway.highway in ('secondary')
);
 ALTER TABLE subset_all_secondaryway ADD COLUMN gid SERIAL PRIMARY KEY;
 
Alter table moa drop column if exists short_secondary_dis;
Alter table moa Add column short_secondary_dis double precision DEFAULT 0.00;
UPDATE moa SET short_secondary_dis = completenessPoly.short_secondary_dis 
from (
select st_length(ST_ShortestLine(ST_Centroid(moa.geom),union_way)) as short_secondary_dis, moa.gid
from subset_all_secondaryway, moa
  )  as completenessPoly
WHERE moa.gid = completenessPoly.gid;
 --UPDATE 983
  -- distance to tertiary way
-- subset of tertiary lines
DROP TABLE IF EXISTS subset_all_tertiaryway; 
CREATE TABLE subset_all_tertiaryway as (
 SELECT st_union(way) as union_way
 FROM 
	subset_all_highway
 WHERE
	subset_all_highway.highway in ('tertiary')
);
 ALTER TABLE subset_all_tertiaryway ADD COLUMN gid SERIAL PRIMARY KEY;
 
Alter table moa drop column if exists short_tertiary_dis;
Alter table moa Add column short_tertiary_dis double precision DEFAULT 0.00;
UPDATE moa SET short_tertiary_dis = completenessPoly.short_tertiary_dis 
from (
select st_length(ST_ShortestLine(ST_Centroid(moa.geom),union_way)) as short_tertiary_dis, moa.gid
from subset_all_tertiaryway, moa
  )  as completenessPoly
WHERE moa.gid = completenessPoly.gid;
 --UPDATE 983
 
 -------------------------------------------------------------  repeat this for loa
 
-- get centroid of loa 
DROP TABLE IF EXISTS loa_centroid;
CREATE TABLE loa_centroid as (
 SELECT ST_PointOnSurface(geom) as centroid_geom, gid
	 FROM loa
);
-- distance to prime way

 
Alter table loa drop column if exists short_prime_dis;
Alter table loa Add column short_prime_dis double precision DEFAULT 0.00;
UPDATE loa SET short_prime_dis = completenessPoly.short_prime_dis 
from (
select st_length(ST_ShortestLine(ST_Centroid(loa.geom),union_way)) as short_prime_dis, loa.gid
from subset_all_primeway, loa
  )  as completenessPoly
WHERE loa.gid = completenessPoly.gid;
 --SELECT 4835
 
 
Alter table loa drop column if exists short_secondary_dis;
Alter table loa Add column short_secondary_dis double precision DEFAULT 0.00;
UPDATE loa SET short_secondary_dis = completenessPoly.short_secondary_dis 
from (
select st_length(ST_ShortestLine(ST_Centroid(loa.geom),union_way)) as short_secondary_dis, loa.gid
from subset_all_secondaryway, loa
  )  as completenessPoly
WHERE loa.gid = completenessPoly.gid;
-- UPDATE 4835


Alter table loa drop column if exists short_tertiary_dis;
Alter table loa Add column short_tertiary_dis double precision DEFAULT 0.00;
UPDATE loa SET short_tertiary_dis = completenessPoly.short_tertiary_dis 
from (
select st_length(ST_ShortestLine(ST_Centroid(loa.geom),union_way)) as short_tertiary_dis, loa.gid
from subset_all_tertiaryway, loa
  )  as completenessPoly
WHERE loa.gid = completenessPoly.gid;

 
 ------------------------------------------------------------      repeat this for SB
 

-- distance to prime way
Alter table street_blocksl_withinloa drop column if exists short_prime_dis;
Alter table street_blocksl_withinloa Add column short_prime_dis double precision DEFAULT 0.00;
UPDATE street_blocksl_withinloa SET short_prime_dis = completenessPoly.short_prime_dis 
from (
select st_length(ST_ShortestLine(ST_PointOnSurface(street_blocksl_withinloa.the_geom),union_way)) as short_prime_dis, street_blocksl_withinloa.gid
from subset_all_primeway, street_blocksl_withinloa
  )  as completenessPoly
WHERE street_blocksl_withinloa.gid = completenessPoly.gid;

 
 
Alter table street_blocksl_withinloa drop column if exists short_secondary_dis;
Alter table street_blocksl_withinloa Add column short_secondary_dis double precision DEFAULT 0.00;
UPDATE street_blocksl_withinloa SET short_secondary_dis = completenessPoly.short_secondary_dis 
from (
select st_length(ST_ShortestLine(ST_Centroid(street_blocksl_withinloa.the_geom),union_way)) as short_secondary_dis, street_blocksl_withinloa.gid
from subset_all_secondaryway, street_blocksl_withinloa
  )  as completenessPoly
WHERE street_blocksl_withinloa.gid = completenessPoly.gid;


Alter table street_blocksl_withinloa drop column if exists short_tertiary_dis;
Alter table street_blocksl_withinloa Add column short_tertiary_dis double precision DEFAULT 0.00;
UPDATE street_blocksl_withinloa SET short_tertiary_dis = completenessPoly.short_tertiary_dis 
from (
select st_length(ST_ShortestLine(ST_Centroid(street_blocksl_withinloa.the_geom),union_way)) as short_tertiary_dis, street_blocksl_withinloa.gid
from subset_all_tertiaryway, street_blocksl_withinloa
  )  as completenessPoly
WHERE street_blocksl_withinloa.gid = completenessPoly.gid;
