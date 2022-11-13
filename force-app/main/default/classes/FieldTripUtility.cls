/**
 * Utility class for Field Tripping
 */
public without sharing class FieldTripUtility {
    
    @AuraEnabled
    public static List<SelectionOption> getFieldTripNames() {
        List<SelectionOption> fieldTripNames = new List<SelectionOption>();

        SelectionOption option = new SelectionOption();
        option.label = '--- None ---';
        option.value = '';
        fieldTripNames.add(option);

        for (AggregateResult aggResult : [SELECT FieldTripName__c FROM Field_Trip__c GROUP BY FieldTripName__c]) {
            SelectionOption r = new SelectionOption();
            r.label = (String)aggResult.get('FieldTripName__c');
            r.value = (String)aggResult.get('FieldTripName__c');

            fieldTripNames.add(r);
        }

        return fieldTripNames;
    }


    @AuraEnabled(cacheable=true)
    public static List<Field_Trip__c> getFieldTripRecordByName(String fieldTripName) {
        return [
            SELECT
                Object__c,
                Field__c,
                Field_Type__c,
                Uses__c
            FROM Field_Trip__c
            WHERE FieldTripName__c =: fieldTripName
            ORDER BY Uses__c DESC
        ];
    }


    @AuraEnabled
    public static Boolean deleteFieldTripRecordByName(String fieldTripName) {
        List<Field_Trip__c> ftList = [
            SELECT
                Object__c,
                Field__c,
                Field_Type__c,
                Uses__c
            FROM Field_Trip__c
            WHERE FieldTripName__c =: fieldTripName
        ];

        delete ftList;

        return true;
    }


    public class FieldTripRequest {

        @InvocableVariable
        public String fieldTripName;

        @InvocableVariable
        public String objectName;

        @InvocableVariable
        public String whereClause;

        @InvocableVariable
        public String submitterEmail;
    }

    public class FieldTripResult {

        @InvocableVariable
        public Boolean isDuplicate;
    }


    @InvocableMethod (label='Calculate Field Trip')
    public static List<FieldTripResult> calculateFieldTrip(List<FieldTripRequest> request) {

        String fieldTripName = request.get(0).fieldTripName;
        String objectName = request.get(0).objectName;
        String whereClause = request.get(0).whereClause;
        String submitterEmail = request.get(0).submitterEmail;

        List<FieldTripResult> results = new List<FieldTripResult>();
        List<Field_Trip__c> ftList = FieldTripUtility.getFieldTripRecordByName(fieldTripName);

        if (ftList.size() > 0) {
            FieldTripResult res = new FieldTripResult();
            res.isDuplicate = true;
            results.add(res);
        }
        else {
            Integer size = (Integer)Batch_Size_Setting__mdt.getInstance('FieldTripCalculationBatch').Batch_Size__c;
            FieldTripCalculationBatch batch = new FieldTripCalculationBatch(fieldTripName, objectName, whereClause, submitterEmail);
            Database.executeBatch(batch, size); 
            
            FieldTripResult res = new FieldTripResult();
            res.isDuplicate = false;
            results.add(res);
        }

        return results;
    }


    public class SelectionOption {
        @AuraEnabled
        public String label {get;set;}

        @AuraEnabled
        public String value {get;set;}
    }
}