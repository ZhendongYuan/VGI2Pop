-------------------  partion the buildings by street blocks which use the ST_Centroid to identify center belonging to which street blocks

--Drop TABLE if exists building_removedOverlap_centre;
--CREATE TABLE building_removedOverlap_centre as (
--SELECT ST_Centroid(building_polygon_removedOverlap.way) AS centre_geom,building_polygon_removedOverlap.*
-- FROM building_polygon_removedOverlap
--);

DROP TABLE IF EXISTS building_removedOverlap_center_street_blocksl; 
CREATE TABLE building_removedOverlap_center_street_blocksl as (
SELECT building_removedOverlap_centre.way AS clipped_geom,street_blocksl.gid as SB_gid,building_removedOverlap_centre.*
 FROM building_removedOverlap_centre
  INNER JOIN 
	street_blocksl
  ON ST_Intersects(street_blocksl.the_geom,building_removedOverlap_centre.centre_geom)
);
--------- create index
Drop index if exists building_removedOverlap_center_street_blocksl_geom_index;
CREATE INDEX building_removedOverlap_center_street_blocksl_geom_index ON public.building_removedOverlap_center_street_blocksl  USING gist  (clipped_geom);

VACUUM building_removedOverlap_center_street_blocksl;

------------------------------------------------------------------------  statistic for each street blocks 
 ----------------------------------------------------------------------- calculate the sum of area based on clipped 
Alter table street_blocksl drop column if exists B_area_sum;
Alter table street_blocksl Add column B_area_sum double precision DEFAULT 0.000;
UPDATE street_blocksl SET B_area_sum = Poly.B_area_sum 
FROM (
 SELECT sum(st_area(geography(st_transform(building_removedOverlap_center_street_blocksl.clipped_geom,4326)))) AS B_area_sum,SB_gid
 FROM building_removedOverlap_center_street_blocksl
 GROUP BY  SB_gid
  )  as Poly
WHERE street_blocksl.gid = Poly.SB_gid;

----------------------------------------------------------------------  calculate the avg, std, max size for each buildings
-- the process of remove overlapped polygon may cause some problems.

--avg
Alter table street_blocksl drop column if exists B_area_avg;
ALTER TABLE street_blocksl ADD COLUMN B_area_avg double precision DEFAULT 0.000;
UPDATE street_blocksl SET B_area_avg = Poly.B_area_avg 
FROM (
 SELECT avg(st_area(geography(st_transform(building_removedOverlap_center_street_blocksl.clipped_geom,4326)))) AS B_area_avg,SB_gid
 FROM building_removedOverlap_center_street_blocksl
 GROUP BY  SB_gid
  )  as Poly
WHERE street_blocksl.gid = Poly.SB_gid;


-- std
Alter table street_blocksl drop column if exists B_area_std;
ALTER TABLE street_blocksl ADD COLUMN B_area_std double precision DEFAULT 0.000;
UPDATE street_blocksl SET B_area_std = Poly.B_area_std 
FROM (
 SELECT stddev(st_area(geography(st_transform(building_removedOverlap_center_street_blocksl.clipped_geom,4326)))) AS B_area_std,SB_gid
 FROM building_removedOverlap_center_street_blocksl
 GROUP BY  SB_gid
  )  as Poly
WHERE street_blocksl.gid = Poly.SB_gid;

-- max
Alter table street_blocksl drop column if exists B_area_max;
ALTER TABLE street_blocksl ADD COLUMN B_area_max double precision DEFAULT 0.000;
UPDATE street_blocksl SET B_area_max = Poly.B_area_max 
FROM (
 SELECT max(st_area(geography(st_transform(building_removedOverlap_center_street_blocksl.clipped_geom,4326)))) AS B_area_max,SB_gid
 FROM building_removedOverlap_center_street_blocksl
 GROUP BY  SB_gid
  )  as Poly
WHERE street_blocksl.gid = Poly.SB_gid;

