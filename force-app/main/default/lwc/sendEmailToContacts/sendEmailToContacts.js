import { LightningElement, api, track, wire } from 'lwc';
import getAllEmailTemplates from '@salesforce/apex/SearchAccountController.getAllEmailTemplates';
import sendEmailToContacts from '@salesforce/apex/SearchAccountController.sendEmailToContacts';
import getFilesFromSalesforce from '@salesforce/apex/SearchAccountController.getFilesFromSalesforce';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import { iconMap, iconDoctypeMap } from './constantService';

const FIELDS = [
    'ContentVersion.Title',
    'ContentVersion.VersionData',
    'ContentVersion.ContentSize',
    'ContentVersion.FileExtension'
];

export default class SendEmailToContacts extends LightningElement {

    iconsMap = iconMap;
    iconDoctypesMap = iconDoctypeMap;
    contactColumns = [
        { label: 'Contact Name', fieldName: 'names' },
        { label: 'Email', fieldName: 'Email' },
    ];

    @track templateOptions = [
        { label: '---None---', value: 'None' },
        { label: 'Text', value: 'Text' },
        { label: 'HTML (using Classic Letterhead)', value: 'HTML' },
        { label: 'Custom (without using Classic Letterhead)', value: 'Custom' },
        { label: 'Visualforce', value: 'Visualforce' },
    ];

    @api storeThirdScreenData;
    allContacts = [];
    emailTemplateOptions = [];
    emailTemplateValue;
    allEmailTemplateData;
    showCombobox = false;
    isSpinnerLoading = false;
    showTemplateData = false;
    @api storeTemplateData;
    isShowModal = false;
    isCustomTemplateSelected = false;
    emailBody;
    emailSubject;
    subject;
    body;
    showTextArea = true;
    templateName;
    letterheadType = '';
    templateStyleValue;

    pageSizeOptions = [10];
    records = [];
    columns = [];
    totalRecords = 0;
    pageSize;
    totalPages;
    pageNumber = 1;
    recordsToDisplay = [];
    @track allRowsSelection = []
    @track filesData = [];
    @track fileNames = [];
    warningMessage = '';

    @track files;
    @track allFiles;
    @track selectedFiles = [];
    @track error;
    handleAttachDisable = false;

    recordId = '';
    contentVersionTitle;
    contentVersionData;
    __Counter = 0;
    cvRecordIds = [];
    storeSelectedFileNames = [];
    @track storeUploadedFileNames = [];
    selectedFileCount = 0;
    @track storeAllSelectedFiles = [];

    totalSize = 0;
    sizeLimitMB = 3;
    sizeLimitBytes = this.sizeLimitMB * 1024 * 1024;

    fileSizeWhileRemove = 0;

    /*
   ***************************************************************************
   Method Name     : contentVersion
   Created Date    : August 8, 2024
   @description    : Handles wired content version data and processes files with delay.
   @author         : Rahul Gupta(TCD)

   Modification Log:
   Ver   Date         Author                     Modification
   1.0   08-8-2024   Rahul Gupta                Initial Version 
   *****************************************************************************
   */

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    contentVersion({ error, data }) {
        if (data) {
            console.log('OUTPUT cvusing wire:called ', data);
            this.filesData.push({
                filename: data.fields.Title.value,
                base64: data.fields.VersionData.value,
                mimeType: this.iconsMap[data.fields.FileExtension.value],
                size: data.fields.ContentSize.value
            });

            if (this.__Counter < this.cvRecordIds.length) {
                this.__Counter++;
                this.__processFilesWithDelay(this.cvRecordIds, this.__Counter);
            } else {
                return;
            }

            console.log('this.filesData wire ', this.filesData);

        } else if (error) {
            console.error('Error retrieving ContentVersion:', error);
        }
    }

    /*
    ***************************************************************************
    Method Name     : __processFilesWithDelay
    Created Date    : August 8, 2024
    @description    : Processes files with a delay to manage large file sizes.
    @author         : Rahul Gupta(TCD)

    Modification Log:
    Ver   Date         Author                     Modification
    1.0   08-8-2024   Rahul Gupta                Initial Version 
    *****************************************************************************
    */

