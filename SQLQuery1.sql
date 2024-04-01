-- Selecting everything and exploring data. Continent should be null (if it is, we're looking at a data for the whole continent).
SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

-- Looking at the percentage of total deaths vs total cases in the Czech Republic
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location like '%czech%'
AND continent IS NOT NULL
ORDER BY 1,2

-- Looking at the percentage of population in the Czech Republic that got Covid
SELECT location, date, population, total_cases, (total_cases/population)*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE location like '%czech%'
AND continent IS NOT NULL
ORDER BY 1,2

-- Looking at countries with highest infection rate vs population
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY 4 DESC

-- Showing countries with the highest death count per population
SELECT location, MAX(CAST(total_deaths as int)) AS TotalDeaths
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeaths DESC

-- Breaking things down by continent.
SELECT continent, MAX(CAST(total_deaths as int)) AS TotalDeaths
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeaths DESC

-- Global numbers.
SELECT SUM(new_cases) AS TotalCases, SUM(new_deaths) AS TotalDeaths, SUM(new_deaths)/SUM(new_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
--GROUP BY date
--HAVING SUM(new_deaths) <> 0
ORDER BY 1,2

-- Looking at total vaccination vs population
-- Using CTE
WITH PopVsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated) AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(vac.new_vaccinations) 
	OVER (PARTITION BY dea.location	ORDER BY dea.location, dea.date) 
	AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated/Population)*100 AS VaccinatedPercentage
FROM PopVsVac
ORDER BY 2,3

-- Using TEMP Table
DROP TABLE IF EXISTS #PercentagePopulationVaccinated
CREATE TABLE #PercentagePopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric,
)

INSERT INTO #PercentagePopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(vac.new_vaccinations) 
	OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) 
	AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *, (RollingPeopleVaccinated/Population)*100 AS VaccinatedPercentage
FROM #PercentagePopulationVaccinated
ORDER BY 2,3

-- Creating view to store data for later visualizations
Use PortfolioProject
Go
CREATE VIEW PercentagePopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	SUM(vac.new_vaccinations) 
	OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) 
	AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *
FROM PercentagePopulationVaccinated
