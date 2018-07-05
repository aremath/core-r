
baz <- function(a, b, c1, d, ...) {
  c(...)
}

foo <- function(a, b, c, ..., d)  {
  baz(...)
}


huehue <- function(a, b=1, ..., e) {
  c(...)
}

huahua <- function(a, b, c) {
  c(a, b, c)
}

foo(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)

huehue(1, 2, 3, 4, 5, 6)



