-- englandtweets1415
-- if this run for long time then we can change into fater one.
---  moa version
Alter table moa drop column if exists tweets_disuser;
Alter table moa Add column tweets_disuser integer DEFAULT 0;
UPDATE moa SET tweets_disuser = completenessPoly.tweets_disuser 
from (

select COUNT(distin_user) as tweets_disuser, gid
from (
	SELECT DISTINCT "UserID" as distin_user,moa.gid
	 FROM englandtweets1415
	  INNER JOIN 
		moa 
	  ON ST_Intersects(st_transform(moa.geom,4326),englandtweets1415.geom)) as foo
group by gid
  )  as completenessPoly
WHERE moa.gid = completenessPoly.gid;

-- start  at 2019/7/9 22:34
-- end at 2019/07/10 10:00
-- UPDATE 983

---  loa version

Alter table loa drop column if exists tweets_disuser;
Alter table loa Add column tweets_disuser integer DEFAULT 0;
UPDATE loa SET tweets_disuser = completenessPoly.tweets_disuser 
from (
select COUNT(distin_user) as tweets_disuser, gid
from (
	SELECT DISTINCT "UserID" as distin_user,loa.gid
	 FROM englandtweets1415
	  INNER JOIN 
		loa 
	  ON ST_Intersects(st_transform(loa.geom,4326),englandtweets1415.geom)) as foo
group by gid
  )  as completenessPoly
WHERE loa.gid = completenessPoly.gid;

---  sb version
Alter table street_blocksl_withinloa drop column if exists tweets_disuser;
Alter table street_blocksl_withinloa Add column tweets_disuser integer DEFAULT 0;
UPDATE street_blocksl_withinloa SET tweets_disuser = completenessPoly.tweets_disuser 
from (
select COUNT(distin_user) as tweets_disuser, gid
from (
	SELECT DISTINCT "UserID" as distin_user,street_blocksl_withinloa.gid
	 FROM englandtweets1415
	  INNER JOIN 
		street_blocksl_withinloa 
	  ON ST_Intersects(st_transform(street_blocksl_withinloa.the_geom,4326),englandtweets1415.geom)) as foo
group by gid
  )  as completenessPoly
WHERE street_blocksl_withinloa.gid = completenessPoly.gid;

--------------------------------------------------------------------------------------------- tweets number at night 
---  need to create the index of twitter data?10
---- 

CREATE INDEX englandtweets1415_geo_inx
  ON public.englandtweets1415
  USING gist
  (geom);

Alter table moa drop column if exists distinct_tweets;
Alter table moa Add column distinct_tweets integer DEFAULT 0;
UPDATE moa SET distinct_tweets = completenessPoly.distinct_tweets 
from (

select COUNT(*) as distinct_tweets, moa.gid
from (englandtweets1415
	  INNER JOIN 
		moa 
	  ON ST_Intersects(st_transform(moa.geom,4326),englandtweets1415.geom))
group by moa.gid
  )  as completenessPoly
WHERE moa.gid = completenessPoly.gid;


---  loa version

Alter table loa drop column if exists distinct_tweets;
Alter table loa Add column distinct_tweets integer DEFAULT 0;
UPDATE loa SET distinct_tweets = completenessPoly.distinct_tweets 
from (

select COUNT(*) as distinct_tweets, loa.gid
from (englandtweets1415
	  INNER JOIN 
		loa 
	  ON ST_Intersects(st_transform(loa.geom,4326),englandtweets1415.geom))
group by loa.gid
  )  as completenessPoly
WHERE loa.gid = completenessPoly.gid;
---  sb version

Alter table street_blocksl_withinloa drop column if exists distinct_tweets;
Alter table street_blocksl_withinloa Add column distinct_tweets integer DEFAULT 0;
UPDATE street_blocksl_withinloa SET distinct_tweets = completenessPoly.distinct_tweets 
from (

select COUNT(*) as distinct_tweets, street_blocksl_withinloa.gid
from (englandtweets1415
	  INNER JOIN 
		street_blocksl_withinloa 
	  ON ST_Intersects(st_transform(street_blocksl_withinloa.the_geom,4326),englandtweets1415.geom))
group by street_blocksl_withinloa.gid
  )  as completenessPoly
WHERE street_blocksl_withinloa.gid = completenessPoly.gid;