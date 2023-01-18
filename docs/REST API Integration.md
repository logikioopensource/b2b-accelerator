# Headless Cart API

## Preconditions
This guide assumes the following in Salesforce:
- System Administrator or similar access is available in order to perform the steps listed.
- Files in this repo were deployed to your Salesforce org (see README.md at the top directory for more info)

## Setup Steps
### Field Security
1. From Setup Home, go to the Object Manager tab, or navigate to Objects and Fields > Object Manager.
2. From Object Manager, search for and open Configuration Line Item (LGK__ConfigurationLineItem__c).
3. Go to Fields & Relationships. Searach for and open Quantity.
4. Click "Set Field-Level Security".
5. Make sure the profiles for the users that will be making the API calls have Field-Level Security set to “Visible”, then Save.
6. Repeat steps 3-5 for the following fields:
   - ProductId
   - Price
   - ConfigurationId
   - Type

A similar set of steps are required on CartItem fields as well.
1. From Setup Home, go to the Object Manager tab, or navigate to Objects and Fields > Object Manager.
2. From Object Manager, search for and open Cart Item (CartItem).
3. Go to Fields & Relationships. Search for and open the field Configuration Id (ConfigurationId__c).
4. Click “Set Field-Level Security”.
5. Make sure the option “Visible” is selected and “Read-Only” is not selected for profiles making the API calls, then Save.
6. Repeat steps 3-5 for the following fields:
   - Quantity
   - ProductId
   - Price
   - Type

### Apex Class Access
1. From Setup home, go to Custom Code > Apex Classes.
2. Look for HeadlessCartController and click Security.
3. Select any profiles that will be configuring products and using the REST API and move them from Available to Enabled.
4. Save.
   
## Schema
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
    }
]
