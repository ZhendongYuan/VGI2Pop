 -- get the distinct value of class
select COUNT(*) as distin_class_number, item2012
from (
	SELECT item2012
	 FROM lulc_london) as foo
group by item2012
ORDER BY distin_class_number DESC;

select COUNT(*) as distin_class_number, adj_classname
from (
	SELECT adj_classname
	 FROM lulc_london) as foo
group by adj_classname
ORDER BY distin_class_number DESC;

-- adjust the class
DROP TABLE IF EXISTS lulc_london_3857; 
CREATE TABLE lulc_london_3857 as (
 SELECT gid,code2012,item2012, st_makevalid(st_transform(geom,3857)) as geom
 FROM 
	lulc_london
);



-----   calculate the area ratio for moa
DROP TABLE IF EXISTS lulc_london_ulb; 
CREATE TABLE lulc_london_ulb as (
select  moa.gid as moa_gid, st_area(geography(st_transform(moa.geom,4326))) as moa_area_4326,st_intersection(moa.geom,lulc_london_3857.geom) as geom,lulc_london_3857.gid as lulc_gid, lulc_london_3857.item2012 as class_name,MSOA11CD
from moa,lulc_london_3857
where st_intersects(moa.geom,lulc_london_3857.geom)
);
 ALTER TABLE lulc_london_ulb ADD COLUMN lulc_obj_gid SERIAL PRIMARY KEY;

--  
--  
Alter table lulc_london_ulb drop column if exists area_ratio;
Alter table lulc_london_ulb Add column area_ratio double precision DEFAULT 0.00;
UPDATE lulc_london_ulb SET area_ratio = completenessPoly.area_ratio 
from (
select st_area(geography(st_transform(geom,4326)))/moa_area_4326 as area_ratio,lulc_obj_gid
from lulc_london_ulb
  )  as completenessPoly
WHERE lulc_london_ulb.lulc_obj_gid = completenessPoly.lulc_obj_gid;
--- the area 
Alter table lulc_london_ulb drop column if exists area_class;
Alter table lulc_london_ulb Add column area_class double precision DEFAULT 0.00;
UPDATE lulc_london_ulb SET area_class = completenessPoly.area_class 
from (
select st_area(geography(st_transform(geom,4326))) as area_class,lulc_obj_gid
from lulc_london_ulb
  )  as completenessPoly
WHERE lulc_london_ulb.lulc_obj_gid = completenessPoly.lulc_obj_gid;


--- output only the table into server and directly read from R.
\copy (SELECT lulc_obj_gid,class_name,msoa11cd,area_ratio,area_class,moa_area_4326 FROM lulc_london_ulb) to '/home/z/zhendong/london/ULB_ATLAS/ulb_raw_features.csv' With CSV DELIMITER ',' HEADER;



---- need to prepare features for sbl

-----   merge the sbl_id
DROP TABLE IF EXISTS lulc_london_ulb_sbl; 
CREATE TABLE lulc_london_ulb_sbl as (
select  street_blocksl_withinloa.gid as sbl_gid, st_area(geography(st_transform(street_blocksl_withinloa.the_geom,4326))) as sbl_area_4326,st_intersection(street_blocksl_withinloa.the_geom,lulc_london_3857.geom) as geom,lulc_london_3857.gid as lulc_gid, lulc_london_3857.item2012 as class_name,street_blocksl_withinloa.gid as sbl_id
from street_blocksl_withinloa,lulc_london_3857
where st_intersects(street_blocksl_withinloa.the_geom,lulc_london_3857.geom)
);

 ALTER TABLE lulc_london_ulb_sbl ADD COLUMN lulc_obj_gid SERIAL PRIMARY KEY;
 
 --- the area 
Alter table lulc_london_ulb_sbl drop column if exists area_class;
Alter table lulc_london_ulb_sbl Add column area_class double precision DEFAULT 0.00;
UPDATE lulc_london_ulb_sbl SET area_class = completenessPoly.area_class 
from (
select st_area(geography(st_transform(geom,4326))) as area_class,lulc_obj_gid
from lulc_london_ulb_sbl
  )  as completenessPoly
WHERE lulc_london_ulb_sbl.lulc_obj_gid = completenessPoly.lulc_obj_gid;

---- the area ratio 
Alter table lulc_london_ulb_sbl drop column if exists area_ratio;
Alter table lulc_london_ulb_sbl Add column area_ratio double precision DEFAULT 0.00;
UPDATE lulc_london_ulb_sbl SET area_ratio = completenessPoly.area_ratio 
from (
select area_class/sbl_area_4326 as area_ratio,lulc_obj_gid
from lulc_london_ulb_sbl
  )  as completenessPoly
WHERE lulc_london_ulb_sbl.lulc_obj_gid = completenessPoly.lulc_obj_gid;

--- output only the table into server and directly read from R.
\copy (SELECT lulc_obj_gid,class_name,sbl_id,area_ratio,area_class,sbl_area_4326 FROM lulc_london_ulb_sbl) to '/home/z/zhendong/london/ULB_ATLAS/ulb_raw_features_sbl.csv' With CSV DELIMITER ',' HEADER;


select count(*)
from street_blocksl_withinloa;


Alter table street_blocksl_withinloa drop column if exists sbl_id;
Alter table street_blocksl_withinloa Add column sbl_id integer;
UPDATE street_blocksl_withinloa SET sbl_id = gid;


SELECT count(distinct(sbl_gid))
FROM lulc_london_ulb_sbl;