-----------  count the number of building inside
Alter table street_blocksl drop column if exists B_number;
ALTER TABLE street_blocksl ADD COLUMN B_number double precision DEFAULT 0.000;
UPDATE street_blocksl SET B_number = Poly.B_number 
FROM (
 SELECT COUNT(osm_id) AS B_number,SB_gid
 FROM building_removedOverlap_center_street_blocksl
 GROUP BY  SB_gid
  )  as Poly
WHERE street_blocksl.gid = Poly.SB_gid;

----------------------------------------------------------------------------------------------------------------------------------- from here, recover the street_blocksl table 

--- copy the current street_blocksl as backups
--DROP TABLE IF EXISTS street_blocksl_backup;
--CREATE TABLE street_blocksl_backup AS (
--SELECT * FROM street_blocksl);

-- rolling back the street_blocksl table
--DROP TABLE IF EXISTS street_blocksl;
--CREATE TABLE street_blocksl AS (
--SELECT * FROM street_blocksl_backup);


----------------------------------------------------------------------------------------------------------------------------------- from here need to consider the non-building 
-------- the shape distribution of individual buildings  avg 
Alter table street_blocksl drop column if exists B_shp_avg;
ALTER TABLE street_blocksl ADD COLUMN B_shp_avg double precision DEFAULT 0.000;
UPDATE street_blocksl SET B_shp_avg = Poly.B_shp_avg 
FROM (
 SELECT avg(st_perimeter(geography(st_transform(buildings.clipped_geom,4326)))/sqrt(st_area(geography(st_transform(buildings.clipped_geom,4326))))) AS B_shp_avg,SB_gid
 FROM building_removedOverlap_center_street_blocksl as buildings
 GROUP BY  SB_gid
  )  as Poly
WHERE street_blocksl.gid = Poly.SB_gid;

-------- the shape distribution of individual buildings std
Alter table street_blocksl drop column if exists B_shp_std;
ALTER TABLE street_blocksl ADD COLUMN B_shp_std double precision DEFAULT 0.000;
UPDATE street_blocksl SET B_shp_std = Poly.B_shp_std 
FROM (
 SELECT stddev(st_perimeter(geography(st_transform(buildings.clipped_geom,4326)))/sqrt(st_area(geography(st_transform(buildings.clipped_geom,4326))))) AS B_shp_std,SB_gid
 FROM building_removedOverlap_center_street_blocksl as buildings
 GROUP BY  SB_gid
  )  as Poly
WHERE street_blocksl.gid = Poly.SB_gid;

------- the shape distribution of individual buildings max
Alter table street_blocksl drop column if exists B_shp_max;
ALTER TABLE street_blocksl ADD COLUMN B_shp_max double precision DEFAULT 0.000;
UPDATE street_blocksl SET B_shp_max = Poly.B_shp_max 
FROM (
 SELECT max(st_perimeter(geography(st_transform(buildings.clipped_geom,4326)))/sqrt(st_area(geography(st_transform(buildings.clipped_geom,4326))))) AS B_shp_max,SB_gid
 FROM building_removedOverlap_center_street_blocksl as buildings
 GROUP BY  SB_gid
  )  as Poly
WHERE street_blocksl.gid = Poly.SB_gid;

-------- the Fractality distribution of individual buildings  avg 
--fractality = 1- (LOG(sb_area_4326)/(2*LOG(perimeter)))
Alter table street_blocksl drop column if exists B_frac_avg;
ALTER TABLE street_blocksl ADD COLUMN B_frac_avg double precision DEFAULT 0.000;
UPDATE street_blocksl SET B_frac_avg = Poly.B_frac_avg 
FROM (
 SELECT avg(1- (LOG(st_area(geography(st_transform(buildings.clipped_geom,4326)))))/(2*LOG(st_perimeter(geography(st_transform(buildings.clipped_geom,4326)))))) AS B_frac_avg,SB_gid
 FROM building_removedOverlap_center_street_blocksl as buildings
 GROUP BY  SB_gid
  )  as Poly
WHERE street_blocksl.gid = Poly.SB_gid;


