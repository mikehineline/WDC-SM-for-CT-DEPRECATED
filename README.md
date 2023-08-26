# WDC-SM-for-CT (DEPRECATED - Salesforce has EOL'd Work.com)
Salesforce Work.com Shift Management for Contact Tracing

Salesforce Work.com offers several solutions, two of which are:
1) Manual Contact Tracing which allows contact tracers to enter encounters and participants
2) Shift Management where employees work shifts together

This tool links the two. When employees worked a shift in the same location (Service Territory) on the same day, a contact tracer can choose to import those shifts and the co-workers in them as Contact Encounters and Contact Encounter Participants in Contact Tracing for Employees.

## Installation
1. Install the components in your Salesforce Work.com Org
2. Navigate to a Contact Tracing record
3. Click Setup > Edit Page
4. Drag a Flow component onto the page layout
5. Set the Flow for the component to "Load Shifts for Contact Tracing"
6. Check the box under the contactTraceRecordID input value to "Pass Record ID into this variable" (You can leave all other input variables blank)
7. Save the page layout and exit the Lightning app builder

## Usage Instructions
1. Navigate to a Contact Tracing record
2. In the "Load Shifts for Contact Tracing" component you added to the page, optionally update the Start Date. All shifts that were shared after this date will be pulled into Contact Tracing.
3. Click "Next". This will perform all of the record creation
5. Optionally click "Finish"
6. Refresh the page and you will see any added contact tracing linkages

## Reset Instructions
If you want to clear out all of the ContactEncounters and (child) ContactEncounterParticipant records from your org that were added by this component, run the following in the Developer Console > Debug > Open Execute Anonymous Window:

    List<ContactEncounter> ce = [SELECT Id FROM ContactEncounter WHERE Name LIKE 'Shift: %']; 
    delete ce;

## Notes
* If you click the demo component a second time, records will be duplicated and you'll have twice as many
* If the same peer employee worked multiple shifts with the affected employee, they will be added multiple times against multiple encounters. This mirrors how the Contact Tracing UI works if an Employee is interviewed as having been with the same person during multiple encounters.
* Exact shift overlap by the minute is not calculated. Rather, any employees who worked in the same area (Service Territory) on the same day are considered participants in an encounter.
* Shifts that span past midnight have not been tested.
* Contact Encounter start and end times may not accurately reflect the TimeZones
