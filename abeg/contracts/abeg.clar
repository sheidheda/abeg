;; Abeg - A Decentralized Crowdfunding Platform

;; Error codes
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-CAMPAIGN-NOT-FOUND (err u101))
(define-constant ERR-CAMPAIGN-EXPIRED (err u102))
(define-constant ERR-CAMPAIGN-GOAL-REACHED (err u103))
(define-constant ERR-INSUFFICIENT-FUNDS (err u104))
(define-constant ERR-ALREADY-CLAIMED (err u105))
(define-constant ERR-GOAL-NOT-REACHED (err u106))
(define-constant ERR-CAMPAIGN-ACTIVE (err u107))
(define-constant ERR-INVALID-PARAMS (err u108))

;; Data maps and variables
(define-map campaigns
  { campaign-id: uint }
  {
    creator: principal,
    title: (string-ascii 100),
    description: (string-utf8 1000),
    goal-amount: uint,
    current-amount: uint,
    deadline: uint,
    claimed: bool
  }
)

(define-map contributions
  { campaign-id: uint, contributor: principal }
  { amount: uint }
)

(define-data-var campaign-count uint u0)

;; Private functions
(define-private (is-campaign-active (campaign-id uint))
  (let ((campaign (unwrap-panic (map-get? campaigns { campaign-id: campaign-id }))))
    (< block-height (get deadline campaign))
  )
)

(define-private (is-campaign-expired (campaign-id uint))
  (let ((campaign (unwrap-panic (map-get? campaigns { campaign-id: campaign-id }))))
    (>= block-height (get deadline campaign))
  )
)

(define-private (is-goal-reached (campaign-id uint))
  (let ((campaign (unwrap-panic (map-get? campaigns { campaign-id: campaign-id }))))
    (>= (get current-amount campaign) (get goal-amount campaign))
  )
)

;; Public functions
(define-public (create-campaign (title (string-ascii 100)) 
                              (description (string-utf8 1000)) 
                              (goal-amount uint) 
                              (duration uint))
  (let ((campaign-id (var-get campaign-count))
        (deadline (+ block-height duration)))
    
    ;; Validate parameters
    (asserts! (> goal-amount u0) ERR-INVALID-PARAMS)
    (asserts! (> duration u0) ERR-INVALID-PARAMS)
    
    ;; Create the campaign
    (map-set campaigns
      { campaign-id: campaign-id }
      {
        creator: tx-sender,
        title: title,
        description: description,
        goal-amount: goal-amount,
        current-amount: u0,
        deadline: deadline,
        claimed: false
      }
    )
    
    ;; Increment campaign count
    (var-set campaign-count (+ campaign-id u1))
    
    ;; Return the campaign ID
    (ok campaign-id)
  )
)

(define-public (contribute (campaign-id uint) (amount uint))
  (let (
    (campaign (unwrap! (map-get? campaigns { campaign-id: campaign-id }) ERR-CAMPAIGN-NOT-FOUND))
    (current-contribution (default-to { amount: u0 } 
      (map-get? contributions { campaign-id: campaign-id, contributor: tx-sender })))
    )
    
    ;; Check if campaign is still active
    (asserts! (is-campaign-active campaign-id) ERR-CAMPAIGN-EXPIRED)
    
    ;; Transfer STX from sender to contract
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    
    ;; Update campaign current amount
    (map-set campaigns
      { campaign-id: campaign-id }
      (merge campaign { current-amount: (+ (get current-amount campaign) amount) })
    )
    
    ;; Update contributor's record
    (map-set contributions
      { campaign-id: campaign-id, contributor: tx-sender }
      { amount: (+ (get amount current-contribution) amount) }
    )
    
    (ok true)
  )
)

(define-public (claim-funds (campaign-id uint))
  (let ((campaign (unwrap! (map-get? campaigns { campaign-id: campaign-id }) ERR-CAMPAIGN-NOT-FOUND)))
    
    ;; Check if sender is the campaign creator
    (asserts! (is-eq (get creator campaign) tx-sender) ERR-NOT-AUTHORIZED)
    
    ;; Check if campaign has expired
    (asserts! (is-campaign-expired campaign-id) ERR-CAMPAIGN-ACTIVE)
    
    ;; Check if goal was reached
    (asserts! (is-goal-reached campaign-id) ERR-GOAL-NOT-REACHED)
    
    ;; Check if funds were already claimed
    (asserts! (not (get claimed campaign)) ERR-ALREADY-CLAIMED)
    
    ;; Transfer funds to creator
    (try! (as-contract (stx-transfer? (get current-amount campaign) tx-sender (get creator campaign))))
    
    ;; Mark campaign as claimed
    (map-set campaigns
      { campaign-id: campaign-id }
      (merge campaign { claimed: true })
    )
    
    (ok true)
  )
)

(define-public (refund (campaign-id uint))
  (let (
    (campaign (unwrap! (map-get? campaigns { campaign-id: campaign-id }) ERR-CAMPAIGN-NOT-FOUND))
    (contribution (unwrap! (map-get? contributions { campaign-id: campaign-id, contributor: tx-sender }) ERR-NOT-AUTHORIZED))
    )
    
    ;; Check if campaign has expired
    (asserts! (is-campaign-expired campaign-id) ERR-CAMPAIGN-ACTIVE)
    
    ;; Check if goal was not reached
    (asserts! (not (is-goal-reached campaign-id)) ERR-CAMPAIGN-GOAL-REACHED)
    
    ;; Check if user has contributed
    (asserts! (> (get amount contribution) u0) ERR-INSUFFICIENT-FUNDS)
    
    ;; Transfer funds back to contributor
    (try! (as-contract (stx-transfer? (get amount contribution) tx-sender tx-sender)))
    
    ;; Update contribution record
    (map-delete contributions { campaign-id: campaign-id, contributor: tx-sender })
    
    ;; Update campaign current amount
    (map-set campaigns
      { campaign-id: campaign-id }
      (merge campaign { current-amount: (- (get current-amount campaign) (get amount contribution)) })
    )
    
    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-campaign (campaign-id uint))
  (map-get? campaigns { campaign-id: campaign-id })
)

(define-read-only (get-contribution (campaign-id uint) (contributor principal))
  (map-get? contributions { campaign-id: campaign-id, contributor: contributor })
)

(define-read-only (get-campaign-count)
  (var-get campaign-count)
)

(define-read-only (get-campaign-status (campaign-id uint))
  (let ((campaign (unwrap! (map-get? campaigns { campaign-id: campaign-id }) ERR-CAMPAIGN-NOT-FOUND)))
    (if (< block-height (get deadline campaign))
      (ok "active")
      (if (>= (get current-amount campaign) (get goal-amount campaign))
        (ok "successful")
        (ok "failed")
      )
    )
  )
)