
drop table if exists #ObservationTbl
drop table if exists #PanelIndexTbl
drop table if exists #PanelTbl


SELECT
    rank() over(
        partition by Destination, LeadSource, CommunicationMethod
        order by AvgRealizedRev desc, AvgRating desc
        ) as GroupRank
        ,x.*
into #ObservationTbl
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
    ,AvgRealizedRev desc  -- accounts for cancelation rate, not just upsell ability
    -- ,SumRealizedRev desc
    ,AvgRating desc

-- select all possible Destination, LeadSource, CommunicationMethod combinations
select 
    distinct b.Destination
    ,ls.LeadSource
    ,cm.CommunicationMethod
into #PanelIndexTbl
from bookings b
join (
    select distinct ah.LeadSource
    from assignment_history ah
) ls on 1=1
join (
    select distinct ah.CommunicationMethod
    from assignment_history ah
) cm on 1=1


select 
    obs.GroupRank, obs.AgentID
    ,idx.Destination, idx.LeadSource, idx.CommunicationMethod
    ,obs.NumObs, obs.SumRealizedRev, obs.AvgRealizedRev
    ,obs.ConfirmedPercent, obs.AvgRating, obs.BookingIDs
into #PanelTbl
from #PanelIndexTbl idx
left join #ObservationTbl obs
    on obs.Destination = idx.Destination
    and obs.LeadSource = idx.LeadSource
    and obs.CommunicationMethod = idx.CommunicationMethod
-- order by obs.GroupRank, idx.Destination, idx.LeadSource, idx.CommunicationMethod
select * from #PanelTbl order by GroupRank, Destination, LeadSource, CommunicationMethod

select 
    AgentID
    ,count()
from #PanelTbl 
group by AgentID