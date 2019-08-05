// Hiearchical model with
// three parameter groupings
data {
  int<lower=1> N;
  int<lower=1> K;
  int<lower=1> L1;
  int<lower=1> L2;
  int y[N];
  int n[N];
  matrix[N, K] X;   // design matrix for vax schedule
  int<lower=0,upper=1> control[N];
  int<lower=0,upper=L1> message[N];
  int<lower=0,upper=L2> timing[N];
  int<lower=0,upper=L1*L2> arm[N];
  int prior_only;
}

transformed data {
  int n_arms = L1*L2 + 1;
  real<lower=0> ran_sd = 10.0;
}

parameters {
  real beta_ctr;
  real beta_trt;
  vector[K] beta;
  vector[L1] gamma1_raw;
  vector[L2] gamma2_raw;
  vector[L1*L2] gamma3_raw;
  real<lower=0> sd_1;
  real<lower=0> sd_2;
  real<lower=0> sd_3;
}

transformed parameters {
  vector[L1] gamma1 = sd_1 * gamma1_raw;
  vector[L2] gamma2 = sd_2 * gamma2_raw;
  vector[L1*L2] gamma3 = sd_3 * gamma3_raw;
}

model {
  // These betas (corresponding to the vaccination scheduling (2m, 4, etc))
  // have contr.sum (sum to zero) contrasts such that when all these terms are
  // at zero we have an overall mean. This helps us as the approach 
  // unencumbers us from having to include these terms in our design matrix
  // when we compute the mean log odds from which we assess probability of 
  // best.
  vector[N] eta = X * beta;
  for (i in 1:N) {
    if(control[i] == 1) {
      // beta_ctr is the overall control mean log odds of vaccination on time.
      eta[i] += beta_ctr;
    }
    if(control[i] == 0) {
      // beta_trt is the overall control mean log odds of vaccination on time across
      // the active treatment groups, which is offset (with random intercepts) 
      // for message, timing and arm.
      // A good way to think about the model is to view it as a two way
      // anova (that includes an interaction) but for which we accomodate
      // clustering within message, timing and interaction and apply 
      // shrinkage based on the amount of information we have for each group.
      eta[i] += beta_trt + gamma1[message[i]] + gamma2[timing[i]] + gamma3[arm[i]];
  }
      
  }
  // priors including all constants
  target += normal_lpdf(beta_ctr | 0, 10);
  target += normal_lpdf(beta_trt | 0, 10);
  target += normal_lpdf(beta | 0, 10);
  
  // https://discourse.mc-stan.org/t/what-is-the-use-of-the-lccdf-suffix-function-in-setting-priors/5452/2
  // If you don’t subtract the log complimentary CDF for a half Student t distribution 
  // (or another distribution defined over the entire real line), then the log kernel 
  // of the posterior distribution would be off by a constant and some post-estimation methods, 
  // such as Bayes Factors, would be incorrectly calculated. Although doing so does not 
  // affect the posterior draws, packages such as brms have to be strictly correct 
  // because we cannot know what the user is going to do with the results subsequently.
  
  target += student_t_lpdf(sd_1 | 3, 0, ran_sd) - 1 * student_t_lccdf(0 | 3, 0, ran_sd);
  target += student_t_lpdf(sd_2 | 3, 0, ran_sd) - 1 * student_t_lccdf(0 | 3, 0, ran_sd);
  target += student_t_lpdf(sd_3 | 3, 0, ran_sd) - 1 * student_t_lccdf(0 | 3, 0, ran_sd);
  target += normal_lpdf(gamma1_raw | 0, 1);
  target += normal_lpdf(gamma2_raw | 0, 1);
  target += normal_lpdf(gamma3_raw | 0, 1);

  // likelihood
  if(!prior_only)
    target += binomial_logit_lpmf(y | n, eta);
}

generated quantities {
  vector[n_arms] mu;
  int<lower=1,upper=n_arms> rnk[n_arms];
  int<lower=0,upper=1> p_best[n_arms];
  int<lower=0,upper=1> p_better_than_control[n_arms];

  mu[1] = beta_ctr;
  // say L1 is 4, L2 is 3
  // indexing mu goes from 2:13, indexing gamma3 goes from 1:12
  for(i in 1:L1) {
    for(j in 1:L2) {
      mu[L2*(i - 1) + j + 1] = beta_trt + gamma1[i] + gamma2[j] + gamma3[L2*(i - 1) + j];
    }
  }

  // rank means and calculate probability best
  {
    int dsc[n_arms];
    dsc = sort_indices_desc(mu);
    for(i in 1:n_arms) {
      rnk[dsc[i]] = i;
      p_best[i] = (rnk[i] == 1);
      p_better_than_control[i] = (mu[i] > mu[1]);
    }
  }
}
