/**
 * Used to calculated field use in Salesforce org.
 */
public class FieldTripCalculationBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    private String objectName;
    private String whereClause;
    private String fieldTripName;
    private String submitterEmail;

    // Field map of all the case fields
    private Map<String, Schema.SObjectField> fieldMap;

    // Map to store the use count
    private Map<String, Integer> fieldUseCountMap = new Map<String, Integer>();

    //Field -> fieldtype map
    Map<String, String> fieldFieldTypeMap = new Map<String, String>();


    public FieldTripCalculationBatch(String fieldTripName, String objectName, String whereClause, String submitterEmail) {
        this.fieldTripName = fieldTripName;
        this.objectName = objectName;
        this.whereClause = whereClause;
        this.submitterEmail = submitterEmail;
        this.fieldMap= Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
    }


    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = getObjectQuery();

        if (String.isNotBlank(this.whereClause)) {
            query += ' ' + whereClause;
        }
        
        return Database.getQueryLocator(query);
    }


    public void execute(Database.BatchableContext bc, List<sObject> records) { 
        try {
            for (SObject obj : records) {
                increaseUseCount(obj);
            }
        } 
        catch (Exception exe) {
            Utility.createPlatformErrorLog(exe, 'FieldTripCalculationBatch', 'execute');
        }
    }


    public void finish(Database.BatchableContext bc) { 

        if (fieldUseCountMap.size() > 0) {
                
            String query = 'SELECT count() FROM ' + this.objectName;

            if (String.isNotBlank(this.whereClause)) {
                query += ' ' + this.whereClause;
            }

            Integer totalRecordCount = Database.countQuery(query);

            List<Field_Trip__c> fieldTrips = new List<Field_Trip__c>();
            for (String fieldAPIName: fieldMap.keySet()) {

                if (fieldUseCountMap.containsKey(fieldAPIName)) {
                    Field_Trip__c ft = new Field_Trip__c();
                    ft.FieldTripName__c = this.fieldTripName;
                    ft.Object__c = this.objectName;
                    ft.Field__c = fieldAPIName;
                    ft.Field_Type__c = fieldFieldTypeMap.get(fieldAPIName);
                    ft.Uses__c = ((Decimal)fieldUseCountMap.get(fieldAPIName) / (Decimal)totalRecordCount);

                    fieldTrips.add(ft);
                } 
                else {
                    Field_Trip__c ft = new Field_Trip__c();
                    ft.FieldTripName__c = this.fieldTripName;
                    ft.Object__c = this.objectName;
                    ft.Field__c = fieldAPIName;
                    ft.Field_Type__c = fieldFieldTypeMap.get(fieldAPIName);
                    ft.Uses__c = 0;

                    fieldTrips.add(ft);
                }
            }

            insert fieldTrips;

            sendEmail();// Send the email
        }
    }


    private String getObjectQuery() {
        String query = 'SELECT ';

        for (String fieldAPIName: fieldMap.keySet()) {

            Schema.DescribeFieldResult fieldResult = fieldMap.get(fieldAPIName).getDescribe();
            Schema.DisplayType fieldType = fieldMap.get(fieldAPIName).getDescribe().getType();

            fieldFieldTypeMap.put(fieldAPIName, String.valueOf(fieldType));

            query += fieldAPIName + ', ';
        }

        query = query.removeEnd(', ');
        query += ' FROM ' + this.objectName;
        
        return query;
    }

    private void increaseUseCount(SObject obj) {
        
        for (String fieldAPIName: fieldMap.keySet()) {

            Schema.DisplayType FieldType = fieldMap.get(fieldAPIName).getDescribe().getType();
            Schema.DescribeFieldResult fieldResult = fieldMap.get(fieldAPIName).getDescribe();

            if ( 
                fieldType == Schema.DisplayType.BOOLEAN
                && obj.get(fieldAPIName) == true
            ) {
                increaseCount(fieldAPIName);
            } 
            else if ((
                    fieldType == Schema.DisplayType.STRING 
                    || fieldType == Schema.DisplayType.PICKLIST
                    || fieldType == Schema.DisplayType.TEXTAREA
                    || fieldType == Schema.DisplayType.EMAIL 
                    || fieldType == Schema.DisplayType.MULTIPICKLIST
                    || FieldType == Schema.DisplayType.ID
                    || fieldType == Schema.DisplayType.ADDRESS
                    || fieldType == Schema.DisplayType.URL 
                    || fieldType == Schema.DisplayType.ENCRYPTEDSTRING
                    || fieldType == Schema.DisplayType.COMBOBOX
                ) 
                && String.isNotBlank((String)obj.get(fieldAPIName))
            ) {
                increaseCount(fieldAPIName);
            } 
            else if ((
                    fieldType == Schema.DisplayType.REFERENCE
                    || fieldType == Schema.DisplayType.DATE
                    || fieldType == Schema.DisplayType.DATETIME 
                    || fieldType == Schema.DisplayType.CURRENCY 
                    || fieldType == Schema.DisplayType.DOUBLE
                    || fieldType == Schema.DisplayType.INTEGER 
                    || fieldType == Schema.DisplayType.LONG
                    || fieldType == Schema.DisplayType.PERCENT  
                    || fieldType == Schema.DisplayType.LOCATION
                    || fieldType == Schema.DisplayType.TIME
                    || fieldType == Schema.DisplayType.DATACATEGORYGROUPREFERENCE
                    || FieldType == Schema.DisplayType.BASE64
                    || fieldType == Schema.DisplayType.PHONE
                )
                && obj.get(fieldAPIName) != null
            ) {
                increaseCount(fieldAPIName);
            }       
        }
    }


    private void increaseCount(String fieldAPIName) {
        Integer count = fieldUseCountMap.containsKey(fieldAPIName) 
                ? fieldUseCountMap.get(fieldAPIName) 
                : 0;
        
        fieldUseCountMap.put(fieldAPIName, ++count);
    }


    private void sendEmail() {
        if (String.isNotBlank(this.submitterEmail)) {

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses( new List<String>{this.submitterEmail});
            mail.setSenderDisplayName('Field Tripping');
            mail.setSubject('Field Trip: ' + this.objectName);
            
            String body = 'Hi,<br/><br/>';
            body += 'Field tripping for object ' + this.objectName + ' is completed.<br/>';
            body += 'Please check the result in Field Trip app.<br/><br/>';
            body += 'Thank you :)<br/><br/>';

            mail.setHtmlBody( body );
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mail});
        }
    }
}