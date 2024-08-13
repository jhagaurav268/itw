import { LightningElement, api, track } from 'lwc';
import SearchContacts from '@salesforce/apex/SearchAccountController.searchContacts';

export default class ContactsRelatedtoAccount extends LightningElement {
    contactColumns = [
        { label: 'Contact Name', fieldName: 'names' },
        { label: 'Email', fieldName: 'Email' },
        { label: 'Account Name', fieldName: 'Name' },
    ];
    @api accountData;
    showData = false;
    isSpinnerLoading = false;
    contactData;
    selectedContact = [];
    accountId = [];
    @api storeSelectedData;

    //Pagination Variables
    pageSizeOptions = [10];
    records = [];
    columns = [];
    totalRecords = 0;
    pageSize;
    totalPages;
    pageNumber = 1;
    recordsToDisplay = [];
    @track allRowsSelection = []

     /*
    ***************************************************************************
    Method Name        : connectedCallback
    Created Date       : August 1, 2024
    @description       : Lifecycle hook called when the component is inserted into the DOM. 
                         Fetches contacts related to accounts and initializes data for the component. 
                         It handles pagination and displays the data in the table.
    @author            : Rahul Gupta(TCD)
    Modification Log:
    Ver   Date         Author                     Modification
    1.0   08-1-2024   Rahul Gupta                Initial Version 
    *****************************************************************************
    */
    connectedCallback() {
        this.isSpinnerLoading = true;
        for (let i = 0; i < this.accountData.ScreenOneData.length; i++) {
            this.accountId.push(this.accountData.ScreenOneData[i].Id);
        }
        console.log('this.accountId ', this.accountId);
        SearchContacts({ accountId: this.accountId }).then((result) => {
            let accountResult = result;
            console.log('accountResult ', accountResult);

            this.contactData = accountResult;

            if (this.storeSelectedData) {
                this.selectedContact = this.storeSelectedData.map(row => row.Id);
            }
            this.showData = true;
            this.totalRecords = this.contactData.length;
            this.pageSize = this.pageSizeOptions[0];
            this.paginationHelper();

            this.isSpinnerLoading = false;
            console.log('contactData ', this.contactData);
        }).catch(error => {
            this.isSpinnerLoading = false;

        });
    }

      /*
    ***************************************************************************
    Method Name        : bDisableFirst
    Created Date       : August 1, 2024
    @description       : Getter method that determines if the "First" page button should be disabled based on the current page number.
    @author            : Rahul Gupta(TCD)
    Modification Log:
    Ver   Date         Author                     Modification
    1.0   08-1-2024   Rahul Gupta                Initial Version 
    *****************************************************************************
    */
    get bDisableFirst() {
        return this.pageNumber == 1;
    }

      /*
    ***************************************************************************
    Method Name        : bDisableLast
    Created Date       : August 1, 2024
    @description       : Getter method that determines if the "Last" page button should be disabled based on the current page number.
    @author            : Rahul Gupta(TCD)
    Modification Log:
    Ver   Date         Author                     Modification
    1.0   08-1-2024   Rahul Gupta                Initial Version 
    *****************************************************************************
    */
    get bDisableLast() {
        return this.pageNumber == this.totalPages;
    }

     /*
    ***************************************************************************
    Method Name        : handleRecordsPerPage
    Created Date       : August 1, 2024
    @description       : Event handler for changing the number of records displayed per page. 
                        Updates the page size and recalculates the pagination.
    @author            : Rahul Gupta(TCD)
    Modification Log:
    Ver   Date         Author                     Modification
    1.0   08-1-2024   Rahul Gupta                Initial Version 
    *****************************************************************************
    */
    handleRecordsPerPage(event) {
        this.pageSize = event.target.value;
        this.paginationHelper();
    }

     /*
    ***************************************************************************
    Method Name        : previousPage
    Created Date       : August 1, 2024
    @description       : Navigates to the previous page in the pagination and updates the displayed records.
    @author            : Rahul Gupta(TCD)
    Modification Log:
    Ver   Date         Author                     Modification
    1.0   08-1-2024   Rahul Gupta                Initial Version 
    *****************************************************************************
    */
    previousPage() {
        this.pageNumber = this.pageNumber - 1;
        this.paginationHelper();
    }

