# process sequence -----------------------------

# Setup
if(!file.exists(int_log_path)) {
  init_interim_log(int_log_path)
}
if(!file.exists(paste0(alloc_seq_dir, "alloc_seq_0.csv"))) {
  message("Creating initial allocation sequence.")
  seed <- as.numeric(automaticr:::interim_schedule[automaticr:::interim_schedule$interim_num == 0, "alloc_seed"])
  alloc_seq <- generate_allocation_sequence(1000, automaticr:::trial_params$init_allocations, seed)
  write_allocation_sequence(paste0(alloc_seq_dir, "alloc_seq_0.csv"), alloc_seq, 0)
}

# Get information we need to determine if interim is due
raw_data            <- read_raw_data(raw_dat_path)
proc_data           <- process_raw_data(raw_data, todays_date)
index_data          <- get_index_data(proc_data)
interim_log         <- read_interim_log(int_log_path)
last_interim        <- dplyr::pull(tail(interim_log, 1), interim_num)
next_interim        <- last_interim + 1
current_sample_size <- sum(dplyr::pull(index_data, vax_past_due))
interim_due         <- current_sample_size >= automaticr:::interim_schedule[
  automaticr:::interim_schedule$interim_num == next_interim, "interim_n"]
final               <- next_interim == max(automaticr:::interim_schedule[
  automaticr:::interim_schedule$interim_num == next_interim, "interim_num"])

if(interim_due) {

  warning(paste("Interim is due\nCurrent index sample size:", current_sample_size))

  interim_seeds <- as.numeric(automaticr:::interim_schedule[automaticr:::interim_schedule$interim_num == next_interim, c("alloc_seed", "stan_seed")])
  agg_data      <- aggregate_data(index_data)
  arm_ss        <- agg_data %>% group_by(randomisation_outcome) %>% summarise(n = sum(trials)) %>% pull(n)
  model_code    <- rstan::stan_model(file = mod_path)
  model_data    <- tidybayes::compose_data(agg_data[, c("y", "trials", "randomisation_outcome")])
  model_fit     <- rstan::sampling(model_code, data = model_data, seed = interim_seeds[2])
  model_draws   <- as.matrix(model_fit, pars = c("m_control", "m_randomisation_outcome"))
  post_quant    <- get_posterior_quantities(model_draws, arm_ss)

  rstan::check_hmc_diagnostics(model_fit)

  alloc_seq <- generate_allocation_sequence(1000, post_quant$alloc_prob, interim_seeds[1])
  write_allocation_sequence(paste0(alloc_seq_dir, "alloc_seq_", next_interim, ".csv"), alloc_seq, next_interim)

  # Generate Interim Reports in HTML and PDF
  if(!dir.exists("reports")) {
    dir.create("reports")
  }
  rmarkdown::render(
    "report.Rmd",
    bookdown::html_document2(),
    quiet = TRUE,
    output_file = paste0("reports/report_", next_interim),
    params = list(
      todays_date = todays_date,
      dat = index_data,
      fit = model_fit,
      interim_num = next_interim))
  rmarkdown::render(
    "report.Rmd",
    bookdown::pdf_document2(),
    quiet = TRUE,
    output_file = paste0("reports/report_", next_interim),
    params = list(
      todays_date = todays_date,
      dat = index_data,
      fit = model_fit,
      interim_num = next_interim))

  message("Updating interim log.")
  update_interim_log(int_log_path, todays_date, next_interim, current_sample_size, post_quant$alloc_prob, post_quant$is_alloc)

  quit(status = interim_completed_exit_code)

} else {

  warning(paste("Interim not due\nCurrent index sample size:", current_sample_size))
  quit(status = threshold_not_reached_exit_code)

}
