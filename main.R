# Assumes build has:
#   - installed automaticr
#   - initialised necessary directory structure

library(automaticr)
library(futile.logger)
library(tryCatchLog)
library(rstan)
library(rmarkdown)
library(tidyverse)
library(lubridate)

options(mc.cores = parallel::detectCores() - 1)

todays_date <- Sys.Date()
threshold_not_reached_exit_code <- 100
interim_completed_exit_code <- 2

# Fixed files
raw_dat_path  <- "input_files/accumulated_data.csv"
int_log_path  <- "input_files/interim_log.csv"
mod_path      <- "stan/automatic_model_ran.stan"
alloc_seq_dir <- "output_files/"
log_dir       <- "log/"

if(!dir.exists(log_dir)) {
  message("Creating log folder.")
  dir.create(log_dir)
}

options(keep.source = TRUE)
flog.threshold(INFO)
flog.appender(appender.file(paste0(log_dir, "run_", todays_date, ".log")))

tryCatchLog({
  source("process.R")}
)
