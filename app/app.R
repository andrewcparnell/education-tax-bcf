# ==============================================================================
# Script: app/app.R
# Purpose: R launcher for the 3-tab interactive Tertiary Education & Fiscal
#          Returns Causal Explorer in app/
# Author: Andrew C. Parnell
# ==============================================================================

# Ensure app data bundle exists
app_dir <- if (file.exists("app/index.html")) "app" else "."
data_js <- file.path(app_dir, "data", "app_data.js")

if (!file.exists(data_js) && file.exists("app/prepare_app_data.R")) {
  message("Generating app data bundle via app/prepare_app_data.R ...")
  source("app/prepare_app_data.R")
}

index_path <- normalizePath(file.path(app_dir, "index.html"), mustWork = TRUE)

if (requireNamespace("shiny", quietly = TRUE)) {
  shiny::addResourcePath("assets", app_dir)
  ui <- shiny::fluidPage(
    shiny::tags$head(
      shiny::tags$style("body, .container-fluid { margin: 0; padding: 0; overflow: hidden; }")
    ),
    shiny::tags$iframe(
      src = "assets/index.html",
      style = "width: 100%; height: 100vh; border: none;"
    )
  )
  server <- function(input, output, session) {}
  shiny::shinyApp(ui = ui, server = server)
} else {
  message("Opening interactive explorer in browser: ", index_path)
  utils::browseURL(index_path)
}
