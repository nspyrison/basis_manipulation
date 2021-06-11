##
## MATH AND TRANSFORMS -----
##

#' Test if a numeric matrix is orthonormal.
#'
#' Handles more cases than tourr::is_orthonormal().
#'
#' @param x Numeric matrix to test the orthonormality of.
#' @param tol Max tolerance of floating point differences.
#' Elecment-wise distance of t(x) %*% x from the identity matrix.
#' @return Single logical, whether or not the matrix is orthonormal.
#' @export
#' @examples 
#' is_orthonormal(tourr::basis_random(n = 6))
#' is_orthonormal(matrix(1:12, ncol = 2), tol = 0.01)
is_orthonormal <- function(x, tol = 0.001) {
  x <- as.matrix(x)
  actual <- t(x) %*% x ## Collapses to identity matrix IFF x is orthonormal
  expected <- diag(ncol(x))
  if(max(abs(actual - expected)) < tol){return(TRUE)}else{return(FALSE)}
}

#' Turns a tour path array into a long data frame.
#'
#' Typically called by a wrapper function, `play_manual_tour` or 
#' `play_tour_path`. Takes the result of `tourr::save_history()` or 
#' `manual_tour()` and restructures the data from an array to a long data frame 
#' for use in ggplots.
#'
#' @param array A (p, d, n_frames) array of a tour, the output of 
#' `manual_tour()`.
#' @param data Optional, (n, p) dataset to project, consisting of numeric 
#' variables.
#' @param basis_label Optional, labels for the reference frame, a character 
#' vector of the number of variables.
#' Defaults to the 3 character abbreviation of the original variables names.
#' @param data_label Optional, labels for plotly tooltip and return object. 
#' Defaults to the rownames of the data, if available.
#' @return A list containing an array of basis frames (p, d, n_frames) and 
#' an array of data frames (n, d, n_frames) if data is present.
#' @export
#' @examples
#' ## Setup
#' dat_std <- tourr::rescale(wine[, 2:14])
#' clas <- wine$Type
#' bas <- basis_pca(dat_std)
#' mv <- manip_var_of(bas)
#' 
#' ## Radial tour array to long df, as used in play_manual_tour()
#' tour_array <- manual_tour(basis = bas, manip_var = mv)
#' ls_df_frames <- array2df(array = tour_array, data = dat_std,
#'                          basis_label = paste0("MyLabs", 1:nrow(bas)))
#' str(ls_df_frames)
#' 
#' ## tourr::save_history tour array to long df, as used in play_tour_path()
#' hist_array <- tourr::save_history(data = dat_std, max_bases = 10)
#' ls_df_frames2 <- array2df(array = hist_array, data = dat_std)
#' str(ls_df_frames2)
array2df <- function(
  array,
  data = NULL,
  basis_label = if(is.null(data) == FALSE) abbreviate(colnames(data), 3L) else paste0("x", 1:dim(array)[1]),
  data_label = if(is.null(data) == FALSE) rownames(data) else NULL
){
  if("history_array" %in% class(array)) class(array) <- "array"
  ## Initialize
  manip_var <- attributes(array)$manip_var
  p <- dim(array)[1L]
  n_frames <- dim(array)[3L]
  
  ## Basis condition handling
  basis_frames <- NULL
  .mute <- sapply(1L:n_frames, function(i){
    basis_rows <- cbind(array[,, i], i)
    basis_frames <<- rbind(basis_frames, basis_rows)
  })
  basis_frames <- as.data.frame(basis_frames)
  .nms <- c("x", "y", "z", "w")
  colnames(basis_frames) <- c(.nms[1:(ncol(basis_frames) - 1L)], "frame")

  
  ## Data; if exists, array to long df
  if(is.null(data) == FALSE){
    data <- as.matrix(data)
    data_frames <- NULL
    .mute <- sapply(1L:n_frames, function(i){
      new_frame <- data %*% matrix(array[,, i], nrow(array), ncol(array))
      ## Center the new frame
      .mute <- sapply(1L:ncol(new_frame), function(i)
        new_frame[, i] <<- new_frame[, i] - mean(new_frame[, i])
      )
      new_frame <- cbind(new_frame, i) ## Append frame number
      data_frames <<- rbind(data_frames, new_frame) ## Add rows to df
    })
    data_frames <- as.data.frame(data_frames)
    colnames(data_frames) <- c(.nms[1:(ncol(data_frames) - 1L)], "frame")
  }
  
  ## Basis label and manip_var attribute.
  basis_frames$label <- rep_len(basis_label, nrow(basis_frames))
  attr(basis_frames, "manip_var") <- manip_var
  
  ## Return obj, add data if it exists.
  ret <- list(basis_frames = basis_frames) ## Init
  if(is.null(data) == FALSE){
    ## Data label rep if applicable
    if(is.null(data_label) == FALSE)
      data_frames$label <- rep_len(data_label, nrow(data_frames))
    ret <- c(ret, list(data_frames = data_frames))
  }
  
  return(ret)
}


