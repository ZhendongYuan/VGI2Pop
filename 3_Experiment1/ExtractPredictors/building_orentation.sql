-- get the oriented minimal envelope 
-- for moa 
DROP INDEX IF EXISTS building_polygon_removedOverlap_clipped_indx;
CREATE INDEX building_polygon_removedOverlap_clipped_indx
  ON public.building_polygon_removedOverlap_clipped
  USING gist
  (way);
  
 -- this run on my local machine for the version problem in zug server 
DROP TABLE IF EXISTS building_orientation_moa; 
CREATE TABLE building_orientation_moa as (
 SELECT sb_gid as moa_id,osm_id,ST_OrientedEnvelope(way) as oe_geom
 FROM 
	building_polygon_removedOverlap_clipped
);

-- get the centroid point then measuring the shortest line, get the azimuth angle and adjust into longest 
-- actually, measuring the shortest orientation is the same. 

DROP TABLE IF EXISTS building_orientation_moa_shortest; 
CREATE TABLE building_orientation_moa_shortest as (
 SELECT ST_ShortestLine(ST_Centroid(oe_geom),ST_Boundary(oe_geom)) as shortestline, osm_id
	 FROM building_orientation_moa
);

Alter table building_orientation_moa drop column if exists Azim_short_deg;
Alter table building_orientation_moa Add column Azim_short_deg double precision DEFAULT 0.0000;
UPDATE building_orientation_moa SET Azim_short_deg = completenessPoly.Azim_short_deg 
from (
select degrees(ST_Azimuth(ST_Startpoint(shortestline), ST_Endpoint(shortestline))) as Azim_short_deg, osm_id
from building_orientation_moa_shortest
  )  as completenessPoly
WHERE building_orientation_moa.osm_id = completenessPoly.osm_id;

-- if deg > 180 then -180; 
Alter table building_orientation_moa drop column if exists line_short_deg;
Alter table building_orientation_moa Add column line_short_deg double precision DEFAULT 0.0000;
UPDATE building_orientation_moa SET line_short_deg = completenessPoly.line_short_deg 
from (
	SELECT osm_id,
	CASE 
		WHEN (Azim_short_deg > 180) THEN (Azim_short_deg-180)
		ELSE Azim_short_deg
	END AS line_short_deg
	from building_orientation_moa
  )  as completenessPoly
WHERE building_orientation_moa.osm_id = completenessPoly.osm_id;


Alter table moa drop column if exists sbro;
--avg
Alter table moa drop column if exists sbro_avg;
Alter table moa Add column sbro_avg double precision DEFAULT 0.0000;
UPDATE moa SET sbro_avg = completenessPoly.sbro_avg 
from (
select avg(line_short_deg) as sbro_avg, moa_id
from building_orientation_moa
group by moa_id
  )  as completenessPoly
WHERE moa.gid = completenessPoly.moa_id;

-- std
Alter table moa drop column if exists sbro_avg;
Alter table moa Add column sbro_avg double precision DEFAULT 0.0000;
UPDATE moa SET sbro_avg = completenessPoly.sbro_avg 
from (
select stddev(line_short_deg) as sbro_avg, moa_id
from building_orientation_moa
group by moa_id
  )  as completenessPoly
WHERE moa.gid = completenessPoly.moa_id;

-- max
Alter table moa drop column if exists sbro_avg;
Alter table moa Add column sbro_avg double precision DEFAULT 0.0000;
UPDATE moa SET sbro_avg = completenessPoly.sbro_avg 
from (
select max(line_short_deg) as sbro_avg, moa_id
from building_orientation_moa
group by moa_id
  )  as completenessPoly
WHERE moa.gid = completenessPoly.moa_id;


-- min
Alter table moa drop column if exists sbro_avg;
Alter table moa Add column sbro_avg double precision DEFAULT 0.0000;
UPDATE moa SET sbro_avg = completenessPoly.sbro_avg 
from (
select min(line_short_deg) as sbro_avg, moa_id
from building_orientation_moa
group by moa_id
  )  as completenessPoly
WHERE moa.gid = completenessPoly.moa_id;


-- for loa 
-- loa 
DROP TABLE IF EXISTS building_orientation_loa_shortest; 
CREATE TABLE building_orientation_loa_shortest as (
 SELECT ST_ShortestLine(ST_Centroid(oe_geom),ST_Boundary(oe_geom)) as shortestline, osm_id
	 FROM building_orientation_loa
);

Alter table building_orientation_loa drop column if exists Azim_short_deg;
Alter table building_orientation_loa Add column Azim_short_deg double precision DEFAULT 0.0000;
UPDATE building_orientation_loa SET Azim_short_deg = completenessPoly.Azim_short_deg 
from (
select degrees(ST_Azimuth(ST_Startpoint(shortestline), ST_Endpoint(shortestline))) as Azim_short_deg, osm_id
from building_orientation_loa_shortest
  )  as completenessPoly
WHERE building_orientation_loa.osm_id = completenessPoly.osm_id;

-- if deg > 180 then -180; 
Alter table building_orientation_loa drop column if exists line_short_deg;
Alter table building_orientation_loa Add column line_short_deg double precision DEFAULT 0.0000;
UPDATE building_orientation_loa SET line_short_deg = completenessPoly.line_short_deg 
from (
	SELECT osm_id,
	CASE 
		WHEN (Azim_short_deg > 180) THEN (Azim_short_deg-180)
		ELSE Azim_short_deg
	END AS line_short_deg
	from building_orientation_loa
  )  as completenessPoly
WHERE building_orientation_loa.osm_id = completenessPoly.osm_id;


