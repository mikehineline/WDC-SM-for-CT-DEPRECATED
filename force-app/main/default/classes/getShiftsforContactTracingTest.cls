@isTest
private class getShiftsforContactTracingTest {
    @isTest
    static void testShiftToTracing() {
        /**
         * Create test data
         **/
        // Create test Users
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];
		List<User> tUsers = new List<User>();
        User u1 = new User(FirstName='Employee',LastName='1',EmployeeNumber='EE-9999901',Email='test1@example.com',Alias='test1',EmailEncodingKey='UTF-8',LanguageLocaleKey='en_US',LocaleSidKey='en_US',ProfileId=p.Id,TimeZoneSidKey='America/Los_Angeles', UserName='test1@mrhtestcode1.com');
        tUsers.add(u1);
        User u2 = new User(FirstName='Employee',LastName='2',EmployeeNumber='EE-9999902',Email='test2@example.com',Alias='test1',EmailEncodingKey='UTF-8',LanguageLocaleKey='en_US',LocaleSidKey='en_US',ProfileId=p.Id,TimeZoneSidKey='America/Los_Angeles', UserName='test2@mrhtestcode1.com');
        tUsers.add(u2);
        try {
            Database.SaveResult[] r0 = Database.insert(tUsers,false);
		} catch(DmlException e) {
    		System.debug('The following exception has occurred: ' + e.getMessage());
		}
        System.Debug('u1.Id: '+u1.Id);

        // Create test Locations
		List<Schema.Location> tLo = new List<Schema.Location>();
        Schema.Location lo1 = new Schema.Location(Name='TestLocation1',TimeZone='America/Los_Angeles',LocationType='Building');
        Schema.Location loc1 = new Schema.Location();
        loc1.Name='TestLocation1';
        loc1.TimeZone='America/Los_Angeles';
        loc1.LocationType='Building';
        tLo.add(lo1);
        Schema.Location lo2 = new Schema.Location(Name='TestLocation2',TimeZone='America/Los_Angeles',LocationType='Building');
        tLo.add(lo2);
        try {
        	Database.SaveResult[] r10 = Database.insert(tLo,false);
		} catch(DmlException e) {
    		System.debug('The following exception has occurred: ' + e.getMessage());
		}
        System.Debug('lo1.Id: '+lo1.Id);
        
        // Create test Employees
		List<Employee> tEmployees = new List<Employee>();
        DateTime statusDate = DateTime.newInstance(2020, 6, 15);
        Employee e1 = new Employee(FirstName='Employee',LastName='1',EmployeeNumber='EE-9999901',Email='test1@example.com',EmployeeStatus='Active',WorkerType='Employee',LocationId=lo1.Id,statusAsOf=statusDate);
        tEmployees.add(e1);
        Employee e2 = new Employee(FirstName='Employee',LastName='2',EmployeeNumber='EE-9999902',Email='test2@example.com',EmployeeStatus='Active',WorkerType='Employee',LocationId=lo1.Id,statusAsOf=statusDate);
        tEmployees.add(e2);
        try {
        	Database.SaveResult[] r1 = Database.insert(tEmployees,false);
		} catch(DmlException e) {
    		System.debug('The following exception has occurred: ' + e.getMessage());
		}
        System.Debug('e1.Id: '+e1.Id);
        
        // Create test PersonAccounts
        RecordType paRT = [SELECT Id FROM RecordType WHERE Name = 'Person Account' and SObjectType = 'Account'];
		List<Account> tPAs = new List<Account>();
        Account p1 = new Account(FirstName='Employee',LastName='1',HealthCloudGA__SourceSystemId__pc='EE-9999901',RecordType=paRT);
		tPAs.add(p1);
        Account p2 = new Account(FirstName='Employee',LastName='2',HealthCloudGA__SourceSystemId__pc='EE-9999902',RecordType=paRT);
		tPAs.add(p2);
        try {
        	Database.SaveResult[] r2 = Database.insert(tPAs,false);
		} catch(DmlException e) {
    		System.debug('The following exception has occurred: ' + e.getMessage());
		}
        System.Debug('p1.Id: '+p1.Id);
       
		// Create Operating Hours (required field for Service Territory)
		OperatingHours o1 = new OperatingHours(Name='OH Test',TimeZone='America/Los_Angeles');
        try {
        	insert o1;
		} catch(DmlException e) {
    		System.debug('The following exception has occurred: ' + e.getMessage());
		}

        // Create ServiceTerritory
        ServiceTerritory st1 = new ServiceTerritory(Name='Test Territory',OperatingHoursId=o1.id,isActive=TRUE);
        try {
        	Database.SaveResult r4 = Database.insert(st1,false);
		} catch(DmlException e) {
    		System.debug('The following exception has occurred: ' + e.getMessage());
		}
        System.Debug('st1.Id: '+st1.Id);
        
        // Create ServiceResources
		List<ServiceResource> tSRs = new List<ServiceResource>();
        ServiceResource sr1 = new ServiceResource(Name='Employee 1',wkfsl__Employee__c=e1.Id,ResourceType='T',RelatedRecordId=u1.Id,isActive=TRUE);
        tSRs.add(sr1);
        ServiceResource sr2 = new ServiceResource(Name='Employee 2',wkfsl__Employee__c=e2.Id,ResourceType='T',RelatedRecordId=u2.Id,isActive=TRUE);
        tSRs.add(sr2);
        try {
        	Database.SaveResult[] r5 = Database.insert(tSRs,false);
		} catch(DmlException e) {
    		System.debug('The following exception has occurred: ' + e.getMessage());
		}
        System.Debug('sr1.Id: '+sr1.Id);
         
