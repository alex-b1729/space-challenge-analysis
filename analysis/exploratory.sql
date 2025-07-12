select top 10 * from space_travel_agents

select top 10 * from bookings

select top 10 * from assignment_history

-- **************************** bookings ****************************
select distinct b.BookingStatus as UniqueCol from bookings as b
-- Cancelled, Confirmed, Pending
select distinct b.Destination as UniqueCol from bookings as b
-- Europa, Ganymede, Mars, Titan, Venus
select distinct b.Package as UniqueCol from bookings as b
-- Cloud City Excursion
-- Glacier Trek Adventure
-- Luxury Dome Stay
-- Private Observatory Suite
-- Ringside Cruise
-- Zero-Gravity Yacht Cruise
select distinct b.LaunchLocation as UniqueCol from bookings as b
-- Dallas-Fort Worth Launch Complex
-- Dubai Interplanetary Hub
-- London Ascension Platform
-- New York Orbital Gateway
-- Sydney Stellar Port
-- Tokyo Spaceport Terminal

-- booking status stats
select 
    b.BookingStatus
    ,count(b.BookingStatus) as NumBookings
    ,min(b.TotalRevenue) as MinTotRev
    ,cast(avg(b.TotalRevenue) as int) as AvgTotRev
    ,max(b.TotalRevenue) as MaxTotRev
from bookings as b
group by b.BookingStatus
-- only 20 pending, ~100:300 cancelled:confirmed
-- min total rev for confirmed is ~half of cancelled. 65k to 135k
-- other stats are similar

-- destination stats
select 
    b.Destination
    ,count(b.Destination) as NumBookings
    ,min(b.DestinationRevenue) as MinDestRev
    ,avg(b.DestinationRevenue) as AvgDestRev
    ,max(b.DestinationRevenue) as MaxDestRev
    ,avg(b.PackageRevenue) as AvgPackageRev
    ,avg(b.TotalRevenue) as AvgTotRev
from bookings as b
group by b.Destination
order by AvgTotRev desc
-- only 9 visits to Ganymede. ~100 to others
-- mars has highest rev across all sub categories

select 
    b.Destination
    ,b.LaunchLocation
    ,count(b.Destination) as NumBookings
    ,min(b.DestinationRevenue) as MinDestRev
    ,avg(b.DestinationRevenue) as AvgDestRev
    ,max(b.DestinationRevenue) as MaxDestRev
    ,avg(b.PackageRevenue) as AvgPackageRev
    ,avg(b.TotalRevenue) as AvgTotRev
from bookings as b
group by b.Destination, b.LaunchLocation
--order by b.Destination -- destinations generally associated with one launch loc
order by b.LaunchLocation
--order by AvgDestRev desc -- mars still highest rev over all
-- frequent dest + launch loc combos are the cheapest options
-- little to no variation in dest rev except for the most common dest + launch locs

--select * from bookings as b where b.DestinationRevenue + b.PackageRevenue != b.TotalRevenue
-- confirm dest + package = tot rev

-- package rev
select 
    b.Package
    ,count(b.Package) as NumBookings
    ,min(b.PackageRevenue) as MinPackageRev
    ,avg(b.PackageRevenue) as AvgPackageRev
    ,max(b.PackageRevenue) as MaxPackageRev
from bookings as b
-- where b.BookingCompleteDate is not Null -- exclude canceled and pending
where b.BookingStatus != 'Pending'
group by b.Package
order by AvgPackageRev desc
-- some packages have $0 for rev
-- cloud city most expensive, 

select top 10 * from bookings
select top 10 * from assignment_history

-- package rev by dest and launch loc
select 
    b.Destination
    ,b.LaunchLocation
    ,b.Package
    ,avg(b.PackageRevenue) as AvgPackageRev
    ,count(b.Destination) as NumBookings
    ,min(b.DestinationRevenue) as MinDestRev
    ,avg(b.DestinationRevenue) as AvgDestRev
    ,max(b.DestinationRevenue) as MaxDestRev
    ,avg(b.TotalRevenue) as AvgTotRev
