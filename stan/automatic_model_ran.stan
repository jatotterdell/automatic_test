// Hiearchical model with
// three parameter groupings
data {
  int<lower=1> N;
  int<lower=1> K;
  int<lower=1> L1;
  int<lower=1> L2;
  int<lower=1> L3;
  int y[N];
  int n[N];
  matrix[N, K] X;   // design matrix
  matrix[N, L1] Z1; // grouping 1
  matrix[N, L2] Z2; // grouping 2
  matrix[N, L3] Z3; // grouping 3
  int prior_only;
}
parameters {
  vector[K] beta;
  vector[L1] gamma1_raw;
  vector[L2] gamma2_raw;
  vector[L3] gamma3_raw;
  real<lower=0> sd_1;
  real<lower=0> sd_2;
  real<lower=0> sd_3;
}
transformed parameters {
  vector[L1] gamma1 = sd_1 * gamma1_raw;
  vector[L2] gamma2 = sd_2 * gamma2_raw;
  vector[L3] gamma3 = sd_3 * gamma3_raw;
  vector[N] mu;
  for (i in 1:N) {
    mu[i] = X[i, ] * beta + Z1[i, ] * gamma1 + Z2[i, ] * gamma2 + Z3[i, ] * gamma3;
  }
}
model {
  // priors including all constants
  target += normal_lpdf(beta | 0, 10);
  target += student_t_lpdf(sd_1 | 3, 0, 10) - 1 * student_t_lccdf(0 | 3, 0, 10);
  target += student_t_lpdf(sd_2 | 3, 0, 10) - 1 * student_t_lccdf(0 | 3, 0, 10);
  target += student_t_lpdf(sd_3 | 3, 0, 10) - 1 * student_t_lccdf(0 | 3, 0, 10);
  target += normal_lpdf(gamma1_raw | 0, 1);
  target += normal_lpdf(gamma2_raw | 0, 1);
  target += normal_lpdf(gamma3_raw | 0, 1);

  // likelihood
  if(!prior_only)
    target += binomial_logit_lpmf(y | n, mu);
}
