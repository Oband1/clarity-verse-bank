# VerseBank

A decentralized banking system built on the Stacks blockchain offering personalized financial services including:

- Deposit and withdrawal of STX tokens
- Earning interest on deposits
- Taking out loans with STX collateral
- Account management system
- Loan liquidation system

## Features

- Secure deposit and withdrawal system
- Interest accrual mechanism for depositors
- Collateralized loan system
- Account balance tracking
- Administrative controls for bank management
- Automated liquidation system for undercollateralized loans
- Liquidation penalties to incentivize responsible borrowing

## Architecture

The contract implements core banking functionalities using Clarity smart contracts. It maintains separate storage for user balances, loans, and interest rates.

### Liquidation System

The new liquidation system allows for the automatic handling of undercollateralized loans:
- Monitors loan health through collateral ratios
- Enables liquidation when collateral ratio falls below threshold
- Implements penalty system for liquidated loans
- Provides incentives for liquidators
- Helps maintain system solvency

## Implementation Details

- Liquidation threshold: 120% collateral ratio
- Liquidation penalty: 10% of loan amount
- Liquidators receive full collateral amount
- Automated checking of loan health
