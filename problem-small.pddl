;; ============================================================================
;; problem-small.pddl : Barcelona Flood Emergency - Small Instance
;;
;; Scenario: A DANA storm brings torrential rain and a Mediterranean storm surge,
;;   flooding Barcelona's coastal Barceloneta district and cutting off access to
;;   Parc de la Ciutadella, which is being used as an evacuation centre.
;;   One drone (droneA) is dispatched from El Prat emergency aerodrome.
;;   A medical kit has been pre-staged at the Montjuic hilltop charging pad.
;;
;; Objects:
;;   1 drone  : droneA  (starts at aerodrome, full battery b4)
;;   5 locations:
;;     aerodrome       - El Prat emergency drone base          (depot, no charger)
;;     montjuic_pad    - Montjuic hilltop charging pad         (CHARGING STATION, kit1 here)
;;     barceloneta     - La Barceloneta flooded beach district  (inspect -> unlocks ciutadella)
;;     hospital_mar    - Hospital del Mar (cut-off by flooding) (deliver kit1)
;;     ciutadella      - Parc de la Ciutadella evacuation hub   (LOCKED, inspect)
;;   1 supply: kit1 (medical_kit) at montjuic_pad
;;
;; Design constraint (mandatory recharge):
;;   droneA starts FULL (b4), so the map itself forces the recharge.
;;   ciutadella's only neighbour is hospital_mar, so it is the last stop and
;;   hospital_mar comes just before it. A 4-flight route would then be
;;   aerodrome -> {montjuic_pad, barceloneta} -> hospital_mar -> ciutadella,
;;   which needs a montjuic_pad-barceloneta edge: there is none. So every
;;   complete mission needs at least 5 flights (e.g. aerodrome->montjuic_pad->
;;   hospital_mar->barceloneta->hospital_mar->ciutadella) = 5 levels > 4.
;;   No recharge-free solution exists; the recharge is at montjuic_pad, which
;;   every route visits to pick up kit1.
;;
;; Optimal plan cost: 10 in both models
;;   (5 flights + 2 inspections + pick-up + delivery + 1 recharge)
;;   Model A (instant full recharge): 10
;;   Model B (incremental +1/action):  10 (one recharge is enough: the drone
;;     only lacks 1 level, e.g. aerodrome->montjuic_pad leaves b3 with 4
;;     flights to go, and b3 -> b4 covers them)
;; ============================================================================

(define (problem barcelona-flood-small)
  (:domain drone_emergency)

  (:objects
    droneA                                                    - drone
    aerodrome montjuic_pad barceloneta hospital_mar ciutadella - location
    kit1                                                       - medical_kit
    b0 b1 b2 b3 b4                                            - level
  )

  (:init

    ;; ---- drone ---------------------------------------------------------------
    (drone_at droneA aerodrome)   ; droneA at El Prat emergency base
    (battery  droneA b4)          ; full battery: the map, not the start, forces the recharge
    (cargo_empty droneA)

    ;; ---- map: connections (bidirectional) ------------------------------------
    ;; Ring: aerodrome-montjuic_pad-hospital_mar-barceloneta-aerodrome
    ;; Plus ciutadella hanging off hospital_mar (its only neighbour)
    ;; No montjuic_pad-barceloneta and no barceloneta-ciutadella edge: this is
    ;; what makes every complete route at least 5 flights long
    (connected aerodrome     montjuic_pad) (connected montjuic_pad aerodrome)
    (connected aerodrome     barceloneta)  (connected barceloneta  aerodrome)
    (connected montjuic_pad  hospital_mar) (connected hospital_mar montjuic_pad)
    (connected barceloneta   hospital_mar) (connected hospital_mar barceloneta)
    (connected hospital_mar  ciutadella)   (connected ciutadella   hospital_mar)

    ;; ---- flight costs (all 1 level per edge) ---------------------------------
    (flight_cost aerodrome    montjuic_pad b1) (flight_cost montjuic_pad aerodrome    b1)
    (flight_cost aerodrome    barceloneta  b1) (flight_cost barceloneta  aerodrome    b1)
    (flight_cost montjuic_pad hospital_mar b1) (flight_cost hospital_mar montjuic_pad b1)
    (flight_cost barceloneta  hospital_mar b1) (flight_cost hospital_mar barceloneta  b1)
    (flight_cost hospital_mar ciutadella   b1) (flight_cost ciutadella   hospital_mar b1)

    ;; ---- distances (plan-cost per edge, equals flight cost here) ------------
    (= (distance aerodrome    montjuic_pad) 1) (= (distance montjuic_pad aerodrome)    1)
    (= (distance aerodrome    barceloneta)  1) (= (distance barceloneta  aerodrome)    1)
    (= (distance montjuic_pad hospital_mar) 1) (= (distance hospital_mar montjuic_pad) 1)
    (= (distance barceloneta  hospital_mar) 1) (= (distance hospital_mar barceloneta)  1)
    (= (distance hospital_mar ciutadella)   1) (= (distance ciutadella   hospital_mar) 1)

    ;; ---- infrastructure ------------------------------------------------------
    (has_charging_station montjuic_pad)    ; Montjuic hilltop solar charging station

    ;; ---- accessibility -------------------------------------------------------
    ;; ciutadella sealed by flood debris + emergency cordon until Barceloneta
    ;; is inspected and declared passable (safe passage from beach confirmed).
    (accessible aerodrome)
    (accessible montjuic_pad)
    (accessible barceloneta)
    (accessible hospital_mar)
    ;; ciutadella NOT listed -- implicitly locked
    (unlocked_by_inspection barceloneta ciutadella)

    ;; ---- supplies -----------------------------------------------------------
    (supply_at kit1 montjuic_pad)          ; medical kit pre-staged at Montjuic pad
    (needs_supply hospital_mar kit1)       ; Hospital del Mar awaits the kit

    ;; ---- mission requirements -----------------------------------------------
    (needs_inspection barceloneta)         ; structural damage / flood depth survey
    (needs_inspection ciutadella)          ; evacuation-centre capacity assessment

    ;; ---- symbolic battery arithmetic (capacity b4 = 4 levels) ---------------
    ;; battery_after ?before ?cost ?result  (before - cost = result, only if >= 0)
    (battery_after b4 b1 b3) (battery_after b3 b1 b2)
    (battery_after b2 b1 b1) (battery_after b1 b1 b0)

    ;; next_level: used by Model B incremental recharge & Model A not-full check
    (next_level b0 b1) (next_level b1 b2) (next_level b2 b3) (next_level b3 b4)
    (max_level b4)     ; Model A: one recharge action jumps directly to b4

    (= (total-cost) 0)
  )

  (:goal (and
    (inspected barceloneta)        ; Barceloneta district cleared for ground teams
    (inspected ciutadella)         ; Parc de la Ciutadella evacuation hub assessed
    (delivered kit1 hospital_mar)  ; Hospital del Mar receives emergency supplies
  ))

  (:metric minimize (total-cost))
)
