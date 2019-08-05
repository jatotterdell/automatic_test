#!/bin/bash

usage()
{
  echo "Usage: run_main [ACTION]... PATTERNS..."
  echo "Try 'run_main -h' for help."
}
help()
{
  echo "Help"
  echo "c = Cleaning directories"
  echo "d = Appending simulated data"
  echo "r = Running main.R"
}
clean() {
  find reports/ -maxdepth 1 -name '*' ! -name .gitignore -type f -delete
  find log/ -maxdepth 1 -name '*' ! -name .gitignore -type f -delete
  find output_files/ -maxdepth 1 -name '*' ! -name .gitignore -type f -delete
  find input_files/ -maxdepth 1 -name '*' ! -name .gitignore -type f -delete
  find interim_data/ -maxdepth 1 -name '*' ! -name .gitignore -type f -delete
}
append_dat() {
  /sbin/Rscript --no-save --no-restore append_sim_data.R
}
run_main() {
  /sbin/Rscript --no-save --no-restore --verbose main.R
}

while getopts ':cdrh' flag; do
  case "${flag}" in
    c) echo "Cleaning directories"; clean ;;
    d) echo "Appending simulated data"; append_dat ;;
    r) echo "Running main.R"; run_main ;;
    h) echo "Showing help information" ; help;;
    \?) echo "No option selected"; usage;; 
  esac
done

if [ $OPTIND -eq 1 ]; then usage; fi
