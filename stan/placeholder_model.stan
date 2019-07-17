data {
  int<lower=0> n;
  int<lower=0> y[n];
  int<lower=0> trials[n];
  // int<lower=0,upper=1> control[n];
  int<lower=0> n_randomisation_outcome;
  //int<lower=0> n_current_eligible_vaccination;
  int<lower=1,upper=n_randomisation_outcome> randomisation_outcome[n];
  //int<lower=1,upper=n_current_eligible_vaccination> current_eligible_vaccination[n];
}

parameters {
  real m_control;
  real m_treatment;
  real<lower=0> sd_randomisation_outcome;
  vector[n_randomisation_outcome - 1] b_randomisation_outcome;
  //vector[n_current_eligible_vaccination] b_current_eligible_vaccination;
}

transformed parameters {
  vector[n_randomisation_outcome - 1] m_randomisation_outcome;
  m_randomisation_outcome = m_treatment + sd_randomisation_outcome * b_randomisation_outcome;
}

model {
  vector[n] eta;
  for(i in 1:n) {
    if(randomisation_outcome[i] == 1)
      eta[i] = m_control;
    else
      eta[i] = m_randomisation_outcome[randomisation_outcome[i] - 1];
  }
  m_control ~ normal(0, 10);
  m_treatment ~ normal(0, 10);
  sd_randomisation_outcome ~ cauchy(0, 10);
  b_randomisation_outcome ~ normal(0, 1); // => ~ normal(int_treatment, sd_randomisation_outcome)
  y ~ binomial_logit(trials, eta);
}
