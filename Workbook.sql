-- Data Analyst Portfolio Project | SQL Data Exploration | Project 1/4
-- https://www.youtube.com/watch?v=qfyynHBFOsM
-- https://github.com/AlexTheAnalyst/PortfolioProjects
-- SOURCE at 2022-06-03 https://covid.ourworldindata.org/data/owid-covid-data.csv
-- Imported in SQL 2019 Developer
-- Import numbers as FLOAT to avoid CAST/CONVERT

SELECT *
FROM PortfolioProject..CovidDeaths
ORDER BY 3,4;

--SELECT *
--FROM PortfolioProject..CovidVaccinations
--ORDER BY 3,4

SELECT 
	[location]
	,[Date]
	,total_cases
	,new_cases
	,total_deaths
	,[population]
FROM
	PortfolioProject..CovidDeaths
ORDER BY
	1,2

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

SELECT TOP 1
	[location]
	,[Date]
	,total_cases
	,total_deaths
	,(CAST(total_deaths AS FLOAT)/total_cases) * 100 AS DeathPercentage

FROM
	PortfolioProject..CovidDeaths
WHERE
	[location] = 'Australia'
ORDER BY
	total_cases desc

-- Looking at Total Cases vs Population
-- Percentage of population that got Covid

SELECT TOP 1
	[location]
	,[Date]
	,[population]
	,total_cases
	,(total_cases/CAST([population] AS FLOAT)) * 100 AS CasePercentage

FROM
	PortfolioProject..CovidDeaths
WHERE
	[location] = 'Australia'
ORDER BY
	total_cases desc

-- Countries with Highest Infection Rate compared to Population

SELECT
	[location]
	,[population]
	,MAX(total_cases) AS HighestInfectionCount
	,Max((total_cases/CAST([population] AS FLOAT)))*100 AS PercentPopulationInfected
FROM
	PortfolioProject..CovidDeaths
--Where location like '%states%'
GROUP BY
	[location], [population]
ORDER BY
	PercentPopulationInfected DESC

-- Countries with Highest Death Count per Population

SELECT 
	[location]
	,MAX(Total_deaths) AS TotalDeathCount
FROM
	PortfolioProject..CovidDeaths
--Where location like '%states%'
WHERE
	continent is not null 
GROUP BY
	[location]
ORDER BY
	TotalDeathCount DESC

-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

SELECT
	continent
	,MAX(Total_deaths) AS TotalDeathCount
FROM
	PortfolioProject..CovidDeaths
WHERE
	continent IS NOT NULL
GROUP BY
	continent
ORDER BY
	TotalDeathCount DESC

-- GLOBAL NUMBERS

SELECT
	SUM(new_cases) AS total_cases
	,SUM(new_deaths) AS total_deaths
	,SUM(new_deaths)/SUM(CAST(New_Cases AS FLOAT))*100 AS DeathPercentage
FROM
	PortfolioProject..CovidDeaths
WHERE
	continent IS NOT NULL
ORDER BY
	1,2


-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT
	dea.continent
	,dea.[location]
	,dea.[date]
	,dea.[population]
	,vac.new_vaccinations
	,SUM(vac.new_vaccinations) OVER (
			PARTITION BY dea.[location]
			ORDER BY dea.[location],dea.[date]
			) AS RollingPeopleVaccinated
	--, (RollingPeopleVaccinated/population)*100
FROM
	PortfolioProject..CovidDeaths dea
	JOIN PortfolioProject..CovidVaccinations vac
	ON dea.[location] = vac.[location] AND dea.[date] = vac.[date]
WHERE
	dea.continent IS NOT NULL
ORDER BY
	2,3

-- USE CTE
With PopVsVac ( continent,[location],[date],[population],new_vaccinations,RollingPeopleVaccinated)
AS (
		SELECT
			dea.continent
			,dea.[location]
			,dea.[date]
			,dea.[population]
			,vac.new_vaccinations
			,SUM(vac.new_vaccinations) OVER (
					PARTITION BY dea.[location]
					ORDER BY dea.[location],dea.[date]
					) AS RollingPeopleVaccinated
			--, (RollingPeopleVaccinated/population)*100
		FROM
			PortfolioProject..CovidDeaths dea
			JOIN PortfolioProject..CovidVaccinations vac
			ON dea.[location] = vac.[location] AND dea.[date] = vac.[date]
		WHERE
			dea.continent IS NOT NULL
		-- ORDER BY	2,3
	)
SELECT 
	*
	,(RollingPeopleVaccinated/CAST([population] AS FLOAT))*100 AS 'Percentage'
FROM
	PopVsVac
ORDER BY
	2,3

-- Using Temp Table to perform Calculation on Partition By in previous query

DROP TABLE
	IF EXISTS
	#PercentPopulationVaccinated
CREATE TABLE
	#PercentPopulationVaccinated
(
	Continent nvarchar(255)
	,[location] nvarchar(255)
	,[date] datetime
	,[population] numeric
	,New_vaccinations numeric
	,RollingPeopleVaccinated numeric
)

INSERT INTO 
	#PercentPopulationVaccinated
		SELECT
			dea.continent
			,dea.[location]
			,dea.[date]
			,dea.[population]
			,vac.new_vaccinations
			,SUM(vac.new_vaccinations) OVER (
					PARTITION BY dea.[location]
					ORDER BY dea.[location],dea.[date]
					) AS RollingPeopleVaccinated
			--, (RollingPeopleVaccinated/population)*100
		FROM
			PortfolioProject..CovidDeaths dea
			JOIN PortfolioProject..CovidVaccinations vac
			ON dea.[location] = vac.[location]
			AND dea.[date] = vac.[date]
		-- WHERE
			-- dea.continent IS NOT NULL
		-- ORDER BY	2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated

-- Creating View to store data for later visualizations

CREATE VIEW
	PercentPopulationVaccinated AS
		SELECT
			dea.continent
			,dea.[location]
			,dea.[date]
			,dea.[population]
			,vac.new_vaccinations
			,SUM(vac.new_vaccinations) OVER (
					PARTITION BY dea.[location]
					ORDER BY dea.[location],dea.[date]
					) AS RollingPeopleVaccinated
			--, (RollingPeopleVaccinated/population)*100
		FROM
			PortfolioProject..CovidDeaths dea
			JOIN PortfolioProject..CovidVaccinations vac
			ON 
				dea.[location] = vac.[location]
			AND dea.[date] = vac.[date]
		 WHERE
			 dea.continent IS NOT NULL

