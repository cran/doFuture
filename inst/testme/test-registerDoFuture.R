#' @tags sequential multisession cluster multicore

library(doFuture)

strategies <- future:::supportedStrategies()

message("*** registerDoFuture() ...")

message("doSEQ() %dopar% information:")
registerDoSEQ()
message("getDoParName(): ", sQuote(getDoParName()))
message("getDoParVersion(): ", sQuote(getDoParVersion()))
message("getDoParWorkers(): ", sQuote(getDoParWorkers()))

oldDoPar <- registerDoFuture()
message("Previously registered foreach backend:")
utils::str(oldDoPar)

stopifnot(
  "fun"  %in% names(oldDoPar),
  "data" %in% names(oldDoPar),
  "info" %in% names(oldDoPar),
  is.function(oldDoPar$fun)
)

message("doFuture() %dopar% information:")

for (strategy in strategies) {
  message(sprintf("- plan('%s') ...", strategy))
  plan(strategy)

  message(name <- getDoParName())
  stopifnot(name == "doFuture")
  message(version <- getDoParVersion())
  stopifnot(packageVersion(name) == version)
  message(nbr_of_workers <- getDoParWorkers())
  stopifnot(nbr_of_workers == nbrOfWorkers())

  # Shutdown current plan
  plan(sequential)

  message(sprintf("- plan('%s') ... DONE", strategy))
} ## for (strategy ...)

message("*** registerDoFuture() ... DONE")

