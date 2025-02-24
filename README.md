# qch: Query Composite Hypotheses

[![CRAN\_Status\_Badge](https://www.r-pkg.org/badges/version/qch)](https://cran.r-project.org/package=qch)

This package provides functions for the joint analysis of $K$ sets of p-values obtained for the same list of items. This joint analysis is performed by querying a composite hypothesis, i.e. an arbitrary complex combination of simple hypotheses, as described in [Mary-Huard et al. (2021)](doi:10.1093/bioinformatics/btab592) and [De Walsche et al.(2023)](doi:10.1101/2024.03.17.585412). In this approach, the $K$-uplet of p-values associated with each item is distributed as a multivariate mixture, where each of the $2^K$ components corresponds to a specific combination of simple hypotheses. The dependence between the p-value series is considered using a Gaussian copula function. A p-value for the composite hypothesis test is derived from the posterior probabilities.

## Getting started

1. Install qch from CRAN: `install.packages("qch")`. For more detailed setup instructions, see below.

2. See the introductory vignette qch_tutorial.Rmd for an introduction to [qch].


## Citing this work

If you find the [qch] package useful for your work, please cite:

> Annaïg De Walsche, Franck Gauthier, Nathalie Boissot, Alain Charcosset and Tristan Mary-Huard
> (2023). [Large-scale composite hypothesis testing for omics analyses](https://www.biorxiv.org/content/10.1101/2024.03.17.585412v3)


## Set up

Please note that this package uses functions from the `qvalue` package, which is downloadable from [Bioconductor](https://www.bioconductor.org/packages/release/bioc/html/qvalue.html). If installation of `qch` fails and you have not yet installed the `qvalue` packages, please try running the following commands:


```R
  if (!requireNamespace("BiocManager", quietly = TRUE))
   install.packages("BiocManager")
  BiocManager::install("qvalue")
  
  install.packages("qch")
```
Alternatively, you may use [remotes][remotes] to install the latest version of qch from GitHub:

```R
install.packages("remotes")
remotes::install_github("annaigdw/qch")
```
