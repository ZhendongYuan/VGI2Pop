-------------------------------------------- area
Alter table street_blocksl drop column if exists SB_area;
Alter table street_blocksl Add column SB_area double precision DEFAULT 0.0;
UPDATE street_blocksl SET SB_area = completenessPoly.SB_area 
FROM (
 SELECT st_area(geography(st_transform(street_blocksl.the_geom,4326))) as SB_area,street_blocksl.gid
 FROM street_blocksl
  )  as completenessPoly
WHERE street_blocksl.gid = completenessPoly.gid;

-------------------------------------------   perimeter
Alter table street_blocksl drop column if exists SB_perimeter;
Alter table street_blocksl Add column SB_perimeter double precision DEFAULT 0.0;
UPDATE street_blocksl SET SB_perimeter = completenessPoly.SB_perimeter 
FROM (
 SELECT ST_Perimeter(geography(st_transform(street_blocksl.the_geom,4326))) as SB_perimeter,street_blocksl.gid
 FROM street_blocksl
  )  as completenessPoly
WHERE street_blocksl.gid = completenessPoly.gid;

-------------------------------------------   fractality
Alter table street_blocksl drop column if exists SB_fractality;
Alter table street_blocksl Add column SB_fractality double precision DEFAULT 0.000;
UPDATE street_blocksl SET SB_fractality = 1- (LOG(SB_area)/(2*LOG(SB_perimeter)));

-------- shape (compactness to circle)
Alter table street_blocksl drop column if exists SB_shape;
ALTER TABLE street_blocksl ADD COLUMN SB_shape double precision DEFAULT 0.000;
UPDATE street_blocksl SET SB_shape = SB_perimeter/sqrt(SB_area);

------ create index 
Drop index if exists street_blocksl_geom_index;
CREATE INDEX street_blocksl_geom_index ON public.street_blocksl  USING gist  (the_geom);

Drop index if exists street_blocksl_gid_index;
CREATE INDEX street_blocksl_gid_index ON public.street_blocksl (gid);
VACUUM street_blocksl;


-------------------------------------------   rebuild loa_id  need to re-run this again.
----------   all version 
-- originally have 23397

Alter table street_blocksl drop column if exists loa_id;
Alter table street_blocksl drop column if exists lsoa11cd;
Alter table street_blocksl Add column lsoa11cd character(100);
UPDATE street_blocksl SET lsoa11cd = completenessPoly.lsoa11cd 
FROM (
 SELECT centertable.gid as sbc_gid,loa.lsoa11cd as lsoa11cd
 FROM (SELECT ST_PointOnSurface(street_blocksl.the_geom) AS centre_geom,gid
 FROM street_blocksl) as centertable
  INNER JOIN 
	loa
  ON ST_Intersects(loa.geom,centertable.centre_geom)
  )  as completenessPoly
WHERE street_blocksl.gid = completenessPoly.sbc_gid;

-- UPDATE 64070
DROP TABLE IF EXISTS street_blocksl_withinloa; 
CREATE TABLE street_blocksl_withinloa as (
SELECT street_blocksl.*
 FROM street_blocksl
 where street_blocksl.lsoa11cd IS NOT NULL
);

-- UPDATE 64070


------------------------------------------- -------------------------------------------  ------------------------------------------- enrich feature space
----------------- landscape metric
Alter table street_blocksl_withinloa drop column if exists sb_B_ratio;
Alter table street_blocksl_withinloa Add column sb_B_ratio double precision DEFAULT 0.000;
UPDATE street_blocksl_withinloa SET sb_B_ratio = (b_area_sum/sb_area);