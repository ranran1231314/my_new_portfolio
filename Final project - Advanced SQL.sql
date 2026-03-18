--1. Exploring the data:
--First Question: Which genere was most successful in terms of sales in each location during the years 2010-2020?
--This is important because as a business we want to be able to judge which generes we should promote on every location for the next years.
--I will measure it using the Max function, on the sales columns of Europe, JAPAN and North America, group by genere. Additionaly I will add a where clause that
--specifies that the years shold be between 2010 AND 2020.

--Second Question: Which gaming platforms were more user friendly across the period between the years 2010 AND 2020?
--This is an important question because as a business we would like to develop more games, therefore we should know,
--which gaming platforms are more intuitive and simple using for the customers.
--I will measure it using an average function for the user score, group by platform AND year of release. I will order it by year of release.
--Then I will be able to see which platforms were rated higher every year.


--2. Games with multiple platforms:
--a. Games that have been released within 3 or more platforms:

--Calculation:

select distinct [name] 'Game Name',
count([name]) as 'Number of Platforms per Game',
count([name]) over (partition by 'number of platforms') as 'Total Games with at least 3 Platforms'
from video_games
group by [name]
having count([name])>=3
order by [name]

--Answer: 1283 Games


--b. Historical peak per genere:

with SumOfSales_cte as
(select genre,
year_of_release,
sum(global_sales) as sum_of_sales,
rank() over (partition by genre order by global_sales desc) as rnk

from video_games

group by genre, Year_of_Release, Global_Sales)


select 
Genre,
Year_of_Release,
max(sum_of_sales) as 'max sales'

from SumOfSales_cte

where rnk = 1
AND genre is NOT NULL

group by Genre, Year_of_Release

order by 'max sales' desc



--3. Finding the middle within the dataset:

with avg_cte as 

(
select
rating,
round(avg(critic_score),1) as normal_average,
round((sum(Critic_Score*Critic_Count) / sum(Critic_Count)),1) as weighted_average
from video_games

where Critic_Score is NOT NULL
group by rating
),


mode_cte as 
(
select
rating,
critic_score as mode,
count(*) as frequency,
rank() over (partition by rating order by count(*) desc) as rnk

from video_games

where Critic_Score is NOT NULL

group by rating, critic_score
)

select 

a.rating,
a.normal_average,
a.weighted_average,
m.mode 

from

avg_cte a 

left join mode_cte m on a.rating = m.rating


where rnk = 1
AND a.rating is NOT NULL


group by a.rating,
a.normal_average,
a.weighted_average,
m.mode

order by Rating asc



--The 2 ratings who has identical values across all 3 measures are K-A (Kids to Adults) and AO (Adults Only).
--The reason for it is that for both rating categories there is only 1 value of a score from the critics which is NOT NULL.
--Therefore the measures are not affected from many different values. 




--4. Data Scaffolding:


with global_sales_cte as 

(
select sum(global_sales) as Total_Sales,
Genre,
Platform,
Year_of_Release

from video_games

group by genre, platform, Year_of_Release
),

combinations_cte as 

(

SELECT DISTINCT A.Genre,
P.Platform,
Y.Year_of_release
FROM (select distinct genre from video_games) A

cross join (select distinct [platform] from video_games) P

cross join (select distinct year_of_release from video_games) Y


where genre is NOT NULL
AND [platform] is NOT NULL
AND Year_of_Release is NOT NULL

)

select distinct C.genre,
C.platform,
C.year_of_release,

case when GS.Total_Sales is NULL
then 0
else Total_Sales
end as Total_sales

from combinations_cte C

left join global_sales_cte GS
ON
C.Genre = GS.genre
AND C.Platform = GS.platform
AND C.Year_of_Release = GS.year_of_release


ORDER BY genre, platform, year_of_release, Total_sales desc






--5. year over year equation:


with YCalc_cte as 

(
select distinct platform, Year_of_Release, sum(global_sales) as Y_Total_Sales,
lag(sum(Global_Sales),1,null) over (partition by [platform] order by year_of_release) as last_year_sales,
(rank() over (partition by platform order by year_of_release)) as year_rank
from video_games

where platform is NOT NULL
AND year_of_release is NOT NULL
AND Year_of_Release <> 2020
group by [platform], Year_of_Release
),

YoY_cte as

(select *,
Round((Y_Total_sales-last_year_sales)/nullif(last_year_sales,0),3) as YoY_growth,
Round((Y_Total_sales-last_year_sales)/nullif(last_year_sales,0),3) * 100 as YoY_growth_percent
from ycalc_cte
),

Max_cte as
(select platform,
max(Yoy_growth) as max_growth_rate,
max(yoy_growth_percent) as max_growth_percent
from YoY_cte
group by [platform]
)

select distinct 
YC.platform,
year_of_release,
case when Y_total_sales is NULL
then 0
else Y_Total_sales
end as Total_sales,
max_growth_rate,
max_growth_percent



from YoY_cte YC

inner join Max_cte MX ON
YC.platform = MX.platform

where year_rank > 1
AND Yoy_growth=Max_growth_rate

order by max_growth_rate desc



--The platform with the max growth rate is GBA, for the year 2001
