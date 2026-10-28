;; ============================================================================
;; domain-B.pddl : Autonomous Drone Planning for Smart-City Emergency Response
;; MODEL B : each recharge action raises the battery by ONE level (next_level);
;;           several recharge actions are needed to reach full capacity.
;; Planner : Fast Downward (no numeric fluents; battery is symbolic via levels)
;; Only the recharge action differs from domain-A.pddl.
;; ============================================================================

(define (domain drone_emergency_model_b)

  ;; --------------------------------------------------------------------------
  ;; Requirements
  ;; --------------------------------------------------------------------------
  (:requirements
    :strips                 ; basic add/delete effects
    :typing                 ; typed objects
    :negative-preconditions ; used for (not (inspected ?l))
    :conditional-effects    ; forall/when used to unlock locations
    :action-costs           ; total-cost as plan cost
  )

  ;; --------------------------------------------------------------------------
  ;; Types  (NOTE: "- object" on the first line, otherwise they become subtypes
  ;;         of supply)
  ;; --------------------------------------------------------------------------
  (:types
    drone location supply level - object   ; the four mandatory base types
    medical_kit water_package communication_device - supply ; kinds of supply
  )

  ;; --------------------------------------------------------------------------
  ;; Functions
  ;; --------------------------------------------------------------------------
  (:functions
    (total-cost) - number                          ; accumulated plan cost
    (distance ?from_location ?to_location - location) - number ; static flight distance (= flight cost)
  )

  ;; --------------------------------------------------------------------------
  ;; Predicates
  ;; --------------------------------------------------------------------------
  (:predicates
    ;; ---- drones ----
    (drone_at ?drone - drone ?location - location)            ; drone is currently at this location
    (carrying ?drone - drone ?supply - supply)                ; drone is carrying this supply
    (cargo_empty ?drone - drone)                              ; drone carries nothing (capacity = 1 supply)

    ;; ---- map ----
    (connected ?from_location ?to_location - location)        ; drone can fly directly between the two (both directions are declared)
    (has_charging_station ?location - location)               ; location has a charging station
    (accessible ?location - location)                         ; location can currently be entered (not locked)
    (unlocked_by_inspection ?inspected_location ?locked_location - location) ; inspecting the first location unlocks the second
    (unlocked_by_delivery ?supply - supply ?locked_location - location)      ; delivering this supply unlocks the location

    ;; ---- mission ----
    (inspected ?location - location)                          ; location has been inspected
    (needs_supply ?location - location ?supply - supply)      ; location is waiting for this specific supply
    (supply_at ?supply - supply ?location - location)         ; supply is lying at this location (not carried)
    (delivered ?supply - supply ?location - location)         ; supply has been delivered to this location

    ;; ---- symbolic battery ----
    (battery ?drone - drone ?level - level)                   ; current battery level of the drone
    (flight_cost ?from_location ?to_location - location ?cost - level) ; flying from->to costs this many levels
    (battery_after ?before - level ?cost - level ?left - level) ; before - cost = left (only listed if before >= cost)
    (next_level ?lower_level ?higher_level - level)           ; higher = lower + 1 (used by partial recharge)
    (max_level ?level - level)                                ; full battery capacity level (declared for same problem files as Model A)
  )

  ;; --------------------------------------------------------------------------
  ;; ACTION fly : move a drone to a connected, accessible location
  ;;              consumes battery equal to the flight cost
  ;; --------------------------------------------------------------------------
  (:action fly
    :parameters (?drone - drone ?from_location ?to_location - location
                 ?battery_before ?cost ?battery_left - level)
    :precondition (and
      (drone_at ?drone ?from_location)                         ; drone starts at ?from_location
      (connected ?from_location ?to_location)                  ; the two locations are connected
      (accessible ?to_location)                                ; destination is not locked
      (battery ?drone ?battery_before)                         ; current battery level
      (flight_cost ?from_location ?to_location ?cost)          ; cost of this flight in levels
      (battery_after ?battery_before ?cost ?battery_left)      ; exists only if enough battery
    )
    :effect (and
      (not (drone_at ?drone ?from_location))                   ; leave origin
      (drone_at ?drone ?to_location)                           ; arrive at destination
      (not (battery ?drone ?battery_before))                   ; remove old battery level
      (battery ?drone ?battery_left)                           ; set new battery level
      (increase (total-cost) (distance ?from_location ?to_location)) ; plan cost = distance
    )
  )

  ;; --------------------------------------------------------------------------
  ;; ACTION inspect : inspect the location where the drone is
  ;;                  may unlock other locations
  ;; --------------------------------------------------------------------------
  (:action inspect
    :parameters (?drone - drone ?location - location)
    :precondition (and
      (drone_at ?drone ?location)                              ; drone is present at the location
      (not (inspected ?location))                              ; avoid useless repeated inspections
    )
    :effect (and
      (inspected ?location)                                    ; location is now inspected
      (forall (?locked_location - location)                    ; unlock every location depending on this inspection
        (when (unlocked_by_inspection ?location ?locked_location)
          (accessible ?locked_location)))
      (increase (total-cost) 1)                                ; every non-flight action costs 1
    )
  )

  ;; --------------------------------------------------------------------------
  ;; ACTION pick-up-supply : drone picks up a supply at its own location
  ;; --------------------------------------------------------------------------
  (:action pick-up-supply
    :parameters (?drone - drone ?supply - supply ?location - location)
    :precondition (and
      (drone_at ?drone ?location)                              ; drone is at the location
      (supply_at ?supply ?location)                            ; supply is at the same location
      (cargo_empty ?drone)                                     ; drone is not already carrying a supply
    )
    :effect (and
      (not (supply_at ?supply ?location))                      ; supply leaves the location
      (carrying ?drone ?supply)                                ; drone now carries it
      (not (cargo_empty ?drone))                               ; drone cargo is occupied
      (increase (total-cost) 1)                                ; every non-flight action costs 1
    )
  )

  ;; --------------------------------------------------------------------------
  ;; ACTION deliver-supply : deliver the carried supply to a location needing it
  ;;                         may unlock other locations
  ;; --------------------------------------------------------------------------
  (:action deliver-supply
    :parameters (?drone - drone ?supply - supply ?location - location)
    :precondition (and
      (drone_at ?drone ?location)                              ; drone is at the target location
      (carrying ?drone ?supply)                                ; drone carries the supply
      (needs_supply ?location ?supply)                         ; this location needs exactly this supply
    )
    :effect (and
      (not (carrying ?drone ?supply))                          ; drone no longer carries it
      (cargo_empty ?drone)                                     ; cargo is free again
      (not (needs_supply ?location ?supply))                   ; need is satisfied
      (delivered ?supply ?location)                            ; record the delivery (goal predicate)
      (forall (?locked_location - location)                    ; unlock locations depending on this delivery
        (when (unlocked_by_delivery ?supply ?locked_location)
          (accessible ?locked_location)))
      (increase (total-cost) 1)                                ; every non-flight action costs 1
    )
  )

  ;; --------------------------------------------------------------------------
  ;; ACTION recharge (MODEL B) : at a charging station, raise the battery by
  ;;                             exactly one level per action
  ;; --------------------------------------------------------------------------
  (:action recharge
    :parameters (?drone - drone ?location - location
                 ?current_level ?higher_level - level)
    :precondition (and
      (drone_at ?drone ?location)                              ; drone is at the location
      (has_charging_station ?location)                         ; location has a charging station
      (battery ?drone ?current_level)                          ; current battery level
      (next_level ?current_level ?higher_level)                ; higher = current + 1 (does not exist for the max level, so no overcharge)
    )
    :effect (and
      (not (battery ?drone ?current_level))                    ; remove old level
      (battery ?drone ?higher_level)                           ; battery raised by one level
      (increase (total-cost) 1)                                ; every non-flight action costs 1
    )
  )

)