    __processFilesWithDelay(files, index) {
        this.isSpinnerLoading = true;
        console.log('OUTPUT :__processFilesWithDelay called ', JSON.parse(JSON.stringify(files)));
        console.log('OUTPUT :__processFilesWithDelay called index  ', index);
        console.log('OUTPUT :__processFilesWithDelay called files.length  ', files.length);
        if (index < files.length) {
            console.log('OUTPUT :__processFilesWithDelay inside if condition files ', files);
            this.recordId = files[index];
            console.log('this.recordId=== ', this.recordId);

        } else {
            console.log(' this.storeAllSelectedFiles ', JSON.stringify(this.storeAllSelectedFiles));
            this.storeAllSelectedFiles.forEach(file => {
                this.totalSize += file.size
            });
            console.log('this.totalSize ', this.totalSize);

            this.isSpinnerLoading = false;
            this.handleClose();
            if (this.totalSize > this.sizeLimitBytes) {

                const selectEvent = new CustomEvent('disablesend', {
                    detail: true
                });
                this.dispatchEvent(selectEvent);
                this.warningMessage = 'Total file size of uploaded file should be less than 3 MB.';
            } else {
                const selectEvent = new CustomEvent('disablesend', {
                    detail: false
                });
                this.dispatchEvent(selectEvent);
                this.warningMessage = '';
            }
        }
    }

    /*
   ***************************************************************************
   Method Name     : connectedCallback
   Created Date    : August 8, 2024
   @description    : Lifecycle hook to initialize data and fetch email templates.
   @author         : Rahul Gupta(TCD)

   Modification Log:
   Ver   Date         Author                     Modification
   1.0   08-8-2024   Rahul Gupta                Initial Version 
   *****************************************************************************
   */

    connectedCallback() {

        this.isSpinnerLoading = true;
        console.log('this.storeThirdScreenData ', JSON.stringify(this.storeThirdScreenData));

        if (this.storeTemplateData) {
            console.log('store template data ', JSON.stringify(this.storeTemplateData));
            this.subject = this.storeTemplateData.subject;
            this.body = this.storeTemplateData.body;
            this.showTemplateData = true;
            this.emailTemplateValue = this.storeTemplateData.emailTemplateValue;
        }

        this.allContacts = this.storeThirdScreenData;
        this.totalRecords = this.allContacts.length;
        this.pageSize = this.pageSizeOptions[0];
        this.paginationHelper();

        getAllEmailTemplates().then((result) => {
            this.allEmailTemplateData = result;
            for (let index = 0; index < this.allEmailTemplateData.length; index++) {
                let element = {};
                element.label = this.allEmailTemplateData[index].Name;
                element.value = this.allEmailTemplateData[index].Name;
                this.emailTemplateOptions.push(element);
            }
            this.showCombobox = true;
            this.isSpinnerLoading = false;
        })
    }

    /*
   ***************************************************************************
   Method Name     : wiredFiles
   Created Date    : August 8, 2024
   @description    : Wire method to get list of files from Salesforce and filter based on size.
   @author         : Rahul Gupta(TCD)

   Modification Log:
   Ver   Date         Author                     Modification
   1.0   08-8-2024   Rahul Gupta                Initial Version 
   *****************************************************************************
   */

    @wire(getFilesFromSalesforce)
    wiredFiles({ error, data }) {
        if (data) {
            this.files = data
                .filter(file => (file.ContentSize / 1024) < 3072)
                .map(file => ({
                    ...file,
                    label: `${file.Title}.${file.FileExtension} (${(file.ContentSize / 1024).toFixed(2)} KB)`,
                    value: file.Id,
                    icon: this.iconDoctypesMap[file.FileExtension],
                    isIconAvailable: !!file.FileExtension,
                    ContentSizeKB: `${(file.ContentSize / 1024).toFixed(2)} KB`,
                    date: file.CreatedDate.split('T')[0],
                    selected: false
                }));

            console.log('this.files======', JSON.stringify(this.files));
            this.allFiles = [...this.files];
            this.error = undefined;
        } else if (error) {
            console.log('error======', error);
            this.error = error;
            this.files = undefined;
        }
    }

