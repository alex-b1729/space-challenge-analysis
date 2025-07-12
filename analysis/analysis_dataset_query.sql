select
    b.BookingID, ah.AssignmentID, sta.AgentID
    -- dependent var
    ,b.PackageRevenue
    ,b.BookingStatus
    -- vars we know about customer
    ,ah.CustomerName, ah.CommunicationMethod, ah.LeadSource, b.Destination, b.LaunchLocation
    -- vars we know about agent
    ,sta.JobTitle, sta.DepartmentName, sta.ManagerName, sta.YearsOfService, sta.AverageCustomerServiceRating
    -- datetime vars
    ,ah.AssignedDateTime, b.BookingCompleteDate, b.CancelledDate
    -- other rev values
    ,b.DestinationRevenue, b.TotalRevenue
from bookings b
left join assignment_history ah
    on ah.AssignmentID = b.AssignmentID
left join space_travel_agents sta
    on sta.AgentID = ah.AgentID
where b.BookingStatus != 'Pending'