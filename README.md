# Logik.io Integration with Salesforce B2B Commerce

## Preconditions
This guide assumes the following in Salesforce:
- Commerce is enabled
- Logik.io Base Managed Package is installed
- System Administrator or similar access is available in order to perform the steps listed.

## Installing the Components to Salesforce
1. If it isn't already installed, download and install the Salesforce Command Line Interface (CLI) using the instructions here: https://developer.salesforce.com/docs/atlas.en-us.sfdx_setup.meta/sfdx_setup/sfdx_setup_install_cli.htm
2. Download and extract the logik-b2b.zip file, which contains the components used for the B2B integration.
   - On Windows, right click and select "Extract All...". Follow the prompts that appear on screen.
   - On Mac, double click the file and its contents will be extracted automatically in the same location.
3. Depending on the operating system, run the application Terminal (on Mac or Linux) or Powershell (on Windows).
4. Use the change directory (cd) command to navigate to the unzipped directory. For example, if the files were extracted in the Downloads folder, type and enter the command "cd Downloads/logik-b2b".
   - For an in-depth guide to navigation using the command line, refer the following:
     - Windows: https://www.howtogeek.com/659411/how-to-change-directories-in-command-prompt-on-windows-10/
	 - Mac/Linux: https://www.macworld.com/article/221277/command-line-navigating-files-folders-mac-terminal.html
5. Type and enter the command "ls" and a list of files and folders in that directory will be returned. Included in the list should be the folder "src" and the file "sfdx-project.json".
6. Run the command "sfdx auth:web:login --setalias myOrg -r https://example-dev-ed.my.salesforce.com"
   - Replace the URL following "-r " with the one that the Logik-B2B integration will be set up on.
   - The text following "--setalias " is a nickname that is used to identify and reference the correct Salesforce org (multiple Salesforce orgs can be connected to a single machine). The example "myOrg" will be used for the purposes of this guide; if using another alias here, be sure to use that same alias in the following steps.
7. The URL specified in the previous login command will be opened in the default browser. Log in and authorize the "Salesforce CLI" connected app.
8. In the command line, run the command "sfdx force:source:deploy -p src -u myOrg". After a few moments, the command line will return a confirmation message, "Deploy Succeeded."

## Post-Install Setup in Salesforce
The following additional steps are required after installing the artifacts here onto Salesforce.

### Field Security
#### For UI Integration
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

#### For Add to Cart API Integration
More field level security permissions are required if using the Add to Cart API.
1. From Object Managed, search for and open Configuration Line Item (LGK__ConfigurationLineItem__c).
2. Make sure shopper profiles have Field-Level Security to “Visible” for the following fields:
   - Quantity
   - ProductId
   - Price
   - ConfigurationId
   - Type

In addition, the following CartItem fields will need to be set to “Visible” (“Read-Only” must not be checked):
1. ConfigurationId (this should already be done for the UI integration)
2. Quantity
3. ProductId
4. Price
5. Type
   
### Runtime Token
1. In Logik, create a Runtime Client, with an Origin matching the Logik base URL. Click Copy to get the client token.
2. In Salesforce, from Setup home, go to Custom Code > Custom Settings.
3. For Logik Tenant, click Manage.
4. If settings already exist, click “Edit”. Otherwise, click “New” above the “Default Organization Level Value” header.
5. For the Runtime Client Token field, paste the copied token for the runtime client. Make sure the URL field(s) are set to the same URL as one of the runtime client’s Origins in Logik.io admin.
6. Save.

### Visualforce Page Access
1. From Setup home, go to Feature Settings > Digital Experiences > All Sites.
2. For your store, click “Workspaces”.
3. Go to Administration > Pages > Go to Force.com.
4. Under “Site Visualforce Pages” click edit.
5. Add commerceConfigurationWindow from Available to Enabled and save.

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

## Add to Cart API
### Endpoint
/services/apexrest/add-to-cart

### Methods
Receives and returns application/json

#### POST
For adding items to the currently active cart (one is created if it does not exist). Requires the following:
- configurableProductId
- configurationId
- webstoreId
- effectiveAccountId

webstoreId and effectiveAccountId are part of Salesforce Commerce’s standard APIs, so that information should be readily available to users.
configurableProductId and configurationId must correspond to the same configurable Product.

#### PATCH
For adding items to a specific cart. Requires the following:
- configurableProductId
- configurationId
- cartId

### Response
An array of Cart Items (CartItem) records

### Examples
#### Request (Create New Quote)
{
    "configurableProductId": "01t8a0000061GQPAA2",
    "configurationId": "7e45beb9-790c-46ef-a05f-9195718bcda7",
    "effectiveAccountId": "0018a00001nsFoNAAU",
    "webstoreId": "0ZE8a000000XwckGAC"
}

#### Request (Add to Existing Quote)
{
    "configurableProductId": "01t8a0000061GQPAA2",
    "configurationId": "7e45beb9-790c-46ef-a05f-9195718bcda7",
    "cartId": "0a68a000000kXQeAAM"
}