    /*
    ***************************************************************************
    Method Name     : selected
    Created Date    : August 8, 2024
    @description    : Getter to return selected files.
    @autor          : Rahul Gupta(TCD)

    Modification Log:
    Ver   Date         Author                     Modification
    1.0   08-8-2024   Rahul Gupta                 Initial Version 
    *****************************************************************************
    */

    get selected() {
        return this.selectedFiles.length ? this.selectedFiles : 'none';
    }

    /*
   ***************************************************************************
   Method Name     : handleSFUpload
   Created Date    : August 8, 2024
   @description    : Handles file upload from Salesforce and processes selected files.
   @autor          : Rahul Gupta(TCD)

   Modification Log:
   Ver   Date         Author                     Modification
   1.0   08-8-2024   Rahul Gupta                 Initial Version 
   *****************************************************************************
   */

    handleSFUpload(event) {
        this.__Counter = 0;
        this.storeAllSelectedFiles = [...this.storeAllSelectedFiles, ...this.storeSelectedFileNames, ...this.storeUploadedFileNames];
        console.log(' kjhg ', JSON.stringify(this.storeAllSelectedFiles));

        this.storeAllSelectedFiles.sort((a, b) => {
            let dateA = new Date(a.timedata);
            let dateB = new Date(b.timedata);
            return dateA - dateB;
        });

        if (this.storeAllSelectedFiles.length > 10) {
            this.storeAllSelectedFiles = this.storeAllSelectedFiles.slice(0, 10);
        }

        if (this.storeAllSelectedFiles.length >= 10) {
            this.handleAttachDisable = true;
        }

        let selectedIds = [];
        this.storeSelectedFileNames.forEach(data => {
            console.log(data);
            selectedIds.push(data.id)
        })

        console.log('Selected Ids: ', JSON.stringify(selectedIds));

        this.cvRecordIds = selectedIds;
        console.log('OUTPUT this.cvRecordIds: ', JSON.parse(JSON.stringify(this.cvRecordIds)));
        this.__processFilesWithDelay(JSON.parse(JSON.stringify(this.cvRecordIds)), this.__Counter);
    }

    /*
   ***************************************************************************
   Method Name     : handleAttachFiles
   Created Date    : August 8, 2024
   @description    : Handles attachment of files for email.
   @autor          : Rahul Gupta(TCD)

   Modification Log:
   Ver   Date         Author                     Modification
   1.0   08-8-2024   Rahul Gupta                 Initial Version 
   *****************************************************************************
   */

    handleAttachFiles() {
        const selectedFileDetails = this.files.filter(file => this.selectedFiles.includes(file.Id));
        const attachments = selectedFileDetails.map(file => ({
            title: file.Title,
            contentType: file.FileExtension,
            contentData: file.VersionData
        }));
        console.log('Selected Files for Email:', attachments);

    }

    /*
   ***************************************************************************
   Method Name     : handleSearchChange
   Created Date    : August 8, 2024
   @description    : Handles search change event to filter files.
   @autor          : Rahul Gupta(TCD)

   Modification Log:
   Ver   Date         Author                     Modification
   1.0   08-8-2024   Rahul Gupta                 Initial Version 
   *****************************************************************************
   */

    handleSearchChange(event) {
        console.log('all files-------', JSON.stringify(this.allFiles));
        let searchTerm = event.target.value.toLowerCase();
        console.log('OUTPUT :searchTerm==', searchTerm.trim());
        if (searchTerm) {
            this.files = this.filterData(this.allFiles, searchTerm);
        } else {

            this.files = [...this.allFiles];
        }

    }

    /*
    ***************************************************************************
    Method Name     : filterData
    Created Date    : August 8, 2024
    @description    : Filters data based on search key.
    @autor          : Rahul Gupta(TCD)

    Modification Log:
    Ver   Date         Author                     Modification
    1.0   08-8-2024   Rahul Gupta                 Initial Version 
    *****************************************************************************
    */

