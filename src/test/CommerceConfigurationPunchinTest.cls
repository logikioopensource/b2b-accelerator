@isTest(SeeAllData=true)
private class CommerceConfigurationPunchinTest {
    // Constants
    final static String[] PRODUCT_NAMES = new String[]{ // update to generic name, need to update payload too
        'Root Configurable Product',
        'Wheelchair',
        'Comfort Pillow',
        'Monthly Disposable Foam Earplug Subscription (50 ct)',
        'Warranty',
        'Warranty Extension'
    };
    final static String LAYOUT_NAME = 'b2bLayout';
    final static String CONFIG_ID = '0bc351ab-76c9-4871-877f-35ee8c84b1ec';
    final static String RUNTIME_TOKEN = 'aXXJs0mO1kccVOx1nCNvGUxA_SaLzxemwA';
    final static Product2[] PRODUCTS_LIST = new Product2[]{
        new Product2(Name = PRODUCT_NAMES[0], LGK__IsConfigurable__c = true, CommerceLayoutName__c = LAYOUT_NAME),
        new Product2(Name = PRODUCT_NAMES[1]),
        new Product2(Name = PRODUCT_NAMES[2]),
        new Product2(Name = PRODUCT_NAMES[3]),
        new Product2(Name = PRODUCT_NAMES[4]),
        new Product2(Name = PRODUCT_NAMES[5])
    };
    final static Id CUSTOMER_PROFILE_ID = [SELECT Id FROM PROFILE WHERE Name = 'Customer Community User' LIMIT 1].Id;
    final static Id PARTNER_PROFILE_ID = [SELECT Id FROM PROFILE WHERE Name = 'Partner Community User' LIMIT 1].Id;
    final static Id WEBSTORE_ID = [SELECT Id FROM WebStore WHERE Type = 'B2B' LIMIT 1].Id;
    final static Id STANDARD_PRICE_BOOK_ID = Test.getStandardPricebookId();
    final static Id STORE_PRICE_BOOK_ID = [SELECT Pricebook2Id FROM WebStorePricebook WHERE WebStoreId = :WEBSTORE_ID LIMIT 1].Pricebook2Id;
    final static Id COMMUNITY_ID = [SELECT NetworkId FROM WebStoreNetwork WHERE WebStoreId = :WEBSTORE_ID LIMIT 1].NetworkId;
    final static NetworkMember[] USERS_LIST = [SELECT MemberId FROM NetworkMember WHERE NetworkId = :COMMUNITY_ID];
    
    // Variables
    static String fullPayload = '';
    static String dynamicData = '';
    static Id configProductId, cartId, accountId;
    static WebCart cart;
    static CartItem[] cartItems;
    static PricebookEntry[] pricebookEntries = new PricebookEntry[]{};

    static void setupData() {
        // Go through list of network members and find one that's part of commerce (profile names may vary based on the store)
        User[] queryUsersList;
        for (NetworkMember each : USERS_LIST) {
            if (queryUsersList == null || queryUsersList.isEmpty()) {
                queryUsersList = [SELECT AccountId FROM User WHERE Id = :each.MemberId AND (ProfileId = :CUSTOMER_PROFILE_ID OR ProfileId = :PARTNER_PROFILE_ID)];   
            }
        }
        accountId = queryUsersList[0].AccountId;

        insert PRODUCTS_LIST;
        dynamicData = '[{"productId":null,"quantity":1,"configurationData":{},"selected":false}';
        Integer count = 0;
        for (Product2 each : PRODUCTS_LIST) {
            PricebookEntry pbe = new PricebookEntry(UnitPrice=count, Pricebook2Id=STANDARD_PRICE_BOOK_ID, Product2Id=each.Id, IsActive=true);
            pricebookEntries.add(pbe);
            if (count > 0) {    // configurable product is already added
                dynamicData += ',{"productId":"' + each.Id + '","Quantity":1,"selected":true,"readOnly":{},"configurationData":{"SBQQ__UnitPrice__c":' + count + '}}';
            }
            count++;
        }
        insert pricebookEntries;
        dynamicData += ']';
        configProductId = [SELECT Id FROM Product2 WHERE LGK__IsConfigurable__c = true AND Name = :PRODUCT_NAMES[0] LIMIT 1].Id;
        fullPayload = '{"runtimeToken":"' + RUNTIME_TOKEN + '","product":{"configuredProductId":"' + configProductId + '","configurationAttributes":{"LGK__ConfigurationId__c":"' + CONFIG_ID  + '"},"optionConfigurations":{"Dynamic":' + dynamicData + '},"configurationData":{}}}';
    }

    @isTest(SeeAllData=true)
    static void TestAddToCart() {
        Decimal configProductPrice = 0;
        Decimal totalPrice = 0;

        Test.startTest();
        setupData();
        cartId = CommerceConfigurationPunchinController.addToCart(fullPayload, COMMUNITY_ID, accountId);
        cart = [SELECT Id, TotalAmount, TotalProductCount FROM WebCart WHERE Id = :cartId AND AccountId = :accountId LIMIT 1];
        System.debug('cart');
        cartItems = [SELECT Name, Product2Id, Quantity, SalesPrice, UnitAdjustedPrice, TotalLineAmount, TotalPrice, TotalPriceAfterAllAdjustments, ConfigurationId__c
            FROM CartItem WHERE CartId = :cartId AND Name IN :PRODUCT_NAMES];
        
        configProductPrice = [SELECT UnitPrice FROM PricebookEntry WHERE Product2Id = :configProductId AND IsActive = true LIMIT 1].UnitPrice;
        totalPrice += configProductPrice;

        for (CartItem each : cartItems) { 
            // check cart item name vs product name, product id vs product2id

            if (!String.isEmpty(each.ConfigurationId__c)) {
                System.assertEquals(CONFIG_ID, each.ConfigurationId__c);
            }
            else {
                totalPrice += each.SalesPrice;
            }
        }
        System.assertEquals(totalPrice, cart.TotalAmount);
        System.assertEquals(cart.Id, cartId);
        System.assertEquals(PRODUCTS_LIST.size(), cart.TotalProductCount);
        Test.stopTest();
    }

    @isTest
    static void TestLayoutName(){
        Test.startTest();
        setupData();
        String layoutName = CommerceConfigurationPunchinController.getLayoutName(configProductId);
        System.assertEquals(LAYOUT_NAME, layoutName);
        Test.stopTest();
    }

    @isTest
    static void TestVisualforceUrl() {
        Test.startTest();
        setupData();
        String generatedUrl = CommerceConfigurationPunchinController.getVisualforceUrl(COMMUNITY_ID, accountId, configProductId);
        String expectedUrl = '/apex/commerceConfigurationWindow?communityId=' + COMMUNITY_ID + '&accountId=' + accountId + '&productId=' + configProductId;
        System.assertEquals(expectedUrl, generatedUrl);
        Test.stopTest();
    }
}