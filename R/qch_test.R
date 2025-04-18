#' @import utils
## quiets concerns of R CMD check re: the .'s that appear in pipelines
# if(getRversion() >= "2.15.1")  utils::globalVariables(c(".",">"))
if (getRversion() >= "2.15.1") utils::globalVariables(c(".", ":=", ".x", ">"))



###################################################################
#' Perform composite hypothesis testing.
#'
#' Perform any composite hypothesis test by specifying
#'  the configurations '\code{Hconfig.H1}' corresponding to the composite alternative hypothesis
#'  among all configurations '\code{Hconfig}'.
#'
#' By default, the function performs the composite hypothesis test of being associated with "at least \eqn{q}" simple tests, for \eqn{q=1,..Q}.
#'
#' @param res.qch.fit The result provided by the [qch.fit()] function.
#' @param Hconfig A list of all possible combination of \eqn{H_0} and \eqn{H_1} hypotheses generated by the [GetHconfig()] function.
#' @param Hconfig.H1 An integer vector (or a list of such vector) of the \code{Hconfig} index corresponding to the composite alternative hypothesis configuration(s).
#'  Can be generated by the [GetH1AtLeast()] or [GetH1Equal()] functions.
#' If \code{NULL}, the composite hypothesis tests of being associated with "at least \eqn{q}" simple tests, for q=1,..Q are performed.
#' @param Alpha the nominal Type I error rate for FDR control. Default is \code{0.05}.
#' @param threads_nb The number of threads to use. The number of thread will set to the number of cores available by default.
#'
#' @return A list with the following elements:
#' \tabular{ll}{
#' \code{Rejection} \tab a matrix providing for each item the result of the composite hypothesis test,
#'  after adaptive Benjamin-Höchberg multiple testing correction.\cr
#' \code{lFDR} \tab a matrix providing for each item its local FDR estimate.\cr
#' \code{Pvalues} \tab a matrix providing for each item its p-value of the composite hypothesis test.
#' }
#'
#' @import purrr
#' @export
#'
#' @seealso [qch.fit()], [GetH1AtLeast()],[GetH1Equal()]
#' @examples
#' data(PvalSets_cor)
#' PvalMat <- as.matrix(PvalSets_cor[, -3])
#' Truth <- PvalSets[, 3]
#'
#' ## Build the Hconfig objects
#' Q <- 2
#' Hconfig <- GetHconfig(Q)
#'
#' ## Infer the posteriors
#' res.fit <- qch.fit(pValMat = PvalMat, Hconfig = Hconfig, copula = "gaussian")
#'
#' ## Run the test procedure with FDR control
#' H1config <- GetH1AtLeast(Hconfig, 2)
#' res.test <- qch.test(res.qch.fit = res.fit, Hconfig = Hconfig, Hconfig.H1 = H1config)
#' table(res.test$Rejection$AtLeast_2, Truth == 4)
#'
qch.test <- function(res.qch.fit, Hconfig, Hconfig.H1 = NULL, Alpha = 0.05, threads_nb = 0) {
  Q <- log2(length(res.qch.fit$prior))

  ### Check on Hconfig.H1
  if (!is.null(Hconfig.H1)) {
    if (!is.list(Hconfig.H1) & !is.integer(Hconfig.H1)) {
      stop("Hconfig.H1 should be a vector of index or a list of such vectors.")
    }
    if (!is.list(Hconfig.H1)) {
      namesH1config <- names(Hconfig.H1)
      Hconfig.H1 <- list(Hconfig.H1)
      names(Hconfig.H1) <- namesH1config
    }
    if (purrr::map(Hconfig.H1, class) %>% `!=`("integer") %>% any() || map(Hconfig.H1, min) %>%
      `<`(1) %>%
      any() || map(Hconfig.H1, min) %>%
      `>`(length(res.qch.fit$prior)) %>%
      any()) {
      stop(paste0("Each element of Hconfig.H1 should be a vector of index between 1 and ", length(res.qch.fit$prior), "."))
    }
  }

  if (is.null(Hconfig.H1)) {
    Hconfig.H1 <- GetH1AtLeast(Hconfig, 1:Q)
  }

  nb_test <- length(Hconfig.H1)


  if (!is.null(res.qch.fit$posterior)) {
    n <- nrow(res.qch.fit$posterior)

    ### localFDR
    Tau1.list <- map(Hconfig.H1, ~ rowSums(res.qch.fit$posterior[, .x, drop = FALSE]))
  } else if (!is.null(res.qch.fit$Rcopula)) {
    n <- nrow(res.qch.fit$f0Mat)
    Logf0Mat <- log(res.qch.fit$f0Mat)
    Logf1Mat <- log(res.qch.fit$f1Mat)

    zeta0 <- qnorm(p = res.qch.fit$F0Mat, mean = 0, sd = 1)
    zeta1 <- qnorm(p = res.qch.fit$F1Mat, mean = 0, sd = 1)

    RcopulaInv <- solve(res.qch.fit$Rcopula)

    ### localFDR
    Tau1.list <- map(Hconfig.H1, ~ {
      fHconfig_sumH1 <- fHconfig_sum_update_gaussian_copula_ptr_parallel(
        Hconfig = Hconfig[.x],
        NewPrior = res.qch.fit$prior[.x],
        Logf0Mat = Logf0Mat,
        Logf1Mat = Logf1Mat,
        zeta0 = zeta0,
        zeta1 = zeta1,
        R = res.qch.fit$Rcopula,
        Rinv = RcopulaInv,
        threads_nb = threads_nb
      )
      return(fHconfig_sumH1 / res.qch.fit$fHconfig_sum)
    })
  } else {
    n <- nrow(res.qch.fit$f0Mat)
    Logf0Mat <- log(res.qch.fit$f0Mat)
    Logf1Mat <- log(res.qch.fit$f1Mat)

    ### localFDR
    Tau1.list <- map(Hconfig.H1, ~ {
      fHconfig_sumH1 <- fHconfig_sum_update_ptr_parallel(
        Hconfig = Hconfig[.x],
        NewPrior = res.qch.fit$prior[.x],
        Logf0Mat = Logf0Mat,
        Logf1Mat = Logf1Mat,
        threads_nb = threads_nb
      )
      return(fHconfig_sumH1 / res.qch.fit$fHconfig_sum)
    })
  }

  Tau1_equals1_index.list <- map(Tau1.list, ~ which(.x == 1))
  one_minus_Tau1equals1.list <- map(1:nb_test, ~ rowSums(res.qch.fit$posterior[Tau1_equals1_index.list[[.x]], -Hconfig.H1[[.x]], drop = FALSE]))


  Order.list <- map(1:nb_test, ~ order(Tau1.list[[.x]], decreasing = TRUE))
  Order_lessthan1.list <- map(1:nb_test, ~ order(Tau1.list[[.x]][-Tau1_equals1_index.list[[.x]]], decreasing = TRUE))
  Order_equals1.list <- map(1:nb_test, ~ order(one_minus_Tau1equals1.list[[.x]], decreasing = FALSE))


  FDR.list <- map(1:nb_test, ~ {
    if (length(Tau1_equals1_index.list[[.x]]) > 0) {
      tmp1 <- cumsum(one_minus_Tau1equals1.list[[.x]][Order_equals1.list[[.x]]])
      tmp <- (1:(n - length(tmp1))) - cumsum(Tau1.list[[.x]][-Tau1_equals1_index.list[[.x]]][Order_lessthan1.list[[.x]]])
      return(c(tmp1, tmp) / (1:n))
    } else {
      tmp <- (1:n) - cumsum(Tau1.list[[.x]][Order.list[[.x]]])
      return(tmp / (1:n))
    }
  })


  NbReject.vec <- map_int(1:nb_test, ~ max(which(FDR.list[[.x]] <= Alpha), 0))

  Rejection.mat <- map_dfc(1:nb_test, function(q) {
    Rejection <- rep(0, n)
    if (NbReject.vec[q] > 0) {
      if (length(Tau1_equals1_index.list[[q]]) > 0) {
        Order_all <- c(Tau1_equals1_index.list[[q]][Order_equals1.list[[q]]], which(Tau1.list[[q]] < 1)[Order_lessthan1.list[[q]]])
        Rejection[Order_all[1:NbReject.vec[q]]] <- 1
      } else {
        Rejection[Order.list[[q]][1:NbReject.vec[q]]] <- 1
      }
    }
    setNames(data.frame(Rejection), names(Hconfig.H1)[q])
  })

  localFDR.mat <- (1 - matrix(unlist(Tau1.list), ncol = nb_test)) %>% as.data.frame()
  colnames(localFDR.mat) <- names(Hconfig.H1)

  ### Pvalue
  Pi0.vec <- map_dbl(1:nb_test, ~ (1 - sum(res.qch.fit$prior[Hconfig.H1[[.x]]])))
  EspTau0.list <- map(1:nb_test, ~ {
    if (length(Tau1_equals1_index.list[[.x]]) > 0) {
      tmp1 <- cumsum(one_minus_Tau1equals1.list[[.x]][Order_equals1.list[[.x]]])
      tmp <- (1:(n - length(tmp1))) - cumsum(Tau1.list[[.x]][-Tau1_equals1_index.list[[.x]]][Order_lessthan1.list[[.x]]])
      tmp <- c(tmp1, tmp)
    } else {
      tmp <- (1:n) - cumsum(Tau1.list[[.x]][Order.list[[.x]]])
    }
    EspTau0 <- tmp / (Pi0.vec[.x] * n)
    EspTau0[EspTau0 > 1] <- EspTau0[EspTau0 > 1] / max(EspTau0)
    return(EspTau0)
  })

  Pval.qch.mat <- map_dfc(1:nb_test, function(q) {
    setNames(data.frame(EspTau0.list[[q]][n + 1 - rank(Tau1.list[[q]])]), names(Hconfig.H1)[q])
  })

  return(list(Rejection = Rejection.mat, lFDR = localFDR.mat, Pvalues = Pval.qch.mat))
}