    filterData(data, searchKey) {
        return data.filter(row => Object.values(row).some(value => String(value).toLowerCase().includes(searchKey)));
    }

    /*
    ***************************************************************************
    Method Name     : getTime
    Created Date    : August 8, 2024
    @description    : Returns current time formatted as string.
    @autor          : Rahul Gupta(TCD)

    Modification Log:
    Ver   Date         Author                     Modification
    1.0   08-8-2024   Rahul Gupta                 Initial Version 
    *****************************************************************************
    */

    getTime() {
        const now = new Date();
        const year = now.getFullYear();
        const month = String(now.getMonth() + 1).padStart(2, '0');
        const day = String(now.getDate()).padStart(2, '0');
        const hours = String(now.getHours()).padStart(2, '0');
        const minutes = String(now.getMinutes()).padStart(2, '0');
        const seconds = String(now.getSeconds()).padStart(2, '0');
        const milliseconds = String(now.getMilliseconds()).padStart(3, '0');

        const formattedDateTime = `${year}-${month}-${day} ${hours}:${minutes}:${seconds}.${milliseconds}`;

        return formattedDateTime;

    }

    /*
   ***************************************************************************
   Method Name     : handleCheckboxChange
   Created Date    : August 8, 2024
   @description    : Handles change event of checkboxes to manage selected files.
   @autor          : Rahul Gupta(TCD)

   Modification Log:
   Ver   Date         Author                     Modification
   1.0   08-8-2024   Rahul Gupta                 Initial Version 
   *****************************************************************************
   */

    handleCheckboxChange(event) {
        this.checkCountAndShowError();

        const fileId = event.target.dataset.id;
        const selected = event.target.checked;

        this.files = this.files.map(file =>
            file.Id === fileId ? { ...file, selected } : file
        );

        this.allFiles = this.allFiles.map(file =>
            file.Id === fileId ? { ...file, selected } : file
        );

        console.log('selected Files ', JSON.stringify(this.files));
        let time = this.getTime();
        console.log('time ', time);

        this.storeSelectedFileNames = this.files
            .filter(storefile => storefile.selected === true)
            .map(storefile => ({ title: storefile.Title, icon: storefile.icon, id: storefile.Id, size: storefile.ContentSize, timedata: time }));
        console.log('this.storeSelectedFileNames ', JSON.stringify(this.storeSelectedFileNames));

        this.selectedFileCount = this.storeSelectedFileNames.length + this.storeUploadedFileNames.length;
        console.log('this.selectedFileCount ', this.selectedFileCount);

        this.checkCountAndShowError();
    }

    /*
    ***************************************************************************
    Method Name     : checkCountAndShowError
    Created Date    : August 8, 2024
    @description    : Checks selected file count and shows error if limit exceeded.
    @autor          : Rahul Gupta(TCD)

    Modification Log:
    Ver   Date         Author                     Modification
    1.0   08-8-2024   Rahul Gupta                 Initial Version 
    *****************************************************************************
    */

    checkCountAndShowError() {
        this.selectedFileCount = this.storeSelectedFileNames.length + this.storeUploadedFileNames.length;

        const allCheckboxes = this.template.querySelectorAll('.file-checkbox');
        const fileUpload = this.template.querySelector('.file-upload');

        const disableCheckboxes = this.selectedFileCount >= 10;

        allCheckboxes.forEach(checkbox => {
            if (disableCheckboxes) {
                checkbox.disabled = !checkbox.checked;
                return;
            } else {
                checkbox.disabled = false;
            }
        });

        if (disableCheckboxes) {
            fileUpload.disabled = true;
        } else {
            fileUpload.disabled = false;
        }

        this.selectedFileCount = this.storeSelectedFileNames.length + this.storeUploadedFileNames.length;

    }

    /*
   ***************************************************************************
   Method Name     : checkCountAndShowErrorFile
   Created Date    : August 8, 2024
   @description    : Checks selected file count and shows error if limit exceeded (file upload scenario).
   @autor          : Rahul Gupta(TCD)

   Modification Log:
   Ver   Date         Author                     Modification
   1.0   08-8-2024   Rahul Gupta                 Initial Version 
   *****************************************************************************
   */

