/*
***************************************************************************
Constant Name      : accountColumns
Created Date       : August 1, 2024
@description       : Defines the column configuration for the Account Data Table component. 
                    - 'Account Name': Displays the account name.
                    - 'Billing Address': Displays a custom formatted address.
                    - 'Email': Displays the email address from the custom field 'DUET__email__c'.
@author            : Rahul Gupta(TCD)

Modification Log:
Ver   Date         Author                     Modification
1.0   08-1-2024   Rahul Gupta                Initial Version 
*****************************************************************************
*/
export const accountColumns = [
    { label: 'Account Name', fieldName: 'Name' },
    { label: 'Billing Address', fieldName: 'customAddress' },
    { label: 'Email', fieldName: 'DUET__email__c' },
]