Alter table moa drop column if exists moa_area_4326;
Alter table moa Add column moa_area_4326 double precision DEFAULT 0.000;
UPDATE moa SET moa_area_4326 = completenessPoly.SB_area 
FROM (
 SELECT st_area(geography(st_transform(moa.geom,4326))) as SB_area,moa.gid
 FROM moa
  )  as completenessPoly
WHERE moa.gid = completenessPoly.gid;

-------------------------------------------   perimeter
Alter table moa drop column if exists moa_perimeter;
Alter table moa Add column moa_perimeter double precision DEFAULT 0.000;
UPDATE moa SET moa_perimeter = completenessPoly.moa_perimeter 
FROM (
 SELECT ST_Perimeter(geography(st_transform(moa.geom,4326))) as moa_perimeter,moa.gid
 FROM moa
  )  as completenessPoly
WHERE moa.gid = completenessPoly.gid;

-------------------------------------------   fractality
Alter table moa drop column if exists moa_fractality;
Alter table moa Add column moa_fractality double precision DEFAULT 0.000;
UPDATE moa SET moa_fractality = 1- (LOG(moa_area_4326)/(2*LOG(moa_perimeter)));

-------- shape (compactness to circle)
Alter table moa drop column if exists moa_shape;
ALTER TABLE moa ADD COLUMN moa_shape double precision DEFAULT 0.000;
UPDATE moa SET moa_shape = moa_perimeter/sqrt(moa_area_4326);


VACUUM moa;


------------------------------------------- -------------------------------------------   enrich feature space

----------------- landscape metric
Alter table moa drop column if exists moa_B_ratio;
Alter table moa Add column moa_B_ratio double precision DEFAULT 0.000;
UPDATE moa SET moa_B_ratio = (b_area_sum/moa_area_4326);

-----------------   shape Reock 
Alter table moa drop column if exists reock;
Alter table moa Add column reock double precision DEFAULT 0.000;
UPDATE moa SET reock = (moa_area_4326/st_area(geography(st_transform(ST_MinimumBoundingCircle(moa.geom),4326))));


------------------   shape Convex 
Alter table moa drop column if exists convexhull;
Alter table moa Add column convexhull double precision DEFAULT 0.000;
UPDATE moa SET convexhull = (moa_area_4326/st_area(geography(st_transform(ST_ConvexHull(moa.geom),4326))));

