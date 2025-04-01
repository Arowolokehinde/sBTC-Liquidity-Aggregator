;; Lending Protocol Adapter Contract

;; Constants 
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u500))
(define-constant ERR_DEPOSIT_FAILED (err u501))
(define-constant ERR_WITHDRAWAL_FAILED (err u502))
(define-constant ERR_INSUFFICIENT_FUNDS (err u503))

;; Protocol information
(define-data-var protocol-principal principal 'SP000000000000000000002Q6VF78.lending-protocol)
(define-data-var is-initialized bool false)

;; Initialize the adapter
(define-public (initialize (lending-principal principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (not (var-get is-initialized)) ERR_UNAUTHORIZED)
    
    (var-set protocol-principal lending-principal)
    (var-set is-initialized true)
    
    ;; Register with liquidity registry
    (try! (contract-call? .liquidity-registry_clar update-liquidity-metrics lending-principal (get-available-liquidity)))
    
    (ok true)
  )
)
;; Define a trait for the lending protocol
(define-trait lending-protocol-trait
  (
    ;; Deposit function that lending protocols must implement
    (deposit (uint principal) (response bool uint))
    ;; Withdraw function that lending protocols must implement
    (withdraw (uint principal) (response bool uint))
  )
)

;; Deposit sBTC into the lending protocol
(define-public (deposit-sBTC (amount uint) (sender principal))
  (let (
    (lending-principal (var-get protocol-principal))
  )
    ;; Transfer sBTC from sender to lending protocol
    (if (is-eq sender tx-sender)
      (try! (contract-call? .sbtc-token_clar transfer amount tx-sender lending-principal none))
      (try! (contract-call? .sbtc-token_clar transfer amount sender lending-principal none))
    )
    
    ;; Since we can't call a dynamic function without a trait, we'll simulate the deposit
    ;; In a real implementation, you would implement trait conformance and call the protocol
    
    ;; Update liquidity metrics
    (try! (contract-call? .liquidity-registry_clar update-liquidity-metrics lending-principal (get-available-liquidity)))
    
    (ok true)
  )
)

;; Withdraw sBTC from the lending protocol
;; Withdraw sBTC from the lending protocol
(define-public (withdraw-sBTC (amount uint) (recipient principal))
  (let (
    (lending-principal (var-get protocol-principal))
  )
    ;; Since we can't call a dynamic function without a trait, we'll simulate the withdrawal
    ;; In a real implementation, you would implement trait conformance and call the protocol
    
    ;; Simulate the transfer of tokens from the lending protocol to the recipient
    (try! (as-contract (contract-call? .sbtc-token_clar transfer amount lending-principal recipient none)))
    
    ;; Update liquidity metrics
    (try! (contract-call? .liquidity-registry_clar update-liquidity-metrics lending-principal (get-available-liquidity)))
    
    (ok true)
  )
)
;; Get current available liquidity
(define-read-only (get-available-liquidity)
  (let (
    (lending-principal (var-get protocol-principal))
  )
    ;; Simply unwrap the response
    (unwrap-panic (contract-call? .sbtc-token_clar get-balance-available lending-principal))
  )
)