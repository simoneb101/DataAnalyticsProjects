#Q1
#Explore the Sakila database and document the film table structure.
#Required:
#•	Document at least 8 key columns from the sakila.film table (film_id, title, description, release_year, rental_rate, length, replacement_cost, rating)
#•	Include data type and description for each column
#•	Write a brief explanation (2-3 sentences) of what the film table stores and its purpose

describe sakila.film;
show columns from sakila.film;

#1
#Field: film_id
#Data type: smallint unsigned
#Description: This the primary key that allows joining this data with other data

#2
#Field: title
#Data type: varchar
#Description: Provides information on the name of the film.

#3
#Field: rating
#Data type: enum('G','PG','PG-13','R','NC-17')
#Description: A descriptor for the level of explicity of a movie. 

#4
#Field: release_year
#Data type: year
#Description: Date film was distributed. 

#5
#Field: language_id
#Data type: tinyint unsigned
#Description: Key used to connect to language table. 

#6
#Field: description
#Data type: text
#Description: Describes what the film is about. 

#7
#Field: rental_duration
#Data type: tinyint unsigned
#Description: The duration that the rental is valid for. 

#8
#Field: length
#Data type: smallint unsigned
#Description: The number of units of time a film last. 

#The purpose of the film table is to provide general information on a film such as title and description which describes
#the name of the film and information about the film. This data is then connected to other tables to get inforamtion 
#such as language.

#Q2
#Count the total number of films in the Sakila database
select count(distinct film_id) as film_count from sakila.film;

#Q3
#Find the 5 longest films by length
#Show: title, length (in minutes), and rating. Order by length in descending order.
select title, length, rating from sakila.film order by length desc limit 5;

#Q4
#Find all PG-rated films with rental rate above $3.00.
#Show: title, rating, rental_rate, and length. Order by rental rate from highest to lowest. Display the top 10 results.
select title, rating, rental_rate, length from sakila.film where rating like '%PG%' and rental_rate > 3
order by rental_rate desc limit 10;

#Required: Brief explanation (1-2 sentences) of why these films might be considered premium rentals.
#Answer: The premium aspect has to do with the rental_rate. These rentals are technically the highest cost value because the query
#is looking for values greater than 3 sorted by descending value. 

#Q5a
#Calculate the minimum, maximum, and average rental rates across all films
select min(rental_rate) as min_rental_rate, max(rental_rate) as max_rental_rate, avg(rental_rate) as avg_rental_rate 
from sakila.film;

#Q5b
#Count films in each rental rate category using CASE statement
#Categories:
#•	Economy: < $1.00
#•	Standard: $1.00 - $2.99
#•	Premium: $3.00 - $4.99
#•	Luxury: >= $5.00
select case when rental_rate < 1.00 then 'Economy' when rental_rate between 1.00 and 2.99 then 'Standard' when rental_rate between 3.00 and 4.99
then 'Premium' else 'Luxury' end as category, count(*) as category_count from sakila.film group by category;

#Q6
#Calculate the average replacement cost grouped by film rating.
#Show: rating, average replacement cost, and total replacement cost. Order by total replacement cost DESC.
select rating, avg(replacement_cost) as avg_replacement_cost, sum(replacement_cost) as total_replacement_cost
from sakila.film group by rating order by total_replacement_cost desc;

#Answer this question: Which film rating has the highest total replacement cost?
#Answer: The film rating with the highest total replacement cost is PG-13. 

#Q7
CREATE DATABASE IF NOT EXISTS sakila_games;

#Q8
#Create the platform table with the following structure:
#•	platform_id (primary key, auto-incrementing, SMALLINT UNSIGNED)
#•	name (required, VARCHAR(50), unique)
#•	manufacturer (optional, VARCHAR(100))
#•	last_update (TIMESTAMP, auto-updates to current timestamp)

CREATE TABLE sboyd.platform
(
platform_id smallint unsigned auto_increment primary key,
name varchar(50) not null unique,
manufacturer varchar(100),
last_update timestamp on update current_timestamp
);

#Q9
#Create the publisher table with the following structure:
#•	publisher_id (primary key, auto-incrementing, SMALLINT UNSIGNED)
#•	name (required, VARCHAR(100), unique)
#•	country (optional, VARCHAR(50))
#•	last_update (TIMESTAMP, auto-updates)

