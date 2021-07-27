#This python program concentrates on obtaining datasets for release dates of the title ids taken from 
#title.basics.tsv file and sending API requests to www.themoviedb.org using tmdbsimple module. 
#TO install tmdbsimple, use the command pip3 install tmdbsimple

import csv
import tmdbsimple as tmdb
tmdb.API_KEY = '74f927fb069bed29595a34c8d3dee165' #Replace with the API-Key of your own.
output=open("releasedates.csv","w",newline="")
writer = csv.DictWriter(output, fieldnames=["tconst","type","release_date"])
writer.writeheader()

with open("title.basics.tsv", "r") as csv_file:
    csv_reader = csv.reader(csv_file, delimiter="\t")
    for lines in csv_reader:
    	try:
    		find=tmdb.Find(lines[0])
    		temp=find.info(external_source='imdb_id')
    		if temp["movie_results"]:
    			writer.writerow({"tconst": lines[0],
    				"type":"Movie",
    				"release_date": temp["movie_results"][0]["release_date"]})
    		elif temp["tv_results"]:
    			writer.writerow({"tconst": lines[0],
    				"type":"TV Series",
    				"release_date": temp["tv_results"][0]["first_air_date"]})
    		elif temp["tv_episode_results"]:
    			writer.writerow({"tconst": lines[0],
    				"type":"Episode",
    				"release_date": temp["tv_episode_results"][0]["air_date"]})
    	except:
    		pass

#Now open releasedates.csv file in the same directory to get the dataset in csv regardig release dates. 