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
  barrier <- example_barrier() |> tar_terra_rast()
  habitat <- example_habitat() |> tar_terra_rast()

  species_name <- tar_target("Blue-Tongued-Lizard")
  target_resolution <- tar_target(500)
  data_resolution <- tar_target(10)
  aggregation_factor <- tar_target(target_resolution / data_resolution)
  buffer_distance <- tar_target(10)

  barrier_mask <- create_barrier_mask(barrier) |> tar_terra_rast()
  remaining <- drop_habitat_under_barrier(habitat, barrier_mask) |>
    tar_terra_rast()
  buffered_habitat <- habitat_buffer(remaining, distance = buffer_distance) |>
    tar_terra_rast(
      pattern = map(buffer_distance)
    )
  fragmentation_raster <- fragment_habitat(buffered_habitat, barrier_mask) |>
    tar_terra_rast(
      pattern = map(buffered_habitat)
    )
  # get IDs of connected areas
  # intersect with habitat to get area IDs of habitat patches
  patches <- assign_patches_to_fragments(remaining, fragmentation_raster) |>
    add_patch_area() |>
    tar_terra_rast(
      pattern = map(fragmentation_raster)
    )
  areas <- aggregate_connected_patches(patches) |>
    tar_target(
      pattern = map(patches)
    )

  # or as one step
  areas_connected <- habitat_connectivity(
    habitat = habitat,
    barrier = barrier,
    distance = buffer_distance
  ) |>
    tar_target(
      pattern = map(buffer_distance),
      iteration = "list"
    )

  results_connect_habitat <- summarise_connectivity(
    area_squared = areas_connected$area_squared,
    area_total = areas_connected$area,
    buffer_distance = buffer_distance,
    target_resolution = target_resolution,
    data_resolution = data_resolution,
    aggregation_factor = aggregation_factor,
    species_name = species_name
  ) |>
    tar_target(
      pattern = map(areas_connected, buffer_distance)
    )

  urbio_pal <- scico(n = 11, palette = "tofino") |>
    vec_slice(c(7, 10)) |>
    # add white
    c(col2hex("white")) |>
    tar_target()

  urbio_cols <- list(
    habitat = urbio_pal[1],
    buffer = urbio_pal[2],
    barrier = urbio_pal[3]
  ) |>
    tar_target()

  saved_spatraster <- plot_barrier_habitat_buffer(
    barrier = barrier,
    buffered = buffered_habitat,
    habitat = habitat,
    distance = buffer_distance,
    species_name = species_name,
    col_barrier = urbio_cols$barrier,
    col_buffer = urbio_cols$buffer,
    col_habitat = urbio_cols$habitat,
    col_paper = "grey96"
  ) |>
    tar_file(
      pattern = map(buffered_habitat, buffer_distance)
    )
})
