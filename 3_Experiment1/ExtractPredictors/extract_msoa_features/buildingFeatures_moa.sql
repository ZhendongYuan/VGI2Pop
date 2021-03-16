DROP TABLE IF EXISTS building_polygon_visiual; 
CREATE TABLE building_polygon_visiual as (
 SELECT *
 FROM 
	osm_160101_polygon
 WHERE
	osm_160101_polygon.building is not null
);


CREATE INDEX building_visiual_idx
  ON public.building_polygon_visiual
  USING gist
  (way);


  -- skip
 -- following code is the remove overlap and this is only for area calculation, need to pay attention to the morphologies process,
----------------------------------------------------------------------------------------------
 
CREATE INDEX building_polygon_pkey ON public.building_polygon_visiual(osm_id);
VACUUM building_polygon_visiual;
-- remove overlapping areas
UPDATE building_polygon_visiual a
 SET way = CASE
		 WHEN ST_IsEmpty(tmp.new_geom) IS true THEN NULL
		 WHEN ST_GeometryType(tmp.new_geom) = 'POLYGON' THEN ST_Multi(tmp.new_geom)
		 WHEN ST_GeometryType(tmp.new_geom) = 'MULTIPOLYGON' THEN tmp.new_geom
		 WHEN ST_GeometryType(tmp.new_geom) = 'LINESTRING' THEN NULL
		 ELSE ST_Multi(ST_CollectionExtract(tmp.new_geom, 3))
		END
FROM (
 SELECT
  a.osm_id, COALESCE(ST_Difference(a.way, ST_Union(b.way))) AS new_geom  -- may have some problem here, because i delete osmid
 FROM
  building_polygon_visiual a
 JOIN
  building_polygon_visiual b ON 
	ST_Within(b.way, a.way) OR 
	(ST_Overlaps(a.way, b.way) AND ST_Area(a.way) > ST_Area(b.way))
 WHERE
  a.osm_id != b.osm_id
 GROUP BY
  a.osm_id, a.way) tmp
WHERE
 tmp.osm_id = a.osm_id;
 --UPDATE 23397


DELETE FROM building_polygon_visiual WHERE way IS NULL; -- due to the overlapping removal empty geometries could be created. 
-- some checks:
SELECT count(*) FROM building_polygon_visiual WHERE ST_IsValid(way) IS false;
SELECT count(*) FROM building_polygon_visiual WHERE ST_IsEmpty(way) IS true;
VACUUM building_polygon_visiual;
-- 0-buffering to remove potential self-intersections caused by overlapping removing
UPDATE building_polygon_visiual
 SET way = ST_Multi(ST_Buffer(way, 0));
 ---UPDATE 1502872 

 -- change the name into building_polygon_removedOverlap
 DROP TABLE IF EXISTS building_polygon_removedOverlap; 
CREATE TABLE building_polygon_removedOverlap as (
	SELECT building_polygon_visiual.*
	FROM   building_polygon_visiual
);

---------------------------------------------- rerun for get original overlapped polygon
DROP TABLE IF EXISTS building_polygon_visiual; 
CREATE TABLE building_polygon_visiual as (
 SELECT *
 FROM 
	osm_160101_polygon
 WHERE
	osm_160101_polygon.building is not null
);

-- SELECT 1502907 
drop index if exists building_visiual_idx;
CREATE INDEX building_visiual_idx
  ON public.building_polygon_visiual
  USING gist
  (way);

-------------------------------------------- create clipped layer for this dataset 

CREATE INDEX building_polygon_removedOverlap_idx
  ON public.building_polygon_removedOverlap
  USING gist
  (way);
 

DROP TABLE IF EXISTS building_polygon_removedOverlap_clipped; 
CREATE TABLE building_polygon_removedOverlap_clipped as (
SELECT st_intersection(building_polygon_removedOverlap.way,moa.geom)AS clipped_geom,moa.gid as SB_gid,building_polygon_removedOverlap.*
 FROM building_polygon_removedOverlap
  INNER JOIN 
	moa 
  ON ST_Intersects(moa.geom,building_polygon_removedOverlap.way)
);

------------------------------------------------------------------------  statistic for each street blocks 
 ----------------------------------------------------------------------- calculate the sum of area based on clipped 
 
   Alter table moa drop column if exists building_area;