#' Returns the axis scale and position.
#' 
#' Typically called by other functions to scale the position of the axes 
#' relative to the data.
#' 
#' @param x Numeric table, first 2 columns and scaled and offset relative to 
#' the `to` argument.
#' @param position Text specifying the position the axes should go to.
#' Defaults to "center" expects one of: "center", "left", "right", 
#' "bottomleft", "topright", or "off".
#' @param to Table to appropriately set the size and position of the axes to.
#' Based on the min/max of the first 2 columns.
#' @return Transformed values of `x`, dimension and class unchanged.
#' @seealso \code{\link{pan_zoom}} for more manual control.
#' @export
#' @examples
#' rb <- tourr::basis_random(4, 2)
#' 
#' scale_axes(x = rb, position = "bottomleft")
#' scale_axes(x = rb, position = "right", to = wine[, 2:3])
scale_axes <- function(x,
                       position = c("center", "left", "right", "bottomleft",
                                    "topright", "off", "pan_zoom() call;",
                                    pan_zoom(c(-1L, 0L), c(.7, .7))),
                       to = data.frame(x = c(-1L, 1L), y = c(-1L, 1L))
){
  ## Assumptions
  position <- match.arg(position)
  if(position == "off") return()
  ## If position is pan_zoom call with x = NULL;
  if(is.list(position) & length(position) == 2L){
    return(pan_zoom(pan = position$pan, zoom = position$zoom, x = x))
  }
  
  ## Initialize
  xrange  <- range(to[, 1L])
  yrange  <- range(to[, 2L])
  xdiff   <- diff(xrange)
  ydiff   <- diff(yrange)
  xcenter <- mean(xrange)
  ycenter <- mean(yrange)
  
  ## Condition handling of position
  if(position == "center"){
    scale <- .3 * ydiff
    xoff  <- xcenter
    yoff  <- ycenter
  } else if(position == "bottomleft"){
    scale <- .25 * ydiff
    xoff  <- -.25 * xdiff + xcenter
    yoff  <- -.5 * ydiff + ycenter
  } else if(position == "topright"){
    scale <- .25 * ydiff
    xoff  <- .25 * xdiff + xcenter
    yoff  <- .5 * ydiff + ycenter
  } else if(position == "left"){
    scale <- .3 * ydiff
    xoff  <- -.7 * xdiff + xcenter
    yoff  <- ycenter
  } else if(position == "right"){
    scale <- .3 * ydiff
    xoff  <- .7 * xdiff + xcenter
    yoff  <- ycenter
  }
  
  ## Apply scale and return
  x[, 1L] <- scale * x[, 1L] + xoff
  x[, 2L] <- scale * x[, 2L] + yoff
  return(x)
}


