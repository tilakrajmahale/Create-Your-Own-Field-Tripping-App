import { LightningElement, track} from 'lwc';
import getFieldTripNames from '@salesforce/apex/FieldTripUtility.getFieldTripNames';
import getFieldTripRecordByName from '@salesforce/apex/FieldTripUtility.getFieldTripRecordByName';
import deleteFieldTripRecordByName from '@salesforce/apex/FieldTripUtility.deleteFieldTripRecordByName';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningConfirm from "lightning/confirm";

export default class FieldTripListView extends LightningElement {
    @track option = [];
    value;
    error;
    fieldTripRecords;
    sortBy;
    sortDirection;
    tableSpinner = false;

    get options() {
        return this.option;
    }

    columns = [{
            label: 'Object Name',
            fieldName: 'Object__c',
            type: 'text',
            sortable: false,
            cellAttributes: { alignment: 'left' }
        },
        {
            label: 'Field Name',
            fieldName: 'Field__c',
            type: 'text',
            sortable: true,
            cellAttributes: { alignment: 'left' }
        },
        {
            label: 'Field Type',
            fieldName: 'Field_Type__c',
            type: 'text',
            sortable: true,
            cellAttributes: { alignment: 'left' }
        },
        {
            label: 'Uses',
            fieldName: 'Uses__c',
            type: 'percent',
            sortable: true,
            cellAttributes: { alignment: 'left' },
            typeAttributes: {
                step: '0.00001',
                minimumFractionDigits: '3',
                maximumFractionDigits: '6',
            }
        }
    ];


    connectedCallback(){
        this.refershOptions();
    }


    handleChange(event) {
        this.tableSpinner = true;
        this.value = event.detail.value;

        if(this.value == ''){
            this.refreshComponent();
        }

        getFieldTripRecordByName({
            fieldTripName: this.value
        })
        .then(result => {
            this.fieldTripRecords = result;
            this.tableSpinner = false
        })
        .catch(error => {
            this.error = error;
        });
    }


    async handleDelete(event) {
        this.tableSpinner = true;
        const confirm = await LightningConfirm.open({
            message: "Are you sure you want to delete this Field Trip?",
            variant: "default",
            label: "Delete all record"
        });

        if (confirm) {
            deleteFieldTripRecordByName({
                fieldTripName: this.value
            })
            .then(result => {
                this.tableSpinner = false;
                this.showNotification();
                setTimeout(() => {
                    eval("$A.get('e.force:refreshView').fire();");
                }, 200); 
            })
            .catch(error => {
                this.error = error;
            });
        }
    }


    showNotification() {
        const evt = new ShowToastEvent({
            title: 'Deleted',
            message: 'Record are deleted successfully!',
            variant: 'success',
        });
        this.dispatchEvent(evt);
    }

    refreshComponent(){
        setTimeout(() => {
            eval("$A.get('e.force:refreshView').fire();");
        }, 200);

        this.refershOptions();
    }

    refershOptions(){
        getFieldTripNames()
        .then(result => {
            this.option = result;
        })
        .catch(error => {
            this.error = error;
        });
    }

    doSorting(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortData(this.sortBy, this.sortDirection);
    }

    sortData(fieldname, direction) {
        let parseData = JSON.parse(JSON.stringify(this.fieldTripRecords));
        
        // Return the value stored in the field
        let keyValue = (a) => {
            return a[fieldname];
        };

        // cheking reverse direction
        let isReverse = direction === 'asc' ? 1: -1;
        
        // sorting data
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; 
            y = keyValue(y) ? keyValue(y) : '';

            // sorting values based on direction
            return isReverse * ((x > y) - (y > x));
        });
        this.fieldTripRecords = parseData;
    }  
}