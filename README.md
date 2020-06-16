# WDC-SM-for-CT
Salesforce Work.com Shift Management for Contact Tracing

Salesforce Work.com offers several solutions, two of which are:
1) Manual Contact Tracing which allows contact tracers to enter encounters and participants
2) Shift Management where employees work shifts together

This tool links the two. When employees worked a shift in the same location (Service Territory) on the same day, a contact tracer can choose to import those shifts and the co-workers in them as Contact Encounters and Contact Encounter Participants in Contact Tracing for Employees.

## Installation
1. Install the components in your Salesforce Work.com Org
2. Navigate to a Contact Tracing record (Randall Pressey is a good choice)
3. Click Setup > Edit Page
4. Drag a Flow component onto the page layout
5. Set the Flow for the component to "Load Shifts for Contact Tracing"
6. Check the box under the contactTraceRecordID input value to "Pass Record ID into this variable" (You can leave all other input variables blank)
7. Save the page layout and exit the Lightning app builder
