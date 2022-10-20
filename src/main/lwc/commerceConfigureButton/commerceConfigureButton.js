import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import COMMUNITY_ID from '@salesforce/community/Id';
import IS_CONFIGURABLE from '@salesforce/schema/Product2.LGK__IsConfigurable__c';
import GET_VISUALFORCE_URL from '@salesforce/apex/CommerceConfigurationPunchinController.getVisualforceUrl';

export default class commerceConfigureButton extends LightningElement {
    @api recordId;
    @api effectiveAccountId;
    @wire(getRecord, { recordId: '$recordId', fields: [IS_CONFIGURABLE] }) product2;
    @wire(GET_VISUALFORCE_URL, { communityId: COMMUNITY_ID, accountId: '$effectiveAccountId', productId: '$recordId'}) visualforceUrl;
    
    visualforceRedirect() {
        window.location.href = this.visualforceUrl.data;
    }

    get productIsConfigurable() {
        return getFieldValue(this.product2.data, IS_CONFIGURABLE);
    }
}