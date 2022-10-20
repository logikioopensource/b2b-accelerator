@RestResource(urlMapping='/LGK/add-to-cart')
global with sharing class HeadlessCartController {
    static RestRequest request = new RestRequest();
    static Map<String, Object> requestBody = new Map<String, Object>{};
    static String configurableProductId, configurationId, webstoreId, accountId, cartId;

    static RestResponse response = new RestResponse();
    static CartItem[] cartItemsList = new CartItem[]{};
    static Id[] productIdList = new Id[]{};
    static Map<Id, Product2> productMap = new Map<Id, Product2>{};

    @HttpPost
    global static void addToNewCart() {
        // Request
        request = RestContext.request;
        requestBody = (Map<String, Object>)JSON.deserializeUntyped(request.requestBody.toString());
        configurableProductId = (String)requestBody.get('configurableProductId');
        configurationId = (String)requestBody.get('configurationId');
        webstoreId = (String)requestBody.get('webstoreId');
        accountId = (String)requestBody.get('effectiveAccountId');
        
        // Response
        response = RestContext.response;
        response.addHeader('Content-Type', 'application/json');
        if (String.isEmpty(configurableProductId) || String.isEmpty(configurationId) || String.isEmpty(webstoreId) || String.isEmpty(accountId)) {
            response.statusCode = 400;
            response.responseBody = Blob.valueOf('{ "message": "One or more required fields are missing: configurableProductId, configurationId, webstoreId, accountId", "errorCode": "MISSING_FIELD(S)" }');
        }
        else {
            ConnectApi.CartSummary cart = ConnectApi.CommerceCart.getOrCreateActiveCartSummary(webstoreId, accountId, 'current');
            convertConfigLinesToCartItems(cart.cartId, configurableProductId, configurationId);
            response.statusCode = 200;
            response.responseBody = Blob.valueOf(JSON.serializePretty(cartItemsList));
        }
    }

    @HttpPatch
    global static void addToExistingCart() {
        // Request
        request = RestContext.request;
        requestBody = (Map<String, Object>)JSON.deserializeUntyped(request.requestBody.toString());
        configurableProductId = (String)requestBody.get('configurableProductId');
        configurationId = (String)requestBody.get('configurationId');
        cartId = (String)requestBody.get('cartId');
        
        // Response
        response = RestContext.response;
        response.addHeader('Content-Type', 'application/json');
        if (String.isEmpty(configurableProductId) || String.isEmpty(configurationId) || String.isEmpty(cartId)) {
            response.statusCode = 400;
            response.responseBody = Blob.valueOf('{ "message": "One or more required fields are missing: configurableProductId, configurationId, cartId", "errorCode": "MISSING_FIELD(S)" }');
        }
        else {
            convertConfigLinesToCartItems(cartId, configurableProductId, configurationId);
            response.statusCode = 200;
            response.responseBody = Blob.valueOf(JSON.serializePretty(cartItemsList));
        }
    }

    /*===== Non-HTTP Methods =====*/
    public static void convertConfigLinesToCartItems(String cartId, String configurableProductId, String configurationId) {
        CartItem[] reversedLines = new CartItem[]{};
        try {
            Id deliveryGroupId = [SELECT Id FROM CartDeliveryGroup WHERE CartId = :cartId WITH SECURITY_ENFORCED LIMIT 1].Id;
            Decimal configProductPrice = [SELECT UnitPrice FROM PricebookEntry WHERE Product2Id = :configurableProductId AND IsActive = true WITH SECURITY_ENFORCED LIMIT 1].UnitPrice;

            productIdList.add(configurableProductId);
            cartItemsList.add(new CartItem(
                CartId = cartId,
                Product2Id = configurableProductId,
                Type = 'Product',
                CartDeliveryGroupId = deliveryGroupId,
                SalesPrice = configProductPrice,
                UnitAdjustedPrice = configProductPrice,
                TotalLineAmount = configProductPrice,
                TotalPrice = configProductPrice,
                TotalPriceAfterAllAdjustments = configProductPrice,
                ConfigurationId__c = configurationId
            ));

            for (LGK__ConfigurationLineItem__c each : [SELECT LGK__ProductId__c, LGK__Price__c, LGK__Quantity__c FROM LGK__ConfigurationLineItem__c WHERE (LGK__ConfigurationId__c = :configurationId AND LGK__Type__c = 'Sales') WITH SECURITY_ENFORCED]) {
                cartItemsList.add(new CartItem(
                    CartId = cartId,
                    Product2Id = each.LGK__ProductId__c,
                    Type = 'Product',
                    CartDeliveryGroupId = deliveryGroupId,
                    Quantity = each.LGK__Quantity__c,
                    SalesPrice = each.LGK__Price__c,
                    UnitAdjustedPrice = each.LGK__Price__c,
                    TotalLineAmount = each.LGK__Price__c,
                    TotalPrice = each.LGK__Price__c,
                    TotalPriceAfterAllAdjustments = each.LGK__Price__c
                ));
                productIdList.add(each.LGK__ProductId__c);
            }

            // Reverse cart order for UI view
            Integer cartSize = cartItemsList.size();
            for (Integer i = cartSize - 1; i >= 0; i--) {
                reversedLines.add(cartItemsList[i]);
            }

            productMap = new Map<Id, Product2>([SELECT Id, Name FROM Product2 WHERE Id IN :productIdList WITH SECURITY_ENFORCED]);
            for (CartItem each : reversedLines) {
                each.Name = productMap.get(each.Product2Id).Name;
            }
        } catch (QueryException qe) {
            System.debug(qe.getMessage());
        }

        try {
            if (Schema.SObjectType.CartItem.isCreateable() &&
                Schema.SObjectType.CartItem.fields.CartId.isCreateable() &&
                Schema.SObjectType.CartItem.fields.Product2Id.isCreateable() &&
                Schema.SObjectType.CartItem.fields.Type.isCreateable() &&
                Schema.SObjectType.CartItem.fields.CartDeliveryGroupId.isCreateable() &&
                Schema.SObjectType.CartItem.fields.Quantity.isCreateable() &&
                Schema.SObjectType.CartItem.fields.SalesPrice.isCreateable() &&
                Schema.SObjectType.CartItem.fields.UnitAdjustedPrice.isCreateable() &&
                Schema.SObjectType.CartItem.fields.TotalLineAmount.isCreateable() &&
                Schema.SObjectType.CartItem.fields.TotalPrice.isCreateable() &&
                Schema.SObjectType.CartItem.fields.TotalPriceAfterAllAdjustments.isCreateable() &&
                Schema.SObjectType.CartItem.fields.ConfigurationId__c.isCreateable()
                )
            {
                insert reversedLines;
            }
        } catch (DmlException de) {
            System.debug(de.getMessage());

        }
    }
}