Alter table loa drop column if exists sbro;
--avg
Alter table loa drop column if exists sbro_avg;
Alter table loa Add column sbro_avg double precision DEFAULT 0.0000;
UPDATE loa SET sbro_avg = completenessPoly.sbro_avg 
from (
select avg(line_short_deg) as sbro_avg, loa_id
from building_orientation_loa
group by loa_id
  )  as completenessPoly
WHERE loa.gid = completenessPoly.loa_id;

-- std
Alter table loa drop column if exists sbro_std;
Alter table loa Add column sbro_std double precision DEFAULT 0.0000;
UPDATE loa SET sbro_std = completenessPoly.sbro_std 
from (
select stddev(line_short_deg) as sbro_std, loa_id
from building_orientation_loa
group by loa_id
  )  as completenessPoly
WHERE loa.gid = completenessPoly.loa_id;

-- max
Alter table loa drop column if exists sbro_max;
Alter table loa Add column sbro_max double precision DEFAULT 0.0000;
UPDATE loa SET sbro_max = completenessPoly.sbro_max 
from (
select max(line_short_deg) as sbro_max, loa_id
from building_orientation_loa
group by loa_id
  )  as completenessPoly
WHERE loa.gid = completenessPoly.loa_id;


-- min
Alter table loa drop column if exists sbro_min;
Alter table loa Add column sbro_min double precision DEFAULT 0.0000;
UPDATE loa SET sbro_min = completenessPoly.sbro_min 
from (
select min(line_short_deg) as sbro_min, loa_id
from building_orientation_loa
group by loa_id
  )  as completenessPoly
WHERE loa.gid = completenessPoly.loa_id;

-- UPDATE 4010

---------------------------------------------------------------------------------- for sb 

--- following chunk for local machine 
DROP INDEX IF EXISTS building_polygon_removedOverlap_clipped_indx;
CREATE INDEX building_polygon_removedOverlap_clipped_indx
  ON public.building_removedOverlap_center_street_blocksl
  USING gist
  (way);
  
 -- this run on my local machine for the version problem in zug server 
DROP TABLE IF EXISTS building_orientation_sbl; 
CREATE TABLE building_orientation_sbl as (
 SELECT sb_gid as sb_id,osm_id,ST_OrientedEnvelope(way) as oe_geom
 FROM 
	building_removedOverlap_center_street_blocksl
);

----- 

DROP TABLE IF EXISTS building_orientation_sbl_shortest; 
CREATE TABLE building_orientation_sbl_shortest as (
 SELECT ST_ShortestLine(ST_Centroid(oe_geom),ST_Boundary(oe_geom)) as shortestline, osm_id
	 FROM building_orientation_sbl
);

Alter table building_orientation_sbl drop column if exists Azim_short_deg;
Alter table building_orientation_sbl Add column Azim_short_deg double precision DEFAULT 0.0000;
UPDATE building_orientation_sbl SET Azim_short_deg = completenessPoly.Azim_short_deg 
from (
select degrees(ST_Azimuth(ST_Startpoint(shortestline), ST_Endpoint(shortestline))) as Azim_short_deg, osm_id
from building_orientation_loa_shortest
  )  as completenessPoly
WHERE building_orientation_sbl.osm_id = completenessPoly.osm_id;

-- if deg > 180 then -180; 
Alter table building_orientation_sbl drop column if exists line_short_deg;
Alter table building_orientation_sbl Add column line_short_deg double precision DEFAULT 0.0000;
UPDATE building_orientation_sbl SET line_short_deg = completenessPoly.line_short_deg 
from (
	SELECT osm_id,
	CASE 
		WHEN (Azim_short_deg > 180) THEN (Azim_short_deg-180)
		ELSE Azim_short_deg
	END AS line_short_deg
	from building_orientation_sbl
  )  as completenessPoly
WHERE building_orientation_sbl.osm_id = completenessPoly.osm_id;


Alter table street_blocksl_withinloa drop column if exists sbro;
--avg
Alter table street_blocksl_withinloa drop column if exists sbro_avg;
Alter table street_blocksl_withinloa Add column sbro_avg double precision DEFAULT 0.0000;
UPDATE street_blocksl_withinloa SET sbro_avg = completenessPoly.sbro_avg 
from (
select avg(line_short_deg) as sbro_avg, sb_id
from building_orientation_sbl
group by sb_id
  )  as completenessPoly
WHERE street_blocksl_withinloa.gid = completenessPoly.sb_id;

-- std
Alter table street_blocksl_withinloa drop column if exists sbro_std;
Alter table street_blocksl_withinloa Add column sbro_std double precision DEFAULT 0.0000;
UPDATE street_blocksl_withinloa SET sbro_std = completenessPoly.sbro_std 
from (
select stddev(line_short_deg) as sbro_std, sb_id
from building_orientation_sbl
group by sb_id
  )  as completenessPoly
WHERE street_blocksl_withinloa.gid = completenessPoly.sb_id;

-- max
Alter table street_blocksl_withinloa drop column if exists sbro_max;
Alter table street_blocksl_withinloa Add column sbro_max double precision DEFAULT 0.0000;
UPDATE street_blocksl_withinloa SET sbro_max = completenessPoly.sbro_max 
from (
select max(line_short_deg) as sbro_max, sb_id
from building_orientation_sbl
group by sb_id
  )  as completenessPoly
WHERE street_blocksl_withinloa.gid = completenessPoly.sb_id;


-- min
Alter table street_blocksl_withinloa drop column if exists sbro_min;
Alter table street_blocksl_withinloa Add column sbro_min double precision DEFAULT 0.0000;
UPDATE street_blocksl_withinloa SET sbro_min = completenessPoly.sbro_min 
from (
select min(line_short_deg) as sbro_min, sb_id
from building_orientation_sbl
group by sb_id
  )  as completenessPoly
WHERE street_blocksl_withinloa.gid = completenessPoly.sb_id;

-- UPDATE 4010