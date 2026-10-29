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
;;   1 drone  : droneA  (starts at aerodrome, battery b3)
;;   5 locations:
;;     aerodrome       - El Prat emergency drone base          (depot, no charger)
;;     montjuic_pad    - Montjuic hilltop charging pad         (CHARGING STATION, kit1 here)
;;     barceloneta     - La Barceloneta flooded beach district  (inspect -> unlocks ciutadella)
;;     hospital_mar    - Hospital del Mar (cut-off by flooding) (deliver kit1)
;;     ciutadella      - Parc de la Ciutadella evacuation hub   (LOCKED, inspect)
;;   1 supply: kit1 (medical_kit) at montjuic_pad
;;
;; Design constraint (mandatory recharge):
;;   droneA starts at b3 (3 levels). Any valid complete mission path requires a
;;   minimum of 4 flights (e.g. aerodrome->montjuic(1)->barceloneta(2)->
;;   hospital_mar(3)->ciutadella(4)), exceeding the 3 remaining levels.
;;   No recharge-free solution exists. One stop at montjuic_pad is unavoidable.
;;
;; Optimal plan cost:
;;   Model A (instant full recharge): 9
;;   Model B (incremental +1/action):  10 (needs 2 recharge actions from b2->b4)
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
    (battery  droneA b3)          ; 3 of 4 levels -- forces at least one recharge
    (cargo_empty droneA)

    ;; ---- map: connections (bidirectional) ------------------------------------
    ;; Triangle: aerodrome-montjuic_pad-barceloneta (3 mutual connections)
    ;; Plus spokes from both montjuic_pad AND barceloneta into hospital_mar
    ;; Plus hospital_mar and barceloneta connections to ciutadella
    (connected aerodrome     montjuic_pad) (connected montjuic_pad aerodrome)
    (connected aerodrome     barceloneta)  (connected barceloneta  aerodrome)
    (connected montjuic_pad  barceloneta)  (connected barceloneta  montjuic_pad)
    (connected montjuic_pad  hospital_mar) (connected hospital_mar montjuic_pad)
    (connected barceloneta   hospital_mar) (connected hospital_mar barceloneta)
    (connected hospital_mar  ciutadella)   (connected ciutadella   hospital_mar)
    (connected barceloneta   ciutadella)   (connected ciutadella   barceloneta)

    ;; ---- flight costs (all 1 level per edge) ---------------------------------
    (flight_cost aerodrome    montjuic_pad b1) (flight_cost montjuic_pad aerodrome    b1)
    (flight_cost aerodrome    barceloneta  b1) (flight_cost barceloneta  aerodrome    b1)
    (flight_cost montjuic_pad barceloneta  b1) (flight_cost barceloneta  montjuic_pad b1)
    (flight_cost montjuic_pad hospital_mar b1) (flight_cost hospital_mar montjuic_pad b1)
    (flight_cost barceloneta  hospital_mar b1) (flight_cost hospital_mar barceloneta  b1)
    (flight_cost hospital_mar ciutadella   b1) (flight_cost ciutadella   hospital_mar b1)
    (flight_cost barceloneta  ciutadella   b1) (flight_cost ciutadella   barceloneta  b1)

    ;; ---- distances (plan-cost per edge, equals flight cost here) ------------
    (= (distance aerodrome    montjuic_pad) 1) (= (distance montjuic_pad aerodrome)    1)
    (= (distance aerodrome    barceloneta)  1) (= (distance barceloneta  aerodrome)    1)
    (= (distance montjuic_pad barceloneta)  1) (= (distance barceloneta  montjuic_pad) 1)
    (= (distance montjuic_pad hospital_mar) 1) (= (distance hospital_mar montjuic_pad) 1)
    (= (distance barceloneta  hospital_mar) 1) (= (distance hospital_mar barceloneta)  1)
    (= (distance hospital_mar ciutadella)   1) (= (distance ciutadella   hospital_mar) 1)
    (= (distance barceloneta  ciutadella)   1) (= (distance ciutadella   barceloneta)  1)

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
