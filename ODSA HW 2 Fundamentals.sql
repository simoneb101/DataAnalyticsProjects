#A1) Pattern Matching – Non-Standard Country Names (10 pts)
select `name` as country_name from world.country where `name` regexp '[^A-Za-z ''-]';
#The regular expression can be broken into multiple components: [^A-Za-z ''-]
#Letters: A–Z, a–z
#Hyphens: -
#Apostrophes: '
#This pattern matches any single character outside the allowed list, so you can use it to validate input by checking if this pattern appears.

#A2) Duplicate City Names by Country (12 pts)
select CountryCode, `name` as city, count(*) as city_count from world.city group by CountryCode, city having count(*) > 1
order by CountryCode, city; 
#This pulls country code and city name then aggregates and find cities that are duplicates. 

#A3) Clean Government Forms (12 pts)
select CASE
    WHEN GovernmentForm LIKE '%Monarch%'    THEN 'Monarchy'
    WHEN GovernmentForm LIKE '%Republic%'   THEN 'Republic'
    WHEN GovernmentForm LIKE '%Communist%'  THEN 'Communist'
    WHEN GovernmentForm LIKE '%Democ%'      THEN 'Democracy'
    ELSE 'Other'
END AS government_form, count(*) as government_count
from world.country group by government_form order by government_form;
#This finds the different government types in goverment form and buckets them in the correct government form then aggregates to get summary by values.

#A4) Years Since Independence (11 pts)
select year(current_date()) - coalesce(IndepYear, 2025) as years_since_indep from world.country;
#Use the year function to get the year of the current date, subtract that by the independence year wrapped in a coalesce to handle null
#values.

#B1) Population by Continent (10 pts)
select Continent, format(sum(case when population is null then 0 else population end), '#,###') as total_population from world.country
group by Continent order by Continent;

#Query country table to get continent summarized by population wrapped in a case statement to handle null values. 

#B2) Top 10 Most Populous Cities per Country (15 pts)
select `Code`, city, pop_rank from (
select a.`Code`, b.`name` as city, a.Population, row_number() over (partition by b.CountryCode order by a.Population desc) as pop_rank from world.country as a inner join world.city as b on a.`Code` = b.CountryCode
) as sub1 where pop_rank <= 10;

#This gives the top 10 per each country

#B3) Language Coverage (10 pts)
select a.`name` as country, b.`language`, count(*) as language_count, sum(b.percentage) as percent_sum
from world.country as a inner join world.countrylanguage as b on a.`Code` = b.CountryCode
where b.IsOfficial = 'T' group by a.`name`, b.`language` order by a.`name`, b.`language`;

#Joins country table to country language table to get country name, language, count of languages, and sum of percentage, filter to only official languages. 

#C1) Rank Countries by GDP per Capita (10 pts)
with capita as 
(
select continent, gnp/Population as gnp_per_capita from world.country where Population > 0
), 
rank_capita as
(
select continent, gnp_per_capita, rank() over (partition by continent order by gnp_per_capita desc) as gnp_per_capita_rank from capita 
)
select * from rank_capita;

#First calculate gnp per capita inside a CTE. Then apply the rank to get a ranking by continent and ordered by descending gnp per capita. 

#C2) Running Total of City Populations within a Country (10 pts)
select a.`name` as country, b.`name` as city, b.Population, sum(b.Population) over (order by b.`name`) as running_pop_total
from world.country as a inner join world.city as b on a.`Code` = b.CountryCode
where a.`Code` = 'USA' order by b.`name`;

#This joins the city and country table to get the names of each country and city. Then calculates a running total using population ordered by 
#city name. Filtered to only USA. 
