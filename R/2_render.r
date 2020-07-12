#' Turns a tour path array into a long data frame.
#'
#' Typically called by a wrapper function, `play_manual_tour` or 
#' `play_tour_path`. Takes the result of `tourr::save_history()` or 
#' `manual_tour()` and restructures the data from an array to a long data frame 
#' for use in ggplots.
#'
#' @param array A (p, d, n_slides) array of a tour, the output of 
#' `manual_tour()`.
#' @param data Optional, (n, p) dataset to project, consisting of numeric 
#' variables.
#' @param lab Optional, labels for the reference frame of length 1 or the 
#' number of variables used. Defaults to an abbreviation of the variables.
#' @return A list containing an array of basis slides (p, d, n_slides) and
#' an array of data slides (n, d, n_slides) if data is present.
#' @export
#' @examples
#' flea_std <- tourr::rescale(tourr::flea[, 1:6])
#' 
#' rb <- tourr::basis_random(n = ncol(flea_std))
#' mtour <- manual_tour(basis = rb, manip_var = 4)
#' array2df(array = mtour, data = flea_std)
array2df <- function(array, 
                     data = NULL,
                     lab = NULL) {
  ## Initialize
  manip_var <- attributes(array)$manip_var
  p <- nrow(array[,, 1L])
  n_slides <- dim(array)[3L]
  
  ## basis; array to long df
  basis_slides <- NULL
  for (slide in 1:n_slides) {
    basis_rows <- data.frame(cbind(array[,, slide], slide))
    basis_slides <- rbind(basis_slides, basis_rows)
  }
  colnames(basis_slides) <- c("x", "y", "slide")
  
  ## Data; if exists, array to long df
  if(!is.null(data)) {
    data <- as.matrix(data)
    data_slides <- NULL
    for (slide in 1L:n_slides) {
      data_rows <- cbind(data %*% array[,, slide], slide)
      data_rows[, 1L] <- scale(data_rows[, 1L], scale = FALSE)
      data_rows[, 2L] <- scale(data_rows[, 2L], scale = FALSE)
      data_slides <- data.frame(rbind(data_slides, data_rows))
    }
    colnames(data_slides) <- c("x", "y", "slide")
  }
  
  ## Add labels, attribute, and list
  basis_slides$lab <- NULL
  if(!is.null(lab)){
    basis_slides$lab <- rep(lab, nrow(basis_slides) / length(lab))
  } else {
    if(!is.null(data)) {basis_slides$lab <- abbreviate(colnames(data), 3L)
    } else {
      basis_slides$lab <- paste0("V", 1L:p)
    }
  }
  
  attr(basis_slides, "manip_var") <- manip_var
  
  slides <- if(!is.null(data)) {
    list(basis_slides = basis_slides, data_slides = data_slides)
  } else list(basis_slides = basis_slides)
  
  slides
}



#' Prepate the ggplot object before passing to either animation package.
#'
#' Typically called by `render_plotly()` or `render_gganimate()`. Takes the 
#' result of `array2df()`, and renders them into a ggplot2 object. 
#'
#' @param slides The result of `array2df()`, a long df of the projected frames.
#' @param manip_col String of the color to highlight the `manip_var` with.
#' Defaults to "blue".
#' @param axes Position of the axes: "center", "bottomleft", "off", "left", 
#' "right". Defaults to "center".
#' @param theme_obj Optional `ggplot2::theme()` to apply to the tour. 
#' Especially for specifying a legend. 
#' Defaults to `ggplot2::theme(legend.position = "none")`.
#' @param ... Optionally passes arguments to the projection points inside the 
#' aesthetics; `geom_point(aes(...))`.
#' @export
#' @examples
#' flea_std <- tourr::rescale(tourr::flea[, 1:6])
#' 
#' rb <- tourr::basis_random(n = ncol(flea_std))
#' mtour <- manual_tour(basis = rb, manip_var = 4)
#' sshow <- array2df(array = mtour, data = flea_std)
#' render_(slides = sshow)
#' 
#' render_(slides = sshow, axes = "bottomleft", 
#'         col = tourr::flea$species, pch = tourr::flea$species, cex = 2, alpha = .5)
#'         
#' render_(slides = sshow, axes = "bottomleft", 
#'         col = tourr::flea$species, pch = tourr::flea$species, cex = 2, alpha = .5)
render_ <- function(slides,
                    axes = "center",
                    manip_col = "blue",
                    palette = "Dark2",
                    theme_obj = ggplot2::theme(legend.position = "none"),
                    ...) {
  prev_theme <-  theme_get()
  theme_set(theme_void()) #capture current theme
  
  ## Initialize
  if (length(slides) == 2L)
    data_slides <- data.frame(slides[["data_slides"]])
  basis_slides  <- data.frame(slides[["basis_slides"]])
  manip_var     <- attributes(slides$basis_slides)$manip_var
  n_slides      <- length(unique(basis_slides$slide))
  p             <- nrow(basis_slides) / n_slides
  d             <- 2L
  ## Axes unit circle
  angle         <- seq(0L, 2L * pi, length = 360L)
  circ          <- data.frame(x = cos(angle), y = sin(angle))
  ## Scale basis axes/circle
  if (axes != "off"){
    zero         <- set_axes_position(0L, axes)
    circ         <- set_axes_position(circ, axes)
    basis_slides <- data.frame(set_axes_position(basis_slides[, 1L:d], axes), 
                               basis_slides[, (d + 1L):ncol(basis_slides)])
  }
  ## manip var axes asethetics
  axes_col <- "grey50"
  axes_siz <- 0.3
  if(!is.null(manip_var)) {
    axes_col            <- rep("grey50", p) 
    axes_col[manip_var] <- manip_col
    axes_col            <- rep(axes_col, n_slides)
    axes_siz            <- rep(0.3, p)
    axes_siz[manip_var] <- 1L
    axes_siz            <- rep(axes_siz, n_slides)
  }
  
  x_min <- min(c(circ[, 1L], data_slides[, 1L])) - .1
  x_max <- max(c(circ[, 1L], data_slides[, 1L])) + .1
  y_min <- min(c(circ[, 2L], data_slides[, 2L])) - .1
  y_max <- max(c(circ[, 2L], data_slides[, 2L])) + .1
  
  gg <- 
    ## Ggplot settings
    ggplot2::ggplot() +
    ggplot2::xlim(x_min, x_max) +
    ggplot2::ylim(y_min, y_max) +
    ## Projected data points
    suppressWarnings( ## Suppress for unused aes "frame".
      ggplot2::geom_point( 
        data = dat,
        mapping = ggplot2::aes(x = x, 
                               y = y, 
                               frame = slide,
                               ...)
      )
    )
  
  ## Add axes directions if needed:
  if (axes != "off"){
    gg <- gg +
      ## Circle path
      ggplot2::geom_path(
        data = circ, color = "grey80", size = .3, inherit.aes = F,
        mapping = ggplot2::aes(x = x, y = y)
      ) +
      ## Basis axes segments
      suppressWarnings( ## Suppress for unused aes "frame".
        ggplot2::geom_segment( 
          data = basis_slides, size = axes_siz, colour = axes_col,
          mapping = ggplot2::aes(x = x, y = y, frame = slide,
                                 xend = zero[, 1L], yend = zero[, 2L])
        )
      ) +
      ## Basis axes text labels
      suppressWarnings( ## Suppress for unused aes "frame".
        ggplot2::geom_text(data = basis_slides, 
                           mapping = ggplot2::aes(x = x, y = y, 
                                                  frame = slide, label = lab),
                           vjust = "outward", hjust = "outward",
                           colour = axes_col, size = 4L)
      )
  }
  
  theme_set(prev_theme)
  gg
}


