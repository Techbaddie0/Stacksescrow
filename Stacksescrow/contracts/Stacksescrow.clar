;; TrustBridge: P2P Trading Escrow Smart Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-authorized (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-trade-not-found (err u103))
(define-constant err-invalid-state (err u104))
(define-constant err-unauthorized (err u105))
(define-constant err-invalid-buyer (err u108))
(define-constant err-invalid-description (err u109))
(define-constant err-invalid-collector (err u110))

;; Status constants as fixed-length strings
(define-constant STATUS-PENDING "pending")
(define-constant STATUS-COMPLETED "completed")
(define-constant STATUS-CANCELLED "cancelled")

;; Data Variables
(define-data-var escrow-fee uint u1) ;; 1% fee

;; Trade Status
(define-data-var fee-collector principal contract-owner)

;; Define block height getter
(define-read-only (get-block-height)
    burn-block-height
)

;; Define the trade structure
(define-map trades
    { trade-id: uint }
    {
        seller: principal,
        buyer: principal,
        amount: uint,
        description: (string-ascii 100),
        status: (string-ascii 20),
        created-at: uint,
        completed-at: uint
    }
)

;; Keep track of trade counts
(define-data-var trade-nonce uint u0)

;; Read-only functions
(define-read-only (get-trade (trade-id uint))
    (map-get? trades { trade-id: trade-id })
)

(define-read-only (get-escrow-fee)
    (var-get escrow-fee)
)

;; Create new trade
(define-public (create-trade (buyer principal) (amount uint) (description (string-ascii 100)))
    (let
        (
            (new-trade-id (var-get trade-nonce))
            (fee-amount (/ (* amount (var-get escrow-fee)) u100))
            (current-height (get-block-height))
        )
        ;; Input validation
        (asserts! (> amount u0) (err u106))
        (asserts! (not (is-eq buyer tx-sender)) err-invalid-buyer)
        (asserts! (not (is-eq description "")) err-invalid-description)
        
        ;; Transfer tokens from seller to contract
        (try! (stx-transfer? (+ amount fee-amount) tx-sender (as-contract tx-sender)))
        
        ;; Create trade record
        (map-set trades
            { trade-id: new-trade-id }
            {
                seller: tx-sender,
                buyer: buyer,
                amount: amount,
                description: description,
                status: STATUS-PENDING,
                created-at: current-height,
                completed-at: u0
            }
        )
        
        ;; Increment trade nonce
        (var-set trade-nonce (+ new-trade-id u1))
        (ok new-trade-id)
    )
)

;; Confirm delivery (buyer)
(define-public (confirm-delivery (trade-id uint))
    (let
        (
            (trade (unwrap! (get-trade trade-id) err-trade-not-found))
        )
        ;; Verify caller is the buyer
        (asserts! (is-eq (get buyer trade) tx-sender) err-unauthorized)
        ;; Verify trade is in pending state
        (asserts! (is-eq (get status trade) STATUS-PENDING) err-invalid-state)
        
        ;; Update trade status
        (try! 
            (begin
                (map-set trades
                    { trade-id: trade-id }
                    (merge trade {
                        status: STATUS-COMPLETED,
                        completed-at: (get-block-height)
                    })
                )
                (as-contract
                    (stx-transfer? (get amount trade) tx-sender (get seller trade))
                )
            )
        )
        (ok true)
    )
)

;; Cancel trade (only possible by seller if not yet confirmed)
(define-public (cancel-trade (trade-id uint))
    (let
        (
            (trade (unwrap! (get-trade trade-id) err-trade-not-found))
        )
        ;; Verify caller is the seller
        (asserts! (is-eq (get seller trade) tx-sender) err-unauthorized)
        ;; Verify trade is in pending state
        (asserts! (is-eq (get status trade) STATUS-PENDING) err-invalid-state)
        
        ;; Update trade status and return funds
        (try! 
            (begin
                (map-set trades
                    { trade-id: trade-id }
                    (merge trade {
                        status: STATUS-CANCELLED,
                        completed-at: (get-block-height)
                    })
                )
                (as-contract
                    (stx-transfer? (get amount trade) tx-sender tx-sender)
                )
            )
        )
        (ok true)
    )
)

;; Admin functions

;; Update escrow fee
(define-public (set-escrow-fee (new-fee uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (<= new-fee u100) (err u107))
        (var-set escrow-fee new-fee)
        (ok true)
    )
)

;; Update fee collector
(define-public (set-fee-collector (new-collector principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (not (is-eq new-collector contract-owner)) err-invalid-collector)
        (var-set fee-collector new-collector)
        (ok true)
    )
)

;; Withdraw collected fees
(define-public (withdraw-fees)
    (let
        (
            (balance (stx-get-balance (as-contract tx-sender)))
        )
        (asserts! (is-eq tx-sender (var-get fee-collector)) err-unauthorized)
        (try! 
            (as-contract
                (stx-transfer? balance tx-sender (var-get fee-collector))
            )
        )
        (ok true)
    )
)