#' Pan (offset) and zoom (scale) a 2 column matrix or dataframe.
#' 
#' A manual variant of `scale_axes()`. Can be used as the `axes` argument 
#' to manually set the size and locations of the axes.
#' 
#' @param pan 2 Numeric value to offset/pan the first 2 dimensions of `x`.
#' @param zoom 2 Numeric value to scale/zoom the first 2 dimensions of `x`.
#' @param x Numeric data object with 2 columns to scale and offset.
#' Defaults to NULL, passing arguments to scale_axes for use internally.
#' @return Scaled and offset `x`.
#' @seealso \code{\link{scale_axes}} for preset choices.
#' @export
#' @examples 
#' rb <- tourr::basis_random(6, 2)
#' pan_zoom(pan = c(-1, 0), zoom = c(2/3, 2/3), x = rb)
pan_zoom <- function(pan = c(0L, 0L),
                     zoom = c(1L, 1L),
                     x = NULL
){
  if(is.null(x)) return(list(pan = pan, zoom = zoom))
  ## Assumptions
  if(ncol(x) != 2L) warning("pan_zoom is only defined for 2 variables. x has more than 2 columns")
  ## Apply scale and return
  ret <- x
  ret[, 1L] <- ret[, 1L] * zoom[1L] + pan[1L]
  ret[, 2L] <- ret[, 2L] * zoom[2L] + pan[2L]
  return(ret)
}

#' Changes an array of bases into a "history_array" for use in `tourr::interpolate`
#' 
#' Attaches data to an array and assigns the custom class "history_array" as 
#' used in `tourr`. Typically called by other `spinifex` functions.
#' 
#' @param basis_array An array of bases.
#' @param data The data matrix to be projected through the basis. This is
#' `tourr::save_history` objects, but not consumed downstream in `spinifex`.
#' @return An array of numeric bases with custom class "history_array" for 
#' consumption by `tourr::interpolate`.
#' 
#' @seealso \code{\link[tourr:save_history]{tourr::save_history}} for preset choices.
#' @export
#' @examples 
#' dat_std <- scale_sd(wine[, 2:14])
#' bas <- basis_pca(dat_std)
#' mv <- manip_var_of(bas)
#' mt_array <- manual_tour(basis = bas, manip_var = mv)
#' as_history_array(mt_array, dat_std)
as_history_array <- function(basis_array, data = NULL){
  if(length(data) > 0L)
    attr(basis_array, "data") <- as.matrix(data)
  class(basis_array) <- "history_array"
  return(basis_array)
}


#### print.history_array, not in use -----
# #' Method for printing history_array object
# #' 
# #' When a history_array object is printed (or explicitly called) remove excess 
# #' information or persisting attributes to be removed for a more friendly 
# #' display of tour arrays. 
# #' 
# #' @param x any object of class "history_array"
# #' @param ... Other arguments passed to print().
# print.history_array <- function (x, ...){
#   ## Remove all non- dim, class attributes before printing.
#   .attr_nms <- names(attributes(x)) 
#   .rm_attr_nms <- .attr_nms[!.attr_nms %in% c("dim", "class")]
#   .mute <- sapply(.rm_attr_nms, function(atr){
#     attr(x, atr) <<- NULL
#   })
#   NextMethod(...)
# }

##
## GGPLOT2 AESTHETICS ------
##

#' A ggplot2 theme suggested for linear projections with spinifex.
#' The default value for ggproto arguments in spinifex functions.
#' 
#' @param ... Optionally pass arguments to `theme()`.
#' @seealso \code{\link[ggplot2:theme]{ggplot2::theme}} for all theme options.
#' @export
#' @examples 
#' theme_spinifex()
#' 
#' require("ggplot2")
#' ggplot(mtcars, aes(wt, mpg, color = as.factor(cyl))) +
#'   geom_point() + theme_spinifex()
theme_spinifex <- function(...){
  list(ggplot2::theme_void(),
       ggplot2::scale_color_brewer(palette = "Dark2"),
       ggplot2::coord_fixed(),
       ggplot2::theme(legend.position = "bottom",      ## Of plot
                      legend.direction = "horizontal", ## With-in aesthetic
                      legend.box = "vertical",         ## Between aesthetic
                      legend.margin = ggplot2::margin(),
                      axis.title = ggplot2::element_text()), ## Allow axis titles
       ggplot2::theme(...) ## Passed args applied over all defaults.
  )
}


##
## BASIS AND MANIP VAR HELPERS -----
##

