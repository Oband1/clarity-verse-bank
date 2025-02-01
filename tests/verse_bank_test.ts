import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Ensures account creation works",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get('wallet_1')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('verse_bank', 'create-account', [], wallet_1.address)
    ]);
    
    block.receipts[0].result.expectOk();
    
    let accountInfo = chain.callReadOnlyFn(
      'verse_bank',
      'get-account-info',
      [types.principal(wallet_1.address)],
      wallet_1.address
    );
    
    accountInfo.result.expectSome();
  },
});

Clarinet.test({
  name: "Can deposit and withdraw funds",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get('wallet_1')!;
    const depositAmount = 20000000; // 20 STX
    
    let block = chain.mineBlock([
      Tx.contractCall('verse_bank', 'create-account', [], wallet_1.address),
      Tx.contractCall('verse_bank', 'deposit', [types.uint(depositAmount)], wallet_1.address)
    ]);
    
    block.receipts.forEach(receipt => {
      receipt.result.expectOk();
    });
    
    let balance = chain.callReadOnlyFn(
      'verse_bank',
      'get-balance',
      [types.principal(wallet_1.address)],
      wallet_1.address
    );
    
    balance.result.expectOk().expectUint(depositAmount);
    
    // Test withdrawal
    block = chain.mineBlock([
      Tx.contractCall('verse_bank', 'withdraw', [types.uint(10000000)], wallet_1.address)
    ]);
    
    block.receipts[0].result.expectOk();
  },
});

Clarinet.test({
  name: "Can take out a loan with sufficient collateral",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get('wallet_1')!;
    const loanAmount = 100000000; // 100 STX
    const collateralAmount = 150000000; // 150 STX
    
    let block = chain.mineBlock([
      Tx.contractCall('verse_bank', 'create-account', [], wallet_1.address),
      Tx.contractCall('verse_bank', 'take-loan', [types.uint(loanAmount)], wallet_1.address)
    ]);
    
    block.receipts[1].result.expectOk();
    
    let loanDetails = chain.callReadOnlyFn(
      'verse_bank',
      'get-loan-details',
      [types.principal(wallet_1.address)],
      wallet_1.address
    );
    
    loanDetails.result.expectSome();
  },
});

Clarinet.test({
  name: "Can liquidate undercollateralized loans",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const borrower = accounts.get('wallet_1')!;
    const liquidator = accounts.get('wallet_2')!;
    const loanAmount = 100000000; // 100 STX
    
    // Setup loan
    let block = chain.mineBlock([
      Tx.contractCall('verse_bank', 'create-account', [], borrower.address),
      Tx.contractCall('verse_bank', 'take-loan', [types.uint(loanAmount)], borrower.address)
    ]);
    
    block.receipts[1].result.expectOk();
    
    // Check liquidation status
    let canLiquidate = chain.callReadOnlyFn(
      'verse_bank',
      'check-liquidation',
      [types.principal(borrower.address)],
      liquidator.address
    );
    
    // Attempt liquidation
    block = chain.mineBlock([
      Tx.contractCall('verse_bank', 'liquidate', [types.principal(borrower.address)], liquidator.address)
    ]);
    
    // Verify loan is cleared after liquidation
    let loanDetails = chain.callReadOnlyFn(
      'verse_bank',
      'get-loan-details',
      [types.principal(borrower.address)],
      borrower.address
    );
    
    loanDetails.result.expectNone();
  },
});
