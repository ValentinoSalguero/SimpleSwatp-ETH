💱 SimpleSwap
A minimal decentralized exchange (DEX) inspired by Uniswap, implemented in Solidity.

This project was developed as the final assignment for Module 3, with the goal of understanding the core concepts of liquidity pools and token swaps without relying on the Uniswap protocol.

🎯 Objective
Build a smart contract called SimpleSwap that allows:

✅ Adding and removing liquidity from token pairs

🔁 Swapping ERC-20 tokens

📊 Querying token prices and expected output amounts

⚙️ Features
1. ✅ Add Liquidity

function addLiquidity(
    address tokenA,
    address tokenB,
    uint amountADesired,
    uint amountBDesired,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
) external returns (uint amountA, uint amountB, uint liquidity);
Transfers tokens from the user

Calculates optimal amounts based on pool reserves

Mints liquidity and updates reserves

2. 🧪 Remove Liquidity

function removeLiquidity(
    address tokenA,
    address tokenB,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
) external returns (uint amountA, uint amountB);
Burns the user's share of liquidity

Returns proportional token amounts

Enforces slippage constraints

3. 🔁 Swap Tokens

function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
) external returns (uint[] memory amounts);
Supports direct swaps between two tokens

Uses constant product formula with 0.3% fee

Validates slippage and deadline

4. 📈 Get Price

function getPrice(address tokenA, address tokenB) external view returns (uint price);
Returns the price of tokenB in terms of tokenA based on current reserves

5. 📤 Get Amount Out

function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
Calculates the expected output after a swap, applying a 0.3% fee

🧠 Design Patterns & Best Practices
🧩 Separation of Concerns: Logic is modularized using internal helper functions

⛓ Checks-Effects-Interactions: Ensures a secure order of execution

🏭 Factory-like Pair Mapping: Uses hash-based mapping to track reserves

📘 NatSpec Documentation: All public functions include structured NatSpec comments

🔐 Security: Uses OpenZeppelin’s SafeERC20 for safe token transfers

📊 AMM Formula: Implements the Uniswap V2 pricing model

🔍 Verification
The contract is tested and verified by calling an external SwapVerifier contract deployed on Sepolia testnet.

This verifier contract runs end-to-end checks on SimpleSwap’s core functions to ensure correct behavior.

🚀 Deployment
Compatible with Hardhat or Remix.

Run the script: scripts/deploy_with_ethers.ts

Or deploy manually using the Remix UI

✅ Verification Checklist
 Contract compiles successfully

 All five core functions are implemented

 Follows Solidity best practices and gas optimization

 Clear function and logic comments in English

 Tested on a testnet or local network

 Properly documented in Markdown

📜 License
GPL-3.0

👤 Author
Valentino Salguero
Module 3 – Final Solidity Project
