// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";

contract FakeNFTMarketplace is Ownable {
    // mapping of FakeTokenID to Owner Address
    mapping(uint256 => address) public tokens;

    // FakeNFT price
    uint256 nftPrice = 0.1 ether;

    address public daoContract;

    modifier onlyDao() {
        require(daoContract != address(0), "undefined DAO contract Address");
        require(daoContract == msg.sender, "Only DAO is executable");
        _;
    }

    function purchase(uint256 _tokenId) external payable onlyDao {
        require(msg.value == nftPrice, "This NFT consts 0.1 ether");

        tokens[_tokenId] = msg.sender;
    }

    function getPrice() external view returns (uint256) {
        return nftPrice;
    }

    // available() check whether given tokenID has already sold or not
    function available(uint256 _tokenId) external view returns (bool) {
        if (tokens[_tokenId] == address(0)) {
            return true;
        }
        return false;
    }

    function setDAOContract(address _daoContract) external onlyOwner {
        daoContract = _daoContract;
    }

    function getOwnerContract() public view returns (address) {
        return daoContract;
    }

    receive() external payable {}

    fallback() external payable {}
}
