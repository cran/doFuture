## From R.utils 2.7.0 (2018-08-26)
queryRCmdCheck <- function(...) {
  evidences <- list()

  # Command line arguments
  args <- commandArgs()

  evidences[["vanilla"]] <- is.element("--vanilla", args)

  # Check the working directory
  pwd <- getwd()
  dirname <- basename(pwd)
  parent <- basename(dirname(pwd))
  pattern <- ".+[.]Rcheck$"

  # Is 'R CMD check' checking tests?
  evidences[["tests"]] <- (
    grepl(pattern, parent) && grepl("^tests(|_.*)$", dirname)
  )

  # Is the current working directory as expected?
  evidences[["pwd"]] <- (evidences[["tests"]] || grepl(pattern, dirname))

  # Is 'R CMD check' checking examples?
  evidences[["examples"]] <- is.element("CheckExEnv", search())
  
  # SPECIAL: win-builder?
  evidences[["win-builder"]] <- (.Platform$OS.type == "windows" && grepl("Rterm[.]exe$", args[1]))

  if (evidences[["win-builder"]]) {
    n <- length(args)
    if (all(c("--no-save", "--no-restore", "--no-site-file", "--no-init-file") %in% args)) {
      evidences[["vanilla"]] <- TRUE
    }

    if (grepl(pattern, parent)) {
      evidences[["pwd"]] <- TRUE
    }
  }

  if (!evidences$vanilla || !evidences$pwd) {
    res <- "notRunning"
  } else if (evidences$tests) {
    res <- "checkingTests"
  } else if (evidences$examples) {
    res <- "checkingExamples"
  } else {
    res <- "notRunning"
  }

  attr(res, "evidences") <- evidences
  
  res
}

inRCmdCheck <- local({
  .cache <- NULL
  function() {
    if (is.null(.cache)) {
      .cache <<- (queryRCmdCheck() != "notRunning")
    }
    .cache
  }
})

future_has_evalFuture <- local({
  res <- NULL
  function() {
    if (is.null(res)) {
      ns <- getNamespace("future")
      res <<- exists("evalFuture", mode = "function", envir = ns)
    }
    res
  }
})

patch_expressions <- function() {
  ## Temporary patches for future package with evalFuture()
  patches <- getOption("doFuture.patches")
  if (is.null(patches)) {
    patches <- NA_character_
    if (future_has_evalFuture()) {
      ## Package 'WARDEN', if 'R CMD check' is running
      if ("WARDEN" %in% loadedNamespaces() && inRCmdCheck()) {
        patches <- c(patches, "WARDEN")
      }
    }
    options(doFuture.patches = patches)
  }

  optional_patches <- NULL
  if (!is.null(patches)) {
    if ("WARDEN" %in% patches) {
      optional_patches <- bquote({
       .(optional_patches)
       T <- TRUE
      })
    }
  }

  optional_patches
}


## covr: skip=all
.onLoad <- function(libname, pkgname) {
  value <- getOption("doFuture.workarounds")
  if (is.null(value)) {
    value <- trim(Sys.getenv("R_DOFUTURE_WORKAROUNDS"))
    value <- unlist(strsplit(value, split = ",", fixed = TRUE))
    value <- trim(value)
    options(doFuture.workarounds = value)
  }

  ## doFuture 1.1.0
  value <- getOption("doFuture.globals.scanVanillaExpression")
  if (is.null(value)) {
    value <- Sys.getenv("R_DOFUTURE_GLOBALS_SCANVANILLAEXPRESSION", NA_character_)
    if (is.na(value) || !nzchar(value)) {
      value <- future_has_evalFuture()
    } else {
      value <- trim(value)
      value <- suppressWarnings(as.logical(value))
      value <- isTRUE(value)
    }
    options(doFuture.globals.scanVanillaExpression = value)
  }

  ## doFuture 1.1.0
  value <- getOption("doFuture.patches")
  if (is.null(value)) {
    value <- Sys.getenv("R_DOFUTURE_PATCHES", NA_character_)
    if (is.na(value) || !nzchar(value)) {
      value <- NULL
    } else {
      value <- strsplit(value, split = ",", fixed = TRUE)[[1]]
    }
    options(doFuture.patches = value)
  }
}
