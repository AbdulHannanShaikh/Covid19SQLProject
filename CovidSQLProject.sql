SELECT *
FROM Covid..CovidDeathss$;

--SELECT *
--FROM Covid..CovidVac$;

-- Select data that we are going to be using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM Covid..CovidDeathss$
ORDER BY 1,2;

-- Looking at Total Cases vs Total deaths

SELECT location, date, total_cases, total_deaths, (total_deaths / total_cases) * 100 AS death_percent
FROM Covid..CovidDeathss$
WHERE location = 'Pakistan'
ORDER BY 1,2;

-- Looking at total cases vs population; shows us how much of the pop got covid

SELECT location, date, total_cases, population, (total_cases / population) * 100 AS infected_percent
FROM Covid..CovidDeathss$
WHERE location = 'pakistan'
ORDER BY 1,2;

-- Looking at countries that has the most infected rate

SELECT location, MAX(total_cases) as max_total_cases, population, MAX(total_cases / population) * 100 AS max_infected_percent
FROM Covid..CovidDeathss$
GROUP BY location, population
ORDER BY max_infected_percent DESC;

-- Looking at countries that has most deaths count

SELECT location, MAX(CAST(total_deaths AS bigint)) AS total_death_count
FROM Covid..CovidDeathss$
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC;

-- Looking at total deaths by continent

SELECT location, MAX(CAST(total_deaths AS bigint)) AS total_death_count
FROM Covid..CovidDeathss$
WHERE location IN ('North America', 'South America', 'Asia', 'Europe', 'Africa', 'Oceania')
GROUP BY location
ORDER BY total_death_count DESC;

-- Death by date globally

Select date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From Covid..CovidDeathss$
--Where location like '%states%'
where continent is not null 
Group By date
order by 1

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT D.continent,D.location, D.date, D.population, V.new_vaccinations,
SUM(CAST(V.new_vaccinations AS int)) OVER(PARTITION BY D.location ORDER BY D.location, V.date) AS RollingPeopleVaccinated
FROM Covid..CovidDeathss$ D
JOIN Covid..CovidVac$ V ON D.date = V.date AND D.location = V.location
WHERE D.continent IS NOT NULL
ORDER BY D.location, V.date

-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From Covid..CovidDeathss$ dea
Join Covid..CovidVac$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100 AS RollingPeopleVaccinatedPercentage
From PopvsVac;

-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From Covid..CovidDeathss$ dea
Join Covid..CovidVac$ vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated AS RollingPeopleVaccinatedPercentage

-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From Covid..CovidDeathss$ dea
Join Covid..CovidVac$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 