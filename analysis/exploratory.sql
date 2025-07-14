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
select distinct b.PackageRevenue from bookings b
-- range(0, 35000, 5000)

select 
    b.PackageRevenue
    ,count(*) as NumBookings
    ,avg(DestinationRevenue) as AvgDestRev
    ,case 
        when b.PackageRevenue != 0 then avg(DestinationRevenue) / b.PackageRevenue 
        else -1.0 
        end as Ratio
from bookings b
where b.BookingStatus = 'Confirmed'
group by b.PackageRevenue

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
order by b.Destination -- destinations generally associated with one launch loc
-- order by b.LaunchLocation
--order by AvgDestRev desc -- mars still highest rev over all
-- frequent dest + launch loc combos are the cheapest options
-- little to no variation in dest rev except for the most common dest + launch locs
-- but surprised there is variation w/i Dest x LaunchLoc. What's the other var that influences this? 

select 
    b.Destination
    ,b.LaunchLocation
    -- ,ah.CommunicationMethod
    ,ah.LeadSource
    ,count(b.Destination) as NumBookings
    ,min(b.DestinationRevenue) as MinDestRev
    ,avg(b.DestinationRevenue) as AvgDestRev
    ,max(b.DestinationRevenue) as MaxDestRev
    ,avg(b.PackageRevenue) as AvgPackageRev
    ,avg(b.TotalRevenue) as AvgTotRev
from bookings as b
join assignment_history ah
    on ah.AssignmentID = b.AssignmentID
group by 
    b.Destination, b.LaunchLocation
    -- ,ah.CommunicationMethod
    ,ah.LeadSource
--order by b.Destination -- destinations generally associated with one launch loc
order by b.LaunchLocation

select *
from bookings b
join assignment_history ah
    on ah.AssignmentID = b.AssignmentID
join space_travel_agents sta
    on sta.AgentID = ah.AgentID
where 
    b.Destination in ('Europa')
    and b.LaunchLocation in ('Dubai Interplanetary Hub')
-- some variation in DestRev d/t Package for Europa

select *
from bookings b
join assignment_history ah
    on ah.AssignmentID = b.AssignmentID
join space_travel_agents sta
    on sta.AgentID = ah.AgentID
where 
    b.Destination in ('Mars')
    and b.LaunchLocation in ('Dallas-Fort Worth Launch Complex')
order by DestinationRevenue
-- there's no clear reason why 4 Dest x LaunchLoc here have <$150k DestRev
-- Maybe a sale etc. Going to assume whatever it is is outside of the agents control

select cast(getdate() as date)

select 
    cast(ah.AssignedDateTime as date) as AssignmentDate
    ,count(*) as NumAssignments
    ,sum(iif(b.BookingStatus = 'Confirmed', 1, 0)) as NumConfirmed
    ,sum(iif(b.BookingStatus = 'Cancelled', 1, 0)) as NumCancelled
    ,avg(b.TotalRevenue) as AvgTotRev
    ,sum(iif(b.BookingID is NULL, 1, 0)) as NumNullBookings
from assignment_history ah
left join bookings b
    on ah.AssignmentID = b.AssignmentID
group by cast(ah.AssignedDateTime as date)
-- 2081-02-20 with 44 assignments
-- rest with ~5-7 and ~1 assignment without a booking
-- wonder if some agents / agent characteristics are more likely to not convert an assignment into a booking? 

--select * from bookings as b where b.DestinationRevenue + b.PackageRevenue != b.TotalRevenue
-- confirm dest + package = tot rev

select datename(dw, getdate())

select 
    datepart(dw, cast(ah.AssignedDateTime as date)) as AssignmentWeekdayNum
    ,datename(dw, cast(ah.AssignedDateTime as date)) as AssignmentWeekday
    ,count(*) as NumAssignments
    ,sum(iif(b.BookingStatus = 'Confirmed', 1, 0)) as NumConfirmed
    ,sum(iif(b.BookingStatus = 'Cancelled', 1, 0)) as NumCancelled
    ,avg(b.TotalRevenue) as AvgTotRev
    ,sum(iif(b.BookingID is NULL, 1, 0)) as NumNullBookings
from assignment_history ah
left join bookings b
    on ah.AssignmentID = b.AssignmentID
group by datepart(dw, cast(ah.AssignedDateTime as date))
order by 1
-- about 60 assignments / weekday. Except thurs probs b/c 02-20 is a thursday