from bookings as b
group by b.Destination, b.LaunchLocation, b.Package
order by AvgPackageRev


-- **************************** assignments ****************************
select top 10 * from assignment_history

select 
    ah.CommunicationMethod
    ,count(*) as NumAssignments
from assignment_history ah
group by ah.CommunicationMethod
--154 call, 296 text

select 
    ah.LeadSource
    ,count(*) as NumAssignments
from assignment_history ah
group by ah.LeadSource
-- bought 219, organic 231

-- are there any repeat customers
select 
    x.TimesAsCustomer 
    ,count(x.TimesAsCustomer) as NumCustomers
from (
    select 
        count(*) as TimesAsCustomer
    from assignment_history ah
    group by ah.CustomerName
) x
group by x.TimesAsCustomer
-- 10 repeat customers



-- **************************** agents ****************************
select top 10 * from space_travel_agents
select distinct sta.JobTitle from space_travel_agents sta
-- space travel agent, lead, senior
select distinct sta.DepartmentName from space_travel_agents sta
-- Interplanetary Sales, Luxury Voyages, Premium Bookings
select count(*) as NumAgents from space_travel_agents sta group by sta.YearsOfService
-- wide dispersion of experience

select 
    sta.AverageCustomerServiceRating
    ,count(*) as NumAgents 
from space_travel_agents sta 
group by sta.AverageCustomerServiceRating
-- 3.3 - 5 ratings pretty evenly dispersed


-- what are the track records of the agents? 
select 
    x.AgentID
    ,count(x.AgentID) as NumBookings
    ,sta.YearsOfService
    ,sta.AverageCustomerServiceRating
    ,avg(x.BookingIsConfirmed) as ConfirmationRate
    ,avg(x.DestinationRevenue) as AvgDestinationRevenue
    ,avg(x.PackageRevenue) as AvgPackageRevenue
    ,avg(x.TotalRevenue) as AvgTotalRevenue
    ,avg(x.ActualPackageRevenue) as AvgActualPackageRevenue
    ,avg(x.PackageRevenue - x.ActualPackageRevenue) as PackageRevLost2Cancels
    ,avg(x.ActualTotalRevenue) as AvgActualTotalRevenue
from (
    select
        sta.AgentID
        ,b.Destination
        ,b.LaunchLocation
        ,b.Package
        ,b.DestinationRevenue
        ,b.PackageRevenue
        ,b.TotalRevenue
        ,iif(b.BookingStatus = 'Confirmed', b.PackageRevenue, 0.0) as ActualPackageRevenue
        ,iif(b.BookingStatus = 'Confirmed', b.TotalRevenue, 0.0) as ActualTotalRevenue
        ,iif(b.BookingStatus = 'Confirmed', 1.0, 0.0) as BookingIsConfirmed
    from space_travel_agents sta
    join assignment_history ah
        on ah.AgentID = sta.AgentID
    join bookings b
        on b.AssignmentID = ah.AssignmentID
    where b.BookingStatus != 'Pending'
) as x
join space_travel_agents sta
    on sta.AgentID = x.AgentID
group by x.AgentID, sta.YearsOfService, sta.AverageCustomerServiceRating
-- order by ConfirmationRate desc
-- order by AvgActualPackageRevenue desc

-- similar numbers of bookings
-- generally larger rev lost to cancels for agents with lower AvgActualPackageRev

-- agents x destination
drop table if exists #AgentXDest 
select 
    ah.AgentID
    ,b.Destination
    ,count(b.Destination) as NumAssignments
into #AgentXDest
from bookings b
join assignment_history ah
    on ah.AssignmentID = b.AssignmentID
where b.BookingStatus != 'Pending'
group by ah.AgentID, b.Destination
order by ah.AgentID

select * from #AgentXDest order by NumAssignments desc
select 
    axd.AgentID
    ,count(axd.Destination) as NumUniqueDestinations
