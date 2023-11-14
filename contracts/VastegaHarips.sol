// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../libs/ERC721.sol";
import "../libs/Strings.sol";
import "../libs/Owned.sol";

contract VastegaHarips is ERC721, Owned {
    using Strings for uint256;

    //// STORAGE ////

    // Metadata
    string private _baseURI = "https://vastega.io/meta/";

    // Presale
    mapping(address => bool) public wlUsed;
    address public operator;

    uint256 constant public MAX_SUPPLY = 5555;
    uint256 public supply;
    uint256 public publicSalePrice = 0.05 ether;

    //// CONSTRUCTOR ////

    constructor(
        address operator_
    ) ERC721("Vastega: Harips", "HRPS") Owned(msg.sender) {
        operator = operator_;
    }

    //// ERC721 OVERRIDES ////

    function tokenURI(
        uint256 id_
    ) public view override returns (string memory) {
        return string.concat(_baseURI, id_.toString());
    }

    //// MINT ////

    function mint(
        address to_,
        uint256 amount_,
        uint256 price_,
        bytes memory signature_
    ) public payable {

        if (signature_.length == 0) {
            price_ = publicSalePrice;
        } else {
            require(!wlUsed[to_], "Vastega: WL already used");
            wlUsed[to_] = true;
            bytes memory prefix = "\x19Ethereum Signed Message:\n32";
            _verifySignature(
                keccak256(abi.encodePacked(prefix, keccak256(abi.encodePacked(to_, amount_, price_)))),
                signature_
            );
        }

        require(msg.value >= price_*amount_, "Vastega: Wrong msg.value");
        uint256 id_ = supply + amount_;
        require(id_ <= MAX_SUPPLY, "Vastega: Max supply reached");
        supply = id_;
        _mint(to_, id_);
    }

    //// ONLY OWNER ////

    function setPublicSalePrice(
        uint256 publicSalePrice_
    ) public onlyOwner {
        publicSalePrice = publicSalePrice_;
    }

    function setBaseURI(
        string memory baseURI_
    ) public onlyOwner {
        _baseURI = baseURI_;
    }

    function setOperator(
        address operator_
    ) public onlyOwner {
        operator = operator_;
    }

    function withdraw() public onlyOwner {
        (bool sent,) = owner.call{value: address(this).balance}("");
        require(sent);
    }

    //// PRIVATE ////

    function _verifySignature(
        bytes32 hash,
        bytes memory signature
    ) private view {
        require(signature.length == 65, "INVALID_SIGNATURE_LENGTH");

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := and(mload(add(signature, 65)), 255)
        }

        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "INVALID_SIGNATURE_S_PARAMETER");
        require(v == 27 || v == 28, "INVALID_SIGNATURE_V_PARAMETER");

        require(ecrecover(hash, v, r, s) == operator, "INVALID_SIGNER");
    }

}
