/**
 * Test class of FieldTripUtility class
 */

 @isTest
private class FieldTripUtilityTest {
    
    @TestSetup
    static void setupData(){
    
        Date TODAYS_DATE = Date.today();
        List<Account> accounts = TestDataFactory.createAccountsWithContacts( 1, 1 );
        Country__c country = TestDataFactory.createCountry();
        Firm_Member__c firmMember = TestDataFactory.createFirmMember();
        Case cs = TestDataFactory.createCase( accounts[0].Id, country.Id);

        cs.CE_code__c = '7383TY';
        cs.Origin_Instance__c = 'ENG';
        cs.Engagement_End_Date__c = TODAYS_DATE - 26;
        cs.Responsible_Partner__c = firmMember.Id;
        cs.CSRC_Review_Required__c = true;
        cs.contract_box_link__c = 'www.salesforce.com';
        Update cs;

        Test.startTest();

        List<FieldTripUtility.FieldTripRequest> requests = new List<FieldTripUtility.FieldTripRequest> ();
        FieldTripUtility.FieldTripRequest req = new FieldTripUtility.FieldTripRequest();
        req.fieldTripName = 'CaseFieldTrip';
        req.objectName = 'Case';
        req.submitterEmail = 'test@gmail.com';
        req.whereClause = 'WHERE CreatedDate >= YESTERDAY';
        requests.add(req);

        FieldTripUtility.calculateFieldTrip(requests);

        Test.stopTest();
    }


    @IsTest
    static void testGetFieldTripNames(){
        
        Test.startTest();
        List<FieldTripUtility.SelectionOption> options = FieldTripUtility.getFieldTripNames();
        Test.stopTest();

        Set<String> optionSet = new Set<String>();
        for (FieldTripUtility.SelectionOption option : options) {
            optionSet.add(option.label);
        }     
        
        System.assert(optionSet.contains('--- None ---'));
        System.assert(optionSet.contains('CaseFieldTrip'));
    }


    @IsTest
    static void testGetFieldTripRecordByName(){
        
        Test.startTest();
        List<Field_Trip__c> ftList = FieldTripUtility.getFieldTripRecordByName('CaseFieldTrip');
        Test.stopTest();
        
        System.assert(ftList.size() > 0);
    }


    @IsTest
    static void testDeleteFieldTripRecordByName(){
        
        Test.startTest();
        FieldTripUtility.deleteFieldTripRecordByName('CaseFieldTrip');
        Test.stopTest();

        List<Field_Trip__c> ftList = new List<Field_Trip__c>([
            SELECT
                Object__c,
                Field__c,
                Field_Type__c,
                Uses__c
            FROM Field_Trip__c
            WHERE FieldTripName__c =: 'CaseFieldTrip'
        ]);
        
        System.assert(ftList.size() == 0);
    }
}