from #AgentXDest axd
group by axd.AgentID
-- decent agent by destination observation dispersion
-- Ganymede obviously underrepresented
select 
    axd.Destination
    ,count(axd.AgentID) as NumAgents
from #AgentXDest axd
group by axd.Destination
-- basically every dest covered at least 1 by each agent

-- agents x launch loc
drop table if exists #AgentXLoc
select 
    ah.AgentID
    ,b.LaunchLocation
    ,count(b.Destination) as NumAssignments
into #AgentXLoc
from bookings b
join assignment_history ah
    on ah.AssignmentID = b.AssignmentID
where b.BookingStatus != 'Pending'
group by ah.AgentID, b.LaunchLocation
order by ah.AgentID

select * from #AgentXLoc order by NumAssignments desc
select 
    axl.AgentID
    ,count(axl.LaunchLocation) as NumUniqueLaunchLocs
from #AgentXLoc axl
group by axl.AgentID
-- handful of agents have same LaunchLoc 7 times
-- NumAssignments from 1-7, no clusters
select 
    axl.LaunchLocation
    ,count(axl.AgentID) as NumAgents
from #AgentXLoc axl
group by axl.LaunchLocation
-- London & Sydney covered by 6, 1 but almost all agents cover all Locs otherwise



-- merged dataset
drop table if exists #temptbl
select
    sta.AgentID, ah.AssignmentID, b.BookingID
    -- dependent var
    ,b.PackageRevenue
    -- package rev interacted with status is important
    ,iif(b.BookingStatus = 'Confirmed', b.PackageRevenue, 0) as EffectivePackageRevenue
    -- what if I penalized agents for loosing a lead with negative ref?
    ,iif(b.BookingStatus = 'Confirmed', b.PackageRevenue, -1.0 * b.DestinationRevenue) as AgentGeneratedRevenue
    ,iif(b.BookingStatus = 'Confirmed', 1, 0) as BookingIsConfirmed
    -- vars we know about customer
    ,ah.CustomerName, ah.CommunicationMethod, ah.LeadSource, b.Destination, b.LaunchLocation
    -- vars we know about agent
    ,sta.JobTitle, sta.DepartmentName, sta.ManagerName, sta.YearsOfService, sta.AverageCustomerServiceRating
into #temptbl
from bookings b
left join assignment_history ah
    on ah.AssignmentID = b.AssignmentID
left join space_travel_agents sta
    on sta.AgentID = ah.AgentID
where b.BookingStatus != 'Pending'

select 
    tt.AgentId
    ,avg(tt.AgentGeneratedRevenue) as AvgAgentGenRev
    ,count(tt.BookingIsConfirmed) as NumAssignments
    ,sum(tt.BookingIsConfirmed) as NumConfirmed
    ,count(tt.BookingIsConfirmed) - sum(tt.BookingIsConfirmed) as NumCanceled
    ,tt.AverageCustomerServiceRating
    ,tt.YearsOfService
from #temptbl tt
group by tt.AgentID, tt.AverageCustomerServiceRating, tt.YearsOfService
order by 2 desc
-- only 6 agents have AvgAgentGenRev non negative
-- 2 canceled assignments is enough to negate 10 confirmed ones in terms of rev

-- how often do we see the same 
-- ah.CommunicationMethod, ah.LeadSource, b.Destination, b.LaunchLocation
-- combinations in the dataset? 
select 
    count(*) as NumTimesObserved
    ,ah.CommunicationMethod, ah.LeadSource, b.Destination, b.LaunchLocation
from bookings b
left join assignment_history ah
    on ah.AssignmentID = b.AssignmentID
where b.BookingStatus != 'Pending'
group by ah.CommunicationMethod, ah.LeadSource, b.Destination, b.LaunchLocation
order by NumTimesObserved desc
--order by b.Destination
-- only 53 unique combos
-- 13 combos are all observed 10+ times
-- 5 combos are observed 25+ times with 2 obs of 40