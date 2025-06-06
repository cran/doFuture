#' @tags %dofuture%
#' @tags sequential multisession cluster multicore

library(doFuture)

message("*** Options in nested parallelization ...")

options(future.debug = FALSE)
options(future.apply.debug = FALSE)
options(future.globals.maxSize = 1234000)

for (cores in 1:availCores) {
  message(sprintf("Testing with %d cores ...", cores))
  options(mc.cores = cores)
  strategies <- supportedStrategies(cores)

  for (strategy1 in strategies) {
    for (strategy2 in strategies) {
      message(sprintf("- plan('%s') ...", strategy2))
      plan(list(outer = tweak(strategy1), inner = strategy2))

      v <- foreach(x = 1:2) %dofuture% {
        outer <- data.frame(
          label   = "outer",
          idx     = x,
          pid     = Sys.getpid(),
          maxSize = getOption("future.globals.maxSize", NA_real_)
        )
        
        inner <- foreach(x = 3:4) %dofuture% {
          data.frame(
            label   = "inner",
            idx     = x,
            pid     = Sys.getpid(),
            maxSize = getOption("future.globals.maxSize", NA_real_))
        }
        inner <- do.call(rbind, inner)
        rbind(outer, inner)
      }
      v <- do.call(rbind, v)
      print(v)
      stopifnot(!anyNA(v$maxSize))
    } ## for (strategy2 ...)
  } ## for (strategy1 ...)
} ## for (cores in ...)

message("*** Options in nested parallelization ... done")

