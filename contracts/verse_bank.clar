;; VerseBank - A DeFi Banking System

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-insufficient-funds (err u101))
(define-constant err-no-account (err u102))
(define-constant err-loan-exists (err u103))
(define-constant err-insufficient-collateral (err u104))
(define-constant err-no-loan (err u105))
(define-constant err-not-liquidatable (err u106))

;; Data Variables
(define-data-var minimum-deposit uint u10000000) ;; 10 STX
(define-data-var interest-rate uint u5) ;; 5% APR
(define-data-var loan-collateral-ratio uint u150) ;; 150% collateral required
(define-data-var liquidation-threshold uint u120) ;; 120% - loan becomes liquidatable
(define-data-var liquidation-penalty uint u10) ;; 10% penalty on liquidation

;; Data Maps
(define-map accounts principal
  {
    balance: uint,
    last-interest-calc: uint,
    has-loan: bool
  }
)

(define-map loans principal
  {
    amount: uint,
    collateral: uint,
    start-block: uint,
    last-check: uint
  }
)

;; Private Functions
(define-private (calculate-interest (balance uint) (blocks uint))
    (let
        (
            (interest-per-block (/ (* balance (var-get interest-rate)) (* u100 u2100)))
        )
        (* interest-per-block blocks)
    )
)

(define-private (get-current-collateral-ratio (loan-amount uint) (collateral uint))
    (/ (* collateral u100) loan-amount)
)

;; Public Functions
(define-public (create-account)
    (let
        ((account-exists (default-to false (get has-loan (map-get? accounts tx-sender))))
        (ok (map-set accounts tx-sender
            {
                balance: u0,
                last-interest-calc: block-height,
                has-loan: false
            }
        ))
    )
)

(define-public (deposit (amount uint))
    (let
        (
            (current-balance (default-to u0 (get balance (map-get? accounts tx-sender))))
            (last-calc (default-to block-height (get last-interest-calc (map-get? accounts tx-sender))))
        )
        (if (>= amount (var-get minimum-deposit))
            (begin
                (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
                (ok (map-set accounts tx-sender
                    {
                        balance: (+ current-balance amount),
                        last-interest-calc: block-height,
                        has-loan: false
                    }
                ))
            )
            (err u105)
        )
    )
)

(define-public (withdraw (amount uint))
    (let
        (
            (current-balance (default-to u0 (get balance (map-get? accounts tx-sender))))
            (last-calc (default-to block-height (get last-interest-calc (map-get? accounts tx-sender))))
            (accrued-interest (calculate-interest current-balance (- block-height last-calc)))
            (total-available (+ current-balance accrued-interest))
        )
        (if (>= total-available amount)
            (begin
                (try! (as-contract (stx-transfer? amount (as-contract tx-sender) tx-sender)))
                (ok (map-set accounts tx-sender
                    {
                        balance: (- total-available amount),
                        last-interest-calc: block-height,
                        has-loan: false
                    }
                ))
            )
            err-insufficient-funds
        )
    )
)

(define-public (take-loan (amount uint))
    (let
        (
            (required-collateral (/ (* amount (var-get loan-collateral-ratio)) u100))
            (account-data (unwrap! (map-get? accounts tx-sender) err-no-account))
        )
        (if (get has-loan account-data)
            err-loan-exists
            (begin
                (try! (stx-transfer? required-collateral tx-sender (as-contract tx-sender)))
                (map-set loans tx-sender
                    {
                        amount: amount,
                        collateral: required-collateral,
                        start-block: block-height,
                        last-check: block-height
                    }
                )
                (try! (as-contract (stx-transfer? amount (as-contract tx-sender) tx-sender)))
                (ok true)
            )
        )
    )
)

(define-public (liquidate (borrower principal))
    (let
        (
            (loan (unwrap! (map-get? loans borrower) err-no-loan))
            (current-ratio (get-current-collateral-ratio (get amount loan) (get collateral loan)))
            (penalty (/ (* (get amount loan) (var-get liquidation-penalty)) u100))
            (liquidation-amount (+ (get amount loan) penalty))
        )
        (if (< current-ratio (var-get liquidation-threshold))
            (begin
                ;; Transfer loan amount + penalty to contract
                (try! (stx-transfer? liquidation-amount tx-sender (as-contract tx-sender)))
                ;; Transfer collateral to liquidator
                (try! (as-contract (stx-transfer? (get collateral loan) (as-contract tx-sender) tx-sender)))
                ;; Clear loan
                (map-delete loans borrower)
                (ok true)
            )
            err-not-liquidatable
        )
    )
)

;; Read-only Functions
(define-read-only (get-balance (account principal))
    (ok (get balance (map-get? accounts account)))
)

(define-read-only (get-loan-details (account principal))
    (ok (map-get? loans account))
)

(define-read-only (get-account-info (account principal))
    (ok (map-get? accounts account))
)

(define-read-only (check-liquidation (account principal))
    (let
        (
            (loan (unwrap! (map-get? loans account) err-no-loan))
            (current-ratio (get-current-collateral-ratio (get amount loan) (get collateral loan)))
        )
        (ok (< current-ratio (var-get liquidation-threshold)))
    )
)
