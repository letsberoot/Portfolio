/*
Originalquelle: https://ourworldindata.org/covid-deaths
Der Originaldatensatz wurde zur Veranschaulichung des Join Befehles vorab mittels Excel in zwei separate Dateien zerteilt.

Skills: Creating Views, Converting Data Types, Aggregate Functions, Joins, Windows Functions, Temp Tables CTE's.

*/

Select *
FROM Covid..CovidDeaths
ORDER BY 3,4


-- Select *
-- FROM Covid..CovidVaccines
-- ORDER BY 3,4


-- Auswählen der Daten, mit denen wir arbeiten

SELECT Location, date, total_cases, new_cases, cast(total_deaths as bigint) as total_deaths, population
FROM Covid..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 5 DESC


-- Fallzahlen zu Todeszahlen

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
FROM Covid..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2


-- Fallzahlen zu Todeszahlen in Deutschland am 26.01.2022

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
FROM Covid..CovidDeaths
WHERE continent IS NOT NULL
and location LIKE 'Germany'
AND Date = '2022-01-26'
ORDER BY 1,2


-- Fallzahlen zu Todeszahlen in "enthält = states"

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
FROM Covid..CovidDeaths
WHERE continent IS NOT NULL
and location like '%states%'
ORDER BY 1,2


-- Totale Fälle in Relation  Gesamtbevölkerung in Deutschland

SELECT Location, date, population, total_cases, (total_cases/population)*100 as covid_cases_percentage
FROM Covid..CovidDeaths
WHERE continent IS NOT NULL
and location like 'Germany'
ORDER BY 1,2


-- Globale Betrachtung
-- Höchste Infektionsrate zur Population weltweit absteigend

SELECT Location, population, MAX(total_cases) as highest_infection_count, MAX((total_cases)/population)*100 as covid_cases_percentage
FROM Covid..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY Location, population
ORDER BY covid_cases_percentage desc


-- Höchste Todesrate zur Population weltweit absteigend

SELECT Location, MAX(cast(total_deaths as int)) as total_death_count
FROM Covid..CovidDeaths
WHERE continent IS NOT NULL
AND total_deaths IS NOT NULL
GROUP BY Location
ORDER BY total_death_count desc


-- Höchste Todesrate zur Population weltweit absteigend & Länder in denen mehr als 100.000 Menschen verstorben sind

SELECT Location, MAX(cast(total_deaths as int)) as total_death_count
FROM Covid..CovidDeaths
WHERE continent IS NOT NULL
AND total_deaths IS NOT NULL
GROUP BY Location
HAVING MAX(cast(total_deaths as int)) > 100000
ORDER BY total_death_count desc


-- Höchste Todesrate zur Population pro Kontinent, absteigend, > 1.000.000 Tote

SELECT location, MAX(cast(total_deaths as int)) as total_death_count
FROM Covid..CovidDeaths
WHERE continent is NULL
GROUP BY location
HAVING MAX(cast(total_deaths as int)) > 1000000
ORDER BY total_death_count desc


-- Covid Fälle, Covid tote + prozentualer Anteil der Verstorbenen erkrankten

SELECT date, location, SUM(new_cases) as total_cases, SUM(cast(new_deaths as bigint)) as total_deaths, (SUM(cast(new_deaths as int))/SUM(new_cases))*100 as death_percentage
FROM Covid..CovidDeaths
WHERE continent is not NULL
GROUP BY date, location
ORDER BY 1,2 desc


-- Wie viele Menschen sind weltweit geimpft

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM Covid..CovidDeaths dea
JOIN Covid..CovidVaccinations vac
    ON dea.LOCATION = vac.LOCATION
    AND dea.date = vac.date
WHERE dea.continent is not NULL
ORDER BY 1,2,3


-- Wie viele Menschen sind in den Ländern geimpft

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,SUM(Convert(bigint, new_vaccinations)) OVER (PARTITION BY dea.location)
FROM Covid..CovidDeaths dea
JOIN Covid..CovidVaccinations vac
    ON dea.LOCATION = vac.LOCATION
    AND dea.date = vac.date
WHERE dea.continent is not NULL
AND vac.new_vaccinations is not null
ORDER BY 6 DESC


-- Wie viele Menschen sind in den Ländern geimpft + kumulierte Werte

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,SUM(Convert(bigint, new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date ROWS UNBOUNDED PRECEDING) AS vac_cum
FROM Covid..CovidDeaths dea
JOIN Covid..CovidVaccinations vac
    ON dea.LOCATION = vac.LOCATION
    AND dea.date = vac.date
WHERE dea.continent is not NULL
AND vac.new_vaccinations is not null
ORDER BY 2,3


-- CTE
-- Prozentual geboosterter Anteil Bevölkerung

WITH PopvsVBoosterd (continent, Location, Date, population, new_vaccinations, boo_cum)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,SUM(Convert(bigint, new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date ROWS UNBOUNDED PRECEDING) AS boo_cum
FROM Covid..CovidDeaths dea
JOIN Covid..CovidVaccinations vac
    ON dea.LOCATION = vac.LOCATION
    AND dea.date = vac.date
WHERE dea.continent is not NULL
AND vac.new_vaccinations is not null
)
Select *, (boo_cum/population)*100
From PopvsVBoosterd
WHERE date = '2022-01-25'

-- TEMP Table
-- Prozentual geboosterter Anteil Bevölkerung

DROP TABLE IF EXISTS #PercentPopulationBoostert
CREATE Table #PercentPopulationBoostert
(
    Continent nvarchar(255),
    Location  nvarchar(255),
    Date  nvarchar(255),
    Population numeric,
    total_boosters numeric,
    boo_cum numeric
)
INSERT INTO #PercentPopulationBoostert
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
,SUM(Convert(bigint, total_boosters)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date ROWS UNBOUNDED PRECEDING) AS boo_cum
FROM Covid..CovidDeaths dea
JOIN Covid..CovidVaccinations vac
    ON dea.LOCATION = vac.LOCATION
    AND dea.date = vac.date
WHERE dea.continent is not NULL

Select location, total_boosters, (boo_cum/population) as Toll
From #PercentPopulationBoostert
WHERE date = '2022-01-25'
AND total_boosters is not NULL
AND boo_cum is not NULL
ORDER BY 3 DESC