# UI-Based Product Detail Page Integration Setup

## Preconditions
This guide assumes the following in Salesforce:
- System Administrator or similar access is available in order to perform the steps listed.
- Files in this repo were deployed to your Salesforce org (see README.md at the top directory for more info)

## Setup Steps
### Field Security
1. From Setup Home, go to the Object Manager tab, or navigate to Objects and Fields > Object Manager.
2. From Object Manager, search for and open Cart Item (CartItem).
3. Go to Fields & Relationships. Search for and open the field Configuration Id (ConfigurationId__c).
4. Click “Set Field-Level Security”.
5. Make sure the option “Visible” is selected and “Read-Only” is not selected for profiles that will be configuring products in Commerce, then Save.

A similar set of steps need to be followed for a Product2 field.
1. From Object Manager, search for and open Product (Product2).
2. Go to Fields & Relationships. Open the field Logik.io Enabled (LGK__IsConfigurable__c).
3. Click “Set Field-Level Security”. Make sure the option “Visible” is selected for any shopper profiles. “Read-Only” can either be enabled or disabled.
4. Save.
   
### Runtime Token
1. In Logik, create a Runtime Client, with an Origin matching the Logik base URL. Click Copy to get the client token.
2. In Salesforce, from Setup home, go to Custom Code > Visualforce Pages.
3. Find the "commerceConfigurationWindow" page and click Edit.
4. Look for the line: `"runtimeToken":"",  // Set this to the token for the Runtime Client created in Logik`
5. Paste the copied token into the empty string and save.

### Apex Class Access
1. From Setup home, go to Custom Code > Apex Classes.
2. Look for CommerceConfigurationPunchinController and click Security.
3. Select any profiles that will be configuring products and move them from Available to Enabled.
4. Save.

### Visualforce Page Access
1. From Setup home, go to Feature Settings > Digital Experiences > All Sites.
2. For your store, click “Workspaces”.
3. Go to Administration > Pages > Go to Force.com.
4. Under “Site Visualforce Pages” click edit.
5. Add commerceConfigurationWindow from Available to Enabled and save.
6. From Setup home, go to Custom Code > Visualforce Pages.
7. Look for commerceConfigurationWindow and click Security.
8. Select any profiles that will be configuring products and move them from Available to Enabled.
9. Save.

### Experience Builder
1. From the Commerce home page, open Experience Builder.
2. Click on “Home” in the top left to open up the list of pages. Search or navigate to Product and click “Product Detail”. Either add the custom Logik button to the existing Product Detail page, or use the packaged page as a variation.
#### To add the button to an existing page:
1. Click the lightning bolt on the left and go to Custom Components (the last section in the list).
2. Click and drag the “Logik.io Configurator…” from the list and move it to where you want it on the layout.

#### To use the packaged page as a variation:
1. Re-open the page navigation menu on the top left.
2. On the Product Detail option, click the three dots and go to the Page Variations tab.
3. Create a new page variation and choose “Configurable Product Detail” as the layout.
4. Give the variation a name and Create.