#' The basis of Principal Component Analysis (PCA)
#' 
#' The linear components of the variables in the next largest direction of 
#' variance.
#' 
#' @param data Numeric matrix or data.frame of the observations.
#' @param d Number of dimensions in the projection space.
#' @seealso \code{\link[Rdimtools:do.pca]{Rdimtools::do.pca}}
#' @export
#' @family basis identifiers
#' @examples 
#' dat_std <- scale_sd(wine[, 2:14])
#' basis_pca(data = dat_std)
basis_pca <- function(data, d = 2){
  ret <- Rdimtools::do.pca(X = as.matrix(data), ndim = d)$projection
  rownames(ret) <- colnames(data)
  colnames(ret) <- paste0("PC", 1:d)
  return(ret)
}


#' The basis of Orthogonal Linear Discriminant Analysis (OLDA)
#' 
#' Orthogonal LDA (OLDA) is an extension of classical LDA where the discriminant 
#' vectors are orthogonal to each other.
#' 
#' @param data Numeric matrix or data.frame of the observations, coerced to matrix.
#' @param class The class for each observation, coerced to a factor.
#' @param d Number of dimensions in the projection space.
#' @return A numeric matrix, an orthogonal basis that best distinguishes the 
#' group means of `class`.
#' @seealso \code{\link[Rdimtools:do.olda]{Rdimtools::do.olda}}
#' @references
#' Ye J (2005). "Characterization of a Family of Algorithms for Generalized 
#' Discriminant Analysis on Undersampled Problems." J. Mach. Learn. Res., 
#' 6, 483-502. ISSN 1532-4435.
#' @export
#' @family basis identifiers
#' @examples 
#' dat_std <- scale_sd(wine[, 2:14])
#' clas <- wine$Type
#' basis_olda(data = dat_std, class = clas)
basis_olda <- function(data, class, d = 2){
  ret <- Rdimtools::do.olda(X = as.matrix(data),
                            label = as.factor(class),
                            ndim = d)$projection
  rownames(ret) <- colnames(data)
  colnames(ret) <- paste0("OLD", 1:d)
  return(ret)
}

#' The basis of Orthogonal Discriminant Projection (ODP)
#' 
#' Orthogonal Discriminant Projection (ODP) is a linear dimension reduction 
#' method with class supervision. It maximizes weighted difference between local
#' and non-local scatter while local information is also preserved by 
#' constructing a neighborhood graph. 
#' 
#' @param data Numeric matrix or data.frame of the observations, coerced to matrix.
#' @param class The class for each observation, coerced to a factor.
#' @param d Number of dimensions in the projection space.
#' of `class`.
#' @param type A vector specifying the neighborhood graph construction. 
#' Expects; `c("knn", k)`, `c("enn", radius)`, or `c("proportion",ratio)`. 
#' Defaults to `c("knn", sqrt(nrow(data)))`, nearest neighbors equal to the 
#' square root of observations.
#' @param ... Optional, other arguments to pass to \code{\link[Rdimtools:do.odp]{Rdimtools::do.odp}}.
#' @seealso \code{\link[Rdimtools:do.odp]{Rdimtools::do.odp}} for locality
#' preservation arguments.
#' @seealso \code{\link[Rdimtools:aux.graphnbd]{Rdimtools::aux.graphnbd}} for 
#' details on `type`.
#' @references
#' Li B, Wang C, Huang D (2009). "Supervised feature extraction based on 
#' orthogonal discriminant projection." Neurocomputing, 73(1-3), 191-196.
#' @export
#' @family basis identifiers
#' @examples 
#' dat_std <- scale_sd(wine[, 2:14])
#' clas <- wine$Type
#' basis_odp(data = dat_std, class = clas)
basis_odp <- function(data, class, d = 2, type = c("proportion", 0.1), ...){
  ret <- Rdimtools::do.odp(X = as.matrix(data),
                           label = as.factor(class),
                           ndim = d,
                           type = type,
                           ...)$projection
  rownames(ret) <- colnames(data)
  colnames(ret) <- paste0("ODP", 1L:d)
  return(ret)
}

