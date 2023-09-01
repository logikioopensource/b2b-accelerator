import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import COMMUNITY_ID from '@salesforce/community/Id';
import USER_ID from "@salesforce/user/Id";
import ACCOUNT_ID from "@salesforce/schema/User.AccountId";
import IS_CONFIGURABLE from '@salesforce/schema/Product2.LGK__IsConfigurable__c';
import GET_VISUALFORCE_URL from '@salesforce/apex/CommerceConfigurationPunchinController.getVisualforceUrlForLwr';

export default class commerceConfigureButton extends LightningElement {
    @api recordId;
    @api basePath;
    @wire(getRecord, { recordId: '$recordId', fields: [IS_CONFIGURABLE] }) product2;
    @wire(getRecord, { recordId: USER_ID, fields: [ACCOUNT_ID] }) user;
    @wire(GET_VISUALFORCE_URL, { pathPrefix: '$basePath', communityId: COMMUNITY_ID, accountId: '$user.data.fields.AccountId.value', productId: '$recordId'}) visualforceUrl;
    
    visualforceRedirect() {
        window.location.href = this.visualforceUrl.data;
    }

    get productIsConfigurable() {
        return getFieldValue(this.product2.data, IS_CONFIGURABLE);
    }
}