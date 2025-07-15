-- **************************************************************************

-- The following stored procedure assigns a lead to the agent with the most 
-- experience, and best performance with given (Destination, LeadSource, 
-- CommunicationMethod) tuple. 

-- Agents are prioritized based on their experience with, in order:
-- 1. (Destination, LeadSource, CommunicationMethod)
-- 2. (Destination, LeadSource)
-- 3. (Destination)

-- Since not all (Destination, LeadSource, CommunicationMethod) tuples
-- have good historical data. I don't want to limit the number of choices
-- of agents too much since it's not clear that experience with a 
-- particular LeadSource or CommunicationMethod are reliable determinants of 
-- an agent's success with a lead. 

-- When there's data on <10 agents with booking experience in the given
-- (Destination, LeadSource, CommunicationMethod) tuple, this script
-- then looks for data on agents with experience with bookings with the 
-- same (Destination, LeadSource). If there are <10 agents in that set
-- (for example Ganymede) the script chooses among all agents with 
-- experience in the given Destination. 
-- When a Destination is not in the historical data, the script sorts
-- all agents using their entire past booking history. 

-- There are 20 (=2x2x5) combinations of (Destination, LeadSource, 
-- CommunicationMethod). In this dataset, 15 of those have >=10 agents
-- with past experience in that exact situation. 

-- Agents are ranked in the following order:
-- 1. AvgRealizedPackageRevenue desc := avg(PackageRevenue if BookingStatus = 'Confirmed' else 0)
-- 2. NumObs desc := The number of historical observations of that agent with 
--      the given (Destination, LeadSource, CommunicationMethod) tuple
-- 3. AverageCustomerServiceRating desc: As given in the space_travel_agents table
-- 4. LastAssignedDateTime desc := max(assignment_history.AssignedDateTime) 
--      partitioned by (Agent, Destination, LeadSource, CommunicationMethod)

-- **************************************************************************

create or alter procedure ReturnStackRankedAgentList
    @CustomerName varchar(100),
    @CommunicationMethod varchar(20),
    @LeadSource varchar(20),
    @Destination varchar(50),
    @LaunchLocation varchar(100),
    @ShowDetailedOutput bit = 0
