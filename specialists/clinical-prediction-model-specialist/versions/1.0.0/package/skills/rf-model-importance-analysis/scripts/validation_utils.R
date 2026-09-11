require_positive_number <- function(value, label, integer_only = FALSE) {
  if (is.null(value) || length(value) != 1 || is.na(value) || !is.finite(value) || value <= 0) {
    fail("SKILL_INVALID_PARAMETER", sprintf("%s must be a positive number.", label))
  }
  if (integer_only && value != as.integer(value)) {
    fail("SKILL_INVALID_PARAMETER", sprintf("%s must be an integer.", label))
  }
  invisible(TRUE)
}

require_probability <- function(value, label) {
  if (is.null(value) || length(value) != 1 || is.na(value) || value < 0 || value > 1) {
    fail("SKILL_INVALID_PARAMETER", sprintf("%s must be between 0 and 1.", label))
  }
  invisible(TRUE)
}
