###################################################################
#' Generate the \eqn{H_0}/\eqn{H_1} configurations.
#'
#' Generate all possible combination of simple hypotheses \eqn{H_0}/\eqn{H_1}.
#'
#' @param Q The number of test series to be combined.
#' @param Signed Should the sign of the effect be taken into account? (optional, default is \code{FALSE}).
#'
#' @export
#' @return A list '\code{Hconfig}' of all possible combination of \eqn{H_0} and \eqn{H_1} hypotheses among \eqn{Q} hypotheses tested.
#'
#' @examples
#' GetHconfig(4)
#'
GetHconfig <- function(Q, Signed = FALSE) {
  if (!Signed) {
    ## Build H configurations
    Hconfig <- as.matrix(expand.grid(lapply(1:Q, function(q) 0:1)))
    Hconfig <- split(Hconfig, seq(2^Q))
  } else {
    ## Build H configurations
    Hconfig <- as.matrix(expand.grid(lapply(1:Q, function(q) c("0", "-", "+"))))
    Hconfig <- split(Hconfig, seq(3^Q))
  }
  ## Put names
  names(Hconfig) <- sapply(Hconfig, function(h) {
    paste(h, collapse = "/")
  })

  ## Collect results
  return(Hconfig)
}


###################################################################
#' Specify the configurations corresponding to the composite \eqn{H_1} test "AtLeast".
#'
#' Specify which configurations among \code{Hconfig} correspond
#'  to the composite alternative hypothesis : \{at least "\code{AtLeast}" \eqn{H_1} hypotheses are of interest \}
#'
#' @param Hconfig A list of all possible combination of \eqn{H_0} and \eqn{H_1} hypotheses generated by the [GetHconfig()] function.
#' @param AtLeast How many \eqn{H_1} hypotheses at least for the item to be of interest ? (an integer or a vector).
#' @param Consecutive Should the significant test series be consecutive ? (optional, default is \code{FALSE}).
#' @param SameSign Should the significant test series have the same sign ? (optional, default is \code{FALSE}).
#'
#' @export
#' @return A vector '\code{Hconfig.H1}' of components of \code{Hconfig} that correspond to the '\code{AtLeast}' specification.
#'
#' @examples
#' GetH1AtLeast(GetHconfig(4), 2)
#'
#' @seealso [GetH1Equal()]
#'

GetH1AtLeast <- function(Hconfig, AtLeast, Consecutive = FALSE, SameSign = FALSE) {
  ## Unsigned case
  if (sum(stringr::str_detect(names(Hconfig), pattern = "\\+")) == 0) {
    if (!Consecutive) {
      Hconfig.H1 <- map(AtLeast, function(atleast) {
        ## Find the ones that match H1
        Matching.H1 <- sapply(Hconfig, function(h) {
          sum(h) >= atleast
        })
        Hconfig.H1 <- which(Matching.H1)
        return(Hconfig.H1)
      })
      names(Hconfig.H1) <- paste0("AtLeast_", AtLeast)
    } else {
      Hconfig.H1 <- map(AtLeast, function(atleast) {
        ## Find the ones that match H1
        Consec <- paste(rep(1, atleast), collapse = "/")
        Hconfig.H1 <- grep(pattern = Consec, x = names(Hconfig))
        names(Hconfig.H1) <- names(Hconfig)[Hconfig.H1]
        return(Hconfig.H1)
      })
      names(Hconfig.H1) <- paste0("AtLeast_", AtLeast, "_Consecutive")
    }
    ## Signed case
  } else {
    if (!Consecutive) {
      if (SameSign) {
        Hconfig.H1 <- map(AtLeast, function(atleast) {
          ## Find the ones that match H1
          Matching.H1 <- sapply(Hconfig, function(h) {
            sum(h == "-") >= atleast | sum(h == "+") >= atleast
          })
          Hconfig.H1 <- which(Matching.H1)
          return(Hconfig.H1)
        })
        names(Hconfig.H1) <- paste0("AtLeast_", AtLeast, "_SameSign")
      } else {
        Hconfig.H1 <- map(AtLeast, function(atleast) {
          ## Find the ones that match H1
          Matching.H1 <- sapply(Hconfig, function(h) {
            sum(h != 0) >= atleast
          })
          Hconfig.H1 <- which(Matching.H1)
          return(Hconfig.H1)
        })
        names(Hconfig.H1) <- paste0("AtLeast_", AtLeast)
      }
    } else {
      if (SameSign) {
        Hconfig.H1 <- map(AtLeast, simplify = FALSE, function(atleast) {
          ## Find the ones that match H1
          Consec <- c(paste(rep("\\+", atleast), collapse = "/"), paste(rep("-", atleast), collapse = "/"))
          Hconfig.H1 <- sapply(Consec, simplify = FALSE, function(consec) {
            grep(pattern = consec, x = names(Hconfig))
          }) %>%
            unlist() %>%
            unique()
          names(Hconfig.H1) <- names(Hconfig)[Hconfig.H1]
          return(Hconfig.H1)
        })
        names(Hconfig.H1) <- paste0("AtLeast_", AtLeast, "_SameSign_Consecutive")
      } else {
        Hconfig.H1 <- map(AtLeast, function(atleast) {
          ## Find the ones that match H1
          Consec <- expand.grid(lapply(1:atleast, function(q) c("\\+", "-"))) %>% as.matrix()
          Consec <- apply(Consec, MARGIN = 1, function(h) {
            paste(h, collapse = "/")
          })
          Hconfig.H1 <- sapply(Consec, function(consec) {
            grep(pattern = consec, x = names(Hconfig))
          }) %>%
            unlist() %>%
            unique()
          names(Hconfig.H1) <- names(Hconfig)[Hconfig.H1]
          return(Hconfig.H1)
        })
        names(Hconfig.H1) <- paste0("AtLeast_", AtLeast, "_Consecutive")
      }
    }
  }
  ## Collect results
  return(Hconfig.H1)
}


