import { LightningElement, api, track } from 'lwc';
import { accountColumns } from './constants';
import SearchAccounts from '@salesforce/apex/SearchAccountController.SearchAccounts';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import LEAFLET from '@salesforce/resourceUrl/Leaflet'

export default class SearchAccountFromPincode extends LightningElement {
    accountColumns = accountColumns;
    @api pincodeValue;
    showDataTable = false;
    accountData;
    isSpinnerLoading = false;
    address;

    //Pagination Variables
    pageSizeOptions = [10];
    records = [];
    columns = [];
    totalRecords = 0;
    pageSize;
    totalPages;
    pageNumber = 1;
    recordsToDisplay = [];
    @track selectedRows = [];
    @track allRowsSelection = []
    @api mainData;
    @api previousClick;


    /*
***************************************************************************
Method Name        : connectedCallback
Created Date       : August 1, 2024
@description       : Lifecycle hook that is called when the component is inserted into the DOM. 
                     If a `pincodeValue` is provided, it initializes the `selectedRows` with IDs from `mainData` and triggers the `handleButtonClick` method to load data based on the pincode.
@author            : Rahul Gupta(TCD)

Modification Log:
Ver   Date         Author                     Modification
1.0   08-1-2024   Rahul Gupta                Initial Version 
*****************************************************************************
*/
    connectedCallback() {
        if (this.pincodeValue) {
            this.selectedRows = this.mainData.map(row => row.Id);
            this.handleButtonClick();
        }
    }

    get bDisableFirst() {
        return this.pageNumber == 1;
    }
    get bDisableLast() {
        return this.pageNumber == this.totalPages;
    }

    /*
***************************************************************************
Method Name        : handleButtonClick
Created Date       : August 1, 2024
@description       : Retrieves account data based on the provided pincode by calling the Apex method `SearchAccounts`. 
                     Processes the data to include a formatted address and updates component state for rendering the data table. 
                     Manages spinner visibility during data loading.
@author            : Rahul Gupta(TCD)

Modification Log:
Ver   Date         Author                     Modification
1.0   08-1-2024   Rahul Gupta                Initial Version 
*****************************************************************************
*/
    handleButtonClick() {
        this.isSpinnerLoading = true;
        SearchAccounts({ inputPinCode: this.pincodeValue }).then((data) => {
            if (data === null) {
                this.isSpinnerLoading = false;
                return;
            }
            console.log(data);
            this.showDataTable = true;
            data = data.map(element => {
                return {
                    ...element,
                    customAddress: element.BillingAddress.street + ' ,' + element.BillingAddress.city + ' ,' + element.BillingAddress.state + ' ,' + element.BillingAddress.country + ' ,' + element.BillingAddress.postalCode
                };
            });

            console.log(data);

            this.accountData = data;
            this.totalRecords = this.accountData.length;
            this.pageSize = this.pageSizeOptions[0];
            this.paginationHelper();
            this.isSpinnerLoading = false;
        }).catch((error) => {
            this.isSpinnerLoading = false;
        })
    }

    /*
***************************************************************************
Method Name        : handleRecordsPerPage
Created Date       : August 1, 2024
@description       : Updates the page size for pagination based on user selection and triggers the `paginationHelper` method to update the displayed records accordingly.
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
@description       : Decreases the current page number and updates the displayed records by calling `paginationHelper`. 
                     Ensures that pagination bounds are respected.
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
@description       : Increases the current page number and updates the displayed records by calling `paginationHelper`. 
                     Ensures that pagination bounds are respected.
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
@description       : Sets the current page number to the first page and updates the displayed records by calling `paginationHelper`.
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
@description       : Sets the current page number to the last page and updates the displayed records by calling `paginationHelper`.
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
Method Name        : handleRowSelect
Created Date       : August 1, 2024
@description       : Handles row selection in the data table. 
                     Updates the `selectedRows` array with the IDs of selected rows and filters the `accountData` to get the selected accounts. 
                     Dispatches a custom event with selected account data and other relevant information.
@author            : Rahul Gupta(TCD)

Modification Log:
Ver   Date         Author                     Modification
1.0   08-1-2024   Rahul Gupta                Initial Version 
*****************************************************************************
*/
    handleRowSelect(event) {
        let updatedItemsSet = new Set();
        let selectedItemsSet = new Set(this.selectedRows);
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
        this.selectedRows = [...selectedItemsSet];

        console.log('selectedRows==> ' + JSON.stringify(this.selectedRows));

        this.allRowsSelection = this.accountData.filter(account => this.selectedRows.includes(account.Id));


        console.log(this.allRowsSelection.length)

        const selectEvent = new CustomEvent('senddata', {
            detail: {
                data: this.allRowsSelection,
                screen: 'one',
                pinCode: this.pincodeValue,
                previousClick: this.previousClick
            }
        });
        this.dispatchEvent(selectEvent);

    }

