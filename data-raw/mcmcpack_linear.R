### Shana comment Jan 2021:
### I'm deleting the data object created by this code and adding the simulation code 
### conditionally to the test files since CRAN is wanting the tarball to be smaller
### for coming release. Perhaps we can compress files going forward to keep a central data source?

# 
#  Generate an example MCMCpack linear fitted model
#

if (require("MCMCpack", quietly = TRUE)) {
  
## fitting the model with MCMCpack
mcmcpack_linear <- MCMCpack::MCMCregress(Y ~ X, b0 = 0, B0 = 0.001,
                                         sigma.mu = 5, sigma.var = 10,
                                         data = list(X = rnorm(100),
                                                     Y = rnorm(100, 5, 5)),
                                         seed = 1)

## save model object
usethis::use_data(mcmcpack_linear, overwrite = TRUE)

}
