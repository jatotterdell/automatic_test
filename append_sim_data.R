library(automaticr)

file_path <- "input_files/accumulated_data.csv"

new_dat <- generate_trial_data(500, sample(0:9999))
if(file.exists(file_path)) {
  readr::write_csv(new_dat, file_path, append = TRUE)
} else {
  readr::write_csv(new_dat, file_path, append = FALSE)
}
