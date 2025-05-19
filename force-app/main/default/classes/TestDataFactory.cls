@isTest
public with sharing class TestDataFactory {
    public static Account createAccount(String newAccountCode, Boolean doInsert) {
        // Account account = new Account(Name = 'TestAccount-' + newAccountCode, AccountCode__c = newAccountCode);
        Account account = new Account(Name = 'TestAccount-' + newAccountCode);
        if (doInsert) {
            insert account;
        }
        return account;
    }

    public static PriceTable__c createPriceTable(Id accountId, Boolean doInsert) {
        PriceTable__c priceTable = new PriceTable__c(
            Name = 'Test Price Table',
            Account__c = accountId,
            CarryOutDate__c = Date.today(),
            PriceTableType__c = 'Charter',
            Active__c = true
        );
        if (doInsert) {
            insert priceTable;
        }
        return priceTable;
    }

    public static OriginDestination__c createOriginDestination(Id accountId, Boolean doInsert) {
        OriginDestination__c originDest = new OriginDestination__c(
            Account__c = accountId,
            Prefecture__c = '19',
            City__c = 'Shibuya',
            Street__c = 'Test Street'
        );
        if (doInsert) {
            insert originDest;
        }
        return originDest;
    }

    public static OrderHeader__c createOrderHeader(
        String accountId,
        String originId,
        String destinationId,
        Boolean doInsert
    ) {
        OrderHeader__c order = new OrderHeader__c(
            QuantityForShippingFeeCal__c = 10,
            UnitForShippingFeeCal__c = 'Ton',
            TransportationMode__c = 'Charter',
            Status__c = 'Reception'
        );
        if (!String.isBlank(accountId)) {
            order.Account__c = accountId;
        }
        if (!String.isBlank(originId)) {
            order.OriginPlace__c = originId;
        }
        if (!String.isBlank(destinationId)) {
            order.Destination__c = destinationId;
        }
        if (doInsert) {
            insert order;
        }
        return order;
    }

    public static ShippingFee__c createShippingFee(
        String accountId,
        Id priceTableId,
        String destinationId,
        Boolean doInsert
    ) {
        ShippingFee__c shippingFee = new ShippingFee__c(
            PriceTable__c = priceTableId,
            MinQuantity__c = 5,
            MaxQuantity__c = 20,
            FixedFeeFlag__c = false,
            Memo__c = 'Test Memo',
            Unit__c = 'Ton',
            AncillaryWorkFee__c = 10000,
            SubcontractFee__c = 1000,
            ShippingFee__c = 5000,
            OriginPrefecture__c = '19',
            ArrivalPrefecture__c = 'Tokyo',
            ArrivalCity__c = 'Shibuya',
            ArrivalStreet__c = 'Test Street',
            Active__c = true
        );
        if (!String.isBlank(destinationId)) {
            shippingFee.Destination__c = destinationId;
        }
        if (doInsert) {
            insert shippingFee;
        }
        return shippingFee;
    }
}