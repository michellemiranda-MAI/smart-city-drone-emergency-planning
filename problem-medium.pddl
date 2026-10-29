;; ============================================================================
;; problem-medium.pddl : Barcelona Flood Emergency - Medium Instance
;;
;; Scenario: Severe storm surge and flash flooding strike Barcelona along the
;;   coastal strip and the Besos river basin. Two drones are coordinated:
;;   - droneA starts at Port Vell Emergency Depot (port_depot) with battery b5.
;;   - droneB starts at Torre Glories Tech District Charging Hub (glories_tower) with battery b4.
;;
;; Objects:
;;   2 drones: droneA, droneB
;;   8 locations:
;;     1 depot:
;;       port_depot      - Port Vell emergency logistics center (stores all supplies)
;;     2 charging stations:
;;       montjuic_pad    - Montjuic hilltop telecommunications & solar charging pad
;;       glories_tower   - Torre Glories charging hub / electrical substation
;;     5 mission sites:
;;       barceloneta     - Flooded beachside district (needs inspection)
;;       hospital_mar    - Coastal hospital cut off by floodwaters (needs kit1 & inspection)
;;       poblenou        - Industrial & residential district with flooded sewers (needs water1 & inspection)
;;       forum_shelter   - Parc del Forum coastal evacuation center (needs comm1)
;;       besos_delta     - Besos river delta & flood barrier (LOCKED until poblenou inspected; needs inspection)
;;
;;   3 supplies (3 different types):
;;     kit1   - medical_kit          (staged at port_depot, needed at hospital_mar)
;;     water1 - water_package        (staged at port_depot, needed at poblenou)
;;     comm1  - communication_device (staged at port_depot, needed at forum_shelter)
;;
;; Design constraint (locking precondition):
;;   besos_delta cannot be entered initially because (accessible besos_delta) is false.
;;   Inspecting poblenou unlocks besos_delta via (unlocked_by_inspection poblenou besos_delta).
;;   Any action sequence attempting to fly directly to besos_delta beforehand (e.g.
;;   from glories_tower, poblenou, or forum_shelter) fails because the (accessible besos_delta)
;;   precondition in the 'fly' action is not satisfied.
;; ============================================================================

