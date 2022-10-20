global with sharing class CommerceConfigurationPunchinController {
    @RemoteAction
    global static String addToCart(String payloadString, String communityId, String accountId) {
        JSONParser parser = JSON.createParser(payloadString);
        // Required store/cart info
        ConnectApi.CartSummary currentCart;
        String webStoreId = '';
        Id deliveryGroupId;
        
        // For line items
        CartItem[] lines = new CartItem[]{};
        Id[] productIdList = new Id[]{};
        Map<Id, Product2> productMap = new Map<Id, Product2>{};
        Integer lineIndex = 0;
        Decimal configProductPrice = 0.0;
        Decimal lineQuantity = 0.0;
        Decimal totalPrice = 0.0;
        String currentName = '';

        // For custom field data
        String configId = '';
        String iteratingOver = '';

        try {
            webStoreId = [SELECT WebStoreId FROM WebStoreNetwork WHERE NetworkId = :communityId WITH SECURITY_ENFORCED LIMIT 1].WebStoreId;
            currentCart = ConnectApi.CommerceCart.getOrCreateActiveCartSummary(webStoreId, accountId, 'current');
            deliveryGroupId = [SELECT Id FROM CartDeliveryGroup WHERE CartId = :currentCart.cartId WITH SECURITY_ENFORCED LIMIT 1].Id;
        } catch (QueryException qe) {
            System.debug(qe.getMessage());
        }
        
        while (parser.nextToken() != null) {
            currentName = parser.getCurrentName();
            if (currentName == null) {
                // Skip
            }
            else if (currentName.equalsIgnoreCase('configuredProductId')) {
                // productId for the configurable product is set separately than the rest of the product(s) info
                // This should come before any of the other products in the payload, but check for the cartitem[] size just in case
                if (lines.isEmpty()) {
                    parser.nextToken();
                    currentName = parser.getCurrentName();
                    productIdList.add(parser.getIdValue());
                    // Need to work on getting the right pricebook, but that's going to be complicated (get pricing strategy from webstore, get all pricebook entries for store/product, then compare according to pricing strategy)
                    configProductPrice = [SELECT UnitPrice FROM PricebookEntry WHERE Product2Id = :parser.getIdValue() AND IsActive = true WITH SECURITY_ENFORCED LIMIT 1].UnitPrice;
                    lines.add(new CartItem(
                        CartId = currentCart.cartId,
                        Product2Id = parser.getIdValue(),
                        Type = 'Product',
                        CartDeliveryGroupId = deliveryGroupId,
                        Quantity = 1,
                        SalesPrice = configProductPrice,
                        UnitAdjustedPrice = configProductPrice,
                        TotalLineAmount = configProductPrice,
                        TotalPrice = configProductPrice,
                        TotalPriceAfterAllAdjustments = configProductPrice
                    ));
                }
                else {
                    lines[0].Product2Id = parser.getIdValue();
                }
            }
            if (currentName == null) {
                // Skip
            }
            else if (currentName.equalsIgnoreCase('ConfigurationId__c')) {
                configId = parser.getText();
                lines[0].ConfigurationId__c = configId;
            }
            else if (currentName.equalsIgnoreCase('Dynamic') && parser.getText().equalsIgnoreCase('Dynamic')) {
                iteratingOver = 'products';
            }
            else if (iteratingOver == 'products') {
                switch on currentName.toLowerCase() {   // Convert to lower case because sometimes quantity is Quantity
                    when 'productid' {
                        parser.nextToken();
                        if (parser.getCurrentToken() == JSONToken.VALUE_NULL) {
                            lineIndex = 0;  // configurableProduct comes with productId as null
                        }
                        else if (parser.getCurrentToken() == JSONToken.VALUE_STRING) {
                            productIdList.add(parser.getIdValue());
                            lines.add(new CartItem(
                                CartId = currentCart.cartId,
                                Product2Id = parser.getIdValue(),
                                Type = 'Product',
                                CartDeliveryGroupId = deliveryGroupId
                            ));
                        }
                    }
                    when 'quantity' {
                        parser.nextToken();
                        lines[lineIndex].Quantity = parser.getIntegerValue();
                        lineQuantity = lines[lineIndex].Quantity;
                    }
                    when 'sbqq__unitprice__c' {
                        parser.nextToken();
                        // There are multiple price fields on the CartItem, these seem like the most appropriate to update based on API name/description
                        if (parser.getCurrentToken() == JSonToken.VALUE_NUMBER_INT) {
                            lines[lineIndex].SalesPrice = parser.getIntegerValue();
                            lines[lineIndex].UnitAdjustedPrice = parser.getIntegerValue();
                        }
                        else if (parser.getCurrentToken() == JSonToken.VALUE_NUMBER_FLOAT) {
                            lines[lineIndex].SalesPrice = parser.getDecimalValue();
                            lines[lineIndex].UnitAdjustedPrice = parser.getDecimalValue();
                        }

                        lines[lineIndex].TotalLineAmount = lines[lineIndex].SalesPrice * lineQuantity;
                        lines[lineIndex].TotalLineAmount = lines[lineIndex].SalesPrice * lineQuantity;
                        lines[lineIndex].TotalPrice = lines[lineIndex].SalesPrice * lineQuantity;
                        lines[lineIndex].TotalPriceAfterAllAdjustments = lines[lineIndex].SalesPrice * lineQuantity;
                    }
                    when 'selected' {
                        parser.nextToken();
                        if (!parser.getBooleanValue() && lineIndex == 0) {
                            lineIndex++;
                        }
                    }
                    when 'configurationdata' {
                        if (parser.getCurrentToken() == JSONToken.END_OBJECT) {
                            lineIndex++;
                        }
                    }
                }
                if (parser.getCurrentName() == 'product' && parser.getCurrentToken() == JSONToken.END_OBJECT) {
                    iteratingOver = '';
                }
            }
        }

        // Reverse lines so they show in shopping cart in the "correct" order
        CartItem[] reversedLines = new CartItem[]{};
        Integer cartSize = lines.size();
        for (Integer i = cartSize - 1; i >= 0; i--) {
            reversedLines.add(lines[i]);
        }
        
        productMap = new Map<Id, Product2>([SELECT Id, Name FROM Product2 WHERE Id IN :productIdList WITH SECURITY_ENFORCED]);
        for (CartItem each : reversedLines) {
            each.Name = productMap.get(each.Product2Id).Name;
        }

        System.debug('Final list of lines, reversed: ' + reversedLines);
        
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
            try {
                insert reversedLines;
            } catch (DmlException de) {
                System.debug(de.getMessage());
            }
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
    public static String getVisualforceUrl(Id communityId, String accountId, String productId) {
        return '/apex/commerceConfigurationWindow?communityId=' + communityId + '&accountId=' + accountId + '&productId=' + productId;
    }
}