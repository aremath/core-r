a <-
  { n <- 0
    k <- 0
    for (n in c(0:5)) {
      n <- n + 1
      k <- k + n
    }
  }

if (is.null(a)) { 1 } else { 0 }

