# SimpleSwap

A minimal decentralized exchange (DEX) inspired by Uniswap, implemented in Solidity.  
This project was developed as the final assignment for Module 3, aiming to understand core concepts of liquidity pools and token swaps without depending on Uniswap’s protocol.

## 🎯 Objective

Implement a smart contract called `SimpleSwap` that allows:
- Adding and removing liquidity to/from a token pair.
- Swapping ERC-20 tokens.
- Querying token prices and expected output amounts.

## ⚙️ Features

### ✅ 1. Add Liquidity

```solidity
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
´´´
Transfers tokens from the user.

Calculates optimal amounts based on pool reserves.

Mints liquidity and updates reserves.

✅ 2. Remove Liquidity
function removeLiquidity(
    address tokenA,
    address tokenB,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
) external returns (uint amountA, uint amountB);
Burns user's liquidity share.

Returns proportional token amounts.

Enforces slippage constraints.

✅ 3. Swap Tokens
function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
) external returns (uint[] memory amounts);
Supports direct swaps between two tokens.

Uses constant product formula with 0.3% fee.

Validates slippage and deadline.

✅ 4. Get Price
function getPrice(address tokenA, address tokenB) external view returns (uint price);
Returns the price of tokenB in terms of tokenA using current reserves.

✅ 5. Get Amount Out
function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
Calculates expected output amount after a swap, applying 0.3% fee.

🧠 Design Patterns and Good Practices
Separation of Concerns: Logic is modularized with internal helper functions.

Check-Effects-Interactions: Ensures safe order of execution.

Factory-Like Pair Mapping: Uses hash-based mapping for pair reserves.

NatSpec Documentation: All public functions include structured NatSpec comments.

Security: Uses OpenZeppelin's SafeERC20 for safe token transfers.

AMM Formula: Implements Uniswap v2 pricing formula.

🧪 How to Deploy
This contract is compatible with Hardhat or Remix.
Use the provided scripts/deploy_with_ethers.ts or deploy manually via Remix UI.

📂 Project Structure
SimpleSwap/
├── contracts/
│   └── SimpleSwap.sol
├── scripts/
│   └── deploy_with_ethers.ts
├── README.md
└── ...
✅ Verification Checklist
 Contract compiles successfully.

 All 5 required functions are implemented.

 Follows best practices and uses gas-efficient patterns.

 Includes clear function and logic comments in English.

 Verified on a testnet or local network.

 Documented using Markdown.

📜 License
GPL-3.0

👤 Author
Valentino Salguero
Module 3 – Final Solidity Project