    checkCountAndShowErrorFile() {
        this.selectedFileCount = this.storeSelectedFileNames.length + this.storeUploadedFileNames.length;

        const fileUpload = this.template.querySelectorAll('.file-upload');
        const allCheckboxes = this.template.querySelectorAll('.file-checkbox');


        const disableCheckboxes = this.selectedFileCount > 10;
        console.log('disableCheckboxes ', this.selectedFileCount, disableCheckboxes);

        allCheckboxes.forEach(checkbox => {
            if (disableCheckboxes) {
                checkbox.disabled = !checkbox.checked;
                return;
            } else {
                checkbox.disabled = false;
            }
        });

        if (disableCheckboxes) {
            console.log('this.storeUploadedFileNames length before splice:', this.storeUploadedFileNames.length);

            // Ensure index is valid and within bounds
            const indexToRemove = Math.min(this.selectedFileCount - 1, this.storeUploadedFileNames.length - 1);
            if (indexToRemove >= 0) {
                this.storeUploadedFileNames.splice(indexToRemove, 1);
            }

            console.log('this.storeUploadedFileNames length after splice:', this.storeUploadedFileNames.length);
            this.selectedFileCount = this.storeSelectedFileNames.length + this.storeUploadedFileNames.length;

        }

        fileUpload.forEach(file => {
            file.disabled = disableCheckboxes;
        });
    }

    /*
   ***************************************************************************
   Method Name     : bDisableFirst
   Created Date    : August 8, 2024
   @description    : Getter to check if first page button should be disabled.
   @autor          : Rahul Gupta(TCD)

   Modification Log:
   Ver   Date         Author                     Modification
   1.0   08-8-2024   Rahul Gupta                 Initial Version 
   *****************************************************************************
   */

    get bDisableFirst() {
        return this.pageNumber == 1;
    }

    /*
    ***************************************************************************
    Method Name     : bDisableLast
    Created Date    : August 8, 2024
    @description    : Getter to check if last page button should be disabled.
    @autor          : Rahul Gupta(TCD)

    Modification Log:
    Ver   Date         Author                     Modification
    1.0   08-8-2024   Rahul Gupta                 Initial Version 
    *****************************************************************************
    */

    get bDisableLast() {
        return this.pageNumber == this.totalPages;
    }

    /*
   ***************************************************************************
   Method Name     : handleRecordsPerPage
   Created Date    : August 8, 2024
   @description    : Handles change in records per page.
   @autor          : Rahul Gupta(TCD)

   Modification Log:
   Ver   Date         Author                     Modification
   1.0   08-8-2024   Rahul Gupta                 Initial Version 
   *****************************************************************************
   */

    handleRecordsPerPage(event) {
        this.pageSize = event.target.value;
        this.paginationHelper();
    }

    /*
   ***************************************************************************
   Method Name     : previousPage
   Created Date    : August 8, 2024
   @description    : Handles navigation to previous page.
   @autor          : Rahul Gupta(TCD)

   Modification Log:
   Ver   Date         Author                     Modification
   1.0   08-8-2024   Rahul Gupta                 Initial Version 
   *****************************************************************************
   */

    previousPage() {
        this.pageNumber = this.pageNumber - 1;
        this.paginationHelper();
    }

    /*
   ***************************************************************************
   Method Name     : nextPage
   Created Date    : August 8, 2024
   @description    : Handles navigation to next page.
   @autor          : Rahul Gupta(TCD)

   Modification Log:
   Ver   Date         Author                     Modification
   1.0   08-8-2024   Rahul Gupta                 Initial Version 
   *****************************************************************************
   */

    nextPage() {
        this.pageNumber = this.pageNumber + 1;
        this.paginationHelper();
    }

    /*
   ***************************************************************************
   Method Name     : firstPage
   Created Date    : August 8, 2024
   @description    : Handles navigation to first page.
   @autor          : Rahul Gupta(TCD)

   Modification Log:
   Ver   Date         Author                     Modification
   1.0   08-8-2024   Rahul Gupta                 Initial Version 
   *****************************************************************************
   */

