-- enrich 
-------------------------------------------------------------------------------------------------------------------------------second round features

----- the distribution of building perimeters avg
Alter table street_blocksl_withinloa drop column if exists b_perimeter_avg;
ALTER TABLE street_blocksl_withinloa ADD COLUMN b_perimeter_avg double precision DEFAULT 0.000;
UPDATE street_blocksl_withinloa SET b_perimeter_avg = Poly.b_perimeter_avg 
FROM (
 SELECT avg(st_perimeter(geography(st_transform(buildings.clipped_geom,4326)))) AS b_perimeter_avg,SB_gid
 FROM building_removedOverlap_center_street_blocks as buildings
 GROUP BY  SB_gid
  )  as Poly
WHERE street_blocksl_withinloa.gid = Poly.SB_gid;

----- the distribution of building perimeters std
Alter table street_blocksl_withinloa drop column if exists b_perimeter_std;
ALTER TABLE street_blocksl_withinloa ADD COLUMN b_perimeter_std double precision DEFAULT 0.000;
UPDATE street_blocksl_withinloa SET b_perimeter_std = Poly.b_perimeter_std 
FROM (
 SELECT stddev(st_perimeter(geography(st_transform(buildings.clipped_geom,4326)))) AS b_perimeter_std,SB_gid
 FROM building_removedOverlap_center_street_blocks as buildings
 GROUP BY  SB_gid
  )  as Poly
WHERE street_blocksl_withinloa.gid = Poly.SB_gid;

----- the distribution of building perimeters max
Alter table street_blocksl_withinloa drop column if exists b_perimeter_max;
ALTER TABLE street_blocksl_withinloa ADD COLUMN b_perimeter_max double precision DEFAULT 0.000;
UPDATE street_blocksl_withinloa SET b_perimeter_max = Poly.b_perimeter_max 
FROM (
 SELECT max(st_perimeter(geography(st_transform(buildings.clipped_geom,4326)))) AS b_perimeter_max,SB_gid
 FROM building_removedOverlap_center_street_blocks as buildings
 GROUP BY  SB_gid
  )  as Poly
WHERE street_blocksl_withinloa.gid = Poly.SB_gid;

----- the distribution of building perimeters min
Alter table street_blocksl_withinloa drop column if exists b_perimeter_min;
ALTER TABLE street_blocksl_withinloa ADD COLUMN b_perimeter_min double precision DEFAULT 0.000;
UPDATE street_blocksl_withinloa SET b_perimeter_min = Poly.b_perimeter_min 
FROM (
 SELECT min(st_perimeter(geography(st_transform(buildings.clipped_geom,4326)))) AS b_perimeter_min,SB_gid
 FROM building_removedOverlap_center_street_blocks as buildings
 GROUP BY  SB_gid
  )  as Poly
WHERE street_blocksl_withinloa.gid = Poly.SB_gid;



------ Elognation 
-- length-width ratio of the building SBR  the width defined as the shortest distance from the centerid to the polygon and the length defined as the area/width
-- width
Alter table building_orientation_sbl drop column if exists width_re;
ALTER TABLE building_orientation_sbl ADD COLUMN width_re double precision DEFAULT 0.000;
UPDATE building_orientation_sbl SET width_re = Poly.width_re 
FROM (
 SELECT 2*st_length(geography(st_transform(shortline.shortestline,4326))) AS width_re,osm_id
 FROM building_orientation_sbl_shortest as shortline
  )  as Poly
WHERE building_orientation_sbl.osm_id = Poly.osm_id;

-- length
Alter table building_orientation_sbl drop column if exists length_re;
Alter table building_orientation_sbl Add column length_re double precision DEFAULT 0.000;
UPDATE building_orientation_sbl SET length_re = 
 (CASE 
		WHEN (width_re > 0) THEN (st_area(geography(st_transform(oe_geom,4326)))/width_re)
		ELSE 0 
	End );
----  Elognation
Alter table building_orientation_sbl drop column if exists Elognation;
Alter table building_orientation_sbl Add column Elognation double precision DEFAULT 0.000;
UPDATE building_orientation_sbl SET Elognation = 
 (CASE 
		WHEN (width_re > 0) THEN (length_re/width_re)
		ELSE 0 
	End );

----  Elognation avg
Alter table street_blocksl_withinloa drop column if exists Elognation_avg;
Alter table street_blocksl_withinloa Add column Elognation_avg double precision DEFAULT 0.000;
UPDATE street_blocksl_withinloa SET Elognation_avg = Poly.Elognation_avg 
FROM (
 SELECT sb_id,avg(Elognation) AS Elognation_avg
	from building_orientation_sbl as building
	group by sb_id
  )  as Poly
WHERE street_blocksl_withinloa.gid = Poly.sb_id;

----  Elognation std
Alter table street_blocksl_withinloa drop column if exists Elognation_std;
Alter table street_blocksl_withinloa Add column Elognation_std double precision DEFAULT 0.000;
UPDATE street_blocksl_withinloa SET Elognation_std = Poly.Elognation_std 
FROM (
 SELECT sb_id,stddev(Elognation) AS Elognation_std
	from building_orientation_sbl as building
	group by sb_id
  )  as Poly
WHERE street_blocksl_withinloa.gid = Poly.sb_id;


----  Elognation max
Alter table street_blocksl_withinloa drop column if exists Elognation_max;
Alter table street_blocksl_withinloa Add column Elognation_max double precision DEFAULT 0.000;
UPDATE street_blocksl_withinloa SET Elognation_max = Poly.Elognation_max 
FROM (
 SELECT sb_id,max(Elognation) AS Elognation_max
	from building_orientation_sbl as building
	group by sb_id
  )  as Poly
WHERE street_blocksl_withinloa.gid = Poly.sb_id;

----  Elognation min
Alter table street_blocksl_withinloa drop column if exists Elognation_min;
Alter table street_blocksl_withinloa Add column Elognation_min double precision DEFAULT 0.000;
UPDATE street_blocksl_withinloa SET Elognation_min = Poly.Elognation_min 
FROM (
 SELECT sb_id,min(Elognation) AS Elognation_min
	from building_orientation_sbl as building
	group by sb_id
  )  as Poly
WHERE street_blocksl_withinloa.gid = Poly.sb_id;

----------------------------------