DROP TABLE IF EXISTS building_polygon_removedOverlap_clipped_loa; 
CREATE TABLE building_polygon_removedOverlap_clipped_loa as (
SELECT st_intersection(building_polygon_removedOverlap.way,loa.geom)AS clipped_geom,loa.gid as SB_gid,building_polygon_removedOverlap.*
 FROM building_polygon_removedOverlap
  INNER JOIN 
	loa 
  ON ST_Intersects(loa.geom,building_polygon_removedOverlap.way)
);

------------------------------------------------------------------------  statistic for each street blocks 
 ----------------------------------------------------------------------- calculate the sum of area based on clipped 
 
   Alter table loa drop column if exists building_area;
Alter table loa Add column building_area double precision DEFAULT 0.0;
UPDATE loa SET building_area = Poly.building_area 
FROM (
 SELECT sum(st_area(geography(st_transform(building_polygon_removedOverlap_clipped_loa.clipped_geom,4326)))) AS building_area,SB_gid
 FROM building_polygon_removedOverlap_clipped_loa
 GROUP BY  SB_gid
  )  as Poly
WHERE loa.gid = Poly.SB_gid;
--UPDATE 968 

----------------------------------------------------------------------  calculate the avg, std, max size for each buildings
-- the process of remove overlapped polygon may cause some problems.

--avg
Alter table loa drop column if exists building_avg_area;
ALTER TABLE loa ADD COLUMN building_avg_area double precision DEFAULT 0.000;
UPDATE loa SET building_avg_area = Poly.building_avg_area 
FROM (
 SELECT avg(st_area(geography(st_transform(building_polygon_removedOverlap_clipped_loa.clipped_geom,4326)))) AS building_avg_area,SB_gid
 FROM building_polygon_removedOverlap_clipped_loa
 GROUP BY  SB_gid
  )  as Poly
WHERE loa.gid = Poly.SB_gid;
-- UPDATE 968

-- std
Alter table loa drop column if exists building_stddev_area;
ALTER TABLE loa ADD COLUMN building_stddev_area double precision DEFAULT 0.000;
UPDATE loa SET building_stddev_area = Poly.building_stddev_area 
FROM (
 SELECT stddev(st_area(geography(st_transform(building_polygon_removedOverlap_clipped_loa.clipped_geom,4326)))) AS building_stddev_area,SB_gid
 FROM building_polygon_removedOverlap_clipped_loa
 GROUP BY  SB_gid
  )  as Poly
WHERE loa.gid = Poly.SB_gid;
-- UPDATE 968

-- max
Alter table loa drop column if exists building_max_area;
ALTER TABLE loa ADD COLUMN building_max_area double precision DEFAULT 0.000;
UPDATE loa SET building_max_area = Poly.building_max_area 
FROM (
 SELECT max(st_area(geography(st_transform(building_polygon_removedOverlap_clipped_loa.clipped_geom,4326)))) AS building_max_area,SB_gid
 FROM building_polygon_removedOverlap_clipped_loa
 GROUP BY  SB_gid
  )  as Poly
WHERE loa.gid = Poly.SB_gid;

-----------  count the number of building inside
Alter table loa drop column if exists building_number;
ALTER TABLE loa ADD COLUMN building_number double precision DEFAULT 0.000;
UPDATE loa SET building_number = Poly.building_number 
FROM (
 SELECT COUNT(osm_id) AS building_number,SB_gid
 FROM building_polygon_removedOverlap_clipped_loa
 GROUP BY  SB_gid
  )  as Poly
WHERE loa.gid = Poly.SB_gid;

-------- the shape distribution of individual buildings  avg 
Alter table loa drop column if exists building_avg_shape;
ALTER TABLE loa ADD COLUMN building_avg_shape double precision DEFAULT 0.000;
UPDATE loa SET building_avg_shape = Poly.building_avg_shape 
FROM (
 SELECT avg(st_perimeter(geography(st_transform(buildings.clipped_geom,4326)))/sqrt(st_area(geography(st_transform(buildings.clipped_geom,4326))))) AS building_avg_shape,SB_gid
 FROM building_polygon_removedOverlap_clipped_loa as buildings
 GROUP BY  SB_gid
  )  as Poly
WHERE loa.gid = Poly.SB_gid;


