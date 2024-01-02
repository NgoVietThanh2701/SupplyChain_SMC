// SPDX-License-Identifier: NONE
pragma solidity ^0.8.19;

import "./Structure.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol"; /*revert when transaction failed */
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SupplyChain {
    IERC20 private token;
    uint uid;
    address public admin;

    mapping(uint256 => Structure.Product) products;
    mapping(Structure.Roles => address[]) roles;

    constructor(address _admin, IERC20 _token) {
        admin = _admin;
        token = _token;
        uid = 1;
    }

    event Harvested(uint uid);
    event PurchasedByThirdParty(uint256 uid);
    event ShippedByFarmer(uint256 uid);
    event ReceivedByThirdParty(uint256 uid);
    event SoldByThirdParty(uint256 uid);
    event PurchasedByCustomer(uint256 uid);
    event ShippedByThirdParty(uint256 uid);
    event ReceivedByDeliveryHub(uint256 uid);
    event ShippedByDeliveryHub(uint256 uid);
    event ReceivedByCustomer(uint256 uid);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Sender is not a admin");
        _;
    }

    /* check sender is a ownerProduct or not*/
    modifier verifyAddress(address _address) {
        require(msg.sender == _address, "Sender is not owner product");
        _;
    }

    modifier harvested(uint256 _uid) {
        require(products[_uid].productState == Structure.State.Harvested);
        _;
    }

    modifier purchasedByThirdParty(uint256 _uid) {
        require(
            products[_uid].productState == Structure.State.PurchasedByThirdParty
        );
        _;
    }

    modifier shippedByFarmer(uint256 _uid) {
        require(products[_uid].productState == Structure.State.ShippedByFarmer);
        _;
    }

    modifier receivedByThirdParty(uint256 _uid) {
        require(
            products[_uid].productState == Structure.State.ReceivedByThirdParty
        );
        _;
    }

    modifier soldByThirdParty(uint256 _uid) {
        require(
            products[_uid].productState == Structure.State.SoldByThirdParty
        );
        _;
    }

    modifier purchasedByCustomer(uint256 _uid) {
        require(
            products[_uid].productState == Structure.State.PurchasedByCustomer
        );
        _;
    }

    modifier shippedByThirdParty(uint256 _uid) {
        require(
            products[_uid].productState == Structure.State.ShippedByThirdParty
        );
        _;
    }

    modifier receivedByDeliveryHub(uint256 _uid) {
        require(
            products[_uid].productState == Structure.State.ReceivedByDeliveryHub
        );
        _;
    }

    modifier shippedByDeliveryHub(uint256 _uid) {
        require(
            products[_uid].productState == Structure.State.ShippedByDeliveryHub
        );
        _;
    }

    modifier receivedByCustomer(uint256 _uid) {
        require(
            products[_uid].productState == Structure.State.ReceivedByCustomer
        );
        _;
    }

    /* check code of product is exist or not */
    function checkProductCode(string memory _code) public view returns (bool) {
        for (uint256 i = 1; i <= uid; i++) {
            if (
                keccak256(bytes(products[i].productDetails.code)) ==
                keccak256(bytes(_code))
            ) {
                return true;
            }
        }
        return false;
    }

    function addFarmer(address _account) public onlyAdmin {
        require(_account != address(0));
        roles[Structure.Roles.Farmer].push(_account);
    }

    function isFarmer(address _account) public view returns (bool) {
        require(_account != address(0));
        address[] memory farmers = roles[Structure.Roles.Farmer];
        for (uint256 i = 0; i < farmers.length; i++) {
            if (farmers[i] == _account) {
                return true;
            }
        }
        return false;
    }

    function addThirdParty(address _account) public onlyAdmin {
        require(_account != address(0));
        roles[Structure.Roles.ThirdParty].push(_account);
    }

    function isThirdParty(address _account) public view returns (bool) {
        require(_account != address(0));
        address[] memory thirdPartys = roles[Structure.Roles.ThirdParty];
        for (uint256 i = 0; i < thirdPartys.length; i++) {
            if (thirdPartys[i] == _account) {
                return true;
            }
        }
        return false;
    }

    function addDeliveryHub(address _account) public onlyAdmin {
        require(_account != address(0));
        roles[Structure.Roles.DeliveryHub].push(_account);
    }

    function isDeliveryHub(address _account) public view returns (bool) {
        require(_account != address(0));
        address[] memory deliveryHubs = roles[Structure.Roles.DeliveryHub];
        for (uint256 i = 0; i < deliveryHubs.length; i++) {
            if (deliveryHubs[i] == _account) {
                return true;
            }
        }
        return false;
    }

    function addCustomer(address _account) public {
        require(_account != address(0));
        roles[Structure.Roles.Customer].push(_account);
    }

    function isCustomer(address _account) public view returns (bool) {
        require(_account != address(0));
        address[] memory customers = roles[Structure.Roles.Customer];
        for (uint256 i = 0; i < customers.length; i++) {
            if (customers[i] == _account) {
                return true;
            }
        }
        return false;
    }

    /// @dev Step 1: Harvesred a product
    function harvestedProduct(
        string memory _name,
        string memory _code,
        uint256 _price,
        string memory _category,
        string memory _images,
        string memory _description,
        uint256 _quantity,
        string memory _longitude,
        string memory _latitude,
        string memory _temp,
        uint32 _humidity,
        string memory _farmerCode
    ) public {
        require(isFarmer(msg.sender), "Sender is not a Farmer!");
        Structure.Product memory product;
        product.uid = uid;
        product.owner = msg.sender;
        /* set role for farmer */
        product.farmerDetails.farmer = msg.sender;
        product.farmerDetails.farmerCode = _farmerCode;
        product.farmerDetails.longitude = _longitude;
        product.farmerDetails.latitude = _latitude;
        /* set details for product*/
        product.productDetails.name = _name;
        product.productDetails.code = _code;
        product.productDetails.price = _price;
        product.productDetails.category = _category;
        product.productDetails.images = _images;
        product.productDetails.description = _description;
        product.productDetails.quantity = _quantity;
        product.productDetails.temp = _temp;
        product.productDetails.humidity = _humidity;
        product.productDetails.date = block.timestamp;
        /* set state for product */
        product.productState = Structure.State.Harvested;

        products[uid] = product;
        emit Harvested(uid);
        uid++;
    }

    /// @dev Step 2: Purchase product from Third Party
    function purchaseByThirdParty(
        uint256 _uid,
        string memory _thirdPartyCode
    ) public harvested(_uid) {
        require(isThirdParty(msg.sender), "Sender is not a Third Party");
        require(
            token.balanceOf(msg.sender) >= products[_uid].productDetails.price,
            "Insufficient account balance"
        );
        SafeERC20.safeTransferFrom(
            token,
            msg.sender,
            address(this),
            products[_uid].productDetails.price
        );
        products[_uid].thirdPartyDetails.thirdParty = msg.sender;
        products[_uid].thirdPartyDetails.thirdPartyCode = _thirdPartyCode;
        products[_uid].productState = Structure.State.PurchasedByThirdParty;

        emit PurchasedByThirdParty(_uid);
    }

    /// @dev Step 3: Farmer shipping of product purchased to Third Party
    function shipByFarmer(
        uint256 _uid
    ) public purchasedByThirdParty(_uid) verifyAddress(products[_uid].owner) {
        require(isFarmer(msg.sender), "Sender is not a Farmer");
        products[_uid].productState = Structure.State.ShippedByFarmer;

        emit ShippedByFarmer(_uid);
    }

    /// @dev Step 4: Third Party received product from Farmer
    function receiveByThirdParty(
        uint256 _uid,
        string memory _longitude,
        string memory _latitude
    )
        public
        shippedByFarmer(_uid)
        verifyAddress(products[_uid].thirdPartyDetails.thirdParty)
    {
        require(isThirdParty(msg.sender));
        products[_uid].owner = msg.sender;
        products[_uid].thirdPartyDetails.longitude = _longitude;
        products[_uid].thirdPartyDetails.latitude = _latitude;
        products[_uid].productState = Structure.State.ReceivedByThirdParty;

        SafeERC20.safeTransfer(
            token,
            products[_uid].farmerDetails.farmer,
            products[_uid].productDetails.price
        );

        emit ReceivedByThirdParty(_uid);
    }

    /// @dev step 5: Third party add attributes for sold product
    function sellByThirdParty(
        uint256 _uid,
        uint256 _price
    ) public receivedByThirdParty(_uid) verifyAddress(products[_uid].owner) {
        require(isThirdParty(msg.sender), "Sender is not a Third party");
        products[_uid].productDetails.priceThirdParty = _price;
        products[_uid].productState = Structure.State.SoldByThirdParty;

        emit SoldByThirdParty(_uid);
    }

    /// @dev Step 6: Customer buy product of Third Party
    function purchaseByCustomer(
        uint256 _uid,
        uint256 _feeShip,
        string memory _addressShip,
        string memory _customerCode
    ) public soldByThirdParty(_uid) {
        require(isCustomer(msg.sender), "Sender is not a Customer");
        products[_uid].customerDetails.customer = msg.sender;
        products[_uid].customerDetails.customerCode = _customerCode;
        products[_uid].customerDetails.feeShip = _feeShip;
        products[_uid].customerDetails.addressShip = _addressShip;
        products[_uid].productState = Structure.State.PurchasedByCustomer;

        uint256 totalPrice = products[_uid].productDetails.priceThirdParty +
            _feeShip;

        SafeERC20.safeTransferFrom(
            token,
            msg.sender,
            address(this),
            totalPrice
        );

        emit PurchasedByCustomer(_uid);
    }

    /// @dev Step 7: Third Party shipping product purchased by Customer to Delivery Hub
    function shipByThirdParty(
        uint256 _uid
    ) public purchasedByCustomer(_uid) verifyAddress(products[_uid].owner) {
        require(isThirdParty(msg.sender), "Sender is not a Third Party");
        products[_uid].productState = Structure.State.ShippedByThirdParty;

        emit ShippedByThirdParty(_uid);
    }

    /// @dev Step 8: Delivery hub receive product of purchased customer from Third Party shipped
    function receiveByDeliveryHub(
        uint256 _uid,
        string memory _longitude,
        string memory _latitude,
        string memory _deliveryHubCode
    ) public shippedByThirdParty(_uid) {
        require(isDeliveryHub(msg.sender), "Sender is not a Delivery Hub");
        products[_uid].owner = msg.sender;
        products[_uid].deliveryHubDetails.deliveryHub = msg.sender;
        products[_uid].deliveryHubDetails.deliveryHubCode = _deliveryHubCode;
        products[_uid].deliveryHubDetails.longitude = _longitude;
        products[_uid].deliveryHubDetails.latitude = _latitude;
        products[_uid].productState = Structure.State.ReceivedByDeliveryHub;

        emit ReceivedByDeliveryHub(_uid);
    }

    /// @dev Step 9: Delivery hub shipped product to Customer
    function shipByDeliveryHub(
        uint256 _uid
    ) public verifyAddress(products[_uid].owner) receivedByDeliveryHub(_uid) {
        require(isDeliveryHub(msg.sender), "Sender is not a Delivery Hub");
        products[_uid].productState = Structure.State.ShippedByDeliveryHub;

        emit ShippedByDeliveryHub(_uid);
    }

    /// @dev Step 10: Customer receive product from Delivery hub
    function receiveByCustomer(
        uint256 _uid
    )
        public
        shippedByDeliveryHub(_uid)
        verifyAddress(products[_uid].customerDetails.customer)
    {
        require(isCustomer(msg.sender), "Sender is not a customer");
        uint256 amountThirdParty = products[_uid]
            .productDetails
            .priceThirdParty -
            (products[_uid].productDetails.priceThirdParty / 10);
        SafeERC20.safeTransfer(
            token,
            products[_uid].thirdPartyDetails.thirdParty,
            amountThirdParty
        );
        uint256 amountDeliveryHub = products[_uid].customerDetails.feeShip -
            (products[_uid].customerDetails.feeShip / 10);
        SafeERC20.safeTransfer(
            token,
            products[_uid].deliveryHubDetails.deliveryHub,
            amountDeliveryHub
        );
        products[_uid].owner = msg.sender;
        products[_uid].productState = Structure.State.ReceivedByCustomer;

        emit ReceivedByCustomer(_uid);
    }

    /// @dev Get all product
    function getProducts() public view returns (Structure.Product[] memory) {
        Structure.Product[] memory listProduct = new Structure.Product[](
            uid - 1
        );
        for (uint256 i = 1; i < uid; i++) {
            listProduct[i - 1] = products[i];
        }
        return listProduct;
    }

    ///@dev Get product by code
    function getProductByCode(
        string memory _code
    ) public view returns (Structure.Product memory) {
        require(checkProductCode(_code), "Code product is not exists");
        uint256 idProduct;
        for (uint256 i = 1; i < uid; i++) {
            if (
                keccak256(bytes(products[i].productDetails.code)) ==
                keccak256(bytes(_code))
            ) {
                idProduct = i;
            }
        }

        return products[idProduct];
    }

    function getProductCount() public view returns (uint256) {
        return uid - 1;
    }

    function getProductState(
        uint256 _uid
    ) public view returns (Structure.State) {
        return products[_uid].productState;
    }
}
