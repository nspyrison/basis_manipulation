#' Runs a shiny app demonstrating manual tours
#' 
#' Runs a local shiny app that demonstrates manual tour and comparable 
#' traditional techniques for static projections of multivariate data sets.
#' 
#' @param example name of the shiny app to run. Expects "intro" or "comparison"
#' @return opens a local shiny app
#' @export
#' @examples 
#' \dontrun{
#' run_app(example = "intro")
#' run_app(example = "comparison")
#' }


# For adjusting or adding more apps it may be useful to read: 
# https://deanattali.com/2015/04/21/r-package-shiny-app/
run_app <- function(example) {
  # required for running some projection pursuit indices.
  require("scagnostics") # "Skinny", "Striated", "Convex", "Clumpy" 
  require("mbgraphic")   # splines2d, dcor2d
  require("minerva")     # MIC, TIC
  
  # locate all the shiny app examples that exist
  validExamples <- list.files(system.file("shiny-examples", package = "spinifex"))
  
  validExamplesMsg <-
    paste0(
      "Valid examples are: '",
      paste(validExamples, collapse = "', '"),
      "'")
  
  # if an invalid example is given, throw an error
  if (missing(example) || !nzchar(example) ||
      !example %in% validExamples) {
    stop(
      'Please run `runExample()` with a valid example app as an argument.\n',
      validExamplesMsg,
      call. = FALSE)
  }
  
  # find and launch the app
  appDir <- system.file("shiny-examples", example, package = "spinifex")
  shiny::runApp(appDir, display.mode = "normal")
}