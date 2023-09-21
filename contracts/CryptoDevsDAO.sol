// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ICryptoDevsNFT.sol";
import "./interfaces/IFakeNFTMarketplace.sol";

contract CryptoDevsDAO is Ownable {
    struct Proposal {
        uint256 nftTokenId;
        uint256 deadline;
        uint256 yayVotes;
        uint256 nayVotes;
        bool executed;
        // mapping of CryptoDevsNFT tokenIDs to booleans inidicationg whether that NFT has already been used or not
        mapping(uint256 => bool) voters;
    }

    enum Vote {
        YAY,
        NAY
    }

    // mapping of IDs to Proposal
    mapping(uint256 => Proposal) public proposals;

    uint256 public numProposals;

    ICryptoDevsNFT cryptoDevsNFT;
    IFakeNFTMarketplace nftMarketplace;

    constructor(address _nftMarletplace, address _cryptoDevNFT) payable {
        nftMarketplace = IFakeNFTMarketplace(_nftMarletplace);
        cryptoDevsNFT = ICryptoDevsNFT(_cryptoDevNFT);
    }

    modifier nftHolderOnly() {
        require(cryptoDevsNFT.balanceOf(msg.sender) > 0, "NOT_A_DAO_MEMBER");
        _;
    }

    modifier activeProposalOnly(uint256 proposalIndex) {
        require(
            proposals[proposalIndex].deadline > block.timestamp,
            "DEADLINE_EXCEEDED"
        );
        _;
    }

    modifier executableProposalOnly(uint256 proposalIndex) {
        require(
            proposals[proposalIndex].deadline <= block.timestamp,
            "DEADLINE_NOT_EXCEEDED"
        );
        require(
            proposals[proposalIndex].executed == false,
            "PROPOSAL_ALREADY_EXCUTED"
        );
        _;
    }

    function createProposal(
        uint256 _nftTokenId
    ) external nftHolderOnly returns (uint256) {
        require(nftMarketplace.available(_nftTokenId), "NFT_NOT_FOR_SALE");
        Proposal storage proposal = proposals[numProposals];
        proposal.nftTokenId = _nftTokenId;
        proposal.deadline = block.timestamp + 5 minutes;

        numProposals++;
        return numProposals - 1;
    }

    function voteProposal(
        uint256 proposalIndex,
        Vote vote
    ) external nftHolderOnly activeProposalOnly(proposalIndex) {
        Proposal storage proposal = proposals[proposalIndex];

        uint256 voteNFTBalance = cryptoDevsNFT.balanceOf(msg.sender);
        uint256 numVotes = 0;

        for (uint256 i = 0; i < voteNFTBalance; i++) {
            uint256 tokenId = cryptoDevsNFT.tokenOfOwnerByIndex(msg.sender, i);
            if (proposal.voters[tokenId] == false) {
                numVotes++;
                proposal.voters[tokenId] == true;
            }
        }
        require(numVotes > 0, "ALREADY_VOTED");

        if (vote == Vote.YAY) {
            proposal.yayVotes += numVotes;
        } else {
            proposal.nayVotes += numVotes;
        }
    }

    function executeProposal(
        uint256 proposalIndex
    ) external nftHolderOnly executableProposalOnly(proposalIndex) {
        Proposal storage proposal = proposals[proposalIndex];

        if (proposal.yayVotes > proposal.nayVotes) {
            uint256 nftPrice = nftMarketplace.getPrice();
            require(address(this).balance >= nftPrice, "NOT_ENOUGH_FUNDS");
            nftMarketplace.purchase{value: nftPrice}(proposal.nftTokenId);
        }
        proposal.executed = true;
    }

    function checkProposalExecute(
        uint256 proposalIndex
    ) external view returns (bool) {
        return proposals[proposalIndex].executed;
    }

    function withdrawEther() external onlyOwner {
        uint256 amount = address(this).balance;
        require(amount > 0, "Nothing to withdraw, contract balance empty.");
        (bool sent, ) = owner().call{value: amount}("");
        require(sent, "FAILED_TO_WITHDRAW_ETHER");
    }

    receive() external payable {}

    fallback() external payable {}
}
