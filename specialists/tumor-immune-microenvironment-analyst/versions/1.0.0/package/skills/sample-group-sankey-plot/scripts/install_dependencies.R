#!/usr/bin/env Rscript

required_packages <- c("optparse", "ggplot2", "ggalluvial", "testthat")
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]

if (length(missing_packages) == 0) {
  cat("All required packages are already installed.\n")
  quit(save = "no", status = 0)
}

cat(
  sprintf(
    "Installing missing packages from CRAN: %s\n",
    paste(missing_packages, collapse = ", ")
  )
)

tryCatch(
  {
    install.packages(missing_packages, repos = "https://cloud.r-project.org")
  },
  error = function(e) {
    cat(
      sprintf("SKILL_DEPENDENCY_MISSING: %s\n", conditionMessage(e)),
      file = stderr()
    )
    quit(save = "no", status = 1)
  }
)

still_missing <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]

if (length(still_missing) > 0) {
  cat(
    sprintf(
      "SKILL_DEPENDENCY_MISSING: Failed to install packages: %s\n",
      paste(still_missing, collapse = ", ")
    ),
    file = stderr()
  )
  quit(save = "no", status = 1)
}

cat("Package installation check completed successfully.\n")
quit(save = "no", status = 0)