        // Create ServiceTerritoryMembers
		List<ServiceTerritoryMember> tSTMs = new List<ServiceTerritoryMember>();
        DateTime eSD = DateTime.newInstance(2020, 1, 1);
        ServiceTerritoryMember stm1 = new ServiceTerritoryMember(ServiceTerritoryId=st1.Id,ServiceResourceId=sr1.Id,EffectiveStartDate=eSD);
        tSTMs.add(stm1);
        ServiceTerritoryMember stm2 = new ServiceTerritoryMember(ServiceTerritoryId=st1.Id,ServiceResourceId=sr2.Id,EffectiveStartDate=eSD);
        tSTMs.add(stm2);
		try {
            Database.SaveResult[] r6 = Database.insert(tSTMs,false);
		} catch(DmlException e) {
    		System.debug('The following exception has occurred: ' + e.getMessage());
		}
        System.Debug('stm1.Id: '+stm1.Id);

		// Create Account for Work.com Asset
        Account wdcAcc = new Account(Name='Salesforce.com');
        try {
        	Database.SaveResult r12 = Database.insert(wdcAcc,false);
		} catch(DmlException e) {
    		System.debug('The following exception has occurred: ' + e.getMessage());
		}
        System.Debug('wdcAcc.Id: '+wdcAcc.Id);

        // Create Work.com Asset
		Asset wdca = new Asset(Name='Work.com',AccountId=wdcAcc.Id);
		try {
            Database.SaveResult r11 = Database.insert(wdca,false);
		} catch(DmlException e) {
    		System.debug('The following exception has occurred: ' + e.getMessage());
		}
        System.Debug('wdca.Id: '+wdca.Id);
        
        // Create ServiceAppointments
		List<ServiceAppointment> tSAs = new List<ServiceAppointment>();
        DateTime tEStart = DateTime.newInstance(2020, 6, 1, 0, 0, 0);
        DateTime tStart = DateTime.newInstance(2020, 6, 1, 9, 0, 0);
        DateTime tEnd = DateTime.newInstance(2020, 6, 1, 12, 0, 0);
        DateTime tDue = DateTime.newInstance(2020, 6, 1, 24, 59, 59);
        ServiceAppointment sa1 = new ServiceAppointment(ServiceTerritoryId=st1.Id,EarliestStartTime=tEStart,SchedStartTime=tStart,SchedEndTime=tEnd,DueDate=tDue,Status='Scheduled',ParentRecordId=wdca.Id);
        tSAs.add(sa1);
        ServiceAppointment sa2 = new ServiceAppointment(ServiceTerritoryId=st1.Id,EarliestStartTime=tEStart,SchedStartTime=tStart,SchedEndTime=tEnd,DueDate=tDue,Status='Scheduled',ParentRecordId=wdca.Id);
        tSAs.add(sa2);
        try {
        	Database.SaveResult[] r7 = Database.insert(tSAs,false);
		} catch(DmlException e) {
    		System.debug('The following exception has occurred: ' + e.getMessage());
		}
        System.Debug('sa1.Id: '+sa1.Id);

        // Create AssignedResources
		List<AssignedResource> tARs = new List<AssignedResource>();
        AssignedResource ar1 = new AssignedResource(ServiceAppointmentId=sa1.Id,ServiceResourceId=sr1.Id);
        tARs.add(ar1);
        AssignedResource ar2 = new AssignedResource(ServiceAppointmentId=sa2.Id,ServiceResourceId=sr2.Id);
        tARs.add(ar2);
        try {
        	Database.SaveResult[] r8 = Database.insert(tARs,false);
		} catch(DmlException e) {
    		System.debug('The following exception has occurred: ' + e.getMessage());
		}
        System.Debug(tARs);
        System.Debug('ar1.Id: '+ar1.Id);

        /**
         * Test getShiftsForContactTracing
         **/
		Test.startTest();
        Date tStartDate = Date.newInstance(2020, 5, 1);
        Date tEndDate = Date.newInstance(2020, 12, 1);
        List<getShiftsForContactTracing.employeesInputs> tInputs= new List<getShiftsForContactTracing.employeesInputs>();
        getShiftsForContactTracing.employeesInputs tInput = new getShiftsForContactTracing.employeesInputs();
        tInput.employeeNumber='EE-9999901';
        tInput.startDate=tStartDate;
        tInput.endDate=tEndDate;
        tInputs.add(tInput);
		getShiftsForContactTracing.getEmployees(tInputs);        

        /**
         * Validate
         * TO DO: Improve on the VERY light validation here which is just to achieve code coverage
         * 	for packaging for a demo component
         **/
		ServiceAppointment saVal = [SELECT Id FROM ServiceAppointment WHERE ServiceTerritoryId = :st1.Id LIMIT 1];
        System.assert(saVal != null); 
        ContactEncounter ceVal = [SELECT Id FROM ContactEncounter WHERE Name LIKE 'Shift: %' LIMIT 1];
        System.assert(ceVal != null); 
        ContactEncounterParticipant cepVal = [SELECT Id FROM ContactEncounterParticipant LIMIT 1];
        System.assert(cepVal != null); 

        Test.stopTest();
    }
}