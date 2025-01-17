#' Add Sparkline Figure
#'
#' This function wraps `gtExtras::gt_sparkline()` and adds a new column
#' illustrating the distribution of a continuous variable. This function converts
#' the gtsummary table into a gt table.
#'
#' @param x 'tbl_summary' object
#' @param type sparkline type. Must be one of `c("histogram", "sparkline")`
#' @param column_header string indicating column header
#' @inheritParams gtExtras::gt_sparkline
#' @inheritDotParams gtExtras::gt_sparkline -gt_object -column -same_limit -type
#'
#' @return a gt table
#' @family gtsummary-related functions
#' @export
#' @examples
#' library(gtsummary)
#'
#' add_sparkline_ex1 <-
#'   trial %>%
#'   select(age, marker) %>%
#'   tbl_summary(missing = "no") %>%
#'   add_sparkline()
#' @section Example Output:
#' \if{html}{Example 1}
#'
#' \if{html}{\figure{add_sparkline_ex1.png}{options: width=50\%}}
add_sparkline <- function(x,
                          type = c("histogram", "sparkline"),
                          column_header = NULL,
                          same_limit = FALSE,
                          ...) {
  assert_package("gtExtras", "gts_sparkline()")
  if (!inherits(x, "tbl_summary")) {
    stop("`x=` must be class 'tbl_summary'", call. = FALSE)
  }
  type <- match.arg(type)
  include <-
    broom.helpers::.select_to_varnames(
      gtsummary::all_continuous(),
      data = x$inputs$data,
      var_info = x$table_body,
      arg_name = "include"
    )
  column_header <-
    column_header %||%
    switch (
      type,
      "histogram" = "**Histogram**",
      "density" = "**Density**",
      "sparkline" = "**Sparkline**"
    )
  stopifnot(rlang::is_string(column_header))
  if (!is.null(x$by)) {
    message("Input table is stratified, but sparkline figure is not.")
  }

  x %>%
    # merge in variables' distribution data
    gtsummary::modify_table_body(
      function(table_body) {
        dplyr::left_join(
          table_body,
          tibble::tibble(
            variable = include,
            row_type = "label"
          ) %>%
            mutate(
              ..sparkline_data.. =
                map(
                  .data$variable,
                  ~na.omit(x$inputs$data[[.x]])
                )
            ),
          by = c("variable", "row_type")
        ) %>%
        mutate(
          ..sparkline_data.. =
            map(.data$..sparkline_data.., ~switch(!is.null(.x), .x) %||% list(NA))
        )
      }
    ) %>%
    # add a column header
    gtsummary::modify_header(..sparkline_data.. = column_header) %>%
    # convert to gt and add gtExtras sparkline
    as_gt() %>%
    gtExtras::gt_sparkline(
      column = .data$..sparkline_data..,
      type = type,
      same_limit = same_limit,
      ...)
}
