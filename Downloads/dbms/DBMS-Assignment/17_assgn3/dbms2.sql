--Question 1
/* Group the table by titleid and and select those titles having count>=2 and has titletype as movie. */
select tconst from directors d1 where (select titletype from originaltitles o1 where o1.tconst=d1.tconst)='movie' group by tconst having count(tconst)>=2;


--Question 2
/* ID of Zack Snyder is "nm0811583". all_actor_director consists all the pairs of actor-directors. From them, do the needful.
select those distinct actors who have more actor-director pairs with zack snyder. */
with all_actor_director as (
    select p.tconst,nconst,director from principals p inner join directors d on d.tconst=p.tconst where p.category='actor'
), all_zack_movies as (
        select p.tconst,nconst,director from principals p inner join directors d on d.tconst=p.tconst where p.category='actor' and director='nm0811583'

)
select distinct nconst from all_zack_movies p1 where 
(select count(*) from all_zack_movies ad where ad.nconst=p1.nconst )> 
(select max(counts) from (select count(*) as counts from all_actor_director ad2 where ad2.nconst=p1.nconst and ad2.director!='nm0811583' group by ad2.director) as all_counts);

--Question 3
/* The table has not been created. So following are assumed. 
The table name is awards which is assumed to have variable tconst referencing to originaltitles.tconst.
Group the table awards by titleid and select only those who have count<2 */
select tconst from awards group by tconst having count(tconst)<2;

--Question 4
/* A straight-forward aoolication of inner join. Join the tables principals and directors and select all actor-director pairs with given conditions */
select foo.nconst,foo.director from 
(select p2.tconst,p2.nconst,d2.director from principals p2 inner join directors d2 on d2.tconst=p2.tconst where
 (p2.nconst,d2.director) in (select nconst,director from principals p1 inner join directors d1 on d1.tconst=p1.tconst where category='actor' group by nconst,director having count(p1.tconst)<=2)) as foo 
 inner join originaltitles o1 on o1.tconst=foo.tconst where o1.rating>7;

--Question 5
/* To ignore the corrupted/unspecified data, the duration considered is 0. If endyear is null, it is considered that the tvSeries is still running.
Sort the table originaltites according to their duration and limit to 1 for 1st record. */
select tconst,(case when startyear is NULL then 0
 when endyear is NULL then date_part('year',now())-startyear
 else endyear-startyear end) as duration from originaltitles where titletype='tvSeries'
 order by duration desc limit 1;

--Question 6
/* First find the runtime of second shortest movie. For this, sort by runtime, set offset 1 and limit to 1. 
Again, the same assumptions are done to avoid unspecified/corrupted data entries. 
Then, search the director the titleid from directors table.*/
select director from directors where tconst in (
select tconst from 
originaltitles where runtime=(
    select distinct (case when runtime is NULL then 999999 else runtime END) from originaltitles where titletype='movie' and startyear='2020' order by runtime offset 1 limit 1
));

--Question 7
/* Union is used here. straight-forward application of ORDER BY. sort by rating and limit the result to 1. */
(select tconst,originalTitle,rating from originaltitles o1 where isAdult=True and titletype='movie' order by rating limit 1)
union
(select tconst,originalTitle,rating from originaltitles o1 where isAdult=True and titletype='tvSeries' order by rating limit 1);

--Question 8
/* LEFT JOIN directors with titles and select only movies as foo. Now, group these by director and sort by average rating. limit the results to 5. */
select distinct director,sum(case when rating is NULL then 0 else rating end)/count(director) as avg_rating from 
(select * from directors d1 left join originalTItles o1 on d1.tconst=o1.tconst where titletype='movie') as foo
group by director order by avg_rating desc limit 5;

--Question 9
/* production_companies and locations tabls have not been created. SO the following are assumed.
production_companies table and locations table have tconst referring to originaltitles.tconst.
Sp select those originaltitles.tconst for tvSeries with the given conditions directly.  */
select tconst from originaltitles o1 where titletype='tvSeries'
and (select count(*) from production_companies p1 where p1.tconst=o1.tconst)>=2 and 
(select count(*) from locations l1 where l1.tconst=o1.tconst )>=3;

--Question 10
/* Awards table have not been created. So the following are assumed.
it has fields awardName,issuedYear,nconst(referring to cast_and_Crew.nconst), isWon. All of them are self-explanatory.
Order by issedYear and select oscars which have been won.  */
select nconst,issuedYear from awards where awardName='Oscars' and isWon='True' order by issuedYear desc; 

