
check_stan_example <- function() {
  
  model_str = "// saved as 8schools.stan
  data {
    int<lower=0> J;         // number of schools 
    real y[J];              // estimated treatment effects
    real<lower=0> sigma[J]; // standard error of effect estimates 
  }
  parameters {
    real mu;                // population treatment effect
    real<lower=0> tau;      // standard deviation in treatment effects
    vector[J] eta;          // unscaled deviation from mu by school
  }
  transformed parameters {
    vector[J] theta = mu + tau * eta;        // school treatment effects
  }
  model {
    target += normal_lpdf(eta | 0, 1);       // prior log-density
    target += normal_lpdf(y | theta, sigma); // log-likelihood
  }"
  
  schools_dat <- list(J = 8, 
                      y = c(28,  8, -3,  7, -1,  1, 18, 12),
                      sigma = c(15, 10, 16, 11,  9, 11, 10, 18))
  
  fit <- rstan::stan(model_code = model_str, data = schools_dat,
                     verbose = T)
  NULL
  
}