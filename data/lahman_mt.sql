-- SELECT DISTINCT(playerid)
-- FROM collegeplaying
-- WHERE schoolid = 'vandy'


-- Lahman Baseball Database Exercise
-- this data has been made available online by Sean Lahman
-- you can find a data dictionary here


-- 1. Find all players in the database who played at Vanderbilt University. Create a list showing each player's first and last names as well as the total 
-- -- salary they earned in the major leagues. Sort this list in descending order by the total salary earned. Which Vanderbilt player earned the most money in the majors?
-- David Price seems to have earned the most money.

-- WITH vandy AS (SELECT
-- *
-- FROM collegeplaying
-- WHERE schoolid ='vandy')
-- SELECT
-- p.namefirst,
-- p.namelast,
-- SUM(s.salary) AS total_salary
-- FROM people as p
-- JOIN vandy
-- USING(playerid)
-- JOIN salaries as s
-- USING(playerid)
-- GROUP BY 1,2
-- ORDER BY SUM(s.salary) DESC;


-- 2. Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in -- 2016.
-- answer: Battery=938, Infield=661, Outfield=354

-- SELECT 
-- CASE WHEN pos='OF' THEN 'Outfield'
-- 	 WHEN pos IN ('SS', '1B', '2B', '3B') THEN 'Infield'
-- 	 WHEN pos IN ('P', 'C') THEN 'Battery'
-- 	 ELSE 'Benchwarmer' END AS group_position,
-- 	 COUNT(po) AS force_outs
-- FROM fielding
-- WHERE yearid = '2016'
-- GROUP BY 1;
 
 
-- 3. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends? (Hint: For this question, you might find it helpful to look at the generate_series function (https://www.postgresql.org/docs/9.1/functions-srf.html). If you want to see an example of this in action, check out this DataCamp video: https://campus.datacamp.com/courses/exploratory-data-analysis-in-sql/summarizing-and-aggregating-numeric-data?ex=6)
-- answer: Both strikeouts and homeruns have increased considerably over time, but appear to have leveled off the last few years.

-- Q FOR MICHAEL, per game strikeout, how does the * 1.0 thing work? Literally just saw it in an article and thought about using it.  

-- create bins
WITH bins AS (
    SELECT generate_series(1920, 2010, 10) AS lower,
           generate_series(1930, 2020, 10) AS upper)
-- count values in each bin
SELECT 
	lower, 
	upper, 
	ROUND(SUM(sto.so * 1.0)/SUM(ghome * 1.0), 2) AS avg_strikeouts,  
	ROUND(SUM(sto.hr * 1.0)/SUM(ghome * 1.0), 2) AS avg_homeruns
-- left join keeps bins
 FROM teams as sto
   LEFT JOIN bins AS b
       ON yearid >= lower
       AND yearid < upper
GROUP BY lower, upper
ORDER BY lower;


-- 4. Find the player who had the most success stealing bases in 2016, where success is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted at least 20 stolen bases. Report the players' names, number of stolen bases, number of attempts, and stolen base percentage.
-- answer = It appears that Jonathan Villar is the most successful base stealer for 2016.

--Q for Michael.  How to cast as a percentage?/Having a problem with percentages...

WITH totals AS (
	SELECT *,
		(sb+cs) AS sb_total,
	ROUND((sb * 1.0)/((sb+cs) * 1.0), 2) AS sb_percentage
    FROM batting
    WHERE yearid=2016)
SELECT 
  p.namefirst,
  p.namelast,
  sb,
  cs,
  sb_total,
  sb_percentage
FROM people AS p
JOIN totals
USING(playerid)
WHERE sb_total >= 20
ORDER BY sb_percentage DESC;


-- 5. From 1970 to 2016, what is the largest number of wins for a team that did not win the world series? What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion; determine why this is the case. Then redo your query, excluding the problem year. How often from 1970 to 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?
-- answers:
-- Largest number of wins for NON WS winner: 116
-- Smallest number of wins for WS winner: 63 (including the strike of 1981)
-- Smallest number of wins for WS winner: 74 (excluding the strike year of 1981)
-- What percentage of the time did a team that won the WS also win the most number of games?: 

--Q For Michael.  Do I need to do a case statement for part 4, or is there and easier way?

--teams that did not win the world series, ordered by year DESC
-- WITH ws AS(SELECT
-- w,
-- teamid,
-- wswin AS ws_win,
-- yearid
-- FROM teams
-- WHERE 
-- --wswin = 'N' 
-- --AND 
-- yearid BETWEEN 1970 AND 2016
-- AND yearid != 1981
-- ORDER BY yearid DESC),
WITH nws AS(SELECT
w,
teamid,
wswin AS ws_win,
yearid
FROM teams
WHERE 
--wswin = 'N' 
--AND 
yearid BETWEEN 1970 AND 2016
AND yearid != 1981
ORDER BY yearid DESC)
--Max number of games won by year, excluding 1981
SELECT
  nws.ws_win, 
  MAX(nws.w) AS not_ws_winner,
  nws.yearid AS year
FROM teams
INNER JOIN nws
USING(teamid)
--JOIN ws
--USING(teamid)		   
GROUP BY year, 1
ORDER BY year ASC;



-- 6. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.

-- SELECT
-- playerid, 
-- awardid,
-- yearid, 
-- FROM awardsmanagers
-- WHERE awardid = 'TSN Manager of the Year';

-- SELECT
-- lgID
-- FROM ManagersHalf;

-- 7. Which pitcher was the least efficient in 2016 in terms of salary / strikeouts? Only consider pitchers who started at least 10 games (across all teams). Note that pitchers often play for more than one team in a season, so be sure that you are counting all stats for each player.

-- 8. Find all players who have had at least 3000 career hits. Report those players' names, total number of hits, and the year they were inducted into the hall of fame (If they were not inducted into the hall of fame, put a null in that column.) Note that a player being inducted into the hall of fame is indicated by a 'Y' in the inducted column of the halloffame table.

-- 9. Find all players who had at least 1,000 hits for two different teams. Report those players' full names.

-- 10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.