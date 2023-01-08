@isTest(SeeAllData=true)
private class CommerceConfigurationPunchinTest {
    // Constants
    final static String CONFIGURABLE_PRODUCT_NAME = 'root',
        LAYOUT_NAME = 'b2bLayout',
        CONFIG_ID = 'config-id-123',
        RUNTIME_TOKEN = 'token123';
    final static Id WEBSTORE_ID = [SELECT Id FROM WebStore WHERE Type = 'B2B' LIMIT 1].Id;
    final static Id STANDARD_PRICE_BOOK_ID = Test.getStandardPricebookId();
    final static Id STORE_PRICE_BOOK_ID = [SELECT Pricebook2Id FROM WebStorePricebook WHERE WebStoreId = :WEBSTORE_ID LIMIT 1].Pricebook2Id;
    final static Id COMMUNITY_ID = [SELECT NetworkId FROM WebStoreNetwork WHERE WebStoreId = :WEBSTORE_ID LIMIT 1].NetworkId;
    final static NetworkMember[] USERS_LIST = [SELECT MemberId FROM NetworkMember WHERE NetworkId = :COMMUNITY_ID];
    
    // Variables
    static String[] productNamesList = new String[]{};
    static Product2[] productsList = new Product2[]{
        new Product2(Name = CONFIGURABLE_PRODUCT_NAME, LGK__IsConfigurable__c = true, IsActive = true, CommerceLayoutName__c = LAYOUT_NAME)
    };
    static String fullPayload = '';
    static Id cartId, accountId;
    static WebCart cart;
    static CartItem[] cartItems;
    static PricebookEntry[] pricebookEntries = new PricebookEntry[]{};

    static void setupData() {
        // Go through list of network members and find one that's part of commerce (profile names may vary based on the store)
        User[] queryUsersList;
        for (NetworkMember each : USERS_LIST) {
            if (queryUsersList == null || queryUsersList.isEmpty()) {
                queryUsersList = [SELECT AccountId FROM User WHERE Id = :each.MemberId AND User.Profile.Name LIKE '%community%'];   
            }
        }
        accountId = queryUsersList[0].AccountId;

        // Create test products
        for (Integer i = 0; i < 20; i++) {
            productsList.add(new Product2(Name = 'Test Child ' + i, IsActive = true));
            productNamesList.add('Test Child ' + i);
        }
        insert productsList;

        String dynamicData = '[{"productId":null,"quantity":1,"configurationData":{},"selected":false}',
            bomDataString = '';
        Integer count = 0;
        for (Product2 each : productsList) {
            PricebookEntry pbe = new PricebookEntry(UnitPrice=count, Pricebook2Id=STANDARD_PRICE_BOOK_ID, Product2Id=each.Id, IsActive=true);
            pricebookEntries.add(pbe);
            
            if (count > 0) {    // configurable product is already added
                Map<String, Object> tempBomRecord = new Map<String, Object>{};

                dynamicData += ',{"productId":"' + each.Id + '","Quantity":1,"selected":true,"readOnly":{},"configurationData":{"SBQQ__UnitPrice__c":' + count + '}}';
                if (!String.isEmpty(bomDataString)) {
                    bomDataString += ',';
                }
                bomDataString += '{"id":"' + each.Id + '","quantity":1,"bomType":"Sales","name":"' + each.Name + '","partnerId":"' + each.Id + '","price":' + count + '}';
            }

            count++;
        }
        insert pricebookEntries;

        dynamicData += ']';
        fullPayload = '{"runtimeToken":"' + RUNTIME_TOKEN + '","product":{"configuredProductId":"' + productsList[0].Id + '","configurationAttributes":{"LGK__ConfigurationId__c":"' + CONFIG_ID  + '","LGK__BomData__c":{"items":[' + bomDataString + ']}},"optionConfigurations":{"Dynamic":' + dynamicData + '},"configurationData":{}}}';
    }

    @isTest(SeeAllData=true)
    static void TestAddToCart() {
        Decimal configProductPrice = 0;
        Decimal totalPrice = 0;

        Test.startTest();
        setupData();
        cartId = CommerceConfigurationPunchinController.addToCart(fullPayload, COMMUNITY_ID, accountId);
        cart = [SELECT Id, TotalAmount, TotalProductCount FROM WebCart WHERE Id = :cartId AND AccountId = :accountId LIMIT 1];
        cartItems = [SELECT Name, Product2Id, Quantity, SalesPrice, UnitAdjustedPrice, TotalLineAmount, TotalPrice, TotalPriceAfterAllAdjustments, ConfigurationId__c
            FROM CartItem WHERE CartId = :cartId AND Name IN :productNamesList];
        
        configProductPrice = [SELECT UnitPrice FROM PricebookEntry WHERE Product2Id = :productsList[0].Id AND IsActive = true LIMIT 1].UnitPrice;
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
        System.assertEquals(productsList.size(), cart.TotalProductCount);
        Test.stopTest();
    }

    @isTest
    static void TestLayoutName(){
        Test.startTest();
        setupData();
        String layoutName = CommerceConfigurationPunchinController.getLayoutName(productsList[0].Id);
        System.assertEquals(LAYOUT_NAME, layoutName);
        Test.stopTest();
    }

    @isTest
    static void TestVisualforceUrl() {
        Test.startTest();
        setupData();
        String generatedUrl = CommerceConfigurationPunchinController.getVisualforceUrl(COMMUNITY_ID, accountId, productsList[0].Id);
        String expectedUrl = '/apex/commerceConfigurationWindow?communityId=' + COMMUNITY_ID + '&accountId=' + accountId + '&productId=' + productsList[0].Id;
        System.assertEquals(expectedUrl, generatedUrl);
        Test.stopTest();
    }
}