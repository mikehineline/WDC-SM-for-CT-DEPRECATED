/**
 * getShiftsForContactTracing - copy shift information from Work.com Shift Management to contact encounters and participants
 * 	for a given person account in contact tracing
 **/
global class getShiftsForContactTracing {
	// Class for input variables from flow
    global class employeesInputs {
        @InvocableVariable
        global String employeeNumber;
        
        @InvocableVariable
        global Date startDate;

        @InvocableVariable
        global Date endDate;
    }
    
    // Class for iterating over affected territories & days
    // Needed to find peers who worked the same shifts (AssignedResource) in the same areas (ServiceTerritories)
    public class territoryClass {
        public Id arId; // AssignedResource Id
        public Id tId;  // ServiceTerritory Id
        public DateTime startDateTime; // Start of day
        public DateTime endDateTime; // End of day
        public String ceName; // Name of Contact Encounter associated with this shift
        public Integer ceDuration; // Duration of ContactEncounter associated with this shift (duration of affected employees shift; not actually calculating overlap)
    }
    
    /**
     * Get a ContactEncounter Id from a list of Contact Encounters given a ContactEncounter.Name;
     **/
    public static Id getCEIdfromName(List<ContactEncounter> encounterList,String encounterName) {
        for (ContactEncounter ce : encounterList){
     		if(ce.Name.equals(encounterName)){
         		return ce.Id;
     		}
		}
		return null;
    }

    /**
     * Get Contact Id from Employee Number
     **/
    public static Id getCIdfromENum(List<Contact> employeeList, String employeeNumber) {
        for (Contact c : employeeList){
     		if(c.HealthCloudGA__SourceSystemId__c.equals(employeeNumber)){
         		return c.Id;
     		}
		}
		return null;
    }

    @InvocableMethod(label='Get Shifts for Contact Tracing')
    global static void getEmployees(List<employeesInputs> inputVars) {
        String affectedEmployeeNumber = inputVars[0].employeeNumber;
		// Set the startDateTime to the beginning of the day of the inputStartDateTime
        // TO DO: adjust/test for timezones; currently using default GMT
        Time startTimeDay = Time.newInstance(0,0,0,0);
        Time endTimeDay = Time.newInstance(23,59,59,99);
        DateTime startDateTime = DateTime.newInstance(inputVars[0].startDate, startTimeDay);
		// Set the endDateTime to the beginning of the day of the inputEndDateTime
        // TO DO: adjust/test for timezones; currently using default GMT
        DateTime endDateTime = DateTime.newInstance(inputVars[0].endDate, endTimeDay);

        /**
         * Get impacted shift info and generate list of ContactEncounters
         **/
       	// Get all AssignedResources (shifts) for this Employee
        List<ContactEncounter> newContactEncounters = new List<ContactEncounter>();
        String thisDateString;
        List<Id> impactedTerritoryIds = new List<Id>();
        List<territoryClass> impactedTerritories = new List<territoryClass>();
		for (AssignedResource ar : [SELECT Id,ServiceAppointment.ServiceTerritoryId,ServiceAppointment.ServiceTerritory.Name,ServiceAppointment.ServiceTerritory.wkfsl__Location__c,ServiceAppointment.SchedStartTime,ServiceAppointment.SchedEndTime 
                                          FROM AssignedResource 
                                          WHERE ServiceResource.wkfsl__Employee__r.EmployeeNumber=:affectedEmployeeNumber AND ServiceAppointment.SchedStartTime > :startDateTime AND ServiceAppointment.SchedEndTime < :endDateTime 
            							  ORDER BY ServiceAppointment.ServiceTerritory.Name ASC, ServiceAppointment.SchedStartTime ASC]) {
            /**
             *  Generate ContactEncounter and add it to the list
             **/
            ContactEncounter ce = new ContactEncounter();
            ce.StartTime=ar.ServiceAppointment.SchedStartTime;
            // Generate ContactEncounter name
            thisDateString = ar.ServiceAppointment.SchedStartTime.date().format();
            ce.Name = 'Shift: ' + ar.ServiceAppointment.ServiceTerritory.Name + ' on ' + thisDateString;
            if (ar.ServiceAppointment.ServiceTerritory.wkfsl__Location__c != null) {
            	ce.LocationId = ar.ServiceAppointment.ServiceTerritory.wkfsl__Location__c;
			}
            ce.Description = 'Encounter generated via Shift Management';
            // Calculate shift duration in minutes
            // Will use the affected employee's shift as the EncounterDuration
            // TO DO: A future option would be to actually calculate the shift overlap
            // TO DO: Test if this works when a Service Appointment spans over a day transition
            // TO DO: Test for timezone impact
            long timeDiff = ((ar.ServiceAppointment.SchedEndTime.getTime())/1000/60) - ((ar.ServiceAppointment.SchedStartTime.getTime())/1000/60);
            ce.EncounterDuration = timeDiff.intValue();
			newContactEncounters.add(ce);

			// Store information from affected Assigned Resources that is needed to find peers
			impactedTerritoryIds.add(ar.ServiceAppointment.ServiceTerritoryId);
			territoryClass t = new territoryClass();
            t.arId = ar.Id;
            t.tId = ar.ServiceAppointment.ServiceTerritoryId;
            Date thisDate = ar.ServiceAppointment.SchedStartTime.date();
            t.startDateTime = DateTime.newInstance(thisDate, startTimeDay);
            t.endDateTime = DateTime.newInstance(thisDate, endTimeDay);
			t.ceName = ce.Name;
            t.ceDuration = ce.EncounterDuration;
            impactedTerritories.add(t);
        }

        /**
         * Insert ContactEncounter records from the overlapping ServiceAppointments 
         **/
		try {
        	insert newContactEncounters;
		} catch(DmlException e) {
    		System.debug('The following exception has occurred: ' + e.getMessage());
		}

		/**
		 * Get a list of affected peer Employees so that we can bulk look up their Contact records
		 **/
        list<String> potentialPeerENums = new List<String>();
		for (AssignedResource ar : [SELECT Id,ServiceResource.wkfsl__Employee__r.EmployeeNumber 
                                    FROM AssignedResource 
                                    WHERE ServiceAppointment.ServiceTerritoryId IN :impactedTerritoryIds AND ServiceAppointment.SchedStartTime > :startDateTime AND ServiceAppointment.SchedEndTime < :endDateTime]) {
			potentialPeerENums.add(ar.ServiceResource.wkfsl__Employee__r.EmployeeNumber);
        }
		List<Contact> potentialPeers = [SELECT Id,HealthCloudGA__SourceSystemId__c FROM Contact WHERE HealthCloudGA__SourceSystemId__c IN :potentialPeerENums];
        
		/**
		 *  Get all Employees sharing shifts in the same ServiceTerritories on the same Days
		 *  TO DO: Prevent duplicates
		 **/
        List<ContactEncounterParticipant> newCEParticipants = new List<ContactEncounterParticipant>();
        // Loop through each ServiceTerritory
        for (territoryClass t : impactedTerritories) {
            // Determine day this employee worked for this shift
            // For this ServiceTerritory get all AssignedResources on the same day the affected employee was assigned
            for (AssignedResource ar : [SELECT Id,ServiceAppointment.ServiceTerritory.Name,ServiceResource.wkfsl__Employee__r.EmployeeNumber,ServiceAppointment.SchedStartTime,ServiceAppointment.SchedEndTime 
                                        FROM AssignedResource 
                                        WHERE ServiceAppointment.ServiceTerritoryId = :t.tId AND ServiceAppointment.SchedStartTime > :t.startDateTime AND ServiceAppointment.SchedStartTime < :t.endDateTime AND ServiceAppointment.SchedEndTime < :endDateTime]) {
    			// Generate a list of ContactEncounterParticipants (affected Employees) 
                // Create the new ContactEncounterParticipant and add it to the list
                ContactEncounterParticipant p = new ContactEncounterParticipant();
            	thisDateString = ar.ServiceAppointment.SchedStartTime.date().format();
                String thisEncounterName = 'Shift: ' + ar.ServiceAppointment.ServiceTerritory.Name + ' on ' + thisDateString;
            	p.ContactEncounterId = getCEIdfromName(newContactEncounters,thisEncounterName); // TO DO: need to write Contact Encounters to DB so we have Ids
                p.ContactId = getCIdfromENum(potentialPeers,ar.ServiceResource.wkfsl__Employee__r.EmployeeNumber); // TO DO: need to lookup Contact from EmployeeNumber
                // TO DO: Determine why these fields are not writeable
                //p.StartTime = ar.ServiceAppointment.SchedStartTime; // Start time for this peer employee
                //p.EncounterDuration = t.ceDuration;
                newCEParticipants.add(p);
            }
        }

        /**
         * Insert ContactEncounterParticipant records for the previously inserted ContactEncounters 
         **/
		try {
        	insert newCEParticipants;
		} catch(DmlException e) {
    		System.debug('The following exception has occurred: ' + e.getMessage());
		}

        // TEST
//		  System.debug(impactedTerritories);
//        System.debug(newContactEncounters);
//        System.debug(employeeNumbers);
//        System.debug(newCEParticipants);
//        delete newContactEncounters;
    }
}