;; Liquidity Registry Contract

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_SOURCE_EXISTS (err u101))
(define-constant ERR_SOURCE_NOT_FOUND (err u102))

;; Protocol types
(define-constant PROTOCOL_TYPE_AMM u1)
(define-constant PROTOCOL_TYPE_LENDING u2)
(define-constant PROTOCOL_TYPE_YIELD u3)

;; (define-data-var active-sources (list 100 principal) (list))

;; Data storage
(define-map liquidity-sources principal 
  {
    adapter: principal,
    protocol-type: uint,
    available-liquidity: uint,
    enabled: bool
  }
)

;; List of all active sources for iteration
(define-data-var active-sources (list 50 principal) (list))

;; Use a counter for indexing
(define-data-var source-count uint u0)

;; Map from index to principal
(define-map source-by-index uint principal)

;; Register a new liquidity source
(define-public (register-liquidity-source (protocol-principal principal) (adapter-principal principal) (protocol-type uint))
  (begin
    ;; Only contract owner can register sources
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    ;; Ensure the source doesn't already exist
    (asserts! (is-none (map-get? liquidity-sources protocol-principal)) ERR_SOURCE_EXISTS)
    
    ;; Add to liquidity sources map
    (map-set liquidity-sources protocol-principal
      {
        adapter: adapter-principal,
        protocol-type: protocol-type,
        available-liquidity: u0,
        enabled: true
      }
    )
    
    ;; Add to index
    (let ((current-count (var-get source-count)))
      (map-set source-by-index current-count protocol-principal)
      (var-set source-count (+ current-count u1))
    )
    
    (ok true)
  )
)

;; Helper function to collect sources without recursion
(define-private (collect-sources (index uint) (result (list 50 principal)))
  (if (>= index (var-get source-count))
    result
    (match (map-get? source-by-index index)
      source (append result source)
      result
    )
  )
)
;; Update liquidity metrics
(define-public (update-liquidity-metrics (protocol-principal principal) (new-liquidity uint))
  (let (
    (source (unwrap! (map-get? liquidity-sources protocol-principal) ERR_SOURCE_NOT_FOUND))
  )
    ;; Only the adapter contract can update its own metrics
    (asserts! (is-eq (get adapter source) contract-caller) ERR_UNAUTHORIZED)
    
    ;; Update the liquidity amount
    (map-set liquidity-sources protocol-principal (merge source { available-liquidity: new-liquidity }))
    
    (ok true)
  )
)

;; Query functions

;; Get all liquidity sources
(define-read-only (get-all-liquidity-sources)
  (var-get active-sources)
)

;; Get details for a specific source
(define-read-only (get-liquidity-source (protocol-principal principal))
  (map-get? liquidity-sources protocol-principal)
)

;; Get total liquidity across all sources
(define-read-only (get-total-liquidity)
  (fold + 
    (map get-source-liquidity (var-get active-sources))
    u0
  )
)

;; Helper to get liquidity for a single source
(define-private (get-source-liquidity (source principal))
  (match (map-get? liquidity-sources source)
    source-data (get available-liquidity source-data)
    u0  ;; Default to 0 if no source data found
  )
)

;; Helper to find best source based on available liquidity
(define-private (find-best-source-for-amount 
  (current-source principal) 
  (best-so-far {source: (optional principal), liquidity: uint})
  (request-amount uint)  ;; The amount parameter
)
  (let (
    (source-data (default-to {available-liquidity: u0, enabled: false} 
                  (map-get? liquidity-sources current-source)))
    (current-liquidity (get available-liquidity source-data))
    (is-enabled (get enabled source-data))
  )
    (if (and is-enabled 
             (> current-liquidity (get liquidity best-so-far))
             (>= current-liquidity request-amount))
      {source: (some current-source), liquidity: current-liquidity}
      best-so-far
    )
  )
)
;; Make the wrapper return all fields including amount
(define-private (find-best-source-wrapper
  (current-source principal)
  (best-so-far {source: (optional principal), liquidity: uint, amount: uint})
)
  (let (
    (new-best (find-best-source-for-amount
                current-source
                {source: (get source best-so-far), liquidity: (get liquidity best-so-far)}
                (get amount best-so-far)
              ))
  )
    ;; Include amount in the result
    {source: (get source new-best), liquidity: (get liquidity new-best), amount: (get amount best-so-far)}
  )
)

;; Get optimal source for a specific amount - now returns the full tuple
(define-read-only (get-optimal-source (amount uint))
  (fold find-best-source-wrapper
        (get-all-liquidity-sources)
        {source: none, liquidity: u0, amount: amount})
)