# _targets.R
## Load your packages, e.g. library(targets).
source("packages.R")

# facilitate this working in parallel
controller <- crew_controller_local(
  name = "my_controller",
  workers = 4,
  seconds_idle = 3
)

tar_option_set(
  controller = controller
)

## Assign like regular R, just make sure to pipe into a tar_ operation
tar_assign({
  ## TODO - use knox data (fairy wren data)
  barrier <- example_barrier() |> tar_terra_rast()
  barrier_scenario_a <- example_barrier_scenario() |> tar_terra_rast()
  habitat <- example_habitat() |> tar_terra_rast()

  species <- tar_target("Blue-tongued Lizard")
  interpatch_distance <- tar_target(c(20, 40))

  baseline_connectivity <- habitat_connectivity(
    habitat = habitat,
    barrier = barrier,
    species = species,
    interpatch_distance = interpatch_distance
  ) |>
    tar_target(
      pattern = map(interpatch_distance)
    )

  scenario_a_connectivity <- habitat_connectivity(
    habitat = habitat,
    barrier = barrier_scenario_a,
    species = species,
    interpatch_distance = interpatch_distance
  ) |>
    tar_target(
      pattern = map(interpatch_distance)
    )

  scenario_a_comparison <- compare_connectivity(
    scenario = scenario_a_connectivity,
    baseline = baseline_connectivity,
    scenario_name = "A new road"
  ) |>
    tar_target(
      pattern = map(scenario_a_connectivity, baseline_connectivity)
    )
})