###################################################################
#' Specify the configurations corresponding to the composite \eqn{H_1} test "Equal".
#'
#' Specify which configurations among \code{Hconfig} correspond
#'  to the composite alternative hypothesis :\{Exactly "\code{Equal}" \eqn{H_1} hypotheses are of interest \}
#'
#' @param Hconfig A list of all possible combination of H0 and H1 hypotheses generated by the [GetHconfig()] function.
#' @param Equal What is the exact number of \eqn{H_1} hypotheses for the item to be of interest? (an integer or a vector).
#' @param Consecutive Should the significant test series be consecutive ? (optional, default is FALSE).
#' @param SameSign Should the significant test series have the same sign ? (optional, default is FALSE).
#'
#' @export
#' @return A vector '\code{Hconfig.H1}' of components of \code{Hconfig} that correspond to the '\code{Equal}' specification.
#'
#' @examples
#' GetH1Equal(GetHconfig(4), 2)
#'
#' @seealso [GetH1AtLeast()]
#'

#'
GetH1Equal <- function(Hconfig, Equal, Consecutive = FALSE, SameSign = FALSE) {
  ## Unsigned case
  if (sum(stringr::str_detect(names(Hconfig), pattern = "\\+")) == 0) {
    if (!Consecutive) {
      Hconfig.H1 <- map(Equal, function(equal) {
        ## Find the ones that match H1
        Matching.H1 <- sapply(Hconfig, function(h) {
          sum(h) == equal
        })
        Hconfig.H1 <- which(Matching.H1)
        return(Hconfig.H1)
      })
      names(Hconfig.H1) <- paste0("Equal_", Equal)
    } else {
      Hconfig.H1 <- map(Equal, function(equal) {
        ## Find the ones that match H1
        Consec <- paste(rep(1, equal), collapse = "/")
        Hconfig.H1 <- intersect(grep(pattern = Consec, x = names(Hconfig)), which(sapply(names(Hconfig), function(h) {
          stringr::str_count(h, pattern = "1") == equal
        })))
        names(Hconfig.H1) <- names(Hconfig)[Hconfig.H1]
        return(Hconfig.H1)
      })
      names(Hconfig.H1) <- paste0("Equal_", Equal, "_Consecutive")
    }
    ## Signed case
  } else {
    if (!Consecutive) {
      if (SameSign) {
        Hconfig.H1 <- map(Equal, function(equal) {
          ## Find the ones that match H1
          Matching.H1 <- sapply(Hconfig, function(h) {
            sum(h == "-") == equal | sum(h == "+") == equal
          })
          Hconfig.H1 <- which(Matching.H1)
          return(Hconfig.H1)
        })
        names(Hconfig.H1) <- paste0("Equal_", Equal, "_SameSign")
      } else {
        Hconfig.H1 <- map(Equal, function(equal) {
          ## Find the ones that match H1
          Matching.H1 <- sapply(Hconfig, function(h) {
            sum(h != 0) == equal
          })
          Hconfig.H1 <- which(Matching.H1)
          return(Hconfig.H1)
        })
        names(Hconfig.H1) <- paste0("Equal_", Equal)
      }
    } else {
      if (SameSign) {
        Hconfig.H1 <- map(Equal, function(equal) {
          ## Find the ones that match H1
          Consec <- c(paste(rep("\\+", equal), collapse = "/"), paste(rep("-", equal), collapse = "/"))
          Matching.H1 <- c(grep(pattern = Consec[1], x = names(Hconfig)), grep(pattern = Consec[2], x = names(Hconfig))) %>% unique()
          Hconfig.H1 <- intersect(Matching.H1, which(sapply(Hconfig, function(h) {
            sum(h == "-") == equal | sum(h == "+") == equal
          })))
          names(Hconfig.H1) <- names(Hconfig)[Hconfig.H1]
          return(Hconfig.H1)
        })
        names(Hconfig.H1) <- paste0("Equal_", Equal, "_SameSign_Consecutive")
      } else {
        Hconfig.H1 <- map(Equal, simplify = FALSE, function(equal) {
          ## Find the ones that match H1
          Consec <- expand.grid(lapply(1:equal, function(q) c("\\+", "-"))) %>% as.matrix()
          Consec <- apply(Consec, MARGIN = 1, function(h) {
            paste(h, collapse = "/")
          })
          Matching.H1 <- sapply(Consec, function(consec) {
            grep(pattern = consec, x = names(Hconfig))
          }) %>%
            unlist() %>%
            unique()
          Hconfig.H1 <- intersect(Matching.H1, which(sapply(Hconfig, function(h) {
            sum(h != 0) == equal
          })))
          names(Hconfig.H1) <- names(Hconfig)[Hconfig.H1]
          return(Hconfig.H1)
        })
        names(Hconfig.H1) <- paste0("Equal_", Equal, "_Consecutive")
      }
    }
  }
  ## Collect results
  return(Hconfig.H1)
}
