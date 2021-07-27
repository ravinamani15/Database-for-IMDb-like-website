/* This is the entire SQL life written in postgreSQL for building database for ImDb website.
The file is neatly commented too for better understanding */

/* The datasets are very corrupted and has many unnecessary data.
Some files have ids for titles and persons whose ids have not been assigned too. This document assumes those are corrupted data and have been deleted before referencing between the tables.*/

/* Drop the tables if they are present */
DROP TABLE IF EXISTS all_titles;
DROP TABLE IF EXISTS cast_and_crew;
DROP TABLE IF EXISTS castAndCrewProfession;
DROP TABLE IF EXISTS castandcrewtitles;
DROP TABLE IF EXISTS crew;
DROP TABLE IF EXISTS directors;
DROP TABLE IF EXISTS episodes;
DROP TABLE IF EXISTS originalTitles;
DROP TABLE IF EXISTS principals;
DROP TABLE IF EXISTS ratings;
DROP TABLE IF EXISTS title_genres;
DROP TABLE IF EXISTS writers;
DROP TABLE IF EXISTS releasedates;
DROP TABLE IF EXISTS awardsAndNominations;


/* This table contains all the original titles and information regarding each of them. 
Everything is put under text datatype to make sure no error is encountered while copying from tsv file
*/
CREATE TABLE originalTitles( 
    tconst TEXT PRIMARY KEY,
    titleType TEXT,
    primaryTitle TEXT,
    originalTitle TEXT,
    isAdult TEXT,
    startYear TEXT,
    endYear TEXT,
    runTime TEXT,
    genres TEXT
);

/* Copy the tsv file title.basics.tsv to the table originalTItles with \t delimeter. Please change the file location accordingly*/
copy originalTitles 
from '/home/hp/Downloads/title.basics.tsv'
with (format text, delimiter E'\t');

/*Delete the first row of csv which contains the column names.*/
delete from originalTitles where tconst='tconst';

/* Changing the datatype of isAdult from text to bool. If isAdult=0, then false or else true. */
alter table originalTitles 
alter COLUMN isAdult type boolean
using case 
when isAdult='0' then False
when isAdult='1' then true
else null end;

/* Changing the datatype of startyear from text to integer.
The integer format is '^[-+0-9]+$'. So change to int when it is encountered.  */
ALTER table originalTitles 
alter COLUMN startYear type integer
using case when startYear ~ '^[-+0-9]+$' then startYear::integer else NULL end;

/* Changing the datatype of endYear from text to integer.
The integer format is '^[-+0-9]+$'. So change to int when it is encountered.  */
ALTER table originalTitles
alter COLUMN endYear type integer
using case when endYear ~ '^[-+0-9]+$' then endYear::integer else NULL end;

/* Changing the datatype of runTime from text to integer.
The integer format is '^[-+0-9]+$'. So change to int when it is encountered.  */
ALTER table originalTitles
alter COLUMN runTime type integer
using case when runTime ~ '^[-+0-9]+$' then runTime::integer else NULL end;

/* Each movie can have multiple genres and vice versa. 
SO create a separate table for it because it is many-many relationship.*/
create table title_genres(
    tconst TEXT,
    genre TEXT,
    PRIMARY key (tconst,genre),
    CONSTRAINT tconst_fk FOREIGN key(tconst) references originalTitles(tconst) on delete cascade
);

/* break the convert the comma separated string to an array using string_to_array() funciton.
Use unnest function to obtain each entry and insert into title_genres table with tconst and genre.
Here tconst references to tconst in originalTitles table */
INSERT INTO title_genres (tconst,genre)
SELECT tconst, unnest(string_to_array(genres,','))
FROM originalTitles;

/*Now that we have separate table for genres, we can delete the column in originalTitles*/
alter table originalTitles drop column genres;

/* This contains all titles in different languages and regions. */
CREATE TABLE all_titles(
    titleid TEXT ,
    ordering TEXT ,
    title TEXT,
    region TEXT,
    title_language TEXT,
    types TEXT,
    attributes TEXT,
    isOriginalTitle TEXT,
    primary key(titleid,ordering)
    ); 

/* Here titleids are not being referenced to tconst in originaltitles because there are some titles who doesn't have
entry in originaltitles and deleting those rows wouldn't be a feasible solution. */

--Copy the data from the file title.akas.tsv.
copy all_titles                                                                                
from '/home/hp/Downloads/title.akas.tsv' 
with (format text, delimiter E'\t');

/* Delete the first entry which has column names. */
delete from all_titles where titleid='titleid';

/* Drop the columns which are not necessary to save memeory*/
ALTER TABLE all_titles DROP COLUMN attributes;
ALTER TABLE all_titles DROP COLUMN types;
/* Reference the titleid which original title of it from originalTitles table. */