-------- the shape distribution of individual buildings std
Alter table loa drop column if exists building_stddev_shape;
ALTER TABLE loa ADD COLUMN building_stddev_shape double precision DEFAULT 0.000;
UPDATE loa SET building_stddev_shape = Poly.building_stddev_shape 
FROM (
 SELECT stddev(st_perimeter(geography(st_transform(buildings.clipped_geom,4326)))/sqrt(st_area(geography(st_transform(buildings.clipped_geom,4326))))) AS building_stddev_shape,SB_gid
 FROM building_polygon_removedOverlap_clipped_loa as buildings
 GROUP BY  SB_gid
  )  as Poly
WHERE loa.gid = Poly.SB_gid;

------- the shape distribution of individual buildings max
Alter table loa drop column if exists building_max_shape;
ALTER TABLE loa ADD COLUMN building_max_shape double precision DEFAULT 0.000;
UPDATE loa SET building_max_shape = Poly.building_max_shape 
FROM (
 SELECT max(st_perimeter(geography(st_transform(buildings.clipped_geom,4326)))/sqrt(st_area(geography(st_transform(buildings.clipped_geom,4326))))) AS building_max_shape,SB_gid
 FROM building_polygon_removedOverlap_clipped_loa as buildings
 GROUP BY  SB_gid
  )  as Poly
WHERE loa.gid = Poly.SB_gid;

-------- the Fractality distribution of individual buildings  avg 
--fractality = 1- (LOG(sb_area_4326)/(2*LOG(perimeter)))
Alter table loa drop column if exists building_avg_fractality;
ALTER TABLE loa ADD COLUMN building_avg_fractality double precision DEFAULT 0.000;
UPDATE loa SET building_avg_fractality = Poly.building_avg_fractality 
FROM (
 SELECT avg(1- (LOG(st_area(geography(st_transform(buildings.clipped_geom,4326)))))/(2*LOG(st_perimeter(geography(st_transform(buildings.clipped_geom,4326)))))) AS building_avg_fractality,SB_gid
 FROM building_polygon_removedOverlap_clipped_loa as buildings
 GROUP BY  SB_gid
  )  as Poly
WHERE loa.gid = Poly.SB_gid;


-------- the Fractality distribution of individual buildings std
Alter table loa drop column if exists building_stddev_fractality;
ALTER TABLE loa ADD COLUMN building_stddev_fractality double precision DEFAULT 0.000;
UPDATE loa SET building_stddev_fractality = Poly.building_stddev_fractality 
FROM (
 SELECT stddev(1- (LOG(st_area(geography(st_transform(buildings.clipped_geom,4326)))))/(2*LOG(st_perimeter(geography(st_transform(buildings.clipped_geom,4326)))))) AS building_stddev_fractality,SB_gid
 FROM building_polygon_removedOverlap_clipped_loa as buildings
 GROUP BY  SB_gid
  )  as Poly
WHERE loa.gid = Poly.SB_gid;


------- the Fractality distribution of individual buildings max
Alter table loa drop column if exists building_max_fractality;
ALTER TABLE loa ADD COLUMN building_max_fractality double precision DEFAULT 0.000;
UPDATE loa SET building_max_fractality = Poly.building_max_fractality 
FROM (
 SELECT max(1- (LOG(st_area(geography(st_transform(buildings.clipped_geom,4326)))))/(2*LOG(st_perimeter(geography(st_transform(buildings.clipped_geom,4326)))))) AS building_max_fractality,SB_gid
 FROM building_polygon_removedOverlap_clipped_loa as buildings
 GROUP BY  SB_gid
  )  as Poly
WHERE loa.gid = Poly.SB_gid;

-------------------------------------------------------------------------------------------------------------------------------second round features
----- the distribution of building perimeters avg
Alter table loa drop column if exists b_perimeter_avg;
ALTER TABLE loa ADD COLUMN b_perimeter_avg double precision DEFAULT 0.000;
UPDATE loa SET b_perimeter_avg = Poly.b_perimeter_avg 
FROM (
 SELECT avg(st_perimeter(geography(st_transform(buildings.clipped_geom,4326)))) AS b_perimeter_avg,SB_gid
 FROM building_polygon_removedOverlap_clipped_loa as buildings
 GROUP BY  SB_gid
  )  as Poly
WHERE loa.gid = Poly.SB_gid;

----- the distribution of building perimeters std
Alter table loa drop column if exists b_perimeter_std;
ALTER TABLE loa ADD COLUMN b_perimeter_std double precision DEFAULT 0.000;
UPDATE loa SET b_perimeter_std = Poly.b_perimeter_std 
FROM (
 SELECT stddev(st_perimeter(geography(st_transform(buildings.clipped_geom,4326)))) AS b_perimeter_std,SB_gid
 FROM building_polygon_removedOverlap_clipped_loa as buildings
 GROUP BY  SB_gid
  )  as Poly