    firstPage() {
        this.pageNumber = 1;
        this.paginationHelper();
    }

    /*
   ***************************************************************************
   Method Name     : lastPage
   Created Date    : August 8, 2024
   @description    : Handles navigation to last page.
   @autor          : Rahul Gupta(TCD)

   Modification Log:
   Ver   Date         Author                     Modification
   1.0   08-8-2024   Rahul Gupta                 Initial Version 
   *****************************************************************************
   */

    lastPage() {
        this.pageNumber = this.totalPages;
        this.paginationHelper();
    }

    /*
    ***************************************************************************
    Method Name     : paginationHelper
    Created Date    : August 8, 2024
    @description    : Helper method for pagination.
    @autor          : Rahul Gupta(TCD)

    Modification Log:
    Ver   Date         Author                     Modification
    1.0   08-8-2024   Rahul Gupta                 Initial Version 
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
            this.recordsToDisplay.push(this.allContacts[i]);

        }
    }

    /*
   ***************************************************************************
   Method Name     : handleComboboxTemplate
   Created Date    : August 8, 2024
   @description    : Handles change event of combobox to select email template.
   @autor          : Rahul Gupta(TCD)

   Modification Log:
   Ver   Date         Author                     Modification
   1.0   08-8-2024   Rahul Gupta                 Initial Version 
   *****************************************************************************
   */

    handleComboboxTemplate(event) {
        this.emailTemplateValue = event.detail.value;
        this.allEmailTemplateData.forEach((element) => {
            if (element.Name === this.emailTemplateValue) {
                this.subject = element.Subject;
                this.body = element.Body;
                console.log('this.body ', this.body);
            }
        })
        this.showTemplateData = true;

        const selectEvent = new CustomEvent('sendtemplate', {
            detail: {
                subject: this.subject,
                body: this.body,
                emailTemplateValue: this.emailTemplateValue
            }
        });
        this.dispatchEvent(selectEvent);

    }

    /*
    ***************************************************************************
    Method Name     : handleInputChange
    Created Date    : August 8, 2024
    @description    : Handles change event of input fields.
    @autor          : Rahul Gupta(TCD)

    Modification Log:
    Ver   Date         Author                     Modification
    1.0   08-8-2024   Rahul Gupta                 Initial Version 
    *****************************************************************************
    */

    handleInputChange(event) {
        const name = event.target.name;
        const value = event.detail.value;
        console.log('value ', value);
        if (name === 'templateType') {
            this.templateType = value;
            console.log('templateType ', this.templateType);

            this.isCustomTemplateSelected = (this.templateType !== 'None');

            if (!this.isCustomTemplateSelected) {
                this.clearCustomTemplateInputs();
            }

            this.showTextArea = (value !== 'HTML') ? true : false;
            console.log(this.showTextArea);
        } else if (name === 'subject') {
            this.emailSubject = event.target.value;
        } else if (name === 'body') {
            this.emailBody = event.target.value;
        } else if (name === 'templateName') {
            this.templateName = event.target.value;
        } else if (name === 'letterheadType') {
            this.letterheadType = event.target.value;
        } else if (name === 'templateStyle') {
            this.templateStyleValue = event.target.value;
        } else if (name === 'emailBodyData') {
            this.body = event.detail.value;
            console.log('this.body ', this.body);
        }
    }

    /*
   ***************************************************************************
   Method Name     : clearCustomTemplateInputs
   Created Date    : August 8, 2024
   @description    : Clears custom template input fields.
   @autor          : Rahul Gupta(TCD)

   Modification Log:
   Ver   Date         Author                     Modification
   1.0   08-8-2024   Rahul Gupta                 Initial Version 
   *****************************************************************************
   */

    clearCustomTemplateInputs() {
        const inputs = this.template.querySelectorAll('.customTemplateInput');
        inputs.forEach(input => {
            input.value = '';
        });
    }

    /*
    ***************************************************************************
    Method Name     : showToast
    Created Date    : August 8, 2024
    @description    : Displays a toast message.
    @autor          : Rahul Gupta(TCD)

    Modification Log:
    Ver   Date         Author                     Modification
    1.0   08-8-2024   Rahul Gupta                 Initial Version 
    *****************************************************************************
    */

