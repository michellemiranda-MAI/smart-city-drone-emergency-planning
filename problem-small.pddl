;; ============================================================================
;; problem-small.pddl : Instance 1 (small) - Barcelona flood emergency
;; 1 drone (droneA) starting at aerodrome.
;; Scenario: storm surge and flooding cut off road access across Barcelona.
;; Parc de la Ciutadella stays locked until Barceloneta is inspected.
;; 5 locations, 1 depot (aerodrome), 1 charging station (montjuic_pad),
;; battery capacity 4 (b0-b4), flight cost 1 level per edge.
;; 3 goals: 1 delivery + 2 inspections.
;; Map forces at least one recharge at montjuic_pad (5 flights needed > b4).
;; ============================================================================

(define (problem barcelona-flood-small)
  (:domain drone_emergency)

  (:objects
    droneA                                                    - drone
    aerodrome montjuic_pad barceloneta hospital_viladecans ciutadella - location
    kit1                                                       - medical_kit
    b0 b1 b2 b3 b4                                            - level
  )

  (:init

    ;; ---- drone ---------------------------------------------------------------
    (drone_at droneA aerodrome)   ; droneA at El Prat emergency base
    (battery  droneA b4)          ; full battery: the map, not the start, forces the recharge
    (cargo_empty droneA)

    ;; ---- map: connections (bidirectional) ------------------------------------
    ;; Line: hospital_viladecans - aerodrome - barceloneta - montjuic_pad - ciutadella
    ;; Both ends are mission sites, so the drone must go to one end and back:
    ;; this is what makes every complete route at least 5 flights long
    (connected aerodrome     hospital_viladecans) (connected hospital_viladecans aerodrome)
    (connected aerodrome     barceloneta)  (connected barceloneta  aerodrome)
    (connected barceloneta   montjuic_pad) (connected montjuic_pad barceloneta)
    (connected montjuic_pad  ciutadella)   (connected ciutadella   montjuic_pad)

    ;; ---- flight costs (all 1 level per edge) ---------------------------------
    (flight_cost aerodrome    hospital_viladecans b1) (flight_cost hospital_viladecans aerodrome    b1)
    (flight_cost aerodrome    barceloneta  b1) (flight_cost barceloneta  aerodrome    b1)
    (flight_cost barceloneta  montjuic_pad b1) (flight_cost montjuic_pad barceloneta  b1)
    (flight_cost montjuic_pad ciutadella   b1) (flight_cost ciutadella   montjuic_pad b1)

    ;; ---- distances (plan-cost per edge, equals flight cost here) ------------
    (= (distance aerodrome    hospital_viladecans) 1) (= (distance hospital_viladecans aerodrome)    1)
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
    (accessible hospital_viladecans)
    ;; ciutadella NOT listed -- implicitly locked
    (unlocked_by_inspection barceloneta ciutadella)

    ;; ---- supplies -----------------------------------------------------------
    (supply_at kit1 aerodrome)             ; medical kit stored at the depot
    (needs_supply hospital_viladecans kit1)       ; Hospital de Viladecans awaits the kit

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
    (delivered kit1 hospital_viladecans)  ; Hospital de Viladecans receives emergency supplies
  ))

  (:metric minimize (total-cost))
)
