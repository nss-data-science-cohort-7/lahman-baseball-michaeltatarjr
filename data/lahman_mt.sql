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
-- SUM(s.salary)::int::MONEY AS total_salary
-- FROM people as p
-- JOIN vandy
-- USING(playerid)
-- JOIN salaries as s
-- USING(playerid)
-- GROUP BY 1,2
-- ORDER BY SUM(s.salary) DESC;

-- David Price is correct, but the playerid is not the primary key.  

WITH vandy_players AS 
(SELECT DISTINCT playerid
FROM collegeplaying	
WHERE schoolid = 'vandy') 
SELECT 
namefirst || ' ' || namelast AS fullname, 
SUM(salary)::int::MONEY AS total_salary
FROM salaries
INNER JOIN vandy_players
USING(playerid)
INNER JOIN people
USING(playerid)
GROUP BY fullname 
ORDER BY total_salary DESC;

-- 2. Using the fielding table, group players into three groups based on their position: label players with position OF as "Outfield", those with position "SS", "1B", "2B", and "3B" as "Infield", and those with position "P" or "C" as "Battery". Determine the number of putouts made by each of these three groups in -- 2016.
-- answer: Battery=938, Infield=661, Outfield=354

-- SELECT 
-- CASE WHEN pos='OF' THEN 'Outfield'
-- 	 WHEN pos IN ('SS', '1B', '2B', '3B') THEN 'Infield'
-- 	 WHEN pos IN ('P', 'C') THEN 'Battery'
-- 	 ELSE 'Benchwarmer' END AS group_position,
-- 	 SUM(po) AS force_outs
-- FROM fielding
-- WHERE yearid = '2016'
-- GROUP BY 1;



 
-- 3. Find the average number of strikeouts per game by decade since 1920. Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends? (Hint: For this question, you might find it helpful to look at the generate_series function (https://www.postgresql.org/docs/9.1/functions-srf.html). If you want to see an example of this in action, check out this DataCamp video: https://campus.datacamp.com/courses/exploratory-data-analysis-in-sql/summarizing-and-aggregating-numeric-data?ex=6)
-- answer: Both strikeouts and homeruns have increased considerably over time, but appear to have leveled off the last few years.



-- create bins
WITH bins AS (
    SELECT generate_series(1920, 2010, 10) AS lower,
           generate_series(1930, 2020, 10) AS upper)
-- count values in each bin
SELECT 
	lower, 
	upper, 
	ROUND(SUM(sto.so * 1.0)/SUM(g * 1.0), 2) AS avg_strikeouts,  
	ROUND(SUM(sto.hr * 1.0)/SUM(g * 1.0), 2) AS avg_homeruns     
-- left join keeps bins
 FROM teams as sto
   LEFT JOIN bins AS b
       ON yearid >= lower
       AND yearid < upper
GROUP BY lower, upper
ORDER BY lower;


-- Alex B's code
-- WITH decade AS (
-- 	SELECT GENERATE_SERIES(1920, 2010, 10) AS decade_start,
-- 		GENERATE_SERIES(1929, 2019, 10) AS decade_end
-- )

-- SELECT decade_start, 
-- 	ROUND(SUM(SO)/CAST(SUM(G) AS DECIMAL),2) AS strikeouts_per_game, 
-- 	ROUND(SUM(HR)/CAST(SUM(G) AS DECIMAL),2) AS homeruns_per_game
-- FROM teams
-- LEFT JOIN decade
-- ON yearID BETWEEN decade_start AND decade_end
-- WHERE yearID>=1920
-- GROUP BY decade_start
-- ORDER BY decade_start DESC;

-- 4. Find the player who had the most success stealing bases in 2016, where success is measured as the percentage of stolen base attempts which are successful. (A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted at least 20 stolen bases. Report the players' names, number of stolen bases, number of attempts, and stolen base percentage.
-- answer = It appears that Chris Owings is the most successful base stealer for 2016.

--Q for Michael.

-- WITH totals AS (
-- 	SELECT *,
-- 		(sb+cs) AS sb_total,
-- 	ROUND((sb * 1.0)/((sb+cs) * 1.0), 2) AS sb_percentage
--     FROM batting
--     WHERE yearid=2016)
-- SELECT 
--   p.namefirst,
--   p.namelast,
--   sb,
--   cs,
--   sb_total,
--   sb_percentage
-- FROM people AS p
-- JOIN totals
-- USING(playerid)
-- WHERE sb_total >= 20
-- ORDER BY sb_percentage DESC;


-- 5. From 1970 to 2016, what is the largest number of wins for a team that did not win the world series? What is the smallest number of wins for a team that did win the world series? Doing this will probably result in an unusually small number of wins for a world series champion; determine why this is the case. Then redo your query, excluding the problem year. How often from 1970 to 2016 was it the case that a team with the most wins also won the world series? What percentage of the time?
-- answers:
-- Largest number of wins for NON WS winner: 116
-- Smallest number of wins for WS winner: 63 (including the strike of 1981)
-- Smallest number of wins for WS winner: 74 (excluding the strike year of 1981)
-- What percentage of the time did a team that won the WS also win the most number of games?: 

-- Q For Michael.  Do I need to do a case statement for part 4, or is there and easier way?

-- Teams that did not win the world series, ordered by year DESC
WITH nws AS(SELECT
w,
teamid,
wswin AS ws_win,
yearid
FROM teams
WHERE 
wswin = 'N' 
AND 
yearid BETWEEN 1970 AND 2016
AND yearid != 1981
ORDER BY yearid DESC),
-- Teams that did win the world series, ordered by year DESC
ws AS(SELECT
w,
teamid,
wswin AS not_win,
yearid
FROM teams
WHERE 
-- wswin = 'N' 
-- AND 
yearid BETWEEN 1970 AND 2016
AND yearid != 1981
ORDER BY yearid DESC)
-- Max number of games won by year, excluding 1981
SELECT
--  ws.ws_win,
--  nws.not_win, 
  MAX(nws.w) AS not_ws_winner,
  MAX(ws.w) AS ws_winner,
  nws.yearid AS year
FROM teams
INNER JOIN nws
USING(teamid)
JOIN ws
USING(teamid)		   
GROUP BY year
ORDER BY year ASC;

-- COULD HAVE USED A sliding window here?

-- d.
-- -NOTE: You have to compare integers to integers here.  This doesn't work...
-- CASE WHEN nws.ws_win= 'Y' AND MAX(nws.w) THEN '1'
--            ELSE '0' END AS win_and_win_count,
-- COUNT(yearid) AS yearid_count,
-- ((win_and_win_count * 1.0)/(yearid_count * 1.0)) AS overall,


-- 6. Which managers have won the TSN Manager of the Year award in both the National League (NL) and the American League (AL)? Give their full name and the teams that they were managing when they won the award.

-- -- league info
-- WITH league AS(SELECT
-- playerid, 
-- awardid,
-- COUNT(DISTINCT lgid) AS league_count
-- FROM awardsmanagers
-- WHERE awardid = 'TSN Manager of the Year' 
-- AND
-- yearid > 1986
-- GROUP BY 1, 2),
-- --  manager info
-- p1 AS(SELECT
-- namefirst,
-- namelast,
-- playerid	  
-- FROM people)
-- SELECT
-- p1.namefirst,
-- p1.namelast,
-- league_count
-- FROM league
-- --JOIN league
-- --USING(playerid)
-- JOIN p1
-- USING(playerid)
-- WHERE league_count = '2'


-- 7. Which pitcher was the least efficient in 2016 in terms of salary / strikeouts? Only consider pitchers who started at least 10 games (across all teams). Note that pitchers often play for more than one team in a season, so be sure that you are counting all stats for each player.

-- Q for Michael.  How to make the below distinct?

-- -- select out pitcher info. Note that a few pitchers had 0 strikeouts.  
-- WITH p AS(SELECT
-- playerid,
-- SUM(p.so) AS so
-- FROM pitching AS p
-- WHERE 
-- --so != '0'
-- --AND
-- GS >= 10
-- GROUP BY playerid )
-- SELECT
-- namefirst || ' ' || namelast AS fullname, 
-- playerid,
-- SUM(salary)::int::MONEY,
-- so,
-- (s.salary/so)::int::MONEY AS cost_per_strikeout
-- FROM salaries AS s
-- JOIN p
-- USING(playerid)
-- JOIN people
-- USING(playerid)
-- WHERE yearid = '2016'
-- GROUP BY 1, playerid, so, salary
-- ORDER BY cost_per_strikeout DESC;


-- 8. Find all players who have had at least 3000 career hits. Report those players' names, total number of hits, and the year they were inducted into the hall of fame (If they were not inducted into the hall of fame, put a null in that column.) Note that a player being inducted into the hall of fame is indicated by a 'Y' in the inducted column of the halloffame table.

-- Q for Michael, again, crazy high hits????

-- SELECT
-- 	CASE WHEN h.inducted = 'Y' THEN h.yearID
-- 	   ELSE NULL END AS inducted,
-- 	namefirst || ' ' || namelast AS fullname, 
-- 	playerid,
-- 	SUM(h) AS hits
-- 	-- h.yearID
-- FROM batting AS b
-- JOIN people
-- USING(playerid)
-- JOIN HallofFame AS h
-- USING(playerid)
-- GROUP BY 1, 2, 3
-- HAVING SUM(h) > 3000
-- ORDER BY hits DESC;


-- 9. Find all players who had at least 1,000 hits for two different teams. Report those players' full names.

With hits AS(SELECT
playerid,
teamid,
SUM(b.h)
FROM batting AS b
GROUP BY 1, 2
HAVING SUM(b.h) > 1000)
SELECT
namefirst || ' ' || namelast AS fullname
FROM people AS p
JOIN hits
USING(playerid)
GROUP BY namefirst, namelast
HAVING COUNT(teamid) > 1;

-- 10. Find all players who hit their career highest number of home runs in 2016. Consider only players who have played in the league for at least 10 years, and who hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.



