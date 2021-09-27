select *
from PortfolioProject..CovidDeaths
--where continent is not null
where location like '%canada%'
order by 3,4

--select *
--from PortfolioProject..CovidVaccinations
--order by 3,4

--Select Data that we are going to be using
select location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject..CovidDeaths
order by 1,2 
l
--Shows likelihood that you die if you get Covid
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as deathpercentage
from PortfolioProject..CovidDeaths
--where location like '%states'
order by 1,2

--Shows what percentage of population got Covid
select location, date, total_cases, total_deaths, (total_cases/population)*100 as PercentInfected
from CovidDeaths
where location like '%states'
order by 1,2

--What countries have the highest infection rate?
select location, population, max(total_cases) as HighestInfectionCount, max((total_cases/population))*100 as PercentInfected
from CovidDeaths
Group by location, population
order by PercentInfected desc

--Countries with highest Death Rate per Population
select location, max(cast(total_deaths as int)) as TotalDeathCount
from CovidDeaths
where continent is not null
group by location
order by TotalDeathCount desc

--Countries with highest Death Rate per Population
select location, population, max(cast(total_deaths as int)) as TotalDeathCount, max((total_deaths/population)*100) as DeathPercentage_of_Pop
from CovidDeaths
where continent is not null
group by location, population
order by DeathPercentage_of_Pop desc
--we can see US has the highest number of deaths


-- Break things out by Continent
select continent, max(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeaths
where continent is not null
group by continent
order by TotalDeathCount desc
--North America doesnt show Canada for some reason


--global deaths by date
select date, sum(new_cases) as worldtotal_new_cases, sum(cast(new_deaths as int)) as worldtotal_new_deaths, 
	sum(cast(new_deaths as int))/sum(new_cases) *100 as DeathPercentage
from PortfolioProject..CovidDeaths
where continent is not null
group by date
order by 1,2

--global total deaths
select sum(new_cases) as worldtotal_new_cases, sum(cast(new_deaths as int)) as worldtotal_new_deaths, 
	sum(cast(new_deaths as int))/sum(new_cases) *100 as DeathPercentage
from PortfolioProject..CovidDeaths
where continent is not null
order by 1,2


-- Inspect the Covid Vaccination file
select *
from PortfolioProject..CovidVaccinations



-- Join the two tables together
select *
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date


-- Total Population vs Vaccinations
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	sum(cast(vac.new_vaccinations as int))
		over (partition by dea.location ORDER BY dea.location,dea.date)
		as rolling_total_vaccinated
	--only want function to work over each location
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3


-- USE CTE
-- Common Table Expression is a temporary named result set
with Pop_vs_Vac (continent, location, date, population, new_vaccinations, rolling_total_vaccinated)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	sum(cast(vac.new_vaccinations as int))
		over (partition by dea.location ORDER BY dea.location,dea.date)
		as rolling_total_vaccinated
	--only want function to work over each location
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
)
select *, (rolling_total_vaccinated/population)*100 as VaccinationRate
from Pop_vs_Vac
where location like '%states%'



-- Use a Temp Table instead of CTE
DROP table if exists #PercentPopulationVaccination
CREATE table #PercentPopulationVaccination
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_total_vaccinated numeric
)

Insert into #PercentPopulationVaccination
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	sum(cast(vac.new_vaccinations as int))
		over (partition by dea.location ORDER BY dea.location,dea.date)
		as rolling_total_vaccinated
	--only want function to work over each location
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null

select *, (rolling_total_vaccinated/population)*100 as VaccinationRate
from #PercentPopulationVaccination


-- Creating VIEW to store for later visualizations
CREATE VIEW PercentPopulationVaccinated AS
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	sum(cast(vac.new_vaccinations as int))
		over (partition by dea.location ORDER BY dea.location,dea.date)
		as rolling_total_vaccinated
	--only want function to work over each location
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