(define (problem barcelona-flood-medium)
  (:domain drone_emergency)

  (:objects
    droneA droneB                                                             - drone
    port_depot montjuic_pad glories_tower barceloneta hospital_mar poblenou forum_shelter besos_delta - location
    kit1                                                                      - medical_kit
    water1                                                                    - water_package
    comm1                                                                     - communication_device
    b0 b1 b2 b3 b4 b5 b6                                                      - level
  )

  (:init

    ;; ---- drones --------------------------------------------------------------
    (drone_at droneA port_depot)
    (battery droneA b5)
    (cargo_empty droneA)

    (drone_at droneB glories_tower)
    (battery droneB b4)
    (cargo_empty droneB)

    ;; ---- map: connections (bidirectional) ------------------------------------
    (connected port_depot    montjuic_pad)  (connected montjuic_pad port_depot)
    (connected port_depot    barceloneta)   (connected barceloneta  port_depot)
    (connected port_depot    glories_tower) (connected glories_tower port_depot)
    (connected montjuic_pad  barceloneta)   (connected barceloneta  montjuic_pad)
    (connected barceloneta   hospital_mar)  (connected hospital_mar barceloneta)
    (connected hospital_mar  glories_tower) (connected glories_tower hospital_mar)
    (connected hospital_mar  poblenou)      (connected poblenou     hospital_mar)
    (connected glories_tower poblenou)      (connected poblenou     glories_tower)
    (connected glories_tower besos_delta)   (connected besos_delta  glories_tower)
    (connected poblenou      forum_shelter) (connected forum_shelter poblenou)
    (connected poblenou      besos_delta)   (connected besos_delta  poblenou)
    (connected forum_shelter besos_delta)   (connected besos_delta  forum_shelter)

    ;; ---- flight costs (varying 1 and 2 levels per edge) ----------------------
    ;; Cost 1 edges:
    (flight_cost port_depot    montjuic_pad  b1) (flight_cost montjuic_pad  port_depot    b1)
    (flight_cost port_depot    barceloneta   b1) (flight_cost barceloneta   port_depot    b1)
    (flight_cost barceloneta   hospital_mar  b1) (flight_cost hospital_mar  barceloneta   b1)
    (flight_cost hospital_mar  poblenou      b1) (flight_cost poblenou      hospital_mar  b1)
    (flight_cost glories_tower poblenou      b1) (flight_cost poblenou      glories_tower b1)
    (flight_cost poblenou      forum_shelter b1) (flight_cost forum_shelter poblenou      b1)
    (flight_cost poblenou      besos_delta   b1) (flight_cost besos_delta   poblenou      b1)
    (flight_cost forum_shelter besos_delta   b1) (flight_cost besos_delta   forum_shelter b1)

    ;; Cost 2 edges:
    (flight_cost port_depot    glories_tower b2) (flight_cost glories_tower port_depot    b2)
    (flight_cost montjuic_pad  barceloneta   b2) (flight_cost barceloneta   montjuic_pad  b2)
    (flight_cost hospital_mar  glories_tower b2) (flight_cost glories_tower hospital_mar  b2)
    (flight_cost glories_tower besos_delta   b2) (flight_cost besos_delta   glories_tower b2)

    ;; ---- distances (metric plan-cost per edge) -------------------------------
    (= (distance port_depot    montjuic_pad)  1) (= (distance montjuic_pad  port_depot)    1)
    (= (distance port_depot    barceloneta)   1) (= (distance barceloneta   port_depot)    1)
    (= (distance barceloneta   hospital_mar)  1) (= (distance hospital_mar  barceloneta)   1)
    (= (distance hospital_mar  poblenou)      1) (= (distance poblenou      hospital_mar)  1)
    (= (distance glories_tower poblenou)      1) (= (distance poblenou      glories_tower) 1)
    (= (distance poblenou      forum_shelter) 1) (= (distance forum_shelter poblenou)      1)
    (= (distance poblenou      besos_delta)   1) (= (distance besos_delta   poblenou)      1)
    (= (distance forum_shelter besos_delta)   1) (= (distance besos_delta   forum_shelter) 1)

    (= (distance port_depot    glories_tower) 2) (= (distance glories_tower port_depot)    2)
    (= (distance montjuic_pad  barceloneta)   2) (= (distance barceloneta   montjuic_pad)  2)
    (= (distance hospital_mar  glories_tower) 2) (= (distance glories_tower hospital_mar)  2)
    (= (distance glories_tower besos_delta)   2) (= (distance besos_delta   glories_tower) 2)

    ;; ---- infrastructure ------------------------------------------------------
    (has_charging_station montjuic_pad)
    (has_charging_station glories_tower)

    ;; ---- accessibility -------------------------------------------------------
    (accessible port_depot)
    (accessible montjuic_pad)
    (accessible glories_tower)
    (accessible barceloneta)
    (accessible hospital_mar)
    (accessible poblenou)
    (accessible forum_shelter)
    ;; besos_delta is initially locked until poblenou is inspected
    (unlocked_by_inspection poblenou besos_delta)

    ;; ---- supplies (all 3 initially staged at port_depot) --------------------
    (supply_at kit1   port_depot)
    (supply_at water1 port_depot)
    (supply_at comm1  port_depot)

    ;; ---- delivery requirements (3 deliveries of 3 different types) -----------
    (needs_supply hospital_mar  kit1)
    (needs_supply poblenou      water1)
    (needs_supply forum_shelter comm1)

    ;; ---- inspection requirements (4 inspections) ----------------------------
    (needs_inspection barceloneta)
    (needs_inspection hospital_mar)
    (needs_inspection poblenou)
    (needs_inspection besos_delta)

    ;; ---- symbolic battery arithmetic (capacity b6 = 6 levels) ---------------
    ;; battery_after for cost b1:
    (battery_after b6 b1 b5) (battery_after b5 b1 b4)
    (battery_after b4 b1 b3) (battery_after b3 b1 b2)
    (battery_after b2 b1 b1) (battery_after b1 b1 b0)

    ;; battery_after for cost b2:
    (battery_after b6 b2 b4) (battery_after b5 b2 b3)
    (battery_after b4 b2 b2) (battery_after b3 b2 b1)
    (battery_after b2 b2 b0)

    ;; next_level chain (b0 to b6):
    (next_level b0 b1) (next_level b1 b2) (next_level b2 b3)
    (next_level b3 b4) (next_level b4 b5) (next_level b5 b6)
    (max_level b6)

    (= (total-cost) 0)
  )

  (:goal (and
    ;; 4 inspection goals:
    (inspected barceloneta)
    (inspected hospital_mar)
    (inspected poblenou)
    (inspected besos_delta)

    ;; 3 delivery goals (3 distinct supply types):
    (delivered kit1   hospital_mar)
    (delivered water1 poblenou)
    (delivered comm1  forum_shelter)
  ))

  (:metric minimize (total-cost))
)
