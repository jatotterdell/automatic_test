library(automaticr)

file_path <- "input_files/accumulated_data.csv"

# think you intended size = 1?, the default is to generate length of x
new_dat <- automaticr::generate_trial_data(500, 
  seed = sample(0:9999, size = 1),
  effect = seq(1/35, 1/28, length.out = 13))
if(file.exists(file_path)) {
  readr::write_csv(new_dat, file_path, append = TRUE)
} else {
  readr::write_csv(new_dat, file_path, append = FALSE)
}
