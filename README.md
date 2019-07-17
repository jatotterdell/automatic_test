# AUTOMATIC Test

## Overview of scripts

`run_main.sh` can be used to clean out folders, simulate source data and initiate interim analysis.

Note that the simulated data will include a variable for the arm to which each participant was randomised.

`main.R` is the R entry point, is invoked by `run_main.sh`, sets up various directories and sources `process.R`, which process the data contained under the `input_files` directory. Amongst other things, the `accumulated_data.csv` file contains the participant data and the `interim_log.csv` contains the current randomisation probabilities.

`process.R` is responsible for invoking `automaticr` commands to initialise and store the allocation sequence, mung input data, decide on whether an interim analysis is due and if so run it. The interim analysis is run using `stan` to fit a binomial response hierarchical model that is used to compute the log-odds of timely vaccination (before or equal to 28 days) in each of the arms. These results are then used to update the allocation probabilities for randomising further individuals into the trial. Finally, the script generates interim reports that summarise the results.





