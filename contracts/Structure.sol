// SPDX-License-Identifier: NONE
pragma solidity ^0.8.19;

library Structure {
    enum State {
        Harvested,
        PurchasedByThirdParty,
        ShippedByFarmer,
        ReceivedByThirdParty,
        SoldByThirdParty,
        PurchasedByCustomer,
        ShippedByThirdParty,
        ReceivedByDeliveryHub,
        ShippedByDeliveryHub,
        ReceivedByCustomer
    }

    struct ProductDetails {
        string name;
        string code;
        uint256 price;
        uint256 priceThirdParty;
        string category;
        string images;
        string description;
        uint256 quantity;
        string temp;
        uint32 humidity;
        uint256 date;
    }

    struct FarmerDetails {
        address farmer;
        string farmerCode;
        string longitude;
        string latitude;
    }

    struct ThirdPartyDetails {
        address thirdParty;
        string thirdPartyCode;
        string longitude;
        string latitude;
    }

    struct DeliveryHubDetails {
        address deliveryHub;
        string deliveryHubCode;
        string longitude;
        string latitude;
    }

    struct CustomerDetails {
        address customer;
        string customerCode;
        uint256 feeShip;
        string addressShip;
    }

    struct Product {
        uint256 uid;
        address owner;
        State productState;
        FarmerDetails farmerDetails;
        ThirdPartyDetails thirdPartyDetails;
        DeliveryHubDetails deliveryHubDetails;
        CustomerDetails customerDetails;
        ProductDetails productDetails;
    }

    enum Roles {
        Farmer,
        ThirdParty,
        DeliveryHub,
        Customer
    }
}
