SELECT * FROM [Portfolio Project]..[CovidDeaths]
ORDER BY 3,4;

--SELECT * FROM [Portfolio Project]..[CovidVaccinations]
--ORDER BY 3, 4



-- Select Data that we are going to be using
SELECT [location], [date], [total_cases], [new_cases], [total_deaths], [population]
FROM [Portfolio Project]..CovidDeaths
ORDER BY 1,2;



-- --------------------COUNTRY ZONE--------------------------------------

-- Total Cases vs Total Deaths ratio
-- Shows the probability of dying after contracting the virus
SELECT [location], [date], [total_cases], [new_cases], cast(total_deaths as INT), (cast(total_deaths as INT)/total_cases) * 100 AS DeathPercentage
FROM [Portfolio Project]..CovidDeaths
ORDER BY 1,2



-- Looking at Total Cases vs Population
--Shows the percentage of the population that contracted Covid
SELECT [location], [date], [population], [total_cases], (total_cases/[population]) * 100 AS CasesPerPopulation
FROM [Portfolio Project]..CovidDeaths
ORDER BY 1,2



-- Looking at countries with highest infection rate compared to population
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX(total_cases/population) * 100 AS PercentPopulationInfected
FROM [Portfolio Project]..CovidDeaths
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC



--Showing countries with highest Death Count
SELECT location, MAX(cast(total_deaths as INT)) AS TotalDeathCount
FROM [Portfolio Project]..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

-- --------------------COUNTRY ZONE--------------------------------------



-- --------------------CONTINENT ZONE--------------------------------------

--this is supposedly the right continent breakdown--
SELECT location, MAX(total_cases) AS ContinentalTotalCases, MAX(cast(total_deaths as INT)) AS ContinentTotalDeathCount
FROM [Portfolio Project]..CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY ContinentTotalDeathCount DESC


--LETS ROLL IT UP TO CONTINENT; we will drill down all the above codes for the continent


-- Total Cases vs Total Deaths ratio per continent
-- Shows the probability of dying after contracting the virus in each continent 
SELECT continent, date, total_cases, new_cases, cast(total_deaths as INT), (cast(total_deaths as INT)/total_cases) * 100 AS ContinentDeathPercentage
FROM [Portfolio Project]..CovidDeaths
WHERE CONTINENT is NOT NULL
ORDER BY 1, 3 DESC


-- Looking at Total Cases vs Population per continent
--Shows the percentage of the population that contracted Covid
SELECT continent, date, population, total_cases, (total_cases/population) * 100 AS ContinentCasesPerPopulation
FROM [Portfolio Project]..CovidDeaths
WHERE CONTINENT is NOT NULL
ORDER BY 1,2



-- Looking at continents with highest infection rate compared to population
SELECT continent, MAX(population) as ContinentPopulation, MAX(total_cases) AS HighestInfectionCount, MAX(total_cases/population) * 100 AS ContinentPercentPopulationInfected
FROM [Portfolio Project]..CovidDeaths
WHERE CONTINENT is NOT NULL
GROUP BY continent
ORDER BY ContinentPercentPopulationInfected DESC



--Showing continents with highest Death Count
SELECT continent, MAX(cast(total_deaths as INT)) AS ContinentTotalDeathCount
FROM [Portfolio Project]..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
--WHERE location like '%states%'
ORDER BY ContinentTotalDeathCount DESC


-- Showing Continents with the highest death count per population
SELECT continent, MAX(cast(total_deaths AS INT)) AS ContinentHighestDeathCount, MAX(cast(total_deaths AS INT)/population) * 100 AS ContinentPercentPopulationDeath
FROM [Portfolio Project]..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY ContinentPercentPopulationDeath DESC

-- Showing Continents with the highest death count per population
SELECT continent, total_deaths, cast(total_deaths AS INT)/population * 100 AS ContinentPercentPopulationDeath
FROM [Portfolio Project]..CovidDeaths
WHERE continent IS NOT NULL AND continent = 'Africa'
--GROUP BY continent
ORDER BY total_deaths DESC

-- --------------------CONTINENT ZONE--------------------------------------


--GLOBAL NUMBERS (daily numbers

SELECT date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as INT)), SUM(cast(new_deaths as INT))/SUM(new_cases) *100 AS DeathPercentage
FROM [Portfolio Project]..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1 DESC


-- Total So far
SELECT date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as INT)), SUM(cast(new_deaths as INT))/SUM(new_cases) *100 AS DeathPercentage
-- use CONVERT (int, column_name) to get same output as cast
FROM [Portfolio Project]..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1 DESC


--Check data in vaccinations table
SELECT * FROM [Portfolio Project]..CovidVaccinations


--join deaths and vaccinations table


SELECT * 
FROM [Portfolio Project]..CovidDeaths dea -- you can use AS or not..it works
JOIN [Portfolio Project]..CovidVaccinations vac 
ON dea.location = vac.location AND dea.date = vac.date



-- Total Population vs Vaccinations
-- select needed columns

SELECT dea.location, dea.date, dea.continent, dea.population, vac.new_vaccinations
FROM [Portfolio Project]..CovidDeaths dea -- you can use AS or not..it works
JOIN [Portfolio Project]..CovidVaccinations vac 
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY  1, 2


-- Rolling Count of new_vaccinations to give Total Vaccination (Use partition)

SELECT dea.location, dea.date, dea.continent, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) 
OVER 
(Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
FROM [Portfolio Project]..CovidDeaths dea -- you can use AS or not..it works
JOIN [Portfolio Project]..CovidVaccinations vac 
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 1, 2


-- USE Common Table Expressions (CTE)
-- vaccinations per population at each dates

With PopvsVac (Location, Date, Continent, Population, New_Vaccinations, RollingPeopleVaccinated)
AS (
SELECT dea.location, dea.date, dea.continent, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) 
OVER 
(Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
FROM [Portfolio Project]..CovidDeaths dea -- you can use AS or not..it works
JOIN [Portfolio Project]..CovidVaccinations vac 
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL)
-- ORDER BY 1, 2)

SELECT *, RollingPeopleVaccinated/Population*100 as MaxVacc

FROM PopvsVac



-- TEMP TABLE

DROP TABLE if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(location nvarchar(255),
date datetime,
Continent nvarchar(255),
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated

SELECT dea.location, dea.date, dea.continent, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) 
OVER 
(Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
FROM [Portfolio Project]..CovidDeaths dea -- you can use AS or not..it works
JOIN [Portfolio Project]..CovidVaccinations vac 
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
-- ORDER BY 1, 2)

SELECT *, RollingPeopleVaccinated/Population*100 as MaxVacc
 
FROM #PercentPopulationVaccinated



-- Create View to store data for visualizations

Create View 
PercentPopulationVaccinated as 
SELECT dea.location, dea.date, dea.continent, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) 
OVER 
(Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
FROM [Portfolio Project]..CovidDeaths dea -- you can use AS or not..it works
JOIN [Portfolio Project]..CovidVaccinations vac 
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 1, 2