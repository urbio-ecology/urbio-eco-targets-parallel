# _targets.R
## Load your packages, e.g. library(targets).
source("packages.R")

## Load any R files
tar_source()

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
  barrier_scenario_a <- example_barrier() |> tar_terra_rast()
  habitat <- example_habitat() |> tar_terra_rast()

  species_name <- tar_target("Blue-Tongued-Lizard")
  target_resolution <- tar_target(500)
  data_resolution <- tar_target(10)
  aggregation_factor <- tar_target(target_resolution / data_resolution)
  buffer_distance <- tar_target(10)

  baseline_connectivity <- habitat_connectivity(
    habitat = habitat,
    barrier = barrier,
    distance = buffer_distance
  ) |>
    tar_target(
      pattern = map(buffer_distance),
      iteration = "list"
    )

  scenario_a_connectivity <- habitat_connectivity(
    habitat = habitat,
    barrier = barrier_scenario_a,
    distance = buffer_distance
  ) |>
    tar_target(
      pattern = map(buffer_distance),
      iteration = "list"
    )

  results_baseline_connectivity <- summarise_connectivity(
    area_squared = baseline_connectivity$area_squared,
    area_total = baseline_connectivity$area,
    buffer_distance = buffer_distance,
    target_resolution = target_resolution,
    data_resolution = data_resolution,
    aggregation_factor = aggregation_factor,
    species_name = species_name
  ) |>
    tar_target(
      pattern = map(baseline_connectivity, buffer_distance)
    )

  results_scenario_a_connectivity <- summarise_connectivity_scenario(
    new_area_squared = scenario_a_connectivity$area_squared,
    new_area_total = scenario_a_connectivity$area,
    baseline_area_total = baseline_connectivity$area,
    buffer_distance = buffer_distance,
    species_name = species_name
  ) |>
    tar_target(
      pattern = map(baseline_connectivity, buffer_distance)
    )
})
