#!/bin/bash
clean() {
  rm reports/*
  rm log/*
  rm output_files/*
  rm input_files/accumulated_data.csv
  rm input_files/interim_log.csv
}
append_dat() {
  Rscript --no-save --no-restore append_sim_data.R
}
run_main() {
  Rscript --no-save --no-restore --verbose main.R
}

while getopts 'cdr' flag; do
  case "${flag}" in
    c) echo "Cleaning directories"; clean ;;
    d) echo "Appending simulated data"; append_dat ;;
    r) echo "Running main.R"; run_main ;;
  esac
done
