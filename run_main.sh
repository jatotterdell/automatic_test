#!/bin/bash
clean() {
  find reports/ -maxdepth 1 -name '*' ! -name .gitignore -type f -delete
  find log/ -maxdepth 1 -name '*' ! -name .gitignore -type f -delete
  find output_files/ -maxdepth 1 -name '*' ! -name .gitignore -type f -delete
  find input_files/ -maxdepth 1 -name '*' ! -name .gitignore -type f -delete
  find interim_data/ -maxdepth 1 -name '*' ! -name .gitignore -type f -delete
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