#### Response
[
    {
        "attributes": {
            "type": "CartItem",
            "url": "/services/data/v56.0/sobjects/CartItem/0a98a000000kWtlAAE"
        },
        "CartId": "0a68a000000kXDsAAM",
        "Product2Id": "01t8a0000061GQPAA2",
        "Type": "Product",
        "CartDeliveryGroupId": "0a78a000000kWwxAAE",
        "SalesPrice": 10000.00,
        "UnitAdjustedPrice": 10000.00,
        "TotalLineAmount": 10000.00,
        "TotalPrice": 10000.00,
        "TotalPriceAfterAllAdjustments": 10000.00,
        "LGK__ConfigurationId__c": "7e45beb9-790c-46ef-a05f-9195718bcda7",
        "Name": "LGK Machine",
        "Id": "0a98a000000kWtlAAE"
    },
    {
        "attributes": {
            "type": "CartItem",
            "url": "/services/data/v56.0/sobjects/CartItem/0a98a000000kWtkAAE"
        },
        "CartId": "0a68a000000kXDsAAM",
        "Product2Id": "01t8a0000061GQOAA2",
        "Type": "Product",
        "CartDeliveryGroupId": "0a78a000000kWwxAAE",
        "Quantity": 1.00,
        "SalesPrice": 0.00,
        "UnitAdjustedPrice": 0.00,
        "TotalLineAmount": 0.00,
        "TotalPrice": 0.00,
        "TotalPriceAfterAllAdjustments": 0.00,
        "Name": "Warranty",
        "Id": "0a98a000000kWtkAAE"
    },
    {
        "attributes": {
            "type": "CartItem",
            "url": "/services/data/v56.0/sobjects/CartItem/0a98a000000kWtjAAE"
        },
        "CartId": "0a68a000000kXDsAAM",
        "Product2Id": "01t8a0000061GQKAA2",
        "Type": "Product",
        "CartDeliveryGroupId": "0a78a000000kWwxAAE",
        "Quantity": 1.00,
        "SalesPrice": 0.00,
        "UnitAdjustedPrice": 0.00,
        "TotalLineAmount": 0.00,
        "TotalPrice": 0.00,
        "TotalPriceAfterAllAdjustments": 0.00,
        "Name": "1.5T Magnet",
        "Id": "0a98a000000kWtjAAE"
    },
    {
        "attributes": {
            "type": "CartItem",
            "url": "/services/data/v56.0/sobjects/CartItem/0a98a000000kWtiAAE"
        },
        "CartId": "0a68a000000kXDsAAM",
        "Product2Id": "01t8a0000061GQGAA2",
        "Type": "Product",
        "CartDeliveryGroupId": "0a78a000000kWwxAAE",
        "Quantity": 1.00,
        "SalesPrice": 1.50,
        "UnitAdjustedPrice": 1.50,
        "TotalLineAmount": 1.50,
        "TotalPrice": 1.50,
        "TotalPriceAfterAllAdjustments": 1.50,
        "Name": "MRI Platform Table",
        "Id": "0a98a000000kWtiAAE"
    },
    {
        "attributes": {
            "type": "CartItem",
            "url": "/services/data/v56.0/sobjects/CartItem/0a98a000000kWthAAE"
        },
        "CartId": "0a68a000000kXDsAAM",
        "Product2Id": "01t8a0000061GQLAA2",
        "Type": "Product",
        "CartDeliveryGroupId": "0a78a000000kWwxAAE",
        "Quantity": 1.00,
        "SalesPrice": 2.50,
        "UnitAdjustedPrice": 2.50,
        "TotalLineAmount": 2.50,
        "TotalPrice": 2.50,
        "TotalPriceAfterAllAdjustments": 2.50,
        "Name": "MRI Scanner",
        "Id": "0a98a000000kWthAAE"
    },
    {
        "attributes": {
            "type": "CartItem",
            "url": "/services/data/v56.0/sobjects/CartItem/0a98a000000kWtgAAE"
        },
        "CartId": "0a68a000000kXDsAAM",
        "Product2Id": "01t8a0000061GQRAA2",
        "Type": "Product",
        "CartDeliveryGroupId": "0a78a000000kWwxAAE",
        "Quantity": 25.00,
        "SalesPrice": 1.00,
        "UnitAdjustedPrice": 1.00,
        "TotalLineAmount": 1.00,
        "TotalPrice": 1.00,
        "TotalPriceAfterAllAdjustments": 1.00,
        "Name": "MRI Gradient Coils",
        "Id": "0a98a000000kWtgAAE"
    },
    {
        "attributes": {
            "type": "CartItem",
            "url": "/services/data/v56.0/sobjects/CartItem/0a98a000000kWtfAAE"
        },
        "CartId": "0a68a000000kXDsAAM",
        "Product2Id": "01t8a0000061GQHAA2",
        "Type": "Product",
        "CartDeliveryGroupId": "0a78a000000kWwxAAE",
        "Quantity": 25.00,
        "SalesPrice": 3.00,
        "UnitAdjustedPrice": 3.00,
        "TotalLineAmount": 3.00,
        "TotalPrice": 3.00,
        "TotalPriceAfterAllAdjustments": 3.00,
        "Name": "MRI Radio Frequency Coils",
        "Id": "0a98a000000kWtfAAE"
    }
]