as 
begin
    set nocount on;
    -- select all non-pending bookings with same destination
    drop table if exists #DestinationTbl
    select 
        ah.AgentID
        ,b.Destination
        ,ah.LeadSource, ah.CommunicationMethod
        ,b.BookingStatus
        ,iif(b.BookingStatus = 'Confirmed', b.PackageRevenue, 0.0) as RealizedPackageRevenue
        ,iif(b.BookingStatus = 'Confirmed', 1.0, 0.0) as IsConfirmed
        ,sta.AverageCustomerServiceRating, ah.AssignedDateTime
    into #DestinationTbl
    from bookings b
    join assignment_history ah
        on ah.AssignmentID = b.AssignmentID
    left join space_travel_agents sta
        on sta.AgentID = ah.AgentID
    where 
        b.BookingStatus != 'Pending'
        and b.Destination = @Destination

    -- how many agents are experience with exact (Destination, LeadSource, CommunicationMethod)?
    declare @NumExperiencedAgents integer = (
        select count(distinct AgentID)
        from #DestinationTbl
        where 
            -- Destination = @Destination -- already included in #DestinationTbl
            LeadSource = @LeadSource
            and CommunicationMethod = @CommunicationMethod
    )

    drop table if exists #AgentChoiceTbl
    create table #AgentChoiceTbl (
        AgentID int,
        Destination varchar(50),
        LeadSource varchar(20),
        CommunicationMethod varchar(20),
        NumObs int,
        AvgRealizedPackageRevenue float,
        ConfirmationPercent float,
        AverageCustomerServiceRating float,
        LastAssignedDateTime datetime
    )

    -- if there are >= 10 distinct agents with experience
    if @NumExperiencedAgents >= 10
    begin
        -- Aggregate to (Destination, LeadSource, CommunicationMethod) level
        print cast(@NumExperiencedAgents as varchar) + N' experienced agents. Aggregating to (Destination, LeadSource, CommunicationMethod) level.'
        insert into #AgentChoiceTbl
        select 
            AgentID
            ,Destination, LeadSource, CommunicationMethod
            ,count(*) as NumObs
            ,avg(RealizedPackageRevenue) as AvgRealizedPackageRevenue
            ,avg(IsConfirmed) as ConfirmationPercent
            ,AverageCustomerServiceRating
            ,max(AssignedDateTime) as LastAssignedDateTime
        from #DestinationTbl
        where LeadSource = @LeadSource and @CommunicationMethod = CommunicationMethod
        group by AgentID, Destination, LeadSource, CommunicationMethod, AverageCustomerServiceRating
    end
    else
    begin
        -- how many distince agents have experience with this (Destination, LeadSource) situation?
        set @NumExperiencedAgents = (
            select count(distinct AgentID)
            from #DestinationTbl
            where 
                -- Destination = @Destination -- already included in #DestinationTbl
                LeadSource = @LeadSource
        )

        if @NumExperiencedAgents >= 10
        begin
            -- Aggregate to (Destination, LeadSource) level
            print cast(@NumExperiencedAgents as varchar) + N' experienced agents. Aggregating to (Destination, LeadSource) level.'
            insert into #AgentChoiceTbl
            select 
                AgentID
                ,Destination, LeadSource, NULL as CommunicationMethod
                ,count(*) as NumObs
                ,avg(RealizedPackageRevenue) as AvgRealizedPackageRevenue
                ,avg(IsConfirmed) as ConfirmationPercent
                ,AverageCustomerServiceRating
                ,max(AssignedDateTime) as LastAssignedDateTime
            from #DestinationTbl
            where LeadSource = @LeadSource
            group by AgentID, Destination, LeadSource, AverageCustomerServiceRating
        end
        else
        begin
            -- is there at lease 1 agent with that destination experience? 
            set @NumExperiencedAgents = (
                select count(distinct AgentID)
                from #DestinationTbl
            )

            if @NumExperiencedAgents >= 1
            begin
                -- aggregate to the (Destination) level
                print cast(@NumExperiencedAgents as varchar) + N' experienced agents. Aggregating to (Destination) level.'
                insert into #AgentChoiceTbl
                select 
                    AgentID
                    ,Destination, NULL as LeadSource, NULL as CommunicationMethod
                    ,count(*) as NumObs
                    ,avg(RealizedPackageRevenue) as AvgRealizedPackageRevenue
                    ,avg(IsConfirmed) as ConfirmationPercent
                    ,AverageCustomerServiceRating
                    ,max(AssignedDateTime) as LastAssignedDateTime
                from #DestinationTbl
                group by AgentID, Destination, AverageCustomerServiceRating
            end
            else
            begin
                -- if there are no agents with experience on this destination
                -- just return all agents with their stats across entire booking history
                print N'No agents match this destination. Aggregating all agents. '
                insert into #AgentChoiceTbl
                select 
                    ah.AgentID
                    ,NULL as Destination, NULL as LeadSource, NULL as CommunicationMethod
                    ,count(*) as NumObs
                    ,avg(iif(b.BookingStatus = 'Confirmed', b.PackageRevenue, 0.0)) as AvgRealizedPackageRevenue
                    ,avg(iif(b.BookingStatus = 'Confirmed', 1.0, 0.0)) as ConfirmationPercent
                    ,sta.AverageCustomerServiceRating
                    ,max(ah.AssignedDateTime) as LastAssignedDateTime
                from bookings b
                join assignment_history ah
                    on ah.AssignmentID = b.AssignmentID
                left join space_travel_agents sta
                    on sta.AgentID = ah.AgentID
                where b.BookingStatus != 'Pending'
                group by ah.AgentID, sta.AverageCustomerServiceRating
            end
        end
    end

    if @ShowDetailedOutput = 1
        select 
            rank() over(
                order by 
                    AvgRealizedPackageRevenue desc
                    ,NumObs desc
                    ,AverageCustomerServiceRating desc
                    ,LastAssignedDateTime desc
                ) as AssignmentRank
                ,act.*
        from #AgentChoiceTbl act

    select 
        rank() over(
            order by 
                AvgRealizedPackageRevenue desc
                ,NumObs desc
                ,AverageCustomerServiceRating desc
                ,LastAssignedDateTime desc
            ) as AssignmentRank
            ,act.AgentID
    from #AgentChoiceTbl act
end
go 

exec ReturnStackRankedAgentList 
    @CustomerName=N'Evelyn Brooks'
    ,@CommunicationMethod='Text'
    ,@LeadSource=N'Organic'
    ,@Destination=N'Venus'
    ,@LaunchLocation=N'Luxury Dome Stay'
    -- ,@ShowDetailedOutput = 1
