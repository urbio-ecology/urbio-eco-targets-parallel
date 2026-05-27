summarise_connectivity_scenario <- function(
  new_area_squared,
  new_area_total,
  baseline_area_total,
  buffer_distance,
  species_name
) {
  results <- tibble::tibble(
    species_name = species_name,
    buffer_distance = buffer_distance,
    n_patches = n_patches(new_area_total),
    effective_mesh_ha = effective_mesh_size(
      new_area_squared,
      baseline_area_total
    ),
    prob_connectedness = connectivity_probability(
      effective_mesh_size = effective_mesh_ha,
      area_total = baseline_area_total
    )
  ) |>
    dplyr::mutate(
      prob_connectedness = round(prob_connectedness, 6),
      effective_mesh_ha = round(effective_mesh_ha)
    )

  results
}
