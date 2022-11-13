
/**
 * Test class of FieldTripCalculationBatch class
 */

@isTest
private class FieldTripCalculationBatchTest {
    
    @TestSetup
    static void setupData(){
    
        Date TODAYS_DATE = Date.today();
        List<Account> accounts = TestDataFactory.createAccountsWithContacts( 1, 1 );
        Country__c country = TestDataFactory.createCountry();
        Firm_Member__c firmMember = TestDataFactory.createFirmMember();
        Case cs = TestDataFactory.createCase( accounts[0].Id, country.Id);

        Test.startTest();

        cs.CE_code__c = '7383TY';
        cs.Origin_Instance__c = 'ENG';
        cs.Engagement_End_Date__c = TODAYS_DATE - 26;
        cs.Responsible_Partner__c = firmMember.Id;
        cs.CSRC_Review_Required__c = true;
        cs.contract_box_link__c = 'www.salesforce.com';
        Update cs;

        Test.stopTest();
    }


    @IsTest
    static void testFieldTrip(){

        System.Test.startTest();
        List<FieldTripUtility.FieldTripRequest> requests = new List<FieldTripUtility.FieldTripRequest> ();
        FieldTripUtility.FieldTripRequest req = new FieldTripUtility.FieldTripRequest();
        req.fieldTripName = 'CaseFieldTrip';
        req.objectName = 'Case';
        req.submitterEmail = 'test@gmail.com';
        req.whereClause = 'WHERE CreatedDate >= YESTERDAY';
        requests.add(req);

        FieldTripUtility.calculateFieldTrip(requests);
        System.Test.stopTest();

        List<Field_Trip__c> ftList = new List<Field_Trip__c> ();
        ftList = [
            SELECT
                Object__c,
                Field__c,
                Field_Type__c,
                Uses__c
            FROM Field_Trip__c
            WHERE FieldTripName__c = 'CaseFieldTrip'
        ];

        System.assert(ftList.size() > 0);

        Map<String, Integer> fieldUseMap = new Map<String, Integer>();
        for (Field_Trip__c ft : ftList) {
            fieldUseMap.put(ft.Field__c, (Integer)ft.Uses__c);
        }
        
        System.assertEquals(1, fieldUseMap.get('ce_code__c'));
        System.assertEquals(1, fieldUseMap.get('origin_instance__c'));
        System.assertEquals(1, fieldUseMap.get('responsible_partner__c'));
        System.assertEquals(0, fieldUseMap.get('pe_code__c'));
        System.assertEquals(0, fieldUseMap.get('background__c'));
    }
}
