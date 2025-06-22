// SPDX-License-Identifier: GPL-3.0
 
pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @custom:dev-run-script ./scripts/deploy_with_ethers.ts
/// @title SimpleSwap - A minimal Uniswap-like DEX for ERC-20 tokens
/// @author Valentino Salguero
/// @notice This contract allows users to add/remove liquidity, swap tokens, fetch price and calculate output amounts.
/// @dev Inspired by Uniswap, but simplified for educational purposes.
contract SimpleSwap {
    using SafeERC20 for IERC20;

    /// @dev Stores the reserves of two tokens in a pair
    struct Reserve {
        uint112 reserveA;
        uint112 reserveB;
    }

    /// @dev Maps the hash of a token pair to its reserve data
    mapping(bytes32 => Reserve) public reserves;

    /// @dev Maps the pair hash to the total liquidity of the pool
    mapping(bytes32 => uint) public totalLiquidity;

    /// @dev Tracks each user's liquidity share in a given pair
    mapping(bytes32 => mapping(address => uint)) public liquidityBalance;

    /// @notice Adds liquidity to a token pair pool
    /// @param tokenA Address of token A
    /// @param tokenB Address of token B
    /// @param amountADesired Desired amount of token A to add
    /// @param amountBDesired Desired amount of token B to add
    /// @param amountAMin Minimum acceptable amount of token A
    /// @param amountBMin Minimum acceptable amount of token B
    /// @param to Recipient of the liquidity tokens
    /// @param deadline Timestamp after which the transaction is invalid
    /// @return amountA Actual amount of token A added
    /// @return amountB Actual amount of token B added
    /// @return liquidity Amount of liquidity tokens minted
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity) {
        require(block.timestamp <= deadline, "Expired");

        bytes32 pairHash = _getPairHash(tokenA, tokenB);
        Reserve storage res = reserves[pairHash]; // Get storage reference here for the original function call

        // Determine how much of each token to add based on existing reserves
        (amountA, amountB) = _calculateLiquidityAmounts(
            res.reserveA,
            res.reserveB,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin
        );

        // Perform token transfers
        _performAddLiquidityTransfers(tokenA, tokenB, amountA, amountB);

        // Mint liquidity and update reserves
        // Pass 'res' directly to avoid re-fetching storage, improving efficiency
        liquidity = _mintLiquidityAndUpdateReserves(pairHash, amountA, amountB, to, res);
    }

    /// @notice Removes liquidity and returns tokens to the user
    /// @param tokenA Address of token A
    /// @param tokenB Address of token B
    /// @param liquidity Amount of liquidity tokens to burn
    /// @param amountAMin Minimum acceptable amount of token A
    /// @param amountBMin Minimum acceptable amount of token B
    /// @param to Address to receive withdrawn tokens
    /// @param deadline Timestamp after which the transaction is invalid
    /// @return amountA Amount of token A received
    /// @return amountB Amount of token B received
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB) {
        require(block.timestamp <= deadline, "Expired");

        bytes32 pairHash = _getPairHash(tokenA, tokenB);
        Reserve storage res = reserves[pairHash];
        uint total = totalLiquidity[pairHash];
        require(total > 0, "No liquidity");

        // Calculate user's share of the pool
        amountA = res.reserveA * liquidity / total;
        amountB = res.reserveB * liquidity / total;

        require(amountA >= amountAMin && amountB >= amountBMin, "Slippage");

        // Burn liquidity and update storage
        liquidityBalance[pairHash][msg.sender] -= liquidity;
        totalLiquidity[pairHash] -= liquidity;
        res.reserveA -= uint112(amountA);
        res.reserveB -= uint112(amountB);

        // Send tokens back to user
        IERC20(tokenA).safeTransfer(to, amountA);
        IERC20(tokenB).safeTransfer(to, amountB);
    }

    /// @notice Swaps exact amountIn of tokenIn for tokenOut
    /// @param amountIn Exact amount of input tokens to swap
    /// @param amountOutMin Minimum amount of output tokens required
    /// @param path Array with [tokenIn, tokenOut]
    /// @param to Address to receive output tokens
    /// @param deadline Timestamp after which the transaction is invalid
    /// @return amounts Array containing input and output amounts
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts) {
        require(block.timestamp <= deadline, "Expired");
        require(path.length == 2, "Only 2-token path supported");

        address tokenIn = path[0];
        address tokenOut = path[1];

        // Calculate the output amount
        uint amountOut = _calculateSwapOutput(amountIn, tokenIn, tokenOut);
        require(amountOut >= amountOutMin, "Insufficient output");

        // Perform token transfer
        _performSwapTransfers(tokenIn, tokenOut, amountIn, amountOut, to);

        // Update reserves
        _updateReservesAfterSwap(tokenIn, tokenOut, amountIn, amountOut);

        // Return input/output info
        amounts = new uint[](2);
        amounts[0] = amountIn;
        amounts[1] = amountOut;
    }

    /// @notice Returns the price of tokenB in terms of tokenA
    /// @param tokenA Address of token A
    /// @param tokenB Address of token B
    /// @return price Price as tokenB/tokenA scaled by 1e18
    function getPrice(address tokenA, address tokenB) external view returns (uint price) {
        bytes32 pairHash = _getPairHash(tokenA, tokenB);
        Reserve memory res = reserves[pairHash];

        (uint reserveA, uint reserveB) = _getSortedReserves(tokenA, tokenB, res);
        require(reserveA > 0 && reserveB > 0, "No reserves");
        price = (reserveB * 1e18) / reserveA;
    }

    /// @notice Calculates output tokens for a given input using Uniswap formula
    /// @param amountIn Input amount
    /// @param reserveIn Reserve of input token
    /// @param reserveOut Reserve of output token
    /// @return amountOut Amount of output tokens after fee
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) public pure returns (uint amountOut) {
        require(amountIn > 0 && reserveIn > 0 && reserveOut > 0, "Invalid reserves");

        uint amountInWithFee = amountIn * 997; // 0.3% fee
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    // --- New Internal Helper Functions for addLiquidity ---

    /// @dev Calculates the optimal amounts of tokens to add for liquidity.
    function _calculateLiquidityAmounts(
        uint112 currentReserveA,
        uint112 currentReserveB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal pure returns (uint calculatedAmountA, uint calculatedAmountB) {
        if (currentReserveA == 0 && currentReserveB == 0) {
            // No liquidity yet; use desired amounts
            (calculatedAmountA, calculatedAmountB) = (amountADesired, amountBDesired);
        } else {
            // Maintain ratio between reserves
            uint amountBOptimal = amountADesired * currentReserveB / currentReserveA;
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, "Insufficient B");
                (calculatedAmountA, calculatedAmountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = amountBDesired * currentReserveA / currentReserveB;
                require(amountAOptimal >= amountAMin, "Insufficient A");
                (calculatedAmountA, calculatedAmountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    /// @dev Handles the token transfers for adding liquidity.
    function _performAddLiquidityTransfers(
        address tokenA,
        address tokenB,
        uint amountA,
        uint amountB
    ) internal {
        IERC20(tokenA).safeTransferFrom(msg.sender, address(this), amountA);
        IERC20(tokenB).safeTransferFrom(msg.sender, address(this), amountB);
    }

    /// @dev Mints liquidity tokens and updates pool reserves.
    function _mintLiquidityAndUpdateReserves(
        bytes32 pairHash,
        uint amountA,
        uint amountB,
        address to,
        Reserve storage res // Pass the storage reference directly
    ) internal returns (uint liquidity) {
        liquidity = amountA + amountB;
        totalLiquidity[pairHash] += liquidity;
        liquidityBalance[pairHash][to] += liquidity;

        res.reserveA += uint112(amountA);
        res.reserveB += uint112(amountB);
    }

    // --- Existing Internal Helper Functions for Swapping & Utilities ---

    /// @dev Internal helper to calculate swap output
    function _calculateSwapOutput(uint amountIn, address tokenIn, address tokenOut) internal view returns (uint) {
        bytes32 pairHash = _getPairHash(tokenIn, tokenOut);
        Reserve memory res = reserves[pairHash];
        (uint reserveIn, uint reserveOut) = _getSortedReserves(tokenIn, tokenOut, res);
        return getAmountOut(amountIn, reserveIn, reserveOut);
    }

    /// @dev Internal helper to perform token transfers for a swap
    function _performSwapTransfers(address tokenIn, address tokenOut, uint amountIn, uint amountOut, address to) internal {
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenOut).safeTransfer(to, amountOut);
    }

    /// @dev Internal helper to update reserves after a swap
    function _updateReservesAfterSwap(address tokenIn, address tokenOut, uint amountIn, uint amountOut) internal {
        bytes32 pairHash = _getPairHash(tokenIn, tokenOut);
        Reserve storage res = reserves[pairHash];
        if (tokenIn < tokenOut) {
            res.reserveA += uint112(amountIn);
            res.reserveB -= uint112(amountOut);
        } else {
            res.reserveB += uint112(amountIn);
            res.reserveA -= uint112(amountOut);
        }
    }

    /// @dev Generates a unique hash for a token pair (ordered)
    function _getPairHash(address tokenA, address tokenB) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(tokenA < tokenB ? tokenA : tokenB, tokenA < tokenB ? tokenB : tokenA));
    }

    /// @dev Sorts and returns reserves based on token order
    function _getSortedReserves(address tokenA, address tokenB, Reserve memory res) internal pure returns (uint, uint) {
        return tokenA < tokenB ? (res.reserveA, res.reserveB) : (res.reserveB, res.reserveA);
    }
}