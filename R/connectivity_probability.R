connectivity_probability <- function(effective_mesh_size, area_total) {
  total_habitat <- sum(area_total)
  prob_connect <- effective_mesh_size / total_habitat
  prob_connect
}