select 
    'Max' as Stat
    ,max(DestinationRevenue) as DestinationRevenue
    ,max(PackageRevenue) as PackageRevenue
    ,max(TotalRevenue) as TotalRevenue
from bookings
union
select 
    'Average' as Stat
    ,avg(DestinationRevenue) as DestinationRevenue
    ,avg(PackageRevenue) as PackageRevenue
    ,avg(TotalRevenue) as TotalRevenue
from bookings
UNION
select 
    'Min' Stat
    ,min(DestinationRevenue) as DestinationRevenue
    ,min(PackageRevenue) as PackageRevenue
    ,min(TotalRevenue) as TotalRevenue
from bookings
-- * Destination avg is $130k with $50k/150k min/max
-- * Package avg is $24k with 0/30 min/max
-- * Total avg 155 with 65/180 min/max

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
-- luxury dome most expensive. It's the mars package so makes sense

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

-- Destination by Package
select 
    b.Destination, b.Package
    ,count(*) as NumBookings
    ,avg(b.DestinationRevenue) as AvgDestRev
from bookings b
where b.BookingStatus != 'Pending'
group by b.Destination, b.Package
order by b.Destination
-- only 1 package per dest
-- NOTE: packages seem determined by destination
-- WITH EXCEPTION of Europa & Glacier Trek / 0-Gravity which have similar avg DestRev


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

-- how long from assignment to booking closure?
select
    avg(
        cast(datediff(d, ah.AssignedDateTime, coalesce(b.BookingCompleteDate, b.CancelledDate)) as float)
    ) as AvgDaysToBookingCompletion
    ,max(
        datediff(d, ah.AssignedDateTime, coalesce(b.BookingCompleteDate, b.CancelledDate))
    ) as MaxDaysToBookingCompletion
    ,avg(
        cast(datediff(hh, ah.AssignedDateTime, coalesce(b.BookingCompleteDate, b.CancelledDate)) as float)
    ) as AvgHoursToBookingCompletion
from bookings b
join assignment_history ah
    on ah.AssignmentID = b.AssignmentID
where b.BookingStatus != 'Pending'
-- conditional on there being a non pending booking linked to an assignment
-- the max days between AssignmentDateTime to BookingCompleteDate or CancelledDate is 1
-- Average is 0.015 days or 0.56 hours
-- I'd feel safe assuming that any assignment that's >1 day old that doesn't have
-- a related booking is a stale customer lead that won't convert



-- **************************** agents ****************************
select top 10 * from space_travel_agents
select distinct sta.JobTitle from space_travel_agents sta
-- space travel agent, lead, senior
select distinct sta.DepartmentName from space_travel_agents sta
-- Interplanetary Sales, Luxury Voyages, Premium Bookings
select distinct sta.ManagerName from space_travel_agents sta
-- Lyra Chen, Zane Holloway
select * from space_travel_agents where FirstName in ('Lyra', 'Zane')
-- no managers are agents
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
order by ConfirmationRate desc
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
select b.LaunchLocation, count(*) as NumBookings
from bookings b
where b.BookingStatus != 'Canceled'
group by b.LaunchLocation
-- but London, Sydney only have 7, 1 launches



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
    -- other rev values
    ,b.DestinationRevenue, b.TotalRevenue
into #temptbl
from bookings b
left join assignment_history ah
    on ah.AssignmentID = b.AssignmentID
left join space_travel_agents sta
    on sta.AgentID = ah.AgentID
where b.BookingStatus != 'Pending'
SELECT * from #temptbl

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

-- what about excluding LaunchLocation since basically always determined by Destination?
select 
    count(*) as NumTimesObserved
    ,ah.CommunicationMethod, ah.LeadSource, b.Destination 
from bookings b
left join assignment_history ah
    on ah.AssignmentID = b.AssignmentID
where b.BookingStatus != 'Pending'
group by ah.CommunicationMethod, ah.LeadSource, b.Destination
order by NumTimesObserved desc
-- only 19 combinations in the data of ah.CommunicationMethod, ah.LeadSource, b.Destination 

-- Within a CMxLSxD bucket, are some agetns reliably (statistically) better than others? 
select 
    ah.AgentID, sta.AverageCustomerServiceRating as AvgRating
    ,b.Destination, ah.LeadSource, ah.CommunicationMethod
    ,count(*) as NumObs
    ,sum(iif(b.BookingStatus = 'Confirmed', b.PackageRevenue, 0.0)) as SumRealizedRev
    ,avg(iif(b.BookingStatus = 'Confirmed', b.PackageRevenue, 0.0)) as AvgRealizedRev
    ,avg(iif(b.BookingStatus = 'Confirmed', 1.0, 0.0)) as ConfirmedPercent
    ,string_agg(cast(b.BookingID as varchar), ', ') as BookingIDs