/* Add the below columns to originalTitles table. 
The season and episode numbers are self explanatory. 
parentTconst contains tconst of the web series to which the season is if it is or else it will be NULL.  */
alter table originalTitles add column seasonNumber TEXT;
alter table originalTitles add column episodeNumber TEXT;
alter table originalTitles add column parentTconst TEXT;

/* This table contains all the cast and crew members. */
CREATE TABLE cast_and_crew(
    nconst TEXT PRIMARY KEY,
    primaryName TEXT,
    birthYear VARCHAR(10),
    deathYear VARCHAR(10),
    primaryProfession TEXT ,
    knownForTitles TEXT
    );

/* Copy the values from the file names.basics.tsv with \t delimiter. */
copy cast_and_crew                                                                                
from '/home/hp/Downloads/name.basics.tsv' 
with (format text, delimiter E'\t');

/* Delete the first entry as usual*/
delete from cast_and_crew where nconst='nconst';

/* Add column age to the table */
alter table cast_and_crew add column age int;

/* Calculate age from birth and death year.
1) if birthyear not known, put NULL,
2) if death year not known, person is still alive. So calculate frmo present date.
3) or calculate deathyear-birthyear.*/
update cast_and_crew 
set age=(case when not birthYear ~ '^[-+0-9]+$' then NULL
when not deathYear ~ '^[-+0-9]+$' then (date_part('year',now())-cast(birthYear as int)) else (cast(deathYear as int)-cast(birthYear as int)) end);

/* The table contains professions of each member from cast_and_crew. References to cast number id */
CREATE TABLE castAndCrewProfession(
    nconst TEXT ,
    profession TEXT ,
    PRIMARY KEY(nconst,profession),
    CONSTRAINT fk_nconst FOREIGN KEY(nconst) REFERENCES cast_and_crew(nconst)
);

/* Use unnest and string_to_array functions as explained earlier above and insert the values accordingly */
INSERT INTO castAndCrewProfession (nconst,profession)
SELECT nconst, unnest(string_to_array(primaryProfession,','))
FROM cast_and_crew;

/* THe table contains titles of each member. References to person id frmo cast_and_Crew table. */
CREATE TABLE castAndCrewTitles(
    nconst TEXT ,
    titleid TEXT ,
    PRIMARY KEY(nconst,titleid),
    CONSTRAINT fk_nconst FOREIGN KEY(nconst) REFERENCES cast_and_crew(nconst) ON DELETE cascade
);

/* Use unnest and string_to_array functions as explained earlier above and insert the values accordingly */
INSERT INTO castAndCrewTitles (nconst,titleid)
SELECT nconst, unnest(string_to_array(knownForTitles,',')) 
FROM cast_and_crew 
On conflict  do nothing;

/* The data is a little corrupted and has extra values. So delete the unnessary corrupted rows to further reference to originalTitles table*/
delete from castAndCrewTitles c
where not exists(
    select from originalTitles o where o.tconst=c.titleid
);

/*Reference the titleid from castandcrewtitles to originalTitles*/
alter table castandcrewtitles add constraint fk_titleid FOREIGN KEY(titleid) REFERENCES originalTitles(tconst) on delete cascade;

/* This is a temporary table to copy information from title.episodes.tsv and then update in originalTitles. */
create temporary table episodes(
    tconst TEXT,
    parentTconst TEXT,
    seasonNumber TEXT,
    episodeNumber TEXT
);

/*Copy the rows from title.episode.tsv file*/
copy episodes                                                                                
from '/home/hp/Downloads/title.episode.tsv' 
with (format text, delimiter E'\t');

/*The file has corrupted and unnecessary information. So delete those before updating them to original titles table.*/
delete from episodes e
where not exists (select from originalTitles o where o.tconst=e.parentTconst);

--todo
/*Update the values from episodes table to originaltitles table by matching tconst.
This query takes lot of time than expected because there are many entries in originalTitles and episodes.*/
update originalTitles 
set parentTconst=episodes.parentTconst,
seasonNumber=episodes.seasonNumber ,
episodeNumber=episodes.episodeNumber
from episodes 
where episodes.tconst=originalTitles.tconst;

/* This is a temporary table too having information about ratings of titles. */
create temporary table ratings(
    tconst TEXT,
    rating TEXT,
    votes TEXT
    ); 

/* Copy from title.ratings.tsv*/
copy ratings                                                                                
from '/home/hp/Downloads/title.ratings.tsv' 
with (format text, delimiter E'\t');

/* Delete the first entry*/
delete from ratings where tconst='tconst'; 

/* Add column for ratings in originalTitles */
alter TABLE originalTitles add COLUMN rating NUMERIC;

/* Check if the rating is of numeric type and then convert to numeric before updating it in table.
THe format of numeric is '^\d+(\.\d+)?$' */
update originalTitles
set rating=(case when ratings.rating ~ '^\d+(\.\d+)?$' then cast(ratings.rating as numeric) else null end)
from ratings
where ratings.tconst=originalTitles.tconst;

