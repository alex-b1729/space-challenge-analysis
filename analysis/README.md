# space-challenge-analysis

## Notes
Unoredered things worth noting: 
* **Categories**: 2x CommunicationMethod, 2x LeadSource, 5x Destination, 6x LaunchLocation, 3x JobTitle, 3x DepartmentName, 2x ManagerName
* **YearsOfService**: 1-16 with even representation
* **AverageCustomerServiceRating**: 3.3-5 with even representation
* **BookingStatus**: ~100 cancelled, ~300 Confirmed, 20 Pending
* **Ganymede** only has 9 visits with ~100 for others
* **London, Sydney** only have 6, 1 non-pending (& confirmed) bookings. Also these locs only covered by 6, 1 unique agents. 
* **Mars** has highest avg revenue
* 2081-02-20 has 44 assignments. Rest have 5-7. Many days early in dataset have ~1 assignment that didn't convert into a booking. 
* Packages seems determined by Destination
* Some packages/dest have $0 package rev
* 10 repeat customers (by name)
* Agents cover all destinations and LaunchLocs mostly evenly
* Revenue
    * Destination avg is $130k with $50k/150k min/max
    * Package avg is $24k with 0/30 min/max
    * Total avg 155 with 65/180 min/max
* There's a max of 1 day between `AssignedDateTime` and `coalesce(BookingCompleteDate, CancelledDate)`. The average is ~0.5 hours. (Conditional on there being a non-pending booking relation to a given assignment.) 

## Brainstorming
### Dependent variable