    showToast() {
        const event = new ShowToastEvent({
            title: 'Record Created',
            message: 'Record Created Successfully',
            variant: 'success',
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }

    /*
   ***************************************************************************
   Method Name     : handleFileChange
   Created Date    : August 8, 2024
   @description    : Handles file input change event for file uploads.
   @autor          : Rahul Gupta(TCD)

   Modification Log:
   Ver   Date         Author                     Modification
   1.0   08-8-2024   Rahul Gupta                 Initial Version 
   *****************************************************************************
   */

    handleFileChange(event) {
        this.checkCountAndShowErrorFile();

        const files = event.target.files;
        console.log('files===handleFileChange====', files);
        let fileSize = 0;

        for (let i = 0; i < files.length; i++) {
            const file = files[i];
            fileSize += file.size;
            const fileType = file.type.split('/').pop();
            let time = this.getTime();


            let obj = {};
            obj.title = file.name;
            obj.icon = this.iconDoctypesMap[fileType];
            obj.size = file.size;
            obj.timedata = time;

            this.storeUploadedFileNames.push(obj);
            this.selectedFileCount = this.storeSelectedFileNames.length + this.storeUploadedFileNames.length;
            this.checkCountAndShowErrorFile();

            const reader = new FileReader();
            reader.onload = () => {
                const base64 = reader.result.split(',')[1];
                this.filesData.push({
                    filename: file.name,
                    base64: base64,
                    mimeType: file.type
                });
            };
            reader.readAsDataURL(file);
            this.fileNames.push(file.name);
        }

        if (fileSize > 3145728) {

            const selectEvent = new CustomEvent('disablesend', {
                detail: true
            });
            this.dispatchEvent(selectEvent);
            this.warningMessage = 'Total file size of uploaded file should be less than 3 MB.';
        } else {
            const selectEvent = new CustomEvent('disablesend', {
                detail: false
            });
            this.dispatchEvent(selectEvent);
            this.warningMessage = '';
        }

    }

    /*
***************************************************************************
Method Name     : removeFile
Created Date    : August 8, 2024
@description    : Handles the removal of a file from the list and updates the total file size.
@param          : event
@return         : void
@modification Log:
Ver   Date         Author                     Modification
1.0   08-8-2024   Rahul Gupta                Initial Version 
***************************************************************************
*/

    removeFile(event) {
        let index = event.target.dataset.index;

        let spliced = this.storeAllSelectedFiles.splice(index, 1);

        if (this.storeAllSelectedFiles.length < 10) {
            this.handleAttachDisable = false;
        }

        if (spliced) {
            this.totalSize = this.totalSize - spliced[0].size;
            this.filesData = this.filesData.filter(obj => obj.filename !== spliced[0].title);
        }

        if (this.totalSize > this.sizeLimitBytes) {
            const selectEvent = new CustomEvent('disablesend', {
                detail: true
            });
            this.dispatchEvent(selectEvent);
            this.warningMessage = 'Total file size of uploaded file should be less than 3 MB.';
        } else {
            const selectEvent = new CustomEvent('disablesend', {
                detail: false
            });
            this.dispatchEvent(selectEvent);
            this.warningMessage = '';
        }
    }

    /*
***************************************************************************
Method Name     : sendEmail
Created Date    : August 8, 2024
@description    : Sends an email to selected contacts with the specified template and files.
@return         : void
@modification Log:
Ver   Date         Author                     Modification
1.0   08-8-2024   Rahul Gupta                Initial Version 
***************************************************************************
*/

    @api sendEmail() {
        console.log('this file data', JSON.stringify(this.filesData));
        console.log('this file data length ', this.filesData.length);
        this.filesData = this.filesData.filter(file =>
            this.storeAllSelectedFiles.some(selectedFile => selectedFile.title === file.filename)
        );
        console.log('this file data length ', this.filesData.length);

        this.isSpinnerLoading = true;
        let allContactId = [];
        this.allContacts.forEach((element) => {
            allContactId.push(element.Id);
        })
        let htmlBody = this.body.replace(/\n/g, '<br>');
        let selectedObj = {};
        selectedObj.templateName = this.emailTemplateValue;
        selectedObj.subject = this.subject;
        selectedObj.body = htmlBody;
        selectedObj.contactIds = allContactId;
        console.log('this.body====> ', htmlBody);
        console.log('selectedObj ', selectedObj);

        sendEmailToContacts({ contactMap: selectedObj, filesData: this.filesData }).then((result) => {
            if (result === true) {
                this.showToast();
                this.isSpinnerLoading = false;
                setTimeout(() => {
                    window.location.reload();
                }, 3000);
            }
        }).catch((error) => {

        })
    }

    /*
***************************************************************************
Method Name     : showToast
Created Date    : August 8, 2024
@description    : Displays a toast notification indicating successful email sending.
@return         : void
@modification Log:
Ver   Date         Author                     Modification
1.0   08-8-2024   Rahul Gupta                Initial Version 
***************************************************************************
*/

    showToast() {
        const event = new ShowToastEvent({
            title: 'Mail Sent',
            message: 'Mail Sent Successfully',
            variant: 'success',
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }

    /*
***************************************************************************
Method Name     : showToastForFileSize
Created Date    : August 8, 2024
@description    : Displays a toast notification for file size related issues.
@param          : title, message, variant
@return         : void
@modification Log:
Ver   Date         Author                     Modification
1.0   08-8-2024   Rahul Gupta                Initial Version 
***************************************************************************
*/

    showToastForFileSize(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }


    @track isPopupOpen = false;
    @track selectedValue;
    @track showUploadFromPC = false;
    @track showUploadFromSalesforce = false;


    options = [
        { label: 'Upload from PC', value: 'uploadFromPC' },
        { label: 'Upload from Salesforce', value: 'uploadFromSalesforce' }
    ];

    /*
***************************************************************************
Method Name     : handleAttachFileClick
Created Date    : August 8, 2024
@description    : Opens the file attachment popup and resets file selection.
@return         : void
@modification Log:
Ver   Date         Author                     Modification
1.0   08-8-2024   Rahul Gupta                Initial Version 
***************************************************************************
*/

    handleAttachFileClick() {
        this.isPopupOpen = true;

        this.files.forEach(file => {
            file.selected = false;
        });

        this.storeUploadedFileNames = [];
        this.storeSelectedFileNames = [];
        this.selectedFileCount = 0;
    }

    /*
***************************************************************************
Method Name     : handleClose
Created Date    : August 8, 2024
@description    : Closes the popup and resets related states.
@return         : void
@modification Log:
Ver   Date         Author                     Modification
1.0   08-8-2024   Rahul Gupta                Initial Version 
***************************************************************************
*/

    handleClose() {
        this.isPopupOpen = false;
        this.showUploadFromSalesforce = false;
        this.showUploadFromPC = false;
        this.files = this.allFiles;
    }

    /*
***************************************************************************
Method Name     : handleRadioChange
Created Date    : August 8, 2024
@description    : Handles changes in the file upload source selection.
@param          : event
@return         : void
@modification Log:
Ver   Date         Author                     Modification
1.0   08-8-2024   Rahul Gupta                Initial Version 
***************************************************************************
*/

    handleRadioChange(event) {
        this.selectedValue = event.detail.value;
        this.showUploadFromPC = this.selectedValue === 'uploadFromPC';
        this.showUploadFromSalesforce = this.selectedValue === 'uploadFromSalesforce';
    }

    /*
***************************************************************************
Method Name     : handleFileUploadFromPC
Created Date    : August 8, 2024
@description    : Handles file selection from PC and logs file details.
@param          : event
@return         : void
@modification Log:
Ver   Date         Author                     Modification
1.0   08-8-2024   Rahul Gupta                Initial Version 
***************************************************************************
*/

    handleFileUploadFromPC(event) {
        const file = event.target.files[0];
        if (file) {
            console.log('File selected for upload from PC:', file.name);
        }
    }
}