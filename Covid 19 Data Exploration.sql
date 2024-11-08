
/* Covid 19 Data Exploration */



--Firstly, I will select all the data from the CovidDeath table

SELECT *
FROM PortfolioProject..CovidDeaths
where continent != ''           --This line here means I'm avoiding grouping the entire continent
ORDER BY 3,4;

Alternately:

SELECT *
FROM PortfolioProject.dbo.CovidVaccinations
where continent != ''           --This line here means I'm avoiding grouping the entire continent
ORDER BY 1,2;


--Now I'm going to select the data that I will use
Select Location,date,total_cases,new_cases,total_deaths,population
FROM PortfolioProject..CovidDeaths
where continent != ''           --This line here means I'm avoiding grouping the entire continent
Order by 1,2;        --The Order by 1,2 means I order the outputs based on column 1 and column 2 (Location and date) in Asc


--This section, I use it to alter the tables and to change the datatypes
alter table PortfolioProject..CovidDeaths  --(This is how I changed the datatype)
alter column total_deaths float null;

alter table PortfolioProject..CovidDeaths  --(This is how I changed the datatype)
alter column total_cases bigint null;

alter table PortfolioProject..CovidDeaths  --(This is how I changed the datatype)
alter column Population float null;

alter table PortfolioProject..CovidDeaths  --(This is how I changed the datatype)
alter column new_deaths int null;

alter table PortfolioProject..CovidDeaths  --(This is how I changed the datatype)
alter column new_cases int null;



--Looking at Total Cases vs Total Deaths so I can get the exact percentage in a country with the name "South Africa" on it
Select Location,date,total_cases,total_deaths,(NullIf (total_deaths,0)/total_cases)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
where location like '%South% Africa'
and continent != ''
order by 1,2;


--Looking at the Total_Cases vs the Population
--Shows what percentage of population got Covid
Select Location,date,population,total_cases,(total_cases/population)*100 as PopulationPercentageInfected
FROM PortfolioProject..CovidDeaths
where location like '%South Africa%'
and continent != ''
order by 1,2;


--Looking at countries with Highest infection rate compared to Population
Select Location,Population, MAX(total_cases) AS HighestInfectionCount, Max((total_cases/NullIf (population,0)))*100 as MaximumCases
FROM PortfolioProject..CovidDeaths
where continent != ''
Group By Location, Population
order by MaximumCases desc;


--LET ME BREAK THINGS DOWN BY CONTINENT
--Showing the Continents with the Highest Death Count per Population
SELECT continent, Max(cast(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
where continent != ''
Group By continent
order by TotalDeathCount desc;


--Showing the Countries with the Highest Death Count per Population
SELECT location, Max(cast(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject..CovidDeaths
where continent != ''
Group By location
order by TotalDeathCount desc;


--GLOBAL NUMBERS / Percentage

Select SUM(new_cases) as Total_Cases, SUM(new_deaths) as Total_Deaths, Sum(new_deaths)/Sum(new_cases)*100 as DeathPercentage 
from CovidDeaths
WHERE continent != ''
order by 1,2;




--Now let me focus on the second table
--Let's Join the first and second table together
--Looking at the Total Population vs Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(Convert(int, vac.new_vaccinations)) OVER (PARTITION BY dea.Location
order by dea.Location, dea.date) as RollingPeopleVaccinated
--Thats partition using the location only, meaning it is the sum of new vaccinations by location
FROM PortfolioProject.dbo.CovidDeaths dea   ---alliase for this table
JOIN PortfolioProject.dbo.CovidVaccinations vac  ---alliase for this table
    ON dea.location = vac.location
	and dea.date = vac.date
where dea.continent != ''
order by 2,3;



--USE CTE 
--Note if the number of columns is different from the ones inside paranthesis, you'll get an error
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(Convert(int, vac.new_vaccinations)) OVER (PARTITION BY dea.Location
order by dea.Location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject.dbo.CovidDeaths dea   
JOIN PortfolioProject.dbo.CovidVaccinations vac  
    ON dea.location = vac.location
	and dea.date = vac.date
where dea.continent != ''
-- order by 2,3  order by clause can't be in there, will get an error if I put it
)
SELECT *, (NullIf(RollingPeopleVaccinated,'')/Population) * 100 as PopvsVacPercentage 
FROM PopvsVac




--TEMP Table

DROP Table if exists #PercentPopulationVaccinated

CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric,
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(Convert(int, vac.new_vaccinations)) OVER (PARTITION BY dea.Location
order by dea.Location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject.dbo.CovidDeaths dea   
JOIN PortfolioProject.dbo.CovidVaccinations vac  
    ON dea.location = vac.location
	and dea.date = vac.date
where dea.continent != ''

SELECT *, (NullIf(RollingPeopleVaccinated,'')/Population) * 100 as PopvsVacPercentage 
FROM #PercentPopulationVaccinated

--Creating View to store Data for later visualizations
Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent != '' 

Select * 
FROM PercentPopulationVaccinated

