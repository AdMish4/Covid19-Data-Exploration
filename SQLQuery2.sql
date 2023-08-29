Select * from covid_project..CovidVaccinations
where continent is not null
order by 3,4;

Select count(*) from covid_project..CovidVaccinations;

Select * from covid_project..CovidDeaths
order by 2,3;

--Selecting relevant data
Select location, date, total_cases, new_cases, total_deaths, population 
from covid_project..CovidDeaths
where continent is not null
order by 1,2;

--Total cases vs total deaths
Select Location, date, total_cases, total_deaths, (cast(total_deaths as float)/cast(total_cases as float))*100 as percentage_died
from covid_project..CovidDeaths
where continent is not null
order by 1,2;

--Total cases vs total deaths in United states
Select Location, date, total_cases, total_deaths, (cast(total_deaths as float)/cast(total_cases as float))*100 as percentage_died
from covid_project..CovidDeaths
where location like '%states%'
order by 1,2;

--Total cases vs total deaths in India
Select Location, date, total_cases, total_deaths, (cast(total_deaths as float)/cast(total_cases as float))*100 as percentage_died
from covid_project..CovidDeaths
where location = 'india'
order by 1,2;

--Total cases vs population
Select location, date, total_cases, population, (cast(total_cases as float)/cast(population as float))*100 as cases_per_capita
from covid_project..CovidDeaths
where location = 'india'
order by 2;

--Countries with highest cases per capita
Select location, population, max(total_cases) as max_cases, max((cast(total_cases as float)/cast(population as float))*100) as max_cases_per_capita
from covid_project..CovidDeaths
group by location, population
order by max_cases_per_capita desc;

--Countries with highest deaths per capita
Select location, population, max(total_deaths) as max_deaths, max((cast(total_deaths as float)/cast(population as float))*100) as max_deaths_per_capita
from covid_project..CovidDeaths
where continent is not null
group by location, population
order by max_deaths_per_capita desc;

--Deaths by continent
Select continent, max(total_deaths) as max_deaths
from covid_project..CovidDeaths
where continent is not null
group by continent
order by max_deaths desc;  --It seems to be an erronous data where north america contains only USA's data and not canada's data

Select location, max(total_deaths) as max_deaths
from covid_project..CovidDeaths
where continent is null
group by location
order by max_deaths desc;

--Continents with highest death per capita
Select location, max(cast(total_deaths as float)/cast(population as float))*100 as max_deaths
from covid_project..CovidDeaths
where continent is null
group by location
order by max_deaths desc;

--Global numbers

--Number of daily new cases and new deaths worldwide
select date, sum(new_cases) as new_cases, sum(new_deaths) as new_deaths, sum(cast(new_deaths as float))/sum(cast(new_cases as float)) as death_percentage
from covid_project..CovidDeaths
where continent is not null
group by date 
order by 1;

--New vaccination per day
select d.continent, d.location, d.date, d.population, v.new_vaccinations
from covid_project..CovidDeaths d 
join covid_project..CovidVaccinations v
on d.location = v.location 
and d.date = v.date
where d.continent is not null
order by 2,3;

--Daily cummulative vaccinations in a country
select d.continent, d.location, d.date, d.population, v.new_vaccinations, sum(cast(v.new_vaccinations as int)) over (partition by d.location order by d.location, d.date) as total_vaccination
from covid_project..CovidDeaths d 
join covid_project..CovidVaccinations v
on d.location = v.location 
and d.date = v.date
where d.continent is not null
order by 2,3;

--Daily cummulative vaccinations vs populaion percentage in a country
select d.continent, d.location, d.date, d.population, v.new_vaccinations, sum(cast(v.new_vaccinations as int)) over (partition by d.location order by d.location, d.date) 
as total_vaccination, (total_vaccination/population)*100 as percent_vaccinated  --We cannot use a column we just created
from covid_project..CovidDeaths d                                              --For that we'll use CTE and temp table
join covid_project..CovidVaccinations v
on d.location = v.location 
and d.date = v.date
where d.continent is not null
order by 2,3;

--CTE
with PopvsVac (continent, location, date, population, new_vaccinations, total_vaccination) as --The number of column here should be equal to the number of column below
(
select d.continent, d.location, d.date, d.population, v.new_vaccinations, sum(cast(v.new_vaccinations as int)) over (partition by d.location order by d.location, d.date) 
as total_vaccination 
from covid_project..CovidDeaths d                                              
join covid_project..CovidVaccinations v
on d.location = v.location 
and d.date = v.date
where d.continent is not null
)
select *, (cast(total_vaccination as float)/cast(population as float))*100 as percent_vaccinated 
from PopvsVac

--Temp table
drop table if exists #PercentPopulationVaccinated
Create table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
total_vaccination numeric
)

Insert into #PercentPopulationVaccinated
select d.continent, d.location, d.date, d.population, v.new_vaccinations, sum(cast(v.new_vaccinations as int)) over (partition by d.location order by d.location, d.date) 
as total_vaccination 
from covid_project..CovidDeaths d                                              
join covid_project..CovidVaccinations v
on d.location = v.location 
and d.date = v.date
where d.continent is not null

select *, (total_vaccination/population)*100 as vaccinated_percent
from #PercentPopulationVaccinated

--Creating view to store data for later visualization
create view Percen_Vaccinated as
select d.continent, d.location, d.date, d.population, v.new_vaccinations, sum(cast(v.new_vaccinations as int)) over (partition by d.location order by d.location, d.date) 
as total_vaccination 
from covid_project..CovidDeaths d                                              
join covid_project..CovidVaccinations v
on d.location = v.location 
and d.date = v.date
where d.continent is not null

select * from Percen_Vaccinated