#' Render the slides as a *gganimate* animation.
#'
#' Takes the result of `array2df()` and renders them into a 
#' *gganimate* animation.
#'
#' @param fps Frames/slides shown per second. Defaults to 3.
#' @param rewind Logical, should the animation play backwards after reaching 
#' the end? Default to FALSE.
#' @param start_pause Number of seconds to pause on the first frame for.
#' Defaults to 1.
#' @param end_pause Number of seconds to pause on the last frame for.
#' Defaults to 3.
#' @param ... Optionally passes arguments to the projection points inside the 
#' aesthetics; `geom_point(aes(...))`.
#' @export
#' @examples
#' \dontrun{
#' flea_std <- tourr::rescale(tourr::flea[, 1:6])
#' 
#' rb <- tourr::basis_random(n = ncol(flea_std))
#' mtour <- manual_tour(basis = rb, manip_var = 4)
#' sshow <- array2df(array = mtour, data = flea_std)
#' render_gganimate(slides = sshow)
#' 
#' render_gganimate(slides = sshow, axes = "bottomleft", fps = 2, rewind = TRUE,
#'   col = tourr::flea$species, pch = tourr::flea$species, size = 2, alpha = .6)
#' }
render_gganimate <- function(fps = 3L,
                             rewind = FALSE,
                             start_pause = 1L,
                             end_pause = 3L,
                             ...) {
  requireNamespace("gganimate")
  
  gg  <- render_(...) + ggplot2::coord_fixed()
  gga <- gg + gganimate::transition_states(slide, 
                                           transition_length = 0L)
  
  gganimate::animate(gga, 
                     fps = fps,
                     rewind = rewind,
                     start_pause = fps * start_pause,
                     end_pause = fps * end_pause)
}



#' Render the slides as a *plotly* animation.
#'
#' Takes the result of `array2df()` and renders them into a 
#' *plotly* animation.
#'
#' @param fps Frames/slides shown per second. Defaults to 3.
#' @param tooltip Character vector of aesthetic mappings to show in the `plotly`
#' hover-over tooltip. Defaults to "none". "all" shows all the 
#' aesthetic mappings. The order of variables controls the order they appear. 
#' For example, tooltip = c("id", "frame", "x", "y", "category", "color").
#' @param ... Optionally passes arguments to the projection points inside the 
#' aesthetics; `geom_point(aes(...))`.
#' @export
#' @examples
#' flea_std   <- tourr::rescale(tourr::flea[, 1:6])
#' flea_class <- tourr::flea$species
#' rb <- tourr::basis_random(n = ncol(flea_std))
#' 
#' mtour <- manual_tour(basis = rb, manip_var = 4)
#' sshow <- array2df(array = mtour, data = flea_std)
#' 
#' \dontrun{
#' render_plotly(slides = sshow)
#' 
#' render_plotly(slides = sshow, axes = "bottomleft", fps = 2, tooltip = "all",
#' col = flea_class, pch = flea_class, size = 2, alpha = .6)
#' }
render_plotly <- function(fps = 3L,
                          tooltip = "none",
                          ...) {
  requireNamespace("plotly")
  
  gg  <- render_(graphics = "plotly", ...)
  ggp <- plotly::ggplotly(p = gg, tooltip = tooltip) 
  ggp <- plotly::animation_opts(p = ggp, 
                                frame = 1L / fps * 1000L, 
                                transition = 0L, 
                                redraw = FALSE)
  ggp <- plotly::layout(ggp, showlegend = FALSE, 
                        yaxis = list(showgrid = FALSE, showline = FALSE),
                        xaxis = list(scaleanchor = "y", scaleratio = 1L,
                                     showgrid = FALSE, showline = FALSE)
  )
  
  ggp
}