WHERE loa.gid = Poly.SB_gid;

----- the distribution of building perimeters max
Alter table loa drop column if exists b_perimeter_max;
ALTER TABLE loa ADD COLUMN b_perimeter_max double precision DEFAULT 0.000;
UPDATE loa SET b_perimeter_max = Poly.b_perimeter_max 
FROM (
 SELECT max(st_perimeter(geography(st_transform(buildings.clipped_geom,4326)))) AS b_perimeter_max,SB_gid
 FROM building_polygon_removedOverlap_clipped_loa as buildings
 GROUP BY  SB_gid
  )  as Poly
WHERE loa.gid = Poly.SB_gid;

----- the distribution of building perimeters min
Alter table loa drop column if exists b_perimeter_min;
ALTER TABLE loa ADD COLUMN b_perimeter_min double precision DEFAULT 0.000;
UPDATE loa SET b_perimeter_min = Poly.b_perimeter_min 
FROM (
 SELECT min(st_perimeter(geography(st_transform(buildings.clipped_geom,4326)))) AS b_perimeter_min,SB_gid
 FROM building_polygon_removedOverlap_clipped_loa as buildings
 GROUP BY  SB_gid
  )  as Poly
WHERE loa.gid = Poly.SB_gid;


------ Elognation 
-- length-width ratio of the building SBR  the width defined as the shortest distance from the centerid to the polygon and the length defined as the area/width
-- width
Alter table building_orientation_loa drop column if exists width_re;
ALTER TABLE building_orientation_loa ADD COLUMN width_re double precision DEFAULT 0.000;
UPDATE building_orientation_loa SET width_re = Poly.width_re 
FROM (
 SELECT 2*st_length(geography(st_transform(shortline.shortestline,4326))) AS width_re,osm_id
 FROM building_orientation_loa_shortest as shortline
  )  as Poly
WHERE building_orientation_loa.osm_id = Poly.osm_id;

-- length
Alter table building_orientation_loa drop column if exists length_re;
Alter table building_orientation_loa Add column length_re double precision DEFAULT 0.000;
UPDATE building_orientation_loa SET length_re = 
 (CASE 
		WHEN (width_re > 0) THEN (st_area(geography(st_transform(oe_geom,4326)))/width_re)
		ELSE 0 
	End );
----  Elognation
Alter table building_orientation_loa drop column if exists Elognation;
Alter table building_orientation_loa Add column Elognation double precision DEFAULT 0.000;
UPDATE building_orientation_loa SET Elognation = 
 (CASE 
		WHEN (width_re > 0) THEN (length_re/width_re)
		ELSE 0 
	End );

----  Elognation avg
Alter table loa drop column if exists Elognation_avg;
Alter table loa Add column Elognation_avg double precision DEFAULT 0.000;
UPDATE loa SET Elognation_avg = Poly.Elognation_avg 
FROM (
 SELECT loa_id,avg(Elognation) AS Elognation_avg
	from building_orientation_loa as building
	group by loa_id
  )  as Poly
WHERE loa.gid = Poly.loa_id;

----  Elognation std
Alter table loa drop column if exists Elognation_std;
Alter table loa Add column Elognation_std double precision DEFAULT 0.000;
UPDATE loa SET Elognation_std = Poly.Elognation_std 
FROM (
 SELECT loa_id,stddev(Elognation) AS Elognation_std
	from building_orientation_loa as building
	group by loa_id
  )  as Poly
WHERE loa.gid = Poly.loa_id;


----  Elognation max
Alter table loa drop column if exists Elognation_max;
Alter table loa Add column Elognation_max double precision DEFAULT 0.000;
UPDATE loa SET Elognation_max = Poly.Elognation_max 
FROM (
 SELECT loa_id,max(Elognation) AS Elognation_max
	from building_orientation_loa as building
	group by loa_id
  )  as Poly
WHERE loa.gid = Poly.loa_id;

----  Elognation min
Alter table loa drop column if exists Elognation_min;
Alter table loa Add column Elognation_min double precision DEFAULT 0.000;
UPDATE loa SET Elognation_min = Poly.Elognation_min 
FROM (
 SELECT loa_id,min(Elognation) AS Elognation_min
	from building_orientation_loa as building
	group by loa_id
  )  as Poly
WHERE loa.gid = Poly.loa_id;
-- UPDATE 4010
