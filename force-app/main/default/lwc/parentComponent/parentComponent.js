import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import Contact_Select_Limit from '@salesforce/label/c.Contact_Select_Limit'
import Contact_Warning_Message from '@salesforce/label/c.Contact_Warning_Message'
export default class ParentComponent extends LightningElement {

    @track allScreenData = {
        isScreenOne: true,
        isScreenTwo: false,
        isScreenThree: false,
        ScreenOneData: null,
        ScreenTwoData: null,
        ScreenThreeData: null,
        previousDisabled: true,
        nextButtonLabel: 'Next',
        currentStep: 1
    };

    pinCodeFromParent;
    mainData;
    contactsRelatedToAccountData;
    isNextDisable = true;
    isPreviousClick = false;
    warningMessage = '';

      /*
    ***************************************************************************
    Method Name        : updateScreenState
    Created Date       : August 1, 2024
    @description       : Updates the visibility and labels of screens based on the current step. 
                         Controls which screen is displayed and the label of the "Next" button.
    @author            : Rahul Gupta(TCD)
    Modification Log:
    Ver   Date         Author                     Modification
    1.0   08-1-2024   Rahul Gupta                Initial Version 
    *****************************************************************************
    */
    updateScreenState() {
        this.allScreenData.isScreenOne = (this.allScreenData.currentStep === 1);
        this.allScreenData.isScreenTwo = (this.allScreenData.currentStep === 2);
        this.allScreenData.isScreenThree = (this.allScreenData.currentStep === 3);
        this.allScreenData.previousDisabled = (this.allScreenData.currentStep === 1);
        this.allScreenData.nextButtonLabel = (this.allScreenData.currentStep === 3) ? 'Send Email' : 'Next';
    }

     /*
    ***************************************************************************
    Method Name        : handleNextClick
    Created Date       : August 1, 2024
    @description       : Handles the click event for the "Next" button. 
                         Advances the step if possible, or triggers the `sendEmail` method on the email component if on the final step.
    @author            : Rahul Gupta(TCD)
    Modification Log:
    Ver   Date         Author                     Modification
    1.0   08-1-2024   Rahul Gupta                Initial Version 
    *****************************************************************************
    */
    handleNextClick(event) {
        if (this.allScreenData.currentStep < 3) {
            this.allScreenData.currentStep++;
            this.updateScreenState();
        }
        if (this.allScreenData.currentStep === 2 && this.allScreenData.ScreenTwoData === null) {
            this.isNextDisable = true;
        }
        console.log('event.target.label ', event.target.label);
        if (event.target.label === 'Send Email') {
            this.template.querySelector('c-send-email-to-contacts').sendEmail();
        }
    }

    /*
    ***************************************************************************
    Method Name        : handlePreviousClick
    Created Date       : August 1, 2024
    @description       : Handles the click event for the "Previous" button. 
                         Moves to the previous step if possible and updates the state of the navigation buttons.
    @author            : Rahul Gupta(TCD)
    Modification Log:
    Ver   Date         Author                     Modification
    1.0   08-1-2024   Rahul Gupta                Initial Version 
    *****************************************************************************
    */
    handlePreviousClick() {
        if (this.allScreenData.currentStep > 1) {
            this.allScreenData.currentStep--;
            this.updateScreenState();
        }


        if (this.allScreenData.currentStep === 1) {
            this.isPreviousClick = true;
        }

        if (this.allScreenData.currentStep === 2 && this.allScreenData.ScreenTwoData === null) {
            this.isNextDisable = true;
        }

        if (this.allScreenData.currentStep === 1 && this.allScreenData.ScreenOneData === null) {
            this.isNextDisable = true;
        } else {
            this.isNextDisable = false;
        }
    }