     /*
    ***************************************************************************
    Method Name        : nextPage
    Created Date       : August 1, 2024
    @description       : Navigates to the next page in the pagination and updates the displayed records.
    @author            : Rahul Gupta(TCD)
    Modification Log:
    Ver   Date         Author                     Modification
    1.0   08-1-2024   Rahul Gupta                Initial Version 
    *****************************************************************************
    */
    nextPage() {
        this.pageNumber = this.pageNumber + 1;
        this.paginationHelper();
    }

     /*
    ***************************************************************************
    Method Name        : firstPage
    Created Date       : August 1, 2024
    @description       : Navigates to the first page in the pagination and updates the displayed records.
    @author            : Rahul Gupta(TCD)
    Modification Log:
    Ver   Date         Author                     Modification
    1.0   08-1-2024   Rahul Gupta                Initial Version 
    *****************************************************************************
    */
    firstPage() {
        this.pageNumber = 1;
        this.paginationHelper();
    }

     /*
    ***************************************************************************
    Method Name        : lastPage
    Created Date       : August 1, 2024
    @description       : Navigates to the last page in the pagination and updates the displayed records.
    @author            : Rahul Gupta(TCD)
    Modification Log:
    Ver   Date         Author                     Modification
    1.0   08-1-2024   Rahul Gupta                Initial Version 
    *****************************************************************************
    */
    lastPage() {
        this.pageNumber = this.totalPages;
        this.paginationHelper();
    }

/*
    ***************************************************************************
    Method Name        : paginationHelper
    Created Date       : August 1, 2024
    @description       : Calculates the records to display based on the current page number and page size. 
                         Updates the pagination controls and selected rows.
    @author            : Rahul Gupta(TCD)
    Modification Log:
    Ver   Date         Author                     Modification
    1.0   08-1-2024   Rahul Gupta                Initial Version 
    *****************************************************************************
    */
    paginationHelper() {
        this.recordsToDisplay = [];
        this.totalPages = Math.ceil(this.totalRecords / this.pageSize);
        
        if (this.pageNumber <= 1) {
            this.pageNumber = 1;
        } else if (this.pageNumber >= this.totalPages) {
            this.pageNumber = this.totalPages;
        }
      
        for (let i = (this.pageNumber - 1) * this.pageSize; i < this.pageNumber * this.pageSize; i++) {
            if (i === this.totalRecords) {
                break;
            }
            this.recordsToDisplay.push(this.contactData[i]);
        }
        this.template.querySelector('[data-id="datatable"]').selectedRows = this.selectedContact;
    }

     /*
    ***************************************************************************
    Method Name        : handleRowSelection
    Created Date       : August 1, 2024
    @description       : Handles row selection in the data table. 
                         Updates the list of selected contacts and dispatches a custom event with the selected contact data.
    @author            : Rahul Gupta(TCD)
    Modification Log:
    Ver   Date         Author                     Modification
    1.0   08-1-2024   Rahul Gupta                Initial Version 
    *****************************************************************************
    */
    handleRowSelection(event) {
        let updatedItemsSet = new Set();
        let selectedItemsSet = new Set(this.selectedContact);
        let loadedItemsSet = new Set();
        this.recordsToDisplay.map((ele) => {
            loadedItemsSet.add(ele.Id);
        });
        if (event.detail.selectedRows) {
            event.detail.selectedRows.map((ele) => {
                updatedItemsSet.add(ele.Id);
            });
            updatedItemsSet.forEach((id) => {
                if (!selectedItemsSet.has(id)) {
                    selectedItemsSet.add(id);
                }
            });
        }
        loadedItemsSet.forEach((id) => {
            if (selectedItemsSet.has(id) && !updatedItemsSet.has(id)) {
                selectedItemsSet.delete(id);
            }
        });
        this.selectedContact = [...selectedItemsSet];
        console.log('this.selectedContact===>', this.selectedContact.length);

        this.allRowsSelection = this.contactData.filter(contact => this.selectedContact.includes(contact.Id));
        console.log('OUTPUT :  this.allRowsSelection====', this.allRowsSelection);
        const selectEvent = new CustomEvent('secondscreendata', {
            detail: this.allRowsSelection
        });
        this.dispatchEvent(selectEvent);
    }
}