Alter table moa Add column building_area double precision DEFAULT 0.0;
UPDATE moa SET building_area = Poly.building_area 
FROM (
 SELECT sum(st_area(geography(st_transform(building_polygon_removedOverlap_clipped.clipped_geom,4326)))) AS building_area,SB_gid
 FROM building_polygon_removedOverlap_clipped
 GROUP BY  SB_gid
  )  as Poly
WHERE moa.gid = Poly.SB_gid;
--UPDATE 968 

----------------------------------------------------------------------  calculate the avg, std, max size for each buildings
-- the process of remove overlapped polygon may cause some problems.

--avg
Alter table moa drop column if exists building_avg_area;
ALTER TABLE moa ADD COLUMN building_avg_area double precision DEFAULT 0.000;
UPDATE moa SET building_avg_area = Poly.building_avg_area 
FROM (
 SELECT avg(st_area(geography(st_transform(building_polygon_removedOverlap_clipped.clipped_geom,4326)))) AS building_avg_area,SB_gid
 FROM building_polygon_removedOverlap_clipped
 GROUP BY  SB_gid
  )  as Poly
WHERE moa.gid = Poly.SB_gid;
-- UPDATE 968

-- std
Alter table moa drop column if exists building_stddev_area;
ALTER TABLE moa ADD COLUMN building_stddev_area double precision DEFAULT 0.000;
UPDATE moa SET building_stddev_area = Poly.building_stddev_area 
FROM (
 SELECT stddev(st_area(geography(st_transform(building_polygon_removedOverlap_clipped.clipped_geom,4326)))) AS building_stddev_area,SB_gid
 FROM building_polygon_removedOverlap_clipped
 GROUP BY  SB_gid
  )  as Poly
WHERE moa.gid = Poly.SB_gid;
-- UPDATE 968

-- max
Alter table moa drop column if exists building_max_area;
ALTER TABLE moa ADD COLUMN building_max_area double precision DEFAULT 0.000;
UPDATE moa SET building_max_area = Poly.building_max_area 
FROM (
 SELECT max(st_area(geography(st_transform(building_polygon_removedOverlap_clipped.clipped_geom,4326)))) AS building_max_area,SB_gid
 FROM building_polygon_removedOverlap_clipped
 GROUP BY  SB_gid
  )  as Poly
WHERE moa.gid = Poly.SB_gid;

-----------  count the number of building inside
Alter table moa drop column if exists building_number;
ALTER TABLE moa ADD COLUMN building_number double precision DEFAULT 0.000;
UPDATE moa SET building_number = Poly.building_number 
FROM (
 SELECT COUNT(osm_id) AS building_number,SB_gid
 FROM building_polygon_removedOverlap_clipped
 GROUP BY  SB_gid
  )  as Poly
WHERE moa.gid = Poly.SB_gid;

-------- the shape distribution of individual buildings  avg 
Alter table moa drop column if exists building_avg_shape;
ALTER TABLE moa ADD COLUMN building_avg_shape double precision DEFAULT 0.000;
UPDATE moa SET building_avg_shape = Poly.building_avg_shape 
FROM (
 SELECT avg(st_perimeter(geography(st_transform(buildings.clipped_geom,4326)))/sqrt(st_area(geography(st_transform(buildings.clipped_geom,4326))))) AS building_avg_shape,SB_gid
 FROM building_polygon_removedOverlap_clipped as buildings
 GROUP BY  SB_gid
  )  as Poly
WHERE moa.gid = Poly.SB_gid;


-------- the shape distribution of individual buildings std
Alter table moa drop column if exists building_stddev_shape;
ALTER TABLE moa ADD COLUMN building_stddev_shape double precision DEFAULT 0.000;
UPDATE moa SET building_stddev_shape = Poly.building_stddev_shape 
FROM (
 SELECT stddev(st_perimeter(geography(st_transform(buildings.clipped_geom,4326)))/sqrt(st_area(geography(st_transform(buildings.clipped_geom,4326))))) AS building_stddev_shape,SB_gid
 FROM building_polygon_removedOverlap_clipped as buildings
 GROUP BY  SB_gid
  )  as Poly
WHERE moa.gid = Poly.SB_gid;