     /*
    ***************************************************************************
    Method Name        : handleDataFromParent
    Created Date       : August 1, 2024
    @description       : Handles the data received from a child component (e.g., screen one). 
                         Updates the screen data and controls the state of the "Next" button based on the received data.
    @author            : Rahul Gupta(TCD)
    Modification Log:
    Ver   Date         Author                     Modification
    1.0   08-1-2024   Rahul Gupta                Initial Version 
    *****************************************************************************
    */
    handleDataFromParent(event) {
        if (event.detail.previousClick === true) {
            this.resetSCreens();
        }
        this.allScreenData.ScreenOneData = event.detail.data;
        this.pinCodeFromParent = event.detail.pinCode;
        this.mainData = this.allScreenData.ScreenOneData;

        if (this.allScreenData.ScreenOneData.length > 0) {
            this.isNextDisable = false;
        } else {
            this.isNextDisable = true;
        }
    }

    /*
    ***************************************************************************
    Method Name        : handleDataFromSecondScreen
    Created Date       : August 1, 2024
    @description       : Handles the data received from the second screen. 
                        Validates the number of selected contacts and sets warning messages if necessary.
    @author            : Rahul Gupta(TCD)
    Modification Log:
    Ver   Date         Author                     Modification
    1.0   08-1-2024   Rahul Gupta                Initial Version 
    *****************************************************************************
    */
    handleDataFromSecondScreen(event) {
        this.allScreenData.ScreenTwoData = event.detail;
        if (this.allScreenData.ScreenTwoData.length > 0 && this.allScreenData.ScreenTwoData.length < Contact_Select_Limit) {
            this.isNextDisable = false;
            this.warningMessage = '';
        }
        else {
            this.isNextDisable = true;
            this.warningMessage = Contact_Warning_Message;
        }
    }

     /*
    ***************************************************************************
    Method Name        : handleTemplateData
    Created Date       : August 1, 2024
    @description       : Handles the data for the email template from a child component. 
                         Updates the screen data with the email subject, body, and template values.
    @author            : Rahul Gupta(TCD)
    Modification Log:
    Ver   Date         Author                     Modification
    1.0   08-1-2024   Rahul Gupta                Initial Version 
    *****************************************************************************
    */
    handleTemplateData(event) {
        let obj = {};
        obj.subject = event.detail.subject;
        obj.body = event.detail.body;
        obj.emailTemplateValue = event.detail.emailTemplateValue;
        this.allScreenData.ScreenThreeData = obj;
    }

     /*
    ***************************************************************************
    Method Name        : handledisablesend
    Created Date       : August 1, 2024
    @description       : Handles disabling the "Send" button based on the data received from a child component. Updates the state of the "Next" button.
    @author            : Rahul Gupta(TCD)
    Modification Log:
    Ver   Date         Author                     Modification
    1.0   08-1-2024   Rahul Gupta                Initial Version 
    *****************************************************************************
    */
    handledisablesend(event) {
        console.log('OUTPUT handledisablesend:called ');
        this.isNextDisable = event.detail;
        console.log('OUTPUT handledisablesend: ', event.detail);
    }

      /*
    ***************************************************************************
    Method Name        : resetSCreens
    Created Date       : August 1, 2024
    @description       : Resets the data for all screens to `null`. This is typically called when resetting the entire flow.
    @author            : Rahul Gupta(TCD)
    Modification Log:
    Ver   Date         Author                     Modification
    1.0   08-1-2024   Rahul Gupta                Initial Version 
    *****************************************************************************
    */
    resetSCreens() {
        this.allScreenData.ScreenOneData = null;
        this.allScreenData.ScreenTwoData = null;
        this.allScreenData.ScreenThreeData = null;
    }

    /*
    ***************************************************************************
    Method Name        : showToast
    Created Date       : August 1, 2024
    @description       : Displays a toast message with a given title, message, and variant. Used to show feedback to the user.
    @author            : Rahul Gupta(TCD)
    Modification Log:
    Ver   Date         Author                     Modification
    1.0   08-1-2024   Rahul Gupta                Initial Version 
    *****************************************************************************
    */
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }
}