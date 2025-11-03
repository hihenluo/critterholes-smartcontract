# CritterHoles 🎮 – Smart Contracts

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Solidity Version](https://img.shields.io/badge/Solidity-^0.8.20-blue.svg)](https://soliditylang.org/)
[![Network: Base](https://img.shields.io/badge/Network-Base-blue.svg)](https://base.org/)

A collection of smart contracts powering the CritterHoles ecosystem on the Base network. This includes game logic, token staking, NFT minting, and token swaps.

## ✨ Features

* **🎮 Game Logic (`CHGame.sol`):** Signature-based reward claiming system to prevent bots. Manages daily claim limits and multiple reward tokens.
* **🔨 NFT Minting (`CritterHolesHammer.sol`):** A one-time-per-wallet ERC1155 NFT mint, required for game participation.
* [cite_start]**🪙 Points Token (`CritterHolesPoints.sol`):** An ERC20 token with 0 decimals, used as the primary in-game point system. [cite: 35, 37]
* **💎 NFT Staking (`LumpStaking.sol`):** Stake `Lump` NFTs (ERC1155) to earn `BONK` token rewards.
* [cite_start]**🔁 Token Swap (`Swap.sol`):** A utility contract allowing users to burn `BONK` tokens in exchange for ETH from the contract's liquidity. [cite: 7, 8]
* [cite_start]**🔒 Secure & Ownable:** Contracts use OpenZeppelin's `Ownable` for administration and `ReentrancyGuard` for protection. [cite: 1, 15, 61, 88]

---

## 🛠️ Development Setup

Follow these steps to set up the project locally for development and testing.

### Prerequisites

* [Node.js](https://nodejs.org/) (v18+ recommended)
* [Yarn](https://yarnpkg.com/) or [NPM](https://www.npmjs.com/)
* An Ethereum wallet (like MetaMask) with a Private Key

### Installation

1.  **Clone the Repository:**
    ```bash
    git clone [https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git](https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git)
    cd YOUR_REPO_NAME
    ```

2.  **Install Dependencies:**
    ```bash
    npm install
    # or
    yarn install
    ```

3.  **Compile Contracts:**
    ```bash
    npx hardhat compile
    ```

---

## 🚀 Deployment & Configuration

### 1. Environment Configuration (`.env`)

Before deploying, create a `.env` file in the root of the project. Your file should look like this:

```env
# Your wallet's private key for deployment
PRIVATE_KEY=0x...your_private_key_here...

# (Optional) A second private key for the 'superSigner' in CHGame
# If you only have one, the script will use the deployer's address as a fallback.
# PRIVATE_KEY_SUPER_SIGNER=0x...your_second_private_key_here...

# RPC URL for the network you are deploying to (e.g., Base Mainnet)
BASE_RPC_URL=[https://mainnet.base.org](https://mainnet.base.org)

# Your Basescan API key for contract verification
BASESCAN_API_KEY=...your_basescan_api_key_here...
```

[cite_start]*Note: The `hardhat.config.cjs` is already set up to read these variables.* [cite: 55-58]

### 2. Deployment Script Configuration

The main deployment script (`scripts/deploy.ts`) handles all 6 contracts. However, it **requires you to provide addresses** for pre-existing tokens.

**➡️ Open `scripts/deploy.ts` and edit these constants at the top:**

* [cite_start]`BONK_TOKEN_ADDRESS`: The address of the BONK (or similar) token. [cite: 5, 17, 62]
* [cite_start]`TOKEN2_ADDRESS`: The address of the first reward token for `CHGame` (e.g., DEGEN). [cite: 94]
* [cite_start]`TOKEN3_ADDRESS`: The address of the second reward token for `CHGame` (e.g., WCT). [cite: 95]

### 3. Run Deployment

Once your `.env` and `deploy.ts` files are configured, run the deployment script targeting the `base` network:

```bash
npx hardhat run scripts/deploy.ts --network base
```

The script will log the addresses of all newly deployed contracts to your console.

### 4. Verify Contracts

After deployment, you can verify all your contracts on Basescan using the Hardhat Etherscan plugin. Run this command for each deployed contract:

```bash
# Example for CritterHolesPoints
npx hardhat verify --network base DEPLOYED_CHP_ADDRESS "YOUR_OWNER_ADDRESS"

# Example for CHGame (with 5 constructor arguments)
npx hardhat verify --network base DEPLOYED_CHGAME_ADDRESS "OWNER" "CHP_ADDR" "TOKEN2_ADDR" "TOKEN3_ADDR" "SUPER_SIGNER"
```
*(You will need to manually run verification for each contract, filling in the constructor arguments used during deployment.)*

---

## 📝 Contracts Overview

Here is a brief overview of the main public and owner-only functions for each contract.

### `CritterHolesPoints.sol` (CHP)
An ERC20 token for in-game points.
* [cite_start]**Public:** `mint(address to, uint256 amount)` [cite: 39]
* [cite_start]**Owner-Only:** `setTransfersEnabled(bool _enabled)` [cite: 40]

### `CritterHolesHammer.sol` (HAMMER)
An ERC1155 NFT used as a game pass.
* [cite_start]**Public:** `mint()` (Payable) [cite: 47]
* [cite_start]**View:** `hasMinted(address user)` [cite: 54]
* [cite_start]**Owner-Only:** `UPrice(uint256 _newPrice)`, `Withdraw()` [cite: 49, 51]

### `CHGame.sol`
The core game contract for claiming rewards.
* [cite_start]**Public:** `claim(bytes databytes, ...)` [cite: 96]
* [cite_start]**View:** `players(address user)` [cite: 91]
* [cite_start]**Owner-Only:** `UDaily(uint256 _newDailyLimit)`, `UToken(uint8 _tokenSlot, ...)` [cite: 107, 108]

### `Lump.sol`
An ERC1155 NFT that can be minted with ETH or BNK.
* [cite_start]**Public:** `mintWithBNK(uint256 _amount)`, `mintWithETH(uint256 _amount)` (Payable) [cite: 19, 21]
* [cite_start]**Owner-Only:** `setPrices(...)`, `setBnkFeeReceiver(...)`, `setEthFeeReceiver(...)`, `setURI(...)` [cite: 27, 28, 29, 30]

### `LumpStaking.sol`
Staking contract for `Lump` NFTs to earn `BONK`.
* [cite_start]**Public:** `stake(uint256 _amount)`, `unstake(uint256 _amount)`, `claimRewards()` [cite: 71, 72, 78]
* [cite_start]**View:** `pendingRewards(address _user)` [cite: 67]
* [cite_start]**Owner-Only:** `setRewardRate(...)`, `setMinClaimAmount(...)`, `withdrawBNK(...)` [cite: 81, 82, 84]

### `Swap.sol`
Contract to burn `BONK` and receive ETH.
* [cite_start]**Public:** `swap(uint256 _bonkAmount)` [cite: 7]
* [cite_start]**Owner-Only:** `setRate(...)`, `setMinSwap(...)`, `withdraw(...)` [cite: 9, 10, 11]

---

## 🤝 Contributing

We welcome contributions! Here's how you can help:

1.  **Fork the repository.**
2.  **Create a new feature branch:**
    ```bash
    git checkout -b feature/your-amazing-feature
    ```
3.  **Make your changes** and ensure you follow Solidity best practices.
4.  **Add/update tests** for your new functionality (if applicable).
5.  **Commit your changes:**
    ```bash
    git commit -m "feat: Add your amazing feature"
    ```
6.  **Push to your branch** and **submit a pull request** to the main repository.

### Reporting Issues
Please use the GitHub issue tracker to report bugs, request features, or ask questions. Provide detailed steps to reproduce any issues.

## 📄 License

This project is open source and available under the [MIT License](LICENSE).