------- the shape distribution of individual buildings max
Alter table moa drop column if exists building_max_shape;
ALTER TABLE moa ADD COLUMN building_max_shape double precision DEFAULT 0.000;
UPDATE moa SET building_max_shape = Poly.building_max_shape 
FROM (
 SELECT max(st_perimeter(geography(st_transform(buildings.clipped_geom,4326)))/sqrt(st_area(geography(st_transform(buildings.clipped_geom,4326))))) AS building_max_shape,SB_gid
 FROM building_polygon_removedOverlap_clipped as buildings
 GROUP BY  SB_gid
  )  as Poly
WHERE moa.gid = Poly.SB_gid;

-------- the Fractality distribution of individual buildings  avg 
--fractality = 1- (LOG(sb_area_4326)/(2*LOG(perimeter)))
Alter table moa drop column if exists building_avg_fractality;
ALTER TABLE moa ADD COLUMN building_avg_fractality double precision DEFAULT 0.000;
UPDATE moa SET building_avg_fractality = Poly.building_avg_fractality 
FROM (
 SELECT avg(1- (LOG(st_area(geography(st_transform(buildings.clipped_geom,4326)))))/(2*LOG(st_perimeter(geography(st_transform(buildings.clipped_geom,4326)))))) AS building_avg_fractality,SB_gid
 FROM building_polygon_removedOverlap_clipped as buildings
 GROUP BY  SB_gid
  )  as Poly
WHERE moa.gid = Poly.SB_gid;


-------- the Fractality distribution of individual buildings std
Alter table moa drop column if exists building_stddev_fractality;
ALTER TABLE moa ADD COLUMN building_stddev_fractality double precision DEFAULT 0.000;
UPDATE moa SET building_stddev_fractality = Poly.building_stddev_fractality 
FROM (
 SELECT stddev(1- (LOG(st_area(geography(st_transform(buildings.clipped_geom,4326)))))/(2*LOG(st_perimeter(geography(st_transform(buildings.clipped_geom,4326)))))) AS building_stddev_fractality,SB_gid
 FROM building_polygon_removedOverlap_clipped as buildings
 GROUP BY  SB_gid
  )  as Poly
WHERE moa.gid = Poly.SB_gid;


------- the Fractality distribution of individual buildings max
Alter table moa drop column if exists building_max_fractality;
ALTER TABLE moa ADD COLUMN building_max_fractality double precision DEFAULT 0.000;
UPDATE moa SET building_max_fractality = Poly.building_max_fractality 
FROM (
 SELECT max(1- (LOG(st_area(geography(st_transform(buildings.clipped_geom,4326)))))/(2*LOG(st_perimeter(geography(st_transform(buildings.clipped_geom,4326)))))) AS building_max_fractality,SB_gid
 FROM building_polygon_removedOverlap_clipped as buildings
 GROUP BY  SB_gid
  )  as Poly
WHERE moa.gid = Poly.SB_gid;


----- enrich feature space

------------------------------------------- -------------------------------------------  -------------------------------------------  enrich feature space
----- the distribution of building perimeters avg
Alter table moa drop column if exists b_perimeter_avg;
ALTER TABLE moa ADD COLUMN b_perimeter_avg double precision DEFAULT 0.000;
UPDATE moa SET b_perimeter_avg = Poly.b_perimeter_avg 
FROM (
 SELECT avg(st_perimeter(geography(st_transform(buildings.clipped_geom,4326)))) AS b_perimeter_avg,SB_gid
 FROM building_polygon_removedOverlap_clipped as buildings
 GROUP BY  SB_gid
  )  as Poly
WHERE moa.gid = Poly.SB_gid;

----- the distribution of building perimeters std
Alter table moa drop column if exists b_perimeter_std;
ALTER TABLE moa ADD COLUMN b_perimeter_std double precision DEFAULT 0.000;
UPDATE moa SET b_perimeter_std = Poly.b_perimeter_std 
FROM (
 SELECT stddev(st_perimeter(geography(st_transform(buildings.clipped_geom,4326)))) AS b_perimeter_std,SB_gid
 FROM building_polygon_removedOverlap_clipped as buildings
 GROUP BY  SB_gid
  )  as Poly
WHERE moa.gid = Poly.SB_gid;