--Question 11
/* LEFT JOIN originaltitles with directors and Group the rows by director. Then order by the average rating which is calculated from the expression given in assignment. */
select director,((sum(case when rating is NULL then 0 else rating end)*0.7)/count(director))+count(director)*0.3 as avg_rating,count(director)  from 
(select * from directors d1 left join originalTItles o1 on d1.tconst=o1.tconst) as foo
group by director order by avg_rating desc ;

--Question 12
/* Box office collections and budget have not been encorporated. So the following are the assumptions.
OriginalTitles table has the two other columns budget and collections for each title. Just order by collections-budget and limit the resilts to 5. 
 */
select originalTitle from originaltitles where titletype='movie' 
order by (case when collections is not NULL and budget is not null then iscollections-budget else 0 end) desc limit 5;

--Question 13
/* Intersect is used here. Select only actors from principals with category='actor'. THen use the intersection of movie actors and tvSeries actors. */
with actors as(
    select tconst,nconst from principals where category='actor'
)
select a1.nconst from actors a1 inner join originalTItles o1 on o1.tconst=a1.tconst
group by a1.nconst,titletype having titletype='movie'
intersect
select a1.nconst from actors a1 inner join originalTItles o1 on o1.tconst=a1.tconst
group by a1.nconst,titletype having titletype='tvSeries';

--Question 14
/* min_runtimes temporary table has minimum runtime for each year for tvEpisodes. Now select titleids from originaltitles with that values. */
with min_runtimes as (
    select startyear,min(runtime) as runtime from originaltitles where titletype='tvEpisode'                         
group by startYear
)

select tconst,o1.startyear,o1.runtime from originaltitles o1 inner join min_runtimes m1 on o1.startyear=m1.startyear where o1.runtime=m1.runtime;

--Question 15
/* give row numbers with following constraints:
partitioned by genres, means each genre has separate numbering to itself.
Order by rating. Meaning, within each genre, index is given by descending order of rating. 
Now select only those rows which have index<=3 to get top 3 ratings of each genre. */
select * from 
(select o1.tconst,
rating,
genre,
row_number () over (partition by genre order by (case when rating is NULL then 0 else rating end) desc) as index
from originaltitles o1 inner JOIN title_genres g1 on g1.tconst=o1.tconst
) as foo where foo.index<=3;

--Question 16
/* title_locations table has not been created. So the follwing are assumed:
title_locations table has attributed location_name and tconst(referring to originaltitles.tconst).
Now select those titles of only movies and tvSeries which has entried with switzerland in title_locaitons.  */
select tl.tconst from title_locations tl where location_name='Switzerland' and 
((select titletype from originalTItles o where o.tconst=tl.tconst)='movie' or
(select titletype from originalTItles o where o.tconst=tl.tconst)='tvSeries');

--Question 17
--The question is not understood correctly at "Same location in year" part. SO it is assumed that the location name is "Switzerland" and continued with the query.
/* title_locations is assumed to be having the earlier described attributes along with certificate attributes.
Select those titles which are movies and has certificate type A in 1995. 
Since the qustion about same location is not clear, it is assumed as the continuation of previous question so switzerland location is used. */
select tl.tconst from title_locations tl inner join originalTItles o1 on o1.tconst=tl.tconst
where tl.certificate='A' and titletype='Movie' AND (startYear>=1995 and endYear<=1995) and location_name='Switzerland';

--Question 18
/* min_ages contains nconst, age,rpofession and row_number partitioned by profession and ordered by age. 
To ignore corrupted and unspecified data, only positive ages will be considered. Now, select only those rows with index 1 for youngest of the profession.*/
with min_ages as (
    select p1.nconst,age,profession,
    row_number () over (partition by profession order by (case when (age is NULL or age<=1)  then 10000 else age end)) as index
    from castAndCrewProfession p1 inner join cast_and_crew c1
    on c1.nconst=p1.nconst
)

select nconst,age,profession from min_ages where index=1;


--Question 19
/* soundtrack table is not created. So the follwoing are the assumptions:
it has attributed producer_name and tconst(referring to originalTitles.tconst). Self-explanatory.
sound_producers has soundtracks only for movies. Select those producer_names who have count>5 in sound_rpoducers.  */
with sound_producers as (
    select producer_name from soundtrack s1 inner join originalTitles o1 on o1.tconst=s1.tconst
where titletype='Movie'
)
select distinct producer_name from sound_producers s1 
where (select count(s1.producer_name) from sound_producers)>=5 ;

--Question 20
/* tconst considered here is 'tt0000003' has 4 crew members.
Now out of all actors from principals table, group by ID and select only those having count=count(crew of tt0000003) */
select nconst from principals p1 where category='actor' group by nconst having count(*)=(select count(*) from principals p2 where p2.tconst='tt0000003');