CREATE TABLE sboyd.publisher
(
publisher_id smallint unsigned auto_increment primary key,
name varchar(100) not null unique,
country varchar(50),
last_update timestamp on update current_timestamp
);

#Q10
#Create the game table with foreign keys to platform and publisher:
#•	game_id (primary key, auto-incrementing, SMALLINT UNSIGNED)
#•	title (required, VARCHAR(255))
#•	platform_id (SMALLINT UNSIGNED, foreign key references platform.platform_id)
#•	publisher_id (SMALLINT UNSIGNED, foreign key references publisher.publisher_id)
#•	rental_rate (required, DECIMAL(4,2), default 4.99)
#•	rating (ENUM('E', 'E10+', 'T', 'M', 'AO'), default 'E')
#•	last_update (TIMESTAMP, auto-updates)

CREATE TABLE sboyd.game
(
game_id smallint auto_increment primary key,
title varchar(255) not null,
platform_id smallint unsigned,
publisher_id smallint unsigned,
rental_rate decimal(4, 2) not null default 4.99,
rating enum('E','E10+','T','M','AO') default 'E',
last_update timestamp on update current_timestamp,
foreign key (platform_id) references sboyd.platform(platform_id),
foreign key (publisher_id) references sboyd.publisher(publisher_id)
);

#Q11

INSERT INTO sboyd.platform (name, manufacturer) VALUES
('PlayStation 5', 'Sony'),
('Xbox Series X', 'Microsoft'),
('Nintendo Switch', 'Nintendo');

select * from sboyd.platform;

INSERT INTO sboyd.publisher (name, country) VALUES
('Nintendo', 'Japan'),
('Electronic Arts', 'United States'),
('Ubisoft', 'France');

select * from sboyd.publisher;

#Q12
INSERT INTO sboyd.game (title, platform_id, publisher_id, rental_rate, rating) VALUES
('The Legend of Zelda: Breath of the Wild', 3, 1, 4.99, 'E10+'),
('The Sims 4', 1, 2, 2.99, 'T'),
('Assassin''s Creed Shadows', 2, 3, 4.99, 'M'),
('Pokémon Legends: Z-A', 3, 1, 3.50, 'E10+'),
('Dragon Age', 1, 2, 1.99, 'M');

select * from sboyd.game;

#Q13
#Create a view called affordable_games_view that shows games with rental_rate < $5.00.
#Show: game_id, title, platform name (use JOIN), rental_rate, and rating.

CREATE OR REPLACE VIEW sboyd.affordable_games AS
select a.game_id, a.title, b.`name` as platform_name, a.rental_rate, a.rating from sboyd.game as a inner join
sboyd.platform as b on a.platform_id = b.platform_id
where a.rental_rate < 5.00;

select * from sboyd.affordable_games order by rental_rate, title;

#Q14
#Perform the following updates:
#a) Update all Nintendo Switch games to have a rental_rate of $5.99
#b) Increase rental_rate by 10% for all games rated 'M' (Mature)

select * from sboyd.game;

UPDATE sboyd.game
SET rental_rate = 5.99
WHERE publisher_id = 1;

select * from sboyd.game;

select * from sboyd.game;

UPDATE sboyd.game
SET rental_rate = round(rental_rate + rental_rate*.10, 2)
WHERE rating = 'M';

select * from sboyd.game;

#Q15
#Delete the publisher "Ubisoft" and handle any associated games.
#Required:
#•	First, identify which games are affected (write a SELECT query)
#•	Choose to either: delete affected games OR reassign them to another publisher
#•	Delete the publisher record
#•	Explain your approach in 2-3 sentences

select a.*, b.`name` as publisher_name from sboyd.game as a inner join 
sboyd.publisher as b on a.publisher_id = b.publisher_id 
where b.`name` like '%Ubisoft%';

DELETE FROM sboyd.game WHERE publisher_id = 3;
select * from sboyd.game;

DELETE FROM sboyd.publisher WHERE publisher_id = 3;
select * from sboyd.publisher;

#I decided to delete the game first where publisher is Ubisoft because it didn't make sense to put it under another publisher.
#First I crafted a query checking if any game has a publisher with a name containing Ubisoft,
#then I deleted the games where publisher id is 3 because I identified that is Ubisoft,
#and finally deleted the publisher record for Ubisoft


