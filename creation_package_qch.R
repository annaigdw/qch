rm(list=ls())
pkg.name <- "qch"

(pkg.dir <- path.expand("C:/Users/Annaig/Desktop/qch_package"))

(path.to.pkg <- file.path(pkg.dir, pkg.name))

pkg.fields <- list()
pkg.fields[["Package"]] <- pkg.name

pkg.fields[["Version"]] <- "1.1.0"

## default: "What the Package Does (One Line, Title Case)"
pkg.fields[["Title"]] <- "Query Composite Hypotheses"

## default: "What the package does (one paragraph)."
pkg.fields[["Description"]] <-
  "Provides functions for the joint analysis of K sets of p-values obtained for a same list of items.
   This joint analysis is performed by querying a composite hypothesis, i.e. an arbitrary complex combination of simple hypotheses, as described in Mary-Huard et al. (2021) <arXiv:2104.14601>.
   The null distribution corresponding to the composite hypothesis of interest is obtained by fitting non-parametric mixtures models (one for each of the simple hypothesis of the complex combination).
   Type I error rate control is achieved through Bayesian False Discovery Rate control.
   The 3 main functions of the package GetHinfo(), qch.fit() and qch.test() correspond to the 3 steps for querying a composite hypothesis (composed H0/H1 formulation, inferring the null distribution and testing the null hypothesis)."

## default: "person(\"First\", \"Last\", , \"first.last@example.com\",
##                  c(\"aut\", \"cre\"), comment = c(ORCID = \"YOUR-ORCID-ID\"))"
pkg.fields[["Authors@R"]] <- c(
  person(
    given = "Tristan",
    family = "Mary-Huard",
    role = c("aut", "cre"),
    email = "tristan.mary-huard@agroparistech.fr",
    comment = c(ORCID = "0000-0002-3839-9067")
  ),
  person(
    given = "Annaig",
    family = "De walsche",
    role = "aut",
    email = "annaig.de-walsche@inrae.fr",
    comment = c(ORCID = "0000-0003-0603-1716 ")
  )
)

## default: "What license it uses"
pkg.fields[["License"]] <- "GPL-3"

#stopifnot(! dir.exists(path.to.pkg))


usethis::create_package(path=path.to.pkg, fields=pkg.fields)


library("roxygen2")
library("testthat")
library("usethis")
library("attachment")
library("tidyverse")
library("devtools")
library("rhub")



# RepRes <- 'C:/Users/annai/Desktop/data/Maize/Processed/'
# metaData <-readRDS(paste0(RepRes,'MetaDatacrop_pkg.rds'))
# metaData <- metaData$Data

# envDesc <- readRDS(paste0(RepRes,'envDesccrop_pkg.rds'))
#matCorr <- readRDS('C:/Users/annai/Desktop/stage/data/Maize/Processed/data_pkg/Matcorr.RDS')

# use_data(metaData, overwrite = T)
# use_data(envDesc, overwrite = T)
#use_data(matCorr, overwrite = T)

# usethis::use_vignette("metaGE-vignette")

document()
#attachment::att_to_description()
attachment::att_amend_desc()

use_package_doc()

document()

# devtools::check()
devtools::check(args="--as-cran")
devtools::check_win_devel()
devtools::check_rhub()
rhub::check()
rhub::check_for_cran()
run_examples()

built.pkg <- devtools::build()
built.pkg
