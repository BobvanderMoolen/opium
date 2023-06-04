// @ts-nocheck
import { assert, near } from "near-sdk-js";
import { Color, Contract, NFT_METADATA_SPEC, NFT_STANDARD_NAME, Player } from ".";
import { internalAddTokenToOwner, refundDeposit } from "./internal";
import { Token, TokenMetadata } from "./metadata";
export function getRandomENumValue<T>(enumeration: T): T[keyof T]{
    const enumvalues = Object.values(enumeration);
    const randomIndex = Math.floor(Math.random() * enumvalues.length);
    return enumvalues[randomIndex];
}
export function internalMint({
    contract,
    tokenId,
    metadata,
    receiverId,
    perpetualRoyalties
}:{ 
    contract: Contract, 
    tokenId: string, 
    metadata: TokenMetadata, 
    receiverId: string 
    perpetualRoyalties: {[key: string]: number}
}): void {
    //measure the initial storage being used on the contract TODO
    let initialStorageUsage = near.storageUsage();
    let playerCalling = near.predecessorAccountId();
    
    const playerToSafe : Player = {color: getRandomENumValue(Color), isMinted: true, isPlaced: false, pixellocation: {0:{x:0, y:0,z:0}}};
    contract.players[playerCalling] = playerToSafe;

    // create a royalty map to store in the token
    let royalty: { [accountId: string]: number } = {}

    // if perpetual royalties were passed into the function: TODO: add isUndefined fn
    if (perpetualRoyalties != null) {
        assert(Object.keys(perpetualRoyalties).length < 7, "Cannot add more than 6 perpetual royalty amounts");
        //iterate through the perpetual royalties and insert the account and amount in the royalty map
        Object.entries(perpetualRoyalties).forEach(([account, amount], index) => {
            royalty[account] = amount;
        });
    }

    let token = new Token ({
        ownerId: receiverId,
        approvedAccountIds: {},
        nextApprovalId: 0,
        royalty,
    });

    //insert the token ID and token struct and make sure that the token doesn't exist
    assert(!contract.tokensById.containsKey(tokenId), "Token already exists");
    contract.tokensById.set(tokenId, token)
    //contract.maxPlayers++;

    //insert the token ID and metadata
    contract.tokenMetadataById.set(tokenId, metadata);

    //call the internal method for adding the token to the owner
    internalAddTokenToOwner(contract, token.owner_id, tokenId)

    // Construct the mint log as per the events standard.
    let nftMintLog = {
        // Standard bname ("nep171").
        standard: NFT_STANDARD_NAME,
        // Version of the standard ("nft-1.0.0").
        version: NFT_METADATA_SPEC,
        // The data related with the event stored in a vector.
        event: "nft_mint",
        data: [
            {
                // Owner of the token.
                owner_id: token.owner_id,
                // Vector of token IDs that were minted.
                token_ids: [tokenId],
            }
        ]
    }
    
    // Log the json.
    near.log(`EVENT_JSON:${JSON.stringify(nftMintLog)}`);

    //calculate the required storage which was the used - initial TODO
    let requiredStorageInBytes = near.storageUsage().valueOf() - initialStorageUsage.valueOf();

    //refund any excess storage if the user attached too much. Panic if they didn't attach enough to cover the required.
    refundDeposit(requiredStorageInBytes);
}