-------- the Fractality distribution of individual buildings std
Alter table street_blocksl drop column if exists B_frac_std;
ALTER TABLE street_blocksl ADD COLUMN B_frac_std double precision DEFAULT 0.000;
UPDATE street_blocksl SET B_frac_std = Poly.B_frac_std 
FROM (
 SELECT stddev(1- (LOG(st_area(geography(st_transform(buildings.clipped_geom,4326)))))/(2*LOG(st_perimeter(geography(st_transform(buildings.clipped_geom,4326)))))) AS B_frac_std,SB_gid
 FROM building_removedOverlap_center_street_blocksl as buildings
 GROUP BY  SB_gid
  )  as Poly
WHERE street_blocksl.gid = Poly.SB_gid;


------- the Fractality distribution of individual buildings max
Alter table street_blocksl drop column if exists B_frac_max;
ALTER TABLE street_blocksl ADD COLUMN B_frac_max double precision DEFAULT 0.000;
UPDATE street_blocksl SET B_frac_max = Poly.B_frac_max 
FROM (
 SELECT max(1- (LOG(st_area(geography(st_transform(buildings.clipped_geom,4326)))))/(2*LOG(st_perimeter(geography(st_transform(buildings.clipped_geom,4326)))))) AS B_frac_max,SB_gid
 FROM building_removedOverlap_center_street_blocksl as buildings
 GROUP BY  SB_gid
  )  as Poly
WHERE street_blocksl.gid = Poly.SB_gid;


-------------------------------------------------------------------------------------------------------------------------------second round features

----- the distribution of building perimeters avg
Alter table street_blocksl drop column if exists b_perimeter_avg;
ALTER TABLE street_blocksl ADD COLUMN b_perimeter_avg double precision DEFAULT 0.000;
UPDATE street_blocksl SET b_perimeter_avg = Poly.b_perimeter_avg 
FROM (
 SELECT avg(st_perimeter(geography(st_transform(buildings.clipped_geom,4326)))) AS b_perimeter_avg,SB_gid
 FROM building_removedOverlap_center_street_blocksl as buildings
 GROUP BY  SB_gid
  )  as Poly
WHERE street_blocksl.gid = Poly.SB_gid;

----- the distribution of building perimeters std
Alter table street_blocksl drop column if exists b_perimeter_std;
ALTER TABLE street_blocksl ADD COLUMN b_perimeter_std double precision DEFAULT 0.000;
UPDATE street_blocksl SET b_perimeter_std = Poly.b_perimeter_std 
FROM (
 SELECT stddev(st_perimeter(geography(st_transform(buildings.clipped_geom,4326)))) AS b_perimeter_std,SB_gid
 FROM building_removedOverlap_center_street_blocksl as buildings
 GROUP BY  SB_gid
  )  as Poly
WHERE street_blocksl.gid = Poly.SB_gid;

----- the distribution of building perimeters max
Alter table street_blocksl drop column if exists b_perimeter_max;
ALTER TABLE street_blocksl ADD COLUMN b_perimeter_max double precision DEFAULT 0.000;
UPDATE street_blocksl SET b_perimeter_max = Poly.b_perimeter_max 
FROM (
 SELECT max(st_perimeter(geography(st_transform(buildings.clipped_geom,4326)))) AS b_perimeter_max,SB_gid
 FROM building_removedOverlap_center_street_blocksl as buildings
 GROUP BY  SB_gid
  )  as Poly
WHERE street_blocksl.gid = Poly.SB_gid;

----- the distribution of building perimeters min
Alter table street_blocksl drop column if exists b_perimeter_min;
ALTER TABLE street_blocksl ADD COLUMN b_perimeter_min double precision DEFAULT 0.000;
UPDATE street_blocksl SET b_perimeter_min = Poly.b_perimeter_min 
FROM (
 SELECT min(st_perimeter(geography(st_transform(buildings.clipped_geom,4326)))) AS b_perimeter_min,SB_gid
 FROM building_removedOverlap_center_street_blocksl as buildings
 GROUP BY  SB_gid
  )  as Poly
WHERE street_blocksl.gid = Poly.SB_gid;