// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

// Upgradable NFT Dutch Auction with ERC20 bids
contract NFTDutchAuction_Upgradable is
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable
{
    address payable public seller;
    uint256 public reservePrice;
    uint256 public numBlocksAuctionOpen;
    uint256 public offerPriceDecrement;
    uint256 public initialPrice;
    uint256 public startBlock;
    bool public isEnded;
    address public winner;
    // mapping (address => uint) public bids;
    // address [] public bidders;

    IERC721 public nftMinter;
    uint256 public nftTokenId;

    IERC20 public tUSDFaucet;

    // event BidSucceeded(address winner, uint256 bidAmount);
    // event AuctionSucceeded(address winner, uint256 finalAuctionPrice);

    modifier isOpenning() {
        require(!isEnded, "Auction has ended");
        _;
    }

    function initialize(
        uint256 _reservePrice,
        uint256 _numBlocksAuctionOpen,
        uint256 _offerPriceDecrement,
        address erc721TokenAddress,
        uint256 _nftTokenId,
        address erc20TokenAddress
    ) public initializer {
        seller = payable(msg.sender);
        reservePrice = _reservePrice;
        numBlocksAuctionOpen = _numBlocksAuctionOpen;
        offerPriceDecrement = _offerPriceDecrement;
        initialPrice =
            reservePrice +
            numBlocksAuctionOpen *
            offerPriceDecrement;
        startBlock = block.number;
        isEnded = false;

        nftMinter = IERC721(erc721TokenAddress);
        nftTokenId = _nftTokenId;

        tUSDFaucet = IERC20(erc20TokenAddress);

        __UUPSUpgradeable_init();
        __Ownable_init();
    }

    function bid(uint bidAmount) public payable isOpenning returns (address) {
        require(
            block.number < startBlock + numBlocksAuctionOpen,
            "Auction expired"
        );
        require(
            bidAmount >= reservePrice,
            "Bid should be no less than the reserve price"
        );
        require(
            bidAmount >= currentPrice(),
            "Bid should be no less than the current price"
        );

        require(
            tUSDFaucet.allowance(msg.sender, address(this)) >= bidAmount,
            "The bidder has not approved enough TUSD allowance for the auction"
        );
        require(
            tUSDFaucet.balanceOf(msg.sender) >= bidAmount,
            "Bidder does not have enough TUSD balance"
        );

        // register the bids
        // bids[msg.sender] = bidAmount;
        // bidders.push(msg.sender);

        winner = msg.sender;
        finalize(currentPrice());

        // if (bidAmount >= currentPrice()) {
        //     winner = msg.sender;
        //     finalize(currentPrice());
        // } else {
        //     winner = address(0); // no winner yet
        // }

        // emit AuctionSucceeded(winner, currentPrice());
        return winner;
    }

    function currentPrice() public view returns (uint256) {
        uint256 elapsedBlocks = block.number - startBlock;
        return initialPrice - elapsedBlocks * offerPriceDecrement;
    }

    function finalize(uint256 finalAuctionPrice) internal {
        // mark auction as ended
        isEnded = true;
        // transfer the ERC20 token of final Auction Price to the seller
        tUSDFaucet.transferFrom(winner, seller, finalAuctionPrice);

        // emit AuctionSucceeded(winner, finalAuctionPrice);

        // for (uint i = 0; i < bidders.length; i++) {
        //     if (bidders[i] == winner) {
        //         // transfer the ERC20 token of final Auction Price to the seller
        //         bids[winner] = 0;
        //         tUSDFaucet.transferFrom(winner, seller, finalAuctionPrice);
        //     } else {
        //         // refund the other bidders
        //         uint256 refundAmount = bids[bidders[i]];
        //         bids[bidders[i]] = 0;
        //         tUSDFaucet.transferFrom(address(this), bidders[i], refundAmount);
        //     }
        // }

        // transfer the NFT to the winner
        nftMinter.safeTransferFrom(address(seller), winner, nftTokenId);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
