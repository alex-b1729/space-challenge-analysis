select
    ah.AssignmentID, b.BookingID, sta.AgentID
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
from assignment_history ah
left join bookings b
    on ah.AssignmentID = b.AssignmentID
left join space_travel_agents sta
    on sta.AgentID = ah.AgentID
order by ah.AssignmentID
-- where b.BookingStatus != 'Pending' or b.BookingStatus is NULL