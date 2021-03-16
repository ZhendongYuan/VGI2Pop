Alter table loa drop column if exists loa_area_4326;
Alter table loa Add column loa_area_4326 double precision DEFAULT 0.0;
UPDATE loa SET loa_area_4326 = completenessPoly.SB_area 
FROM (
 SELECT st_area(geography(st_transform(loa.geom,4326))) as SB_area,loa.gid
 FROM loa
  )  as completenessPoly
WHERE loa.gid = completenessPoly.gid;

-------------------------------------------   perimeter
Alter table loa drop column if exists loa_perimeter;
Alter table loa Add column loa_perimeter double precision DEFAULT 0.0;
UPDATE loa SET loa_perimeter = completenessPoly.loa_perimeter 
FROM (
 SELECT ST_Perimeter(geography(st_transform(loa.geom,4326))) as loa_perimeter,loa.gid
 FROM loa
  )  as completenessPoly
WHERE loa.gid = completenessPoly.gid;

-------------------------------------------   fractality
Alter table loa drop column if exists loa_fractality;
Alter table loa Add column loa_fractality double precision DEFAULT 0.00000;
UPDATE loa SET loa_fractality = 1- (LOG(loa_area_4326)/(2*LOG(loa_perimeter)));

-------- shape (compactness to circle)
Alter table loa drop column if exists loa_shape;
ALTER TABLE loa ADD COLUMN loa_shape double precision DEFAULT 0.000;
UPDATE loa SET loa_shape = loa_perimeter/sqrt(loa_area_4326);

VACUUM loa;


------------------------------------------- -------------------------------------------   enrich feature space

----------------- landscape metric
Alter table loa drop column if exists loa_B_ratio;
Alter table loa Add column loa_B_ratio double precision DEFAULT 0.000;
UPDATE loa SET loa_B_ratio = (b_area_sum/loa_area_4326);

-----------------   shape Reock 
Alter table loa drop column if exists reock;
Alter table loa Add column reock double precision DEFAULT 0.000;
UPDATE loa SET reock = (loa_area_4326/st_area(geography(st_transform(ST_MinimumBoundingCircle(loa.geom),4326))));


------------------   shape Convex 
Alter table loa drop column if exists convexhull;
Alter table loa Add column convexhull double precision DEFAULT 0.000;
UPDATE loa SET convexhull = (loa_area_4326/st_area(geography(st_transform(ST_ConvexHull(loa.geom),4326))));