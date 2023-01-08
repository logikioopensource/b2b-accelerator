@isTest(SeeAllData=true)
private class HeadlessCartControllerTest {
    // Constants
    final static String[] PRODUCT_NAMES = new String[]{ // update to generic name, need to update payload too
        'Root Configurable Product',
        'Child Test Product 1',
        'Child Test Product 2',
        'Child Test Product 3',
        'Child Test Product 4',
        'Child Test Product 5'
    };
    final static String CONFIG_ID = '0bc351ab-76c9-4871-877f-35ee8c84b1ec';
    final static Product2[] PRODUCTS_LIST = new Product2[]{
        new Product2(Name = PRODUCT_NAMES[0], LGK__IsConfigurable__c = true),
        new Product2(Name = PRODUCT_NAMES[1]),
        new Product2(Name = PRODUCT_NAMES[2]),
        new Product2(Name = PRODUCT_NAMES[3]),
        new Product2(Name = PRODUCT_NAMES[4]),
        new Product2(Name = PRODUCT_NAMES[5])
    };
    final static Id WEBSTORE_ID = [SELECT Id FROM WebStore WHERE Type = 'B2B' LIMIT 1].Id;
    final static Id STANDARD_PRICE_BOOK_ID = Test.getStandardPricebookId();
    final static Id STORE_PRICE_BOOK_ID = [SELECT Pricebook2Id FROM WebStorePricebook WHERE WebStoreId = :WEBSTORE_ID LIMIT 1].Pricebook2Id;
    final static Id COMMUNITY_ID = [SELECT NetworkId FROM WebStoreNetwork WHERE WebStoreId = :WEBSTORE_ID LIMIT 1].NetworkId;
    final static NetworkMember[] USERS_LIST = [SELECT MemberId FROM NetworkMember WHERE NetworkId = :COMMUNITY_ID];
    final static String NEW_CART_MISSING_FIELDS_ERROR = '{ "message": "One or more required fields are missing: configurableProductId, configurationId, webstoreId, accountId", "errorCode": "MISSING_FIELD(S)" }';
    final static String EXISTING_CART_MISSING_FIELDS_ERROR = '{ "message": "One or more required fields are missing: configurableProductId, configurationId, cartId", "errorCode": "MISSING_FIELD(S)" }';
    
    // Variables
    static Id configProductId, cartId, accountId;
    static LGK__ConfigurationLineItem__c[] configLineItemsList = new LGK__ConfigurationLineItem__c[]{};
    static ConnectApi.CartSummary cart;
    static CartItem[] cartItems;
    static PricebookEntry[] pricebookEntries = new PricebookEntry[]{};
    static RestRequest request = new RestRequest();
    static RestResponse response = new RestResponse();
    static String responseBody = '';
    static CartItem[] responseCartItemsList = new CartItem[]{};

    @isTest
    static void TestNewCartApi(){
        Test.startTest();
        setupData();
        RestContext.request = request;
        RestContext.response = response;
        request.requestBody = Blob.valueOf('{"configurableProductId":"' + configProductId + '","configurationId":"' + CONFIG_ID + '","effectiveAccountId":"' + accountId + '","webstoreId":"' + WEBSTORE_ID + '"}');

        HeadlessCartController.addToNewCart();
        cart = ConnectApi.CommerceCart.getOrCreateActiveCartSummary(WEBSTORE_ID, accountId, 'current');

        assertSuccessResponse();
        Test.stopTest();
    }

    @isTest
    static void TestExistingCartApi() {
        Test.startTest();
        setupData();
        cart = ConnectApi.CommerceCart.getOrCreateActiveCartSummary(WEBSTORE_ID, accountId, 'current');
        cartId = cart.cartId;
        RestContext.request = request;
        RestContext.response = response;
        request.requestBody = Blob.valueOf('{"configurableProductId":"' + configProductId + '","configurationId":"' + CONFIG_ID + '","cartId":"' + cartId + '"}');
        
        HeadlessCartController.addToExistingCart();
        cart = ConnectApi.CommerceCart.getOrCreateActiveCartSummary(WEBSTORE_ID, accountId, 'current');

        assertSuccessResponse();
        Test.stopTest();
    }

