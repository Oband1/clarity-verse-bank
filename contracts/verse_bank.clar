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
(define-constant err-invalid-amount (err u107))
(define-constant err-unauthorized (err u108))

;; Data Variables
(define-data-var minimum-deposit uint u10000000) ;; 10 STX
(define-data-var interest-rate uint u5) ;; 5% APR
(define-data-var loan-collateral-ratio uint u150) ;; 150% collateral required
(define-data-var liquidation-threshold uint u120) ;; 120% - loan becomes liquidatable
(define-data-var liquidation-penalty uint u10) ;; 10% penalty on liquidation
(define-data-var reentrancy-guard uint u0)

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

;; Events
(define-data-var last-event-nonce uint u0)

;; Private Functions
(define-private (check-reentrancy)
  (if (is-eq (var-get reentrancy-guard) u0)
    (ok true)
    err-unauthorized
  )
)

(define-private (begin-atomic)
  (var-set reentrancy-guard u1)
  (ok true)
)

(define-private (end-atomic)
  (var-set reentrancy-guard u0)
  (ok true)
)

(define-private (emit-event (event-name (string-ascii 64)) (data (string-ascii 64)))
  (var-set last-event-nonce (+ (var-get last-event-nonce) u1))
  (print { event-name: event-name, data: data, nonce: (var-get last-event-nonce) })
)

(define-private (calculate-interest (balance uint) (blocks uint))
  (let
    (
      (interest-per-block (/ (* balance (var-get interest-rate)) (* u100 u2100)))
    )
    (if (> blocks u0)
      (* interest-per-block blocks)
      u0
    )
  )
)

;; Public Functions
(define-public (create-account)
  (let
    ((account-exists (is-some (map-get? accounts tx-sender))))
    (if account-exists
      err-loan-exists
      (begin
        (emit-event "account-created" (concat "account:" (to-ascii tx-sender)))
        (ok (map-set accounts tx-sender
          {
            balance: u0,
            last-interest-calc: block-height,
            has-loan: false
          }
        ))
      )
    )
  )
)

(define-public (deposit (amount uint))
  (let
    (
      (account-data (unwrap! (map-get? accounts tx-sender) err-no-account))
      (current-balance (get balance account-data))
    )
    (asserts! (>= amount (var-get minimum-deposit)) err-invalid-amount)
    (try! (check-reentrancy))
    (try! (begin-atomic))
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    
    (map-set accounts tx-sender
      {
        balance: (+ current-balance amount),
        last-interest-calc: block-height,
        has-loan: (get has-loan account-data)
      }
    )
    (try! (end-atomic))
    (ok true)
  )
)

(define-public (withdraw (amount uint))
  (let
    (
      (account-data (unwrap! (map-get? accounts tx-sender) err-no-account))
      (current-balance (get balance account-data))
    )
    (asserts! (>= current-balance amount) err-insufficient-funds)
    (try! (check-reentrancy))
    (try! (begin-atomic))
    
    (try! (as-contract (stx-transfer? amount (as-contract tx-sender) tx-sender)))
    (map-set accounts tx-sender
      {
        balance: (- current-balance amount),
        last-interest-calc: block-height,
        has-loan: (get has-loan account-data)
      }
    )
    (try! (end-atomic))
    (ok true)
  )
)
