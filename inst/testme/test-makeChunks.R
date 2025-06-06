library(doFuture)

makeChunks <- doFuture:::makeChunks

message("*** makeChunks() ...")

for (nbrOfElements in c(1L, 2L, 8L)) {
  for (nbrOfWorkers in seq_len(nbrOfElements + 1L)) {
    ## Defaults
    chunks <- makeChunks(nbrOfElements, nbrOfWorkers = nbrOfWorkers)
    str(chunks)
    idxs <- unlist(chunks, use.names = TRUE)
    str(idxs)
    stopifnot(length(idxs) == nbrOfElements)
    uidxs <- unique(idxs)
    stopifnot(length(uidxs) == nbrOfElements)
    nidxs <- vapply(idxs, FUN = length, FUN.VALUE = 0L)
    str(nidxs)
    stopifnot(all(nidxs >= 1))
    stopifnot(length(chunks) <= nbrOfWorkers)

    orderings <- list(
      NULL,
      "random",
      seq_len(nbrOfElements),
      function(n) rev(seq_len(n))
    )

    for (ordering in orderings) {
      ## future.chunk.size
      for (future.chunk.size in seq_len(nbrOfElements + 1L)) {
        if (!is.null(ordering)) attr(future.chunk.size, "ordering") <- ordering
        chunks <- makeChunks(nbrOfElements, nbrOfWorkers = nbrOfWorkers,
                             future.chunk.size = future.chunk.size)
        str(chunks)
        idxs <- unlist(chunks, use.names = TRUE)
        str(idxs)
        stopifnot(length(idxs) == nbrOfElements)
        uidxs <- unique(idxs)
        stopifnot(length(uidxs) == nbrOfElements)
        nidxs <- vapply(idxs, FUN = length, FUN.VALUE = 0L)
        str(nidxs)
        stopifnot(all(nidxs >= 1), all(nidxs <= future.chunk.size))
      }
    
      ## future.scheduling
      for (future.scheduling in list(FALSE, TRUE, 0, 0.01, 0.5, 1.0, 2.0, +Inf)) {
        if (!is.null(ordering)) attr(future.scheduling, "ordering") <- ordering
        chunks <- makeChunks(nbrOfElements, nbrOfWorkers = nbrOfWorkers,
                             future.scheduling = future.scheduling)
        str(chunks)
        idxs <- unlist(chunks, use.names = TRUE)
        str(idxs)
        stopifnot(length(idxs) == nbrOfElements)
        uidxs <- unique(idxs)
        stopifnot(length(uidxs) == nbrOfElements)
        nidxs <- vapply(idxs, FUN = length, FUN.VALUE = 0L)
        str(nidxs)
        stopifnot(all(nidxs >= 1))
      }
    } ## for (ordering ...)
  }
}


message("- Exceptions")

opt <- TRUE
attr(opt, "ordering") <- "unknown"
res <- tryCatch({
  makeChunks(3L, nbrOfWorkers = 2L, future.chunk.size = opt)
}, error = identity)
str(res)
stopifnot(inherits(res, "error"))

res <- tryCatch({
  makeChunks(3L, nbrOfWorkers = 2L, future.scheduling = opt)
}, error = identity)
str(res)
stopifnot(inherits(res, "error"))

message("*** makeChunks() ... DONE")