    @isTest
    static void TestMissingFieldsError() {
        Test.startTest();
        setupData();
        RestContext.request = request;
        RestContext.response = response;
        request.requestURI = '/add-to-cart';
        request.requestBody = Blob.valueOf('{"configurableProductId":"","configurationId":""}');
        HeadlessCartController.addToNewCart();
        System.assertEquals(400, response.statusCode);
        System.assertEquals('application/json', response.headers.get('Content-Type'));
        System.assertEquals(NEW_CART_MISSING_FIELDS_ERROR, response.responseBody.toString());

        HeadlessCartController.addToExistingCart();
        System.assertEquals(400, response.statusCode);
        System.assertEquals('application/json', response.headers.get('Content-Type'));
        System.assertEquals(EXISTING_CART_MISSING_FIELDS_ERROR, response.responseBody.toString());
        Test.stopTest();
    }

    /*===== Non-Test Methods =====*/
    static void setupData() {
        // Go through list of network members and find one that's part of commerce (profile names may vary based on the store)
        User[] queryUsersList;
        for (NetworkMember each : USERS_LIST) {
            if (queryUsersList == null || queryUsersList.isEmpty()) {
                queryUsersList = [SELECT AccountId FROM User WHERE Id = :each.MemberId AND User.Profile.Name LIKE '%community%'];   
            }
        }
        accountId = queryUsersList[0].AccountId;

        insert PRODUCTS_LIST;
        for (Product2 each : PRODUCTS_LIST) {
            Decimal randomPrice = Math.random() * 100;
            Integer randomQuantity = Math.round(1 + (Math.random() * 10));

            PricebookEntry pbe = new PricebookEntry(UnitPrice=randomPrice, Pricebook2Id=STANDARD_PRICE_BOOK_ID, Product2Id=each.Id, IsActive=true);
            pricebookEntries.add(pbe);

            if(each.Name != PRODUCT_NAMES[0]) {
                configLineItemsList.add(new LGK__ConfigurationLineItem__c(
                    LGK__ProductId__c=each.Id,
                    LGK__ConfigurationId__c=CONFIG_ID,
                    LGK__Price__c=randomPrice,
                    LGK__Quantity__c=randomQuantity,
                    LGK__Type__c='Sales'
                ));
            }
        }
        insert pricebookEntries;
        insert configLineItemsList;
        configProductId = [SELECT Id FROM Product2 WHERE LGK__IsConfigurable__c = true AND Name = :PRODUCT_NAMES[0] LIMIT 1].Id;
    }

    static void assertSuccessResponse() {
        responseCartItemsList = (CartItem[])JSON.deserialize(response.responseBody.toString(), CartItem[].class);

        System.assertEquals(200, response.statusCode);
        System.assertEquals('application/json', response.headers.get('Content-Type'));
        System.assertEquals(6, responseCartItemsList.size());
        System.assertEquals(CONFIG_ID, responseCartItemsList[0].get('ConfigurationId__c'));

        Integer index = 0;
        for (CartItem each : responseCartItemsList) {
            System.assertEquals(PRODUCT_NAMES[index], each.Name);
            if (index == 0) {
                System.assertEquals(CONFIG_ID, each.get('ConfigurationId__c'));
                System.assertEquals(PRODUCTS_LIST[index].Id, each.Product2Id);
            }
            else {
                System.assertEquals(configLineItemsList[index - 1].LGK__ProductId__c, each.Product2Id);
                System.assertEquals(configLineItemsList[index - 1].LGK__Price__c, each.SalesPrice);
                System.assertEquals(configLineItemsList[index - 1].LGK__Quantity__c, each.Quantity);
            }
            index++;
        }
    }
}