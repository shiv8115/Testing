const { expect } = require("chai");
const hre = require("hardhat");

describe("MarketPlace Contract Deploy and List Function1", function () {
  let Market;
  let Erc721;
  let Erc20;
  let ListedNFTInfo;
  let Buyer;
  let Seller;
  let Price;
  let nftSeller;
  const TOKEN_ID = 1;

  // Use a forked mainnet network
  beforeEach(async function () {
    await hre.network.provider.request({
      method: "hardhat_reset",
      params: [
        {
          forking: {
            jsonRpcUrl: "https://eth-mainnet.g.alchemy.com/v2/CR0jZfJoRngGFWeFojtEY23kLF9YijMA",
            blockNumber: 13414215 
          }
        }
      ]
    });

    // Get contract factories
    const ERC20 = await ethers.getContractFactory("MyToken");
    const ERC721 = await ethers.getContractFactory("NFT");
    const MarketPlace = await ethers.getContractFactory("market");

    // Deploy contracts
    Erc20 = await ERC20.deploy();
    await Erc20.deployed();
    Erc721 = await ERC721.deploy();
    await Erc721.deployed();
    Market = await MarketPlace.deploy(Erc20.address);
    await Market.deployed();

    // Mint NFT to NFTSeller
    const [NFTSeller] = await ethers.getSigners();
    nftSeller = NFTSeller;
    await Erc721.connect(nftSeller).Safemint();
  });

  it("Market approved by NFT", async function () {
    await Erc20.approve(Market.address, 1000);
    await Erc721.approve(Market.address, TOKEN_ID);
    expect(await Erc721.getApproved(TOKEN_ID)).to.equal(Market.address);
  });

  it("Listing Items", async function () {
    await Erc721.connect(nftSeller).approve(Market.address, TOKEN_ID);
    await Market.listItem(Erc721.address, TOKEN_ID, 50, 1, 1);

    // Use the getListing function to retrieve the listing from the marketplace
    const listing = await Market.getListing(Erc721.address, TOKEN_ID);

    // Assert that the listing was created correctly
    expect(listing.nftAddress).to.equal(Erc721.address);
    expect(listing.seller).to.equal(nftSeller.address);
    expect(listing.price).to.equal(50);
    expect(listing.quantity).to.equal(1);
  });
});