#### TODO: Error in Rdimtools::do.olpp(), issue opened to GH 10/4/2021.
# #' The basis of Orthogonal Locality Preserving Projection (OLPP)
# #' 
# #' Orthogonal Locality Preserving Projection (OLPP) is the orthogonal variant of
# #' LPP, a linear approximation to Laplacian Eigenmaps. It finds a linear 
# #' approximation to the eigenfunctions of the Laplace-Beltrami operator on the 
# #' graph-approximated data manifold.
# #' 
# #' @param data Numeric matrix or data.frame of the observations, coerced to matrix.
# #' @param d Number of dimensions in the projection space.
# #' @param type A vector specifying the neighborhood graph construction. 
# #' Expects; `c("knn", k)`, `c("enn", radius)`, or `c("proportion",ratio)`. 
# #' Defaults to `c("knn", sqrt(nrow(data)))`, nearest neighbors equal to the 
# #' square root of observations.
# #' @param ... Optional, other arguments to pass to \code{\link[Rdimtools]{do.olpp}}.
# #' @return Orthogonal matrix basis
# #' @seealso \code{\link[Rdimtools:do.olpp]{Rdimtools::do.olpp}} for locality
# #' preservation parameters.
# #' @seealso \code{\link[Rdimtools:aux.graphnbd]{Rdimtools::aux.graphnbd}} for 
# #' details on `type`.
# #' @references
# #' He X (2005). Locality Preserving Projections. PhD Thesis, 
# #' University of Chicago, Chicago, IL, USA.
# #' @export
# #' @family basis identifiers
# #' @examples
# #' dat_std <- scale_sd(wine[, 2:14])
# #' basis_olpp(data = dat_std)
# basis_olpp <- function(data, d = 2, type = c("knn", sqrt(nrow(data))), ...){
#   
#   ret <- Rdimtools::do.olpp(X = as.matrix(data),
#                             ndim = d,
#                             type = type,
#                             ...)$projection
#   rownames(ret) <- colnames(data)
#   colnames(ret) <- paste0("OLPP", 1L:d)
#   return(ret)
# }

#' The basis of Orthogonal Neighborhood Preserving Projection (OLPP)
#' 
#' Orthogonal Neighborhood Preserving Projection (ONPP) is an unsupervised 
#' linear dimension reduction method. It constructs a weighted data graph from 
#' LLE method. Also, it develops LPP method by preserving the structure of local 
#' neighborhoods. For the more details on `type` see 
#' \code{\link[Rdimtools:aux.graphnbd]{Rdimtools::aux.graphnbd()}}.
#' 
#' @param data Numeric matrix or data.frame of the observations, coerced to matrix.
#' @param d Number of dimensions in the projection space.
#' @param type A vector specifying the neighborhood graph construction. 
#' Expects; `c("knn", k)`, `c("enn", radius)`, or `c("proportion",ratio)`. 
#' Defaults to `c("knn", sqrt(nrow(data)))`, nearest neighbors equal to the 
#' square root of observations.
#' @return Orthogonal matrix basis that distinguishes the levels of `class` 
#' based on local and non-local variation as weighted against the neighborhood 
#' graph.
#' @seealso \code{\link[Rdimtools:do.onpp]{Rdimtools::do.onpp}}
#' @seealso \code{\link[Rdimtools:aux.graphnbd]{Rdimtools::aux.graphnbd}} for 
#' details on `type`.
#' @references
#' He X (2005). Locality Preserving Projections. PhD Thesis, 
#' University of Chicago, Chicago, IL, USA.
#' @export
#' @family basis identifiers
#' @examples
#' dat_std <- scale_sd(wine[, 2:14])
#' basis_onpp(data = dat_std)
basis_onpp <- function(data, d = 2, type = c("knn", sqrt(nrow(data)))){
  ret <- Rdimtools::do.onpp(X = as.matrix(data),
                            ndim = d,
                            type = type)$projection
  rownames(ret) <- colnames(data)
  colnames(ret) <- paste0("ONPP", 1L:d)
  return(ret)
}


