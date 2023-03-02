// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract market is ReentrancyGuard{   
    /**
 * @dev Struct for listing an NFT in the marketplace.
 * @param nftAddress Address of the NFT contract.
 * @param seller Address of the NFT seller.
 * @param tokenId ID of the NFT token.
 * @param price Price of the NFT token.
 * @param quantity Quantity of the NFT tokens.
 * @param nftType Type of the NFT contract (ERC721 or ERC1155).
 */
    struct Listing{
        address nftAddress;
        address seller;
        uint256 tokenId;
        uint256 price;
        uint256 quantity;
        uint256 nftType;
    }

/**
 * @dev Event for listing an NFT in the marketplace.
 * @param seller Address of the NFT seller.
 * @param nftAddress Address of the NFT contract.
 * @param tokenId ID of the NFT token.
 * @param price Price of the NFT token.
 */
    event ItemListed(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
    );
// Address of the marketplace owner.
   address payable private Owner;

   address NFT20; // // Address of the ERC20 token used for fees

   // Mapping of NFT listings.
   mapping(address => mapping(uint256 => Listing)) private s_listings;

   // Mapping of NFT seller proceeds.
   mapping(address => uint256) private s_proceeds;


/**
 * @dev Constructor function for initializing the marketplace.
 * @param nft20 Address of the ERC20 token used for fees.
 */
   constructor(address nft20){
       Owner= payable(msg.sender);
       NFT20= nft20;
   }
/**
 * @dev Modifier to check if an NFT is not already listed in the marketplace.
 * @param nftAddress Address of the NFT contract.
 * @param tokenId ID of the NFT token.
 * @param owner Address of the NFT owner.
 */
   modifier notListed(address nftAddress,uint256 tokenId,address owner) {
        Listing memory listing = s_listings[nftAddress][tokenId];
        if (listing.price > 0) {
            revert("This is already listed");
        }
        _;
    }
/**
 * @dev Modifier to check if an NFT is listed in the marketplace.
 * @param nftAddress Address of the NFT contract.
 * @param tokenId ID of the NFT token.
 */
    modifier isListed(address nftAddress, uint256 tokenId) {
        Listing memory listing = s_listings[nftAddress][tokenId];
        if (listing.price <= 0) {
            revert("Not listed");
        }
        _;
    }

/**

@dev Lists an NFT on the marketplace with the specified details.
@param nftAddress The address of the NFT contract.
@param tokenId The ID of the NFT to list.
@param price The price of the NFT.
@param quantity The quantity of the NFT to list.
@param nftType The type of the NFT, either 1 for NFT721 or 2 for NFT1155.
*/

    function listItem(address nftAddress,uint256 tokenId,uint256 price, uint256 quantity,uint256 nftType) external
    notListed(nftAddress, tokenId, msg.sender) 
    {  
        //for NFT721
        if(nftType==1){
        IERC721 nft = IERC721(nftAddress);
        require(nft.ownerOf(tokenId)==msg.sender, "You are not owner of token");
       
        if (nft.getApproved(tokenId) != address(this)) {
            revert("Not approve for market place");
        }
        s_listings[nftAddress][tokenId] = Listing(nftAddress,msg.sender,tokenId, price, quantity, nftType);
        emit ItemListed(msg.sender, nftAddress, tokenId, price); 
        }
        //for NFT1155
        if(nftType==2){
            s_listings[nftAddress][tokenId] = Listing(nftAddress,msg.sender,tokenId, price, quantity, nftType);
            emit ItemListed(msg.sender, nftAddress, tokenId, price); 
        }       
    }
/**

@dev Allows a user to buy an NFT from the marketplace
@param nftAddress The address of the NFT contract
@param tokenId The ID of the NFT to be bought
@param _amount The quantity of the NFT to be bought (for NFT1155)
*/
    function buyItem(address nftAddress, uint256 tokenId, uint256 _amount)
        external
        payable
        isListed(nftAddress, tokenId)
        nonReentrant
    {
        Listing memory listedItem = s_listings[nftAddress][tokenId];
        if (msg.value < listedItem.price) {
            revert("Insufficient balance");
        }
        require(listedItem.quantity >= _amount, "Required quantity not available");
        
        s_proceeds[listedItem.seller] += (listedItem.price);

        if(listedItem.nftType == 1) {
        IERC721(nftAddress).safeTransferFrom(listedItem.seller, msg.sender, tokenId);
    }
         else if(listedItem.nftType == 2) {
        ERC1155(nftAddress).safeTransferFrom(listedItem.seller ,msg.sender, tokenId,_amount,"");
    }  
    // Remove listing and take fees
    delete (s_listings[nftAddress][tokenId]);
    Owner.transfer((listedItem.price * 55)/10000);
    }

    function getProceeds(address seller) external view returns (uint256) {
        return s_proceeds[seller];
    }

/**

@dev Returns the details of a specific NFT listing.
@param nftAddress The address of the NFT contract.
@param tokenId The ID of the NFT being listed.
@return A Listing struct.
*/
    function getListing(address nftAddress, uint256 tokenId)
        external
        view
        returns (Listing memory)
    {
        return s_listings[nftAddress][tokenId];
    }
}