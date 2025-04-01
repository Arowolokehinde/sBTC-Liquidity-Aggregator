;; Flash Loan Vault Contract

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u200))
(define-constant ERR_INSUFFICIENT_FUNDS (err u201))
(define-constant ERR_LOAN_NOT_FOUND (err u202))
(define-constant ERR_REPAYMENT_FAILED (err u203))
(define-constant ERR_NOT_IN_CALLBACK (err u204))

;; Fee configuration (in basis points, 100 = 1%)
(define-data-var flash-loan-fee uint u10) ;; 0.1% fee

;; Active loan tracking
(define-map active-loans uint 
  {
    amount: uint,
    borrower: principal,
    callback: (string-ascii 128),
    fee: uint,
    repaid: bool
  }
)

(define-data-var loan-nonce uint u0)
(define-data-var in-flash-loan bool false)

;; Fee collection
(define-data-var fee-collector principal CONTRACT_OWNER)
(define-data-var collected-fees uint u0)

;; Administrative functions

;; Set the flash loan fee
(define-public (set-flash-loan-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (var-set flash-loan-fee new-fee)
    (ok true)
  )
)

;; Set the fee collector
(define-public (set-fee-collector (new-collector principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (var-set fee-collector new-collector)
    (ok true)
  )
)

;; Flash loan functions
;; Define a trait for the borrower contract to implement
(define-trait flash-loan-callback-trait
  (
    ;; This is the callback function that will be called
    (flash-loan-callback (uint uint uint) (response bool uint))
  )
)

;; Execute a flash loan
(define-public (execute-flash-loan (amount uint) (borrower <flash-loan-callback-trait>) (fee-fixed uint))
  (let (
    (loan-id (generate-loan-id))
    (fee-amount (if (> fee-fixed u0) fee-fixed (calculate-fee amount)))
    (vault-balance (unwrap! (contract-call? .sbtc-token_clar get-balance-available (as-contract tx-sender)) ERR_UNAUTHORIZED))
  )
    ;; Check if we have enough funds
    (asserts! (>= vault-balance amount) ERR_INSUFFICIENT_FUNDS)
    
    ;; Record the loan
    (map-set active-loans loan-id 
      {
        amount: amount,
        borrower: (contract-of borrower),
        callback: "flash-loan-callback",
        fee: fee-amount,
        repaid: false
      }
    )
    
    ;; Set that we're in a flash loan
    (var-set in-flash-loan true)
    
    ;; Transfer funds to borrower
    (try! (as-contract (contract-call? .sbtc-token_clar transfer amount tx-sender (contract-of borrower) none)))
    
    ;; Call the callback function using the trait
    (try! (contract-call? borrower flash-loan-callback loan-id amount fee-amount))
    
    ;; Verify repayment
    (asserts! (get repaid (default-to {repaid: false} (map-get? active-loans loan-id))) ERR_REPAYMENT_FAILED)
    
    ;; Reset flash loan state
    (var-set in-flash-loan false)
    
    (ok loan-id)
  )
)
;; Repay a flash loan
(define-public (repay-flash-loan (loan-id uint))
  (let (
    (loan (unwrap! (map-get? active-loans loan-id) ERR_LOAN_NOT_FOUND))
    (total-repayment (+ (get amount loan) (get fee loan)))
  )
    ;; Check we're in a callback context
    (asserts! (var-get in-flash-loan) ERR_NOT_IN_CALLBACK)
    
    ;; Check the caller is the borrower
    (asserts! (is-eq tx-sender (get borrower loan)) ERR_UNAUTHORIZED)
    
    ;; Transfer funds back plus fee
    (try! (contract-call? .sbtc-token_clar transfer total-repayment tx-sender (as-contract tx-sender) none))
    
    ;; Update loan status
    (map-set active-loans loan-id (merge loan {repaid: true}))
    
    ;; Add to collected fees
    (var-set collected-fees (+ (var-get collected-fees) (get fee loan)))
    
    (ok true)
  )
)

;; Withdraw collected fees
(define-public (withdraw-fees)
  (let (
    (fees (var-get collected-fees))
    (collector (var-get fee-collector))
  )
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (> fees u0) ERR_INSUFFICIENT_FUNDS)
    
    ;; Reset fees
    (var-set collected-fees u0)
    
    ;; Transfer fees to collector
    (as-contract (contract-call? .sbtc-token_clar transfer fees tx-sender collector none))
  )
)

;; Helper functions

;; Generate a unique loan ID
(define-private (generate-loan-id)
  (let (
    (current-nonce (var-get loan-nonce))
  )
    (var-set loan-nonce (+ current-nonce u1))
    current-nonce
  )
)

;; Calculate the fee for a loan amount
(define-private (calculate-fee (amount uint))
  (/ (* amount (var-get flash-loan-fee)) u10000)
)

;; Query functions

;; Get loan details
(define-read-only (get-loan-details (loan-id uint))
  (map-get? active-loans loan-id)
)

;; Get current fee rate
(define-read-only (get-fee-rate)
  (var-get flash-loan-fee)
)

;; Get total collected fees
(define-read-only (get-collected-fees)
  (var-get collected-fees)
)