/* The table contains principal members for titles and their information in title like character name etc */
create table principals(
    tconst text,
    ordering text,
    nconst text,
    category text,
    job text,
    characters text
);

/* copy from title.principals.tsv*/
copy principals                                                                                
from '/home/hp/Downloads/title.principals.tsv' 
with (format text, delimiter E'\t');

/* Delete the corrupted and unnecessary data which are not present in originaltitles table to add foreign key constraint. */
delete from principals 
where not exists(select from originalTitles where principals.tconst=originalTitles.tconst);

/* Reference tconst and nconst respectively to originaltitles and cast_andC_rew tables */
alter table principals add constraint tconst_fk FOREIGN KEY (tconst) references originalTitles(tconst) on delete cascade;
alter table principals add constraint nconst_fk FOREIGN KEY (nconst) references cast_and_crew(nconst) on delete cascade;

/* This is a temporary table too to copy the from tsv */
create temporary table crew(
    tconst TEXT,
    directors TEXT,
    writers TEXT
);

/*Copy from title.crew.tsv file into appropriate columns*/
copy crew                                                                                
from '/home/hp/Downloads/title.crew.tsv' 
with (format text, delimiter E'\t');

/* delete first row*/
delete from crew where tconst='tconst';

/* Delete unnecessary corrupted data to reference back to original titles. */
delete from crew c
where not exists(select from originalTitles o where o.tconst=c.tconst)

/* A separate table for directors. referenced to originaltitles by tconst*/
create table directors(
    tconst TEXT,
    director TEXT,
    PRIMARY key(tconst,director),
    constraint tconst_fk foreign key (tconst) references originalTitles(tconst)
);

/* Insert the values from temporary table to directors by unnest and string_to_array inbuilt funcitons*/
INSERT INTO directors (tconst,director)
SELECT tconst, unnest(string_to_array(directors,',')) 
FROM crew 
On conflict  do nothing;

/* A separate table for writers. referenced to originaltitles by tconst*/
create table writers(
    tconst TEXT,
    writer TEXT,
    PRIMARY key(tconst,writer),
    constraint tconst_fk foreign key (tconst) references originalTitles(tconst)
);

/* Insert the values from temporary table to writers by unnest and string_to_array inbuilt funcitons*/
INSERT INTO writers (tconst,writer)
SELECT tconst, unnest(string_to_array(writers,',')) 
FROM crew 
On conflict  do nothing;

/* Delete directors whose id is not present in cast_and_Crew to reference to it*/
delete from directors d
where not exists(select from cast_and_crew c where c.nconst=d.director);

/* Delete writers whose id is not present in cast_and_Crew to reference to it*/
delete from writers w
where not exists(select from cast_and_crew c where c.nconst=w.writer);

/* add foreign key constraint from directors and writers tables to cast_and_crew by nconst*/
alter table directors add constraint director_fk foreign key(director) references cast_and_crew(nconst);
alter table writers add constraint writer_fk foreign key(writer) references cast_and_crew(nconst);

/* This is an extra table that had been crawled from https://www.themoviedb.org/documentation/api.
The CSV file is attached with this file too for reference.
This table contains information if the title is a movie/TV Series/ Episode. also the release/AIR date. */
create temporary table releasedates(
    tconst TEXT,
    title_type TEXT,
    releasedate TEXT
);

/* Copy the data into appropriate fields*/
copy releasedates                                                                                
from '/home/hp/Documents/dbms/releasedates.csv' 
delimiter ','
CSV HEADER;

/* Add the columns for the data in originalTitles*/
alter table originalTitles add column release_date TEXT;

/* Update the table to add the keys into appropriate rows in originalTitles table.*/
update originalTitles o
set release_date=r.releasedate
from releasedates r
where r.tconst=o.tconst;

/* The is an extra table. The dataset of which had been crawled from https://imdb8.p.rapidapi.com/actors/get-awards. 
The python program for crawling the data and appending to a csv file is attached with this. Run the program to generate the csv file.
Could not attach the file due to large size of it. */

/* This table contains information about the awards and nominations the cast member has recieved. And also if they have won the award. 
The nconst is referenced to cast_and_crew*/
create table awardsAndNominations(
    nconst TEXT,
    awardname TEXT,
    category TEXT,
    isWinner TEXT,
    constraint nconst_fk foreign key (nconst) references cast_and_crew(nconst)
);

/* Copy the data into appropriate fields from the generated csv file*/
copy awardsAndNominations                                                                                
from '/home/hp/Documents/awards.csv' 
delimiter ','
CSV HEADER;

/* Change the datatype of isWinner from text to boolean*/
alter table awardsAndNominations 
alter COLUMN isWinner type boolean
using case 
when isWinner='False' then False
when isWinner='True' then true
else null end;
 