----- the distribution of building perimeters max
Alter table moa drop column if exists b_perimeter_max;
ALTER TABLE moa ADD COLUMN b_perimeter_max double precision DEFAULT 0.000;
UPDATE moa SET b_perimeter_max = Poly.b_perimeter_max 
FROM (
 SELECT max(st_perimeter(geography(st_transform(buildings.clipped_geom,4326)))) AS b_perimeter_max,SB_gid
 FROM building_polygon_removedOverlap_clipped as buildings
 GROUP BY  SB_gid
  )  as Poly
WHERE moa.gid = Poly.SB_gid;

----- the distribution of building perimeters min
Alter table moa drop column if exists b_perimeter_min;
ALTER TABLE moa ADD COLUMN b_perimeter_min double precision DEFAULT 0.000;
UPDATE moa SET b_perimeter_min = Poly.b_perimeter_min 
FROM (
 SELECT min(st_perimeter(geography(st_transform(buildings.clipped_geom,4326)))) AS b_perimeter_min,SB_gid
 FROM building_polygon_removedOverlap_clipped as buildings
 GROUP BY  SB_gid
  )  as Poly
WHERE moa.gid = Poly.SB_gid;


------ Elognation 
-- length-width ratio of the building SBR  the width defined as the shortest distance from the centerid to the polygon and the length defined as the area/width
-- width
Alter table building_orientation_moa drop column if exists width_re;
ALTER TABLE building_orientation_moa ADD COLUMN width_re double precision DEFAULT 0.000;
UPDATE building_orientation_moa SET width_re = Poly.width_re 
FROM (
 SELECT 2*st_length(geography(st_transform(shortline.shortestline,4326))) AS width_re,osm_id
 FROM building_orientation_moa_shortest as shortline
  )  as Poly
WHERE building_orientation_moa.osm_id = Poly.osm_id;

-- length
Alter table building_orientation_moa drop column if exists length_re;
Alter table building_orientation_moa Add column length_re double precision DEFAULT 0.000;
UPDATE building_orientation_moa SET length_re = 
 (CASE 
		WHEN (width_re > 0) THEN (st_area(geography(st_transform(oe_geom,4326)))/width_re)
		ELSE 0 
	End );
----  Elognation
Alter table building_orientation_moa drop column if exists Elognation;
Alter table building_orientation_moa Add column Elognation double precision DEFAULT 0.000;
UPDATE building_orientation_moa SET Elognation = 
 (CASE 
		WHEN (width_re > 0) THEN (length_re/width_re)
		ELSE 0 
	End );

----  Elognation avg
Alter table moa drop column if exists Elognation_avg;
Alter table moa Add column Elognation_avg double precision DEFAULT 0.000;
UPDATE moa SET Elognation_avg = Poly.Elognation_avg 
FROM (
 SELECT moa_id,avg(Elognation) AS Elognation_avg
	from building_orientation_moa as building
	group by moa_id
  )  as Poly
WHERE moa.gid = Poly.moa_id;

----  Elognation std
Alter table moa drop column if exists Elognation_std;
Alter table moa Add column Elognation_std double precision DEFAULT 0.000;
UPDATE moa SET Elognation_std = Poly.Elognation_std 
FROM (
 SELECT moa_id,stddev(Elognation) AS Elognation_std
	from building_orientation_moa as building
	group by moa_id
  )  as Poly
WHERE moa.gid = Poly.moa_id;


----  Elognation max
Alter table moa drop column if exists Elognation_max;
Alter table moa Add column Elognation_max double precision DEFAULT 0.000;
UPDATE moa SET Elognation_max = Poly.Elognation_max 
FROM (
 SELECT moa_id,max(Elognation) AS Elognation_max
	from building_orientation_moa as building
	group by moa_id
  )  as Poly
WHERE moa.gid = Poly.moa_id;

----  Elognation min
Alter table moa drop column if exists Elognation_min;
Alter table moa Add column Elognation_min double precision DEFAULT 0.000;
UPDATE moa SET Elognation_min = Poly.Elognation_min 
FROM (
 SELECT moa_id,min(Elognation) AS Elognation_min
	from building_orientation_moa as building
	group by moa_id
  )  as Poly
WHERE moa.gid = Poly.moa_id;

----------------------------------