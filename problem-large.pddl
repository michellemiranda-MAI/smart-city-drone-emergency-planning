;; ============================================================================
;; problem-large.pddl : Instance 3 (large) - Tarragona chemical emergency
;; 3 drones spread over three regions (port, rambla, campus).
;; Scenario (loosely based on Tarragona): a leak at the petrochemical park.
;; Responders need a radio relay (comm1) at Bonavista before drones may enter
;; the park; the old town (Part Alta) stays closed until the Roman
;; amphitheatre below it is inspected for structural damage.
;; 12 locations, 2 depots (port, estacio), 3 charging stations,
;; battery capacity 6 (b0-b6), flight costs 1-3 levels per edge.
;; 8 goals: 4 deliveries + 4 inspections.
;; Generated from one edge list, so flight_cost and distance always match.
;; ============================================================================

(define (problem drone-large)
  (:domain drone_emergency)

  (:objects
    droneA droneB droneC - drone
    port serrallo bonavista petrochem       ; west bank (port and industry)
    francoli                                ; river crossing
    estacio rambla amfiteatre part_alta     ; city centre
    campus hospital pont_diable             ; north
      - location
    comm1 - communication_device
    water1 - water_package
    kit1 kit2 - medical_kit
    b0 b1 b2 b3 b4 b5 b6 - level
  )

  (:init
    ;; ---- drones: full battery, empty cargo ----
    (drone_at droneA port) (battery droneA b6) (cargo_empty droneA)
    (drone_at droneB rambla) (battery droneB b6) (cargo_empty droneB)
    (drone_at droneC campus) (battery droneC b6) (cargo_empty droneC)

    ;; ---- map: every edge in both directions ----
    (connected port serrallo) (connected serrallo port)
    (connected port bonavista) (connected bonavista port)
    (connected serrallo bonavista) (connected bonavista serrallo)
    (connected bonavista petrochem) (connected petrochem bonavista)
    (connected port francoli) (connected francoli port)
    (connected francoli estacio) (connected estacio francoli)
    (connected hospital francoli) (connected francoli hospital)
    (connected estacio rambla) (connected rambla estacio)
    (connected rambla amfiteatre) (connected amfiteatre rambla)
    (connected amfiteatre part_alta) (connected part_alta amfiteatre)
    (connected rambla part_alta) (connected part_alta rambla)
    (connected rambla campus) (connected campus rambla)
    (connected campus hospital) (connected hospital campus)
    (connected campus pont_diable) (connected pont_diable campus)
    (connected bonavista campus) (connected campus bonavista)

    ;; ---- flight cost in battery levels ----
    (flight_cost port serrallo b1) (flight_cost serrallo port b1)
    (flight_cost port bonavista b2) (flight_cost bonavista port b2)
    (flight_cost serrallo bonavista b1) (flight_cost bonavista serrallo b1)
    (flight_cost bonavista petrochem b1) (flight_cost petrochem bonavista b1)
    (flight_cost port francoli b1) (flight_cost francoli port b1)
    (flight_cost francoli estacio b1) (flight_cost estacio francoli b1)
    (flight_cost hospital francoli b2) (flight_cost francoli hospital b2)
    (flight_cost estacio rambla b1) (flight_cost rambla estacio b1)
    (flight_cost rambla amfiteatre b1) (flight_cost amfiteatre rambla b1)
    (flight_cost amfiteatre part_alta b1) (flight_cost part_alta amfiteatre b1)
    (flight_cost rambla part_alta b2) (flight_cost part_alta rambla b2)
    (flight_cost rambla campus b2) (flight_cost campus rambla b2)
    (flight_cost campus hospital b1) (flight_cost hospital campus b1)
    (flight_cost campus pont_diable b2) (flight_cost pont_diable campus b2)
    (flight_cost bonavista campus b3) (flight_cost campus bonavista b3)

    ;; ---- distance for plan cost (same numbers as flight_cost) ----
    (= (distance port serrallo) 1) (= (distance serrallo port) 1)
    (= (distance port bonavista) 2) (= (distance bonavista port) 2)
    (= (distance serrallo bonavista) 1) (= (distance bonavista serrallo) 1)
    (= (distance bonavista petrochem) 1) (= (distance petrochem bonavista) 1)
    (= (distance port francoli) 1) (= (distance francoli port) 1)
    (= (distance francoli estacio) 1) (= (distance estacio francoli) 1)
    (= (distance hospital francoli) 2) (= (distance francoli hospital) 2)
    (= (distance estacio rambla) 1) (= (distance rambla estacio) 1)
    (= (distance rambla amfiteatre) 1) (= (distance amfiteatre rambla) 1)
    (= (distance amfiteatre part_alta) 1) (= (distance part_alta amfiteatre) 1)
    (= (distance rambla part_alta) 2) (= (distance part_alta rambla) 2)
    (= (distance rambla campus) 2) (= (distance campus rambla) 2)
    (= (distance campus hospital) 1) (= (distance hospital campus) 1)
    (= (distance campus pont_diable) 2) (= (distance pont_diable campus) 2)
    (= (distance bonavista campus) 3) (= (distance campus bonavista) 3)

    ;; ---- charging stations (bonavista is also a mission site) ----
    (has_charging_station bonavista) (has_charging_station rambla) (has_charging_station campus)

    ;; ---- access: everything open except petrochem and part_alta ----
    (accessible port) (accessible serrallo) (accessible bonavista) (accessible francoli)
    (accessible estacio) (accessible rambla) (accessible amfiteatre) (accessible campus)
    (accessible hospital) (accessible pont_diable)
    (unlocked_by_delivery comm1 petrochem)
    (unlocked_by_inspection amfiteatre part_alta)

    ;; ---- supplies at the depots and where they are needed ----
    (supply_at comm1 port)
    (supply_at water1 port)
    (supply_at kit1 estacio)
    (supply_at kit2 estacio)
    (needs_supply bonavista comm1)
    (needs_supply serrallo water1)
    (needs_supply part_alta kit1)
    (needs_supply hospital kit2)

    ;; ---- mission sites to inspect ----
    (needs_inspection francoli) (needs_inspection amfiteatre) (needs_inspection petrochem) (needs_inspection pont_diable)

    ;; ---- battery arithmetic (capacity 6, costs 1, 2, 3) ----
    ;; before - cost = left, only when before >= cost: 15 facts
    (battery_after b6 b1 b5) (battery_after b5 b1 b4) (battery_after b4 b1 b3)
    (battery_after b3 b1 b2) (battery_after b2 b1 b1) (battery_after b1 b1 b0)
    (battery_after b6 b2 b4) (battery_after b5 b2 b3) (battery_after b4 b2 b2)
    (battery_after b3 b2 b1) (battery_after b2 b2 b0)
    (battery_after b6 b3 b3) (battery_after b5 b3 b2) (battery_after b4 b3 b1)
    (battery_after b3 b3 b0)
    (next_level b0 b1) (next_level b1 b2) (next_level b2 b3) (next_level b3 b4) (next_level b4 b5) (next_level b5 b6)
    (max_level b6)

    (= (total-cost) 0)
  )

  (:goal (and
    (delivered comm1 bonavista)
    (delivered water1 serrallo)
    (delivered kit1 part_alta)
    (delivered kit2 hospital)
    (inspected francoli)
    (inspected amfiteatre)
    (inspected petrochem)   ; locked until comm1 reaches bonavista
    (inspected pont_diable)
  ))

  (:metric minimize (total-cost))
)