#Q16
#Write a query that shows which films are in the "Action" category.
#Show: film title, category name, rental_rate, and length.
#Order by rental_rate DESC. Limit to 10 results.
select distinct c.title, a.category_name, c.rental_rate, c.length from (select category_id, `name` as category_name from sakila.category where `name` like '%Action%') as a
inner join sakila.film_category as b on a.category_id = b.category_id
inner join sakila.film as c on b.film_id = c.film_id
order by c.rental_rate desc limit 10;

#First create the query that pulls the action category record. Then I have to join it film_category to get film_id to join
#and get the remaining fields from the film table. 

#Q17
#Find all rentals for customer_id = 1.
#Show: customer name (first and last), film title, rental_date, return_date.
#Order by rental_date DESC.
select distinct c.first_name, c.last_name, d.title, a.rental_date, a.return_date from sakila.rental as a inner join
sakila.inventory as b on a.inventory_id = b.inventory_id
inner join sakila.customer as c on b.store_id = c.store_id
inner join sakila.film as d on b.film_id = d.film_id
where c.customer_id = 1
order by a.rental_date desc;

#I used the inventory table to connect rental and customer tables together. Then used the inventory join to film table
#to get film information. 

#Q18
#Create a comprehensive game catalog showing:
#game title, platform name, manufacturer, publisher name, rental_rate, and rating.
#Order by platform name, then by title.
select distinct a.title, b.`name` as platform_name, b.manufacturer, c.`name` as publisher_name, a.rental_rate, a.rating
from sboyd.game as a inner join sboyd.platform as b on a.platform_id = b.platform_id
inner join sboyd.publisher as c on a.publisher_id = c.publisher_id
order by platform_name, title;

#I used game as the first table to select from then join in the following order: game -> platform -> publisher; Using platform id and
#publisher id to connect them.

#Q19
#Count how many games are available on each platform.
#Show: platform name, manufacturer, and game count.
#Order by game count DESC.
select a.`name` as platform_name, a.manufacturer, count(distinct b.game_id) as game_count
from sboyd.platform as a inner join sboyd.game as b on a.platform_id = b.platform_id
group by platform_name, manufacturer
order by game_count desc;

#In order to get the count of games per platform, you have to join the platform table with the game table. 
#I would then do a distinct count for game id to get the correct game count. 

#Q20
#Create a combined report showing titles from both films and games.
#Show: type ('Film' or 'Game'), title, rental_rate, and rating.
#Order by type, then by title.
#SELECT 'Film' AS type, title, rental_rate, rating
#FROM sakila.film
#UNION
#SELECT 'Game' AS type, title, rental_rate, rating
#FROM sakila_games.game
#ORDER BY type, title;
#Analysis: Compare the average rental rates between films and games. Which is higher?

CREATE VIEW sboyd.film_or_game_analysis AS 
SELECT 'Film' AS type, title, rental_rate, rating
FROM sakila.film
UNION
SELECT 'Game' AS type, title, rental_rate, rating
FROM sboyd.game
ORDER BY type, title;

select avg(case when `type` = 'Game' then rental_rate else 0 end) as avg_game_rental_rate,
avg(case when `type` = 'Film' then rental_rate else 0 end) as avg_film_rental_rate from sboyd.film_or_game_analysis;

#The conclusion of the analysis is that the average rental rate for games or films is higher for films. 

#Q21
#Find all films with rental_rate above the average rental rate.
#Show: title, rental_rate, and the overall average (from subquery).
#Order by rental_rate DESC.
select title, rental_rate, (select avg(rental_rate) from sakila.film) as overall_average_rental_rate
from sakila.film where rental_rate > (select avg(rental_rate) from sakila.film)
group by title, rental_rate
order by rental_rate desc;

#Q22
#Find customers who have spent more than $100 total on film rentals.
#Show: customer_id, customer name, and total amount spent.
#Order by total amount DESC.
select a.customer_id, concat(a.first_name, ' ', a.last_name) as customer_name, sum(case when b.amount is null then 0 else b.amount end) as total_payment
from sakila.customer as a left join sakila.payment as b on a.customer_id = b.customer_id
group by a.customer_id, customer_name having total_payment > 100 
order by total_payment desc;