#' Solve for the last basis of a guided tour.
#' 
#' Performs simulated annealing on the index function, solving for it's local
#' extrema. Returns only the last identified basis of the optimization. A 
#' truncated, muted extension of tourr::save_history(guided_tour())).
#' 
#' @param data Numeric matrix or data.frame of the observations.
#' @param index_f The index function to optimize.
#' `{tourr}` exports `holes()`, `cmass()`, and `lda_pp(class)`.
#' @param d Number of dimensions in the projection space.
#' @param ... Optional, other arguments to pass to 
#' \code{\link[tourr:guided_tour]{tourr::guided_tour}}
#' @return Numeric matrix of the last basis of a guided tour.
#' @seealso \code{\link[tourr:guided_tour]{tourr::guided_tour}} for annealing 
#' arguments.
#' @export
#' @family basis identifiers
#' @examples 
#' dat_std <- scale_sd(wine[, 2:14])
#' basis_guided(data = dat_std, index_f = tourr::holes())
#' 
#' basis_guided(data = dat_std, index_f = tourr::cmass(),
#'              alpha = .4, cooling = .9, max.tries = 30)
basis_guided <- function(data, index_f = tourr::holes(), d = 2, ...){
  invisible(utils::capture.output(
    hist <- tourr::save_history(
      data,
      tourr::guided_tour(index_f = index_f, d = d, ...)
    )
  ))
  ret <- matrix(hist[,, length(hist)], ncol = d)
  rownames(ret) <- colnames(data)
  colnames(ret) <- paste0(index_f, 1L:d)
  return(ret)
}


#' Create a basis that gives uniform contribution in a circle
#' 
#' Orthonormalizes uniform variable contributions on a unit circle. This
#' serves as a NULL basis, one that is variable agnostic while spacing the
#' variables to have minimize variable dependence.
#' 
#' @param data The data to create a basis for.
#' @export
#' @family basis identifiers
#' @examples 
#' dat_std <- scale_sd(wine[, 2:14])
#' bas <- basis_half_circle(dat_std)
basis_half_circle <- function(data){
  pp1 <- ncol(data) + 1L ## p++
  arc <- seq(0L, pi, length.out = pp1)[-pp1]
  u_circ <- as.matrix(data.frame(y1 = sin(arc), y2 = cos(arc)))
  bas <- tourr::orthonormalise(u_circ)
  rownames(bas) <- colnames(data)
  colnames(bas) <- paste0("half_circ", 1L:2L)
  return(bas)
}


#' Suggest a manipulation variable.
#' 
#' Find the column number of the variable with the `rank`-ith largest 
#' contribution in the first column of the supplied basis. 
#' Useful for identifying a variable to change the contribution of in a manual 
#' tour, it's `manip_var` argument.
#' 
#' @param basis Numeric matrix (p x d), orthogonal liner combinations of the 
#' variables.
#' @param rank The number, specifying the variable with the `rank`-th largest 
#' contribution. Defaults to 1.
#' @return Numeric scalar, the column number of a variable.
#' @export
#' @examples 
#' ## Setup
#' dat_std <- scale_sd(wine[, 2:14])
#' bas <- basis_pca(dat_std)
#' 
#' manip_var_of(basis = bas, rank = 1)
manip_var_of <- function(basis, rank = 1){
  if(spinifex::is_orthonormal(basis) == FALSE) 
    warning("Supplied basis isn't orthonormal.")
  ret <- order(abs(basis[, 1L]), decreasing = TRUE)[rank]
  names(ret) <- rownames(basis)[rank]
  return(ret)
}

#' Preprocessing variable transformation
#' 
#' Centers and scales each column by standard deviation (sd) or to the 
#' interval (0, 1).
#' 
#' @param data Numeric matrix or data.frame of the observations.
#' @export
#' @examples
#' scale_sd(data = wine[, 2:14])
scale_sd <- function(data){
  return(apply(data, 2L, function(c){(c - mean(c)) / stats::sd(c)}))
}

#' @rdname scale_sd
#' @export
#' @examples 
#' scale_01(data = wine[, 2:14])
scale_01 <- function(data){
  return(apply(data, 2L, function(c) (c - min(c)) / diff(range(c))))
}

