global with sharing class CommerceConfigurationPunchinController {
    @RemoteAction
    global static String addToCart(String payloadString, String communityId, String accountId) {
        // Request payload parsing
        Map<String, Object> requestBody = (Map<String, Object>)JSON.deserializeUntyped(payloadString),
            requestProduct = (Map<String, Object>)requestBody.get('product'),
            configurationAttributesMap = (Map<String, Object>)requestProduct.get('configurationAttributes');
        Object[] bomDataList = (Object[])((Map<String, Object>)configurationAttributesMap.get('LGK__BomData__c')).get('items');
        String configuredProductId = String.valueOf(requestProduct.get('configuredProductId'));
        String configurationId = String.valueOf(configurationAttributesMap.get('LGK__ConfigurationId__c'));
        
        // Store/Cart
        ConnectApi.CartSummary currentCart;
        String webStoreId = '';
        Id deliveryGroupId;
        CartItem[] cartItemsList = new CartItem[]{},
            reversedCartItemsList = new CartItem[]{};

        try {
            webStoreId = [SELECT WebStoreId FROM WebStoreNetwork WHERE NetworkId = :communityId WITH SECURITY_ENFORCED LIMIT 1].WebStoreId;
            currentCart = ConnectApi.CommerceCart.getOrCreateActiveCartSummary(webStoreId, accountId, 'current');
            deliveryGroupId = [SELECT Id FROM CartDeliveryGroup WHERE CartId = :currentCart.cartId WITH SECURITY_ENFORCED LIMIT 1].Id;
        } catch (QueryException qe) {
            System.debug(qe.getMessage());
        }

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
            // Add configuredProduct. Adjust PBE retrieval as necessary
            PricebookEntry configuredPricebookEntry = [SELECT Name, UnitPrice FROM PricebookEntry WHERE Product2Id = :configuredProductId AND IsActive = true WITH SECURITY_ENFORCED LIMIT 1];
            cartItemsList.add(new CartItem(
                Name = configuredPricebookEntry.Name,
                CartId = currentCart.cartId,
                Type = 'Product',
                CartDeliveryGroupId = deliveryGroupId,
                Product2Id = configuredProductId,
                Quantity = 1,
                SalesPrice = configuredPricebookEntry.UnitPrice,
                UnitAdjustedPrice = configuredPricebookEntry.UnitPrice,
                TotalLineAmount = configuredPricebookEntry.UnitPrice,
                TotalPrice = configuredPricebookEntry.UnitPrice,
                TotalPriceAfterAllAdjustments = configuredPricebookEntry.UnitPrice,
                ConfigurationId__c = configurationId
            ));

            // Add child products
            for (Object each : bomDataList) {
                Map<String, Object> tempRecord = (Map<String,Object>)each;
                if (tempRecord.containsKey('partnerId') && String.valueOf(tempRecord.get('bomType')).equalsIgnoreCase('Sales')) {
                    Decimal tempQuantity = Double.valueOf(tempRecord.get('quantity'));
                    Decimal tempPrice = Double.valueOf(tempRecord.get('price'));

                    try {
                        Id productId = Id.valueOf(String.valueOf(tempRecord.get('partnerId')));
                        if (productId.getSObjectType() == Product2.SObjectType) {
                            cartItemsList.add(new CartItem(
                                Name = String.valueOf(tempRecord.get('name')),
                                CartId = currentCart.cartId,
                                Type = 'Product',
                                CartDeliveryGroupId = deliveryGroupId,
                                Product2Id = String.valueOf(tempRecord.get('partnerId')),
                                Quantity = tempQuantity,
                                // There are multiple price fields on the CartItem, these seem like the most appropriate to update based on API name/description
                                SalesPrice = tempPrice,
                                UnitAdjustedPrice = tempPrice,
                                TotalLineAmount = tempQuantity * tempPrice,
                                TotalPrice = tempQuantity * tempPrice,
                                TotalPriceAfterAllAdjustments = tempQuantity * tempPrice
                            ));
                        }
                    } catch (StringException se) {
                        System.debug(se.getMessage());
                    }
                }
            }

            // Reverse lines so they show in shopping cart in the "correct" order
            for (Integer i = cartItemsList.size() - 1; i >= 0; i--) {
                reversedCartItemsList.add(cartItemsList[i]);
            }

            try {
                insert reversedCartItemsList;
            } catch (DmlException de) {
                System.debug(de.getMessage());
            }
        }
        else {
            System.debug('Missing SObject permission to add Cart Items via CommerceConfigurationPunchinController.');
        }

        return currentCart.cartId;
    }

    @RemoteAction
    public static String getLayoutName(String productId) { 
        String result = '';
        if (Schema.SObjectType.Product2.isAccessible() && Schema.SObjectType.Product2.fields.CommerceLayoutName__c.isAccessible())
        {
            try {
                result = [SELECT CommerceLayoutName__c FROM Product2 WHERE Id = :productId LIMIT 1].CommerceLayoutName__c;
            } catch (QueryException qe) {
                System.debug(qe.getMessage());
            }
        }
        else {
            System.debug('Product data is inaccessible, could not retrieve layout name for: ' + productId);
        }

        return result;
    }

    @AuraEnabled(cacheable=true)
    public static String getVisualforceUrlForAura(Id communityId, String accountId, String productId) {
        String pathPrefix = [SELECT UrlPathPrefix FROM Network WHERE Id = :communityId WITH SECURITY_ENFORCED LIMIT 1].UrlPathPrefix;
        return '/' + pathPrefix + '/apex/commerceConfigurationWindow?communityId=' + communityId + '&accountId=' + accountId + '&productId=' + productId;
    }

    @AuraEnabled(cacheable=true)
    public static String getVisualforceUrlForLwr(String pathPrefix, Id communityId, String accountId, String productId) {
        if (String.isEmpty(pathPrefix)) {
            pathPrefix = '/';
        }
        return pathPrefix + 'vforcesite/apex/commerceConfigurationWindowLwr?communityId=' + communityId + '&accountId=' + accountId + '&productId=' + productId;
    }
}