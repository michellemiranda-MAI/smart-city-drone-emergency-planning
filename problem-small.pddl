;; ============================================================================
;; problem-small.pddl : Barcelona Flood Emergency - Small Instance
;;
;; Scenario: A DANA storm brings torrential rain and a Mediterranean storm surge,
;;   flooding Barcelona's coastal Barceloneta district and cutting off access to
;;   Parc de la Ciutadella, which is being used as an evacuation centre.
;;   One drone (droneA) is dispatched from El Prat emergency aerodrome, the
;;   central depot where the medical kit is stored.
;;
;; Objects:
;;   1 drone  : droneA  (starts at aerodrome, full battery b4)
;;   5 locations (a line: hospital_mar - aerodrome - barceloneta - montjuic_pad - ciutadella):
;;     aerodrome       - El Prat emergency drone base          (DEPOT, kit1 here, no charger)
;;     hospital_mar    - Hospital del Mar (cut-off by flooding) (deliver kit1)
;;     barceloneta     - La Barceloneta flooded beach district  (inspect -> unlocks ciutadella)
;;     montjuic_pad    - Montjuic hilltop charging pad         (CHARGING STATION)
;;     ciutadella      - Parc de la Ciutadella evacuation hub   (LOCKED, inspect)
;;   1 supply: kit1 (medical_kit) at the depot (aerodrome)
;;
;; Design constraint (mandatory recharge):
;;   droneA starts FULL (b4), so the map itself forces the recharge.
;;   The map is a line and the drone starts between its two ends:
;;   hospital_mar (one side) and ciutadella (other side) must both be visited.
;;   So the drone must reach one end and come back: the cheapest way is
;;   aerodrome->hospital_mar->aerodrome (2 flights), then
;;   aerodrome->barceloneta->montjuic_pad->ciutadella (3 flights).
;;   Every complete mission needs at least 5 flights = 5 levels > 4.
;;   No recharge-free solution exists. On the best route the drone reaches
;;   montjuic_pad (the only charger) with b0, just before the last flight.
;;
;; Optimal plan cost: 10 in both models
;;   (5 flights + 2 inspections + pick-up + delivery + 1 recharge)
;;   Model A (instant full recharge): 10
;;   Model B (incremental +1/action):  10 (one recharge is enough: b0 -> b1
;;     covers the last flight montjuic_pad->ciutadella)
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
    ;; Line: hospital_mar - aerodrome - barceloneta - montjuic_pad - ciutadella
    ;; Both ends are mission sites, so the drone must go to one end and back:
    ;; this is what makes every complete route at least 5 flights long
    (connected aerodrome     hospital_mar) (connected hospital_mar aerodrome)
    (connected aerodrome     barceloneta)  (connected barceloneta  aerodrome)
    (connected barceloneta   montjuic_pad) (connected montjuic_pad barceloneta)
    (connected montjuic_pad  ciutadella)   (connected ciutadella   montjuic_pad)

    ;; ---- flight costs (all 1 level per edge) ---------------------------------
    (flight_cost aerodrome    hospital_mar b1) (flight_cost hospital_mar aerodrome    b1)
    (flight_cost aerodrome    barceloneta  b1) (flight_cost barceloneta  aerodrome    b1)
    (flight_cost barceloneta  montjuic_pad b1) (flight_cost montjuic_pad barceloneta  b1)
    (flight_cost montjuic_pad ciutadella   b1) (flight_cost ciutadella   montjuic_pad b1)

    ;; ---- distances (plan-cost per edge, equals flight cost here) ------------
    (= (distance aerodrome    hospital_mar) 1) (= (distance hospital_mar aerodrome)    1)
    (= (distance aerodrome    barceloneta)  1) (= (distance barceloneta  aerodrome)    1)
    (= (distance barceloneta  montjuic_pad) 1) (= (distance montjuic_pad barceloneta)  1)
    (= (distance montjuic_pad ciutadella)   1) (= (distance ciutadella   montjuic_pad) 1)

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
    (supply_at kit1 aerodrome)             ; medical kit stored at the depot
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
