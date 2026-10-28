;; Figure 1 example from the statement (expected optimal cost 10)
(define (problem figure1)
  (:domain drone_emergency)
  (:objects
    droneA droneB - drone
    port center charging tower hospital plant - location
    kit1 - medical_kit
    b0 b1 b2 b3 b4 b5 - level
  )
  (:init
    (drone_at droneA port) (battery droneA b2) (cargo_empty droneA)
    (drone_at droneB tower) (battery droneB b4) (cargo_empty droneB)

    (connected port center) (connected center port)
    (connected port charging) (connected charging port)
    (connected center tower) (connected tower center)
    (connected center hospital) (connected hospital center)
    (connected charging hospital) (connected hospital charging)
    (connected tower plant) (connected plant tower)

    (flight_cost port center b1) (flight_cost center port b1)
    (flight_cost port charging b1) (flight_cost charging port b1)
    (flight_cost center tower b1) (flight_cost tower center b1)
    (flight_cost center hospital b2) (flight_cost hospital center b2)
    (flight_cost charging hospital b2) (flight_cost hospital charging b2)
    (flight_cost tower plant b2) (flight_cost plant tower b2)

    (= (distance port center) 1) (= (distance center port) 1)
    (= (distance port charging) 1) (= (distance charging port) 1)
    (= (distance center tower) 1) (= (distance tower center) 1)
    (= (distance center hospital) 2) (= (distance hospital center) 2)
    (= (distance charging hospital) 2) (= (distance hospital charging) 2)
    (= (distance tower plant) 2) (= (distance plant tower) 2)

    (has_charging_station charging)

    (accessible port) (accessible center) (accessible charging)
    (accessible tower) (accessible hospital)
    (unlocked_by_inspection tower plant)

    (supply_at kit1 port)
    (needs_supply hospital kit1)
    (needs_inspection tower) (needs_inspection plant)

    (battery_after b5 b1 b4) (battery_after b4 b1 b3) (battery_after b3 b1 b2)
    (battery_after b2 b1 b1) (battery_after b1 b1 b0)
    (battery_after b5 b2 b3) (battery_after b4 b2 b2) (battery_after b3 b2 b1)
    (battery_after b2 b2 b0)
    (next_level b0 b1) (next_level b1 b2) (next_level b2 b3)
    (next_level b3 b4) (next_level b4 b5)
    (max_level b5)

    (= (total-cost) 0)
  )
  (:goal (and
    (inspected tower)
    (inspected plant)
    (delivered kit1 hospital)
  ))
  (:metric minimize (total-cost))
)