    /*
***************************************************************************
Method Name        : paginationHelper
Created Date       : August 1, 2024
@description       : Manages pagination by calculating the total number of pages and slicing the account data to display the records for the current page. 
                    Updates the data table to reflect the selected rows.
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
            this.recordsToDisplay.push(this.accountData[i]);
        }
        this.template.querySelector('[data-id="datatable"]').selectedRows = this.selectedRows;
    }

    /*
***************************************************************************
Method Name        : handleInputChange
Created Date       : August 1, 2024
@description       : Updates the component state based on user input changes. 
                     Currently handles updates for the `pincode` input field.
@author            : Rahul Gupta(TCD)

Modification Log:
Ver   Date         Author                     Modification
1.0   08-1-2024   Rahul Gupta                Initial Version 
*****************************************************************************
*/
    handleInputChange(event) {
        switch (event.target.name) {
            case 'pincode':
                this.pincodeValue = event.target.value;
                break;
        }
    }

    @track latitude;
    @track longitude;
    leafletMap;

    /*
***************************************************************************
Method Name        : renderedCallback
Created Date       : August 1, 2024
@description       : Lifecycle hook that is called after every render of the component. 
                     Loads the Leaflet library and initializes the map if it hasn’t been initialized yet.
@author            : Rahul Gupta(TCD)

Modification Log:
Ver   Date         Author                     Modification
1.0   08-1-2024   Rahul Gupta                Initial Version 
*****************************************************************************
*/
    renderedCallback() {
        if (this.leafletMap) {
            return;
        }

        Promise.all([
            loadScript(this, LEAFLET + '/leaflet.js'),
            loadStyle(this, LEAFLET + '/leaflet.css'),
        ])
            .then(() => {
                console.log('Loaded');
                this.initializeMap();
            })
            .catch(error => {
                console.error('Error loading Leaflet scripts:', error);
            });
    }

    /*
***************************************************************************
Method Name        : initializeMap
Created Date       : August 1, 2024
@description       : Initializes and configures the Leaflet map, setting the view to a default location and adding a tile layer. 
                     Sets up a click event handler to capture latitude and longitude.
@author            : Rahul Gupta(TCD)

Modification Log:
Ver   Date         Author                     Modification
1.0   08-1-2024   Rahul Gupta                Initial Version 
*****************************************************************************
*/
    initializeMap() {
        const mapContainer = this.template.querySelector('.map-container');
        console.log('mapContainer ', mapContainer);
        this.leafletMap = L.map(mapContainer).setView([37.7749, -122.4194], 13);
        console.log('this.leafletMap ', this.leafletMap);

        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
            attribution: '© OpenStreetMap contributors'
        }).addTo(this.leafletMap);

        this.leafletMap.on('click', this.handleMouseMove.bind(this));
    }

    /*
***************************************************************************
Method Name        : handleMouseMove
Created Date       : August 1, 2024
@description       : Handles the map click event to update latitude and longitude values and fetch the address based on the clicked location.
@author            : Rahul Gupta(TCD)

Modification Log:
Ver   Date         Author                     Modification
1.0   08-1-2024   Rahul Gupta                Initial Version 
*****************************************************************************
*/
    handleMouseMove(event) {
        this.latitude = event.latlng.lat;
        this.longitude = event.latlng.lng;
        this.fetchAddress(this.latitude, this.longitude)
    }

    /*
***************************************************************************
Method Name        : fetchAddress
Created Date       : August 1, 2024
@description       : Fetches the address information based on latitude and longitude using the Nominatim API. 
                     Updates the pincode value and triggers the `handleButtonClick` method to load data.
@author            : Rahul Gupta(TCD)

Modification Log:
Ver   Date         Author                     Modification
1.0   08-1-2024   Rahul Gupta                Initial Version 
*****************************************************************************
*/
    fetchAddress(lat, lng) {
        const nominatimUrl = `https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lng}`;

        fetch(nominatimUrl)
            .then(response => response.json())
            .then(data => {
                console.log(data);
                this.address = data.display_name;
                this.pincodeValue = data.address.city;
                this.template.querySelector('.userInput').value = this.pincodeValue;
                this.handleButtonClick();
            })
            .catch(error => {
                console.error('Error fetching address:', error);
            });
    }

}