from bookings b
left join assignment_history ah
    on ah.AssignmentID = b.AssignmentID
left join space_travel_agents sta
    on sta.AgentID = ah.AgentID
where 
    b.BookingStatus != 'Pending'
    -- and (b.Destination = 'Mars' and ah.LeadSource = 'Organic' and ah.CommunicationMethod = 'Text')
group by ah.AgentID, sta.AverageCustomerServiceRating, ah.CommunicationMethod, ah.LeadSource, b.Destination
order by 
    b.Destination
    ,ah.LeadSource
    ,ah.CommunicationMethod
    ,AvgRealizedRev desc
    -- ,SumRealizedRev desc
    ,sta.AverageCustomerServiceRating desc
-- I suspect the lead source is much more important to the E[rev] and cancelation likelyhood 
-- than the communication method
-- but maybe not? 
-- For (Europa, Bought) agent 6 on the Phone has has a 100% confirmed rate with 3 bookings and 65k total rev
-- But agent 6 with text has a 25% confirmed rate with 4 bookings
-- select * from bookings where BookingID in (4, 53, 243)



SELECT
    rank() over(
        partition by Destination, LeadSource, CommunicationMethod
        order by SumRealizedRev desc, AvgRating desc
        ) as rating
        ,x.*
from (
    select 
        ah.AgentID
        ,b.Destination, ah.LeadSource, ah.CommunicationMethod
        ,count(*) as NumObs
        ,sum(iif(b.BookingStatus = 'Confirmed', b.PackageRevenue, 0.0)) as SumRealizedRev
        ,avg(iif(b.BookingStatus = 'Confirmed', b.PackageRevenue, 0.0)) as AvgRealizedRev
        ,avg(iif(b.BookingStatus = 'Confirmed', 1.0, 0.0)) as ConfirmedPercent
        ,sta.AverageCustomerServiceRating as AvgRating
        ,string_agg(cast(b.BookingID as varchar), ', ') as BookingIDs
    from bookings b
    left join assignment_history ah
        on ah.AssignmentID = b.AssignmentID
    left join space_travel_agents sta
        on sta.AgentID = ah.AgentID
    where 
        b.BookingStatus != 'Pending'
        -- and (b.Destination = 'Mars' and ah.LeadSource = 'Organic' and ah.CommunicationMethod = 'Text')
    group by ah.AgentID, sta.AverageCustomerServiceRating, ah.CommunicationMethod, ah.LeadSource, b.Destination
) as x
order by 
    Destination
    ,LeadSource
    ,CommunicationMethod
    -- ,AvgRealizedRev desc
    ,SumRealizedRev desc
    ,AvgRating desc


-- exluding LeadSource
SELECT
    rank() over(
        partition by Destination, CommunicationMethod
        order by SumRealizedRev desc, AvgRating desc
        ) as rating
        ,x.*
from (
    select 
        ah.AgentID
        ,b.Destination, ah.CommunicationMethod
        ,count(*) as NumObs
        ,sum(iif(b.BookingStatus = 'Confirmed', b.PackageRevenue, 0.0)) as SumRealizedRev
        ,avg(iif(b.BookingStatus = 'Confirmed', b.PackageRevenue, 0.0)) as AvgRealizedRev
        ,avg(iif(b.BookingStatus = 'Confirmed', 1.0, 0.0)) as ConfirmedPercent
        ,sta.AverageCustomerServiceRating as AvgRating
        ,string_agg(cast(b.BookingID as varchar), ', ') as BookingIDs
    from bookings b
    left join assignment_history ah
        on ah.AssignmentID = b.AssignmentID
    left join space_travel_agents sta
        on sta.AgentID = ah.AgentID
    where 
        b.BookingStatus != 'Pending'
        -- and (b.Destination = 'Mars' and ah.LeadSource = 'Organic' and ah.CommunicationMethod = 'Text')
    group by ah.AgentID, sta.AverageCustomerServiceRating, ah.CommunicationMethod, b.Destination
) as x
order by 
    Destination
    ,CommunicationMethod
    -- ,AvgRealizedRev desc
    ,SumRealizedRev desc
    ,AvgRating desc

