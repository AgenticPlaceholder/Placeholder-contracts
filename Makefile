include .env
export

deploy:
	forge script script/DeployPlaceholderAds.s.sol:DeployPlaceholderAds --rpc-url  https://sepolia.base.org --broadcast --verify

psdt: 
	forge script script/MintStableCoin.s.sol --rpc-url  https://sepolia.base.org --broadcast

approve:
	forge script script/ApproveMarketplace.s.sol --rpc-url  https://sepolia.base.org --broadcast
	
check-approve:
	forge script script/CheckApprovals.s.sol --rpc-url  https://sepolia.base.org --broadcast
	
mint-ad1:
	forge script script/MintAd.s.sol:MintAdScript --private-key $$PRIVATE_KEY_1 --rpc-url https://sepolia.base.org --broadcast

mint-ad2:
	forge script script/MintAd.s.sol:MintAdScript --private-key $$PRIVATE_KEY_2 --rpc-url https://sepolia.base.org --broadcast	

mint-ad3:
	forge script script/MintAd.s.sol:MintAdScript --private-key $$PRIVATE_KEY_3 --rpc-url https://sepolia.base.org --broadcast		

start-auction:
	forge script script/StartAuctionScript.s.sol:StartAuctionScript --rpc-url https://sepolia.base.org --broadcast	

bid1:
	forge script script/PlaceBid.s.sol --private-key $$PRIVATE_KEY_1 --rpc-url https://sepolia.base.org --broadcast

bid2:
	forge script script/PlaceBid.s.sol --private-key $$PRIVATE_KEY_2 --rpc-url https://sepolia.base.org --broadcast

bid3: 
	forge script script/PlaceBid.s.sol --private-key $$PRIVATE_KEY_3 --rpc-url https://sepolia.base.org --broadcast	