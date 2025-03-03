# VerseBank

A decentralized banking system built on the Stacks blockchain offering personalized financial services including:

- Deposit and withdrawal of STX tokens
- Earning interest on deposits
- Taking out loans with STX collateral
- Account management system
- Loan liquidation system

## Features

- Secure deposit and withdrawal system with reentrancy protection
- Interest accrual mechanism for depositors
- Collateralized loan system
- Account balance tracking
- Administrative controls for bank management
- Automated liquidation system for undercollateralized loans
- Liquidation penalties to incentivize responsible borrowing

## Security Features

- Reentrancy protection on all state-changing functions
- Overflow protection in calculations
- Proper validation of all inputs
- Atomic operations for critical functions

## Architecture

The contract implements core banking functionalities using Clarity smart contracts. It maintains separate storage for user balances, loans, and interest rates.

### Liquidation System

The liquidation system allows for the automatic handling of undercollateralized loans:
- Monitors loan health through collateral ratios
- Enables liquidation when collateral ratio falls below threshold
- Implements penalty system for liquidated loans
- Provides incentives for liquidators
- Helps maintain system solvency

## Implementation Details

- Minimum deposit: 10 STX
- Liquidation threshold: 120% collateral ratio
- Liquidation penalty: 10% of loan amount
- Liquidators receive full collateral amount
- Automated checking of loan health
