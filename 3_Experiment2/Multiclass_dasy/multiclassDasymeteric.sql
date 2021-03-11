DROP TABLE IF EXISTS lulc_london; 
CREATE TABLE lulc_london as (
 SELECT uk001l3_london_ua2012.gid,uk001l3_london_ua2012.code2012,item2012,uk001l3_london_ua2012.geom
 FROM 
	uk001l3_london_ua2012,aoi
 WHERE
	st_intersects(uk001l3_london_ua2012.geom,st_transform(aoi.the_geom,3035))
);


 -- get the distinct value of class
select COUNT(*) as distin_class_number, item2012
from (
	SELECT item2012
	 FROM lulc_london) as foo
group by item2012
ORDER BY distin_class_number DESC;

-- adjust the class
Alter table lulc_london drop column if exists adj_classname;
Alter table lulc_london Add column adj_classname VARCHAR(150);
UPDATE lulc_london SET adj_classname = tempPoly.adj_classname 
from (
select  lulc_london.gid,
	case item2012 when 'Land without current use' then 'Green urban areas'
		 when  'Construction sites' then 'Green urban areas'
		 when  'Pastures' then 'Agricultural area'
		 when  'Arable land (annual crops)' then 'Agricultural area'
		 when  'Permanent crops (vineyards, fruit trees, olive groves)' then 'Agricultural area'
		 when  'Open spaces with little or no vegetation (beaches, dunes, bare rocks, glaciers)' then 'Agricultural area'
		 when  'Other roads and associated land' then 'Industrial, commercial, public, military and private units'
		 when  'Railways and associated land' then 'Industrial, commercial, public, military and private units'
		 when  'Fast transit roads and associated land' then 'Industrial, commercial, public, military and private units'
		 when  'Sports and leisure facilities' then 'Industrial, commercial, public, military and private units'
		 when  'Mineral extraction and dump sites' then 'Industrial, commercial, public, military and private units'
		 when 'Isolated structures' then 'Industrial, commercial, public, military and private units'
		 when  'Airports' then 'Port areas'
		 when  'Wetlands' then 'Water'
		 when  'Discontinuous very low density urban fabric (S.L. : < 10%)' then 'low_pop'
		 when  'Discontinuous low density urban fabric (S.L. : 10% - 30%)' then 'low_pop'
		 when  'Discontinuous medium density urban fabric (S.L. : 30% - 50%)' then 'low_pop'
		 when  'Discontinuous dense urban fabric (S.L. : 50% -  80%)' then 'med_pop'
		 when  'Continuous urban fabric (S.L. : > 80%)' then 'hi_pop'
		 Else  item2012
	END as adj_classname
from lulc_london
  )  as tempPoly
WHERE lulc_london.gid = tempPoly.gid;

--check
select COUNT(*) as distin_class_number, adj_classname
from (
	SELECT adj_classname
	 FROM lulc_london) as foo
group by adj_classname
ORDER BY distin_class_number DESC;

-- delete the water samples
DROP TABLE IF EXISTS lulc_london_nowater; 
CREATE TABLE lulc_london_nowater as (
 SELECT gid,code2012,item2012,adj_classname, st_transform(geom,3857) as geom
 FROM 
	lulc_london
 WHERE
	adj_classname != 'Water'
);
--check
select COUNT(*) as distin_class_number, adj_classname
from (
	SELECT adj_classname
	 FROM lulc_london_nowater) as foo
group by adj_classname
ORDER BY distin_class_number DESC;

-----   calculate the area ratio
DROP TABLE IF EXISTS lulc_london_temp; 
CREATE TABLE lulc_london_temp as (
select  moa.gid as moa_gid, st_area(geography(st_transform(moa.geom,4326))) as moa_area_4326,st_intersection(moa.geom,lulc_london_nowater.geom) as geom,lulc_london_nowater.gid as lulc_gid, lulc_london_nowater.adj_classname as class_name,MSOA11CD
from moa,lulc_london_nowater
where st_intersects(moa.geom,lulc_london_nowater.geom)
);
 ALTER TABLE lulc_london_temp ADD COLUMN lulc_obj_gid SERIAL PRIMARY KEY;

--  
Alter table lulc_london_temp drop column if exists area_ratio;
Alter table lulc_london_temp Add column area_ratio double precision DEFAULT 0.00;
UPDATE lulc_london_temp SET area_ratio = completenessPoly.area_ratio 
from (
select st_area(geography(st_transform(geom,4326)))/moa_area_4326 as area_ratio,lulc_obj_gid
from lulc_london_temp
  )  as completenessPoly
WHERE lulc_london_temp.lulc_obj_gid = completenessPoly.lulc_obj_gid;
--- the area 
Alter table lulc_london_temp drop column if exists area_class;
Alter table lulc_london_temp Add column area_class double precision DEFAULT 0.00;
UPDATE lulc_london_temp SET area_class = completenessPoly.area_class 
from (
select st_area(geography(st_transform(geom,4326))) as area_class,lulc_obj_gid
from lulc_london_temp
  )  as completenessPoly
WHERE lulc_london_temp.lulc_obj_gid = completenessPoly.lulc_obj_gid;



DROP TABLE IF EXISTS classdensity; 
CREATE TABLE classdensity as (
with maxgv as 
(
    select class_name, max(area_ratio) maxg
    from lulc_london_temp
    group by class_name
)

select lulc_london_temp.class_name, lulc_london_temp.area_ratio,MSOA11CD,area_class,geom
from   maxgv
inner join lulc_london_temp
on         lulc_london_temp.class_name = maxgv.class_name
and        lulc_london_temp.area_ratio = maxgv.maxg
);
								 
--- output the 
pgsql2shp -f /home/z/zhendong/london/multiclassdsymetric/classdensity.shp  -h localhost -u zhendong -P y1995z828d london classdensity


Alter table lulc_london_temp drop column if exists area_ratio_class;
Alter table lulc_london_temp Add column area_ratio_class double precision DEFAULT 0.00;
UPDATE lulc_london_temp SET area_ratio_class = completenessPoly.area_ratio_class 
from (
select area_ratio as area_ratio_class,lulc_obj_gid
from lulc_london_temp
  )  as completenessPoly
WHERE lulc_london_temp.lulc_obj_gid = completenessPoly.lulc_obj_gid;

--- get loa_gid
Alter table lulc_london_temp drop column if exists loa_gid;
Alter table lulc_london_temp Add column loa_gid character(10);
UPDATE lulc_london_temp SET loa_gid = completenessPoly.loa_gid 
from (
select lsoa11cd as loa_gid,lulc_obj_gid
from lulc_london_temp,loa
where st_intersects(lulc_london_temp.geom,loa.geom)
  )  as completenessPoly
WHERE lulc_london_temp.lulc_obj_gid = completenessPoly.lulc_obj_gid;

--  output as shape
pgsql2shp -f /home/z/zhendong/london/multiclassdsymetric/lulc_london_temp.shp  -h localhost -u zhendong -P y1995z828d london lulc_london_temp



--------------------------------------------------------------  instead of directly use st_intersects to determine the object should be aggregated into LOA, propose to use the area ratio to do it.

DROP TABLE IF EXISTS lulc_london_loa; 
CREATE TABLE lulc_london_loa as (
select  ST_MakeValid(st_intersection(loa.geom,lulc_london_temp.geom)) as geom,lulc_obj_gid,loa_gid,lulc_london_temp.msoa11cd,area_class
from loa,lulc_london_temp
where st_intersects(loa.geom,lulc_london_temp.geom)
);

ALTER TABLE lulc_london_loa ADD COLUMN lulc_obj_loa_gid SERIAL PRIMARY KEY;

DELETE FROM lulc_london_loa WHERE st_geometrytype(geom) NOT IN ('ST_Polygon', 'ST_MultiPolygon');

select COUNT(*) as distin_class_number, adj_classname
from (
	SELECT st_geometrytype(geom) as adj_classname
	 FROM lulc_london_loa) as foo
group by adj_classname
ORDER BY distin_class_number DESC;

-- calculate the area_ratio of each lulc_obj_loa_gid.
Alter table lulc_london_loa drop column if exists area_ratio_lulc_moa;
Alter table lulc_london_loa Add column area_ratio_lulc_moa double precision DEFAULT 0.00;
UPDATE lulc_london_loa SET area_ratio_lulc_moa = completenessPoly.area_ratio_lulc_moa 
from (
select st_area(geography(st_transform(geom,4326)))/area_class as area_ratio_lulc_moa,lulc_obj_loa_gid
from lulc_london_loa
  )  as completenessPoly
WHERE lulc_london_loa.lulc_obj_loa_gid = completenessPoly.lulc_obj_loa_gid;

--  output as shape
pgsql2shp -f /home/z/zhendong/london/multiclassdsymetric/lulc_london_loa.shp  -h localhost -u zhendong -P y1995z828d london lulc_london_loa
--  ERROR: Incompatible mixed geometry types in table

-- then in R, merge by lulc_obj_gid and separate population into each lulc_obj_loa_gid

