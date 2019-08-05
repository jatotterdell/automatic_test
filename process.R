# process sequence -----------------------------

# Setup
if(!file.exists(int_log_path)) {
  # Retrieve, interim control parameters e.g. number of arms, 
  # initial allocation probabilities.
  automaticr::init_interim_log(int_log_path)
}
if(!file.exists(paste0(alloc_seq_dir, "alloc_seq_0.csv"))) {
  message("Creating initial allocation sequence.")
  
  # minor - maybe encapsulate the seed generation in a public method rather 
  # than referencing an automaticr member obj directly
  seed <- as.numeric(automaticr:::interim_schedule[automaticr:::interim_schedule$interim_num == 0, "alloc_seed"])
  
  # as above wrt to init_alloc. 
  # can use double colon for prefixing automaticr methods for clarity and namespace.
  alloc_seq <- automaticr::generate_allocation_sequence(1000, automaticr:::trial_params$init_allocations, seed)
  write_allocation_sequence(paste0(alloc_seq_dir, "alloc_seq_0.csv"), alloc_seq, 0)
}

# Get information we need to determine if interim is due
raw_data            <- automaticr::read_raw_data(raw_dat_path)
proc_data           <- automaticr::process_raw_data(raw_data, ref_date = todays_date)
# First event for each parent id
index_data          <- automaticr::get_index_data(proc_data)
interim_log         <- automaticr::read_interim_log(int_log_path)
last_interim        <- dplyr::pull(tail(interim_log, 1), interim_num)
next_interim_sch    <- last_interim + 1
# Current sample size based on all those who are past the vax due date
current_sample_size <- sum(dplyr::pull(index_data, vax_past_due))

# What interim are we up to according to sample size?
current_interim     <- findInterval(current_sample_size, automaticr:::interim_schedule[, "interim_n"]) - 1
# Has this interim already been undertaken?
interim_due         <- current_interim > last_interim
# Is this the final analysis at maximum sample size?
final               <- current_interim == max(automaticr:::interim_schedule[, "interim_num"])

if(interim_due) {

  # was "warning" intenetional?
  message(paste("Interim is due\nCurrent index sample size:", current_sample_size))

  # minor - same comment as previous - it might be better to encapsulate the schedule in a public getter func
  interim_seeds <- as.numeric(automaticr:::interim_schedule[automaticr:::interim_schedule$interim_num == current_interim, c("alloc_seed", "stan_seed")])
  # aggregate into events/trials (gets rid of any on_time na values)
  agg_data      <- automaticr::aggregate_data(index_data)
  # sample size by arm
  arm_ss        <- agg_data %>% dplyr::group_by(randomisation_outcome) %>% dplyr::summarise(n = sum(trials)) %>% dplyr::pull(n)
  model_code    <- rstan::stan_model(file = "stan/automatic_model.stan", auto_write = TRUE)
  model_data    <- automaticr::make_model_data(agg_data)

  model_fit     <- rstan::sampling(model_code, data = model_data, seed = interim_seeds[2],
                                   control = list(adapt_delta = 0.999))
  model_draws   <- as.matrix(model_fit, pars = c("beta_ctr", "beta_trt", "gamma1", "gamma2", "gamma3"))
  model_mu      <- model_draws %*% t(automaticr:::design_matrix)
  post_quant    <- automaticr::get_posterior_quantities(model_mu, arm_ss)

  rstan::check_hmc_diagnostics(model_fit)

  alloc_seq <- generate_allocation_sequence(1000, post_quant$alloc_prob, interim_seeds[1])
  write_allocation_sequence(paste0(alloc_seq_dir, "alloc_seq_", current_interim, ".csv"), alloc_seq, current_interim)
  readr::write_csv(agg_data, paste0(interim_dat_dir, "dat_interim_", current_interim, ".csv"))

  # Generate Interim Reports in HTML and PDF
  if(!dir.exists("reports")) {
    dir.create("reports")
  }
  rmarkdown::render(
    "report.Rmd",
    bookdown::html_document2(),
    quiet = TRUE,
    output_file = paste0("reports/report_", current_interim),
    params = list(
      todays_date = todays_date,
      raw_dat = raw_data,
      proc_dat = proc_data,
      agg_dat = agg_data,
      mod_fit = model_fit,
      interim_num = current_interim,
      post_quant = post_quant))
  rmarkdown::render(
    "report.Rmd",
    bookdown::pdf_document2(),
    quiet = TRUE,
    output_file = paste0("reports/report_", current_interim),
    params = list(
      todays_date = todays_date,
      raw_dat = raw_data,
      proc_dat = proc_data,
      agg_dat = agg_data,
      mod_fit = model_fit,
      interim_num = current_interim,
      post_quant = post_quant))

  message("Interim complete. Updating interim log.")
  update_interim_log(int_log_path, todays_date, current_interim, current_sample_size, post_quant$alloc_prob, post_quant$is_alloc)

  quit(status = interim_completed_exit_code)

} else {

  message(paste("Interim not due\nCurrent index sample size:", current_sample_size))
  quit(status = threshold_not_reached_exit_code)

}
