#' Produce the series of projection bases to rotate a variable into and out 
#' of a projection
#'
#' Typically called by `array2af()`. An array of projections, 
#' the manual tour of the `manip_var`, which is rotated from phi's starting 
#' position to `phi_max`, to `phi_min`, and back to the start position.
#'
#' @param basis A (p, d) dim orthonormal matrix. Required, no default.
#' @param manip_var Integer column number or string exact column name of the.
#'   variable to manipulate. Required, no default.
#' @param theta Angle in radians of "in-plane" rotation, on the XY plane of the 
#'   reference frame. Defaults to theta of the basis for a radial manual tour.
#' @param phi_min Minimum value phi should move to. Phi is angle in radians of 
#'   the "out-of-plane" rotation, the z-axis of the reference frame. 
#'   Required, defaults to 0.
#' @param phi_max Maximum value phi should move to. Phi is angle in radians of 
#'   the "out-of-plane" rotation, the z-axis of the reference frame. 
#'   Required, defaults to pi/2.
#' @param angle target distance (in radians) between bases.
#' @return A (p, d, 4) history_array of the manual tour. The bases set for
#'   phi_start, `phi_min`,  `phi_max`, and back to phi_start. To be called by
#'   `tourr::interpolate()`.
#' @export
#' @examples
#' flea_std <- tourr::rescale(tourr::flea[,1:6])
#' 
#' rb <- basis_random(n = ncol(flea_std))
#' radial_tour(basis = rb, manip_var = 4)
radial_tour <- function(basis = NULL,
                        manip_var,
                        theta = NULL,
                        phi_min = 0,
                        phi_max = .5 * pi,
                        angle = .05
) {
  # Initalize
  basis <- as.matrix(basis)
  p     <- nrow(basis)
  d     <- ncol(basis)
  manip_space <- create_manip_space(basis = basis, manip_var = manip_var)
  if (is.null(theta)) theta <- atan(basis[manip_var, 2] / basis[manip_var, 1])
  phi_start <- acos(sqrt(basis[manip_var, 1]^2 + basis[manip_var, 2]^2)) 
  stopifnot(phi_min <= phi_start & phi_max >= phi_start)
  
  # Find phi's path
  find_path <- function(start, end){
    
    mvar_xsign <- -sign(basis[manip_var, 1])
    start <- mvar_xsign * (start - phi_start)
    end   <- mvar_xsign * (end - phi_start)
    dist  <- abs(end - start)
    remainder <- dist %% angle # remainder
    sign  <- ifelse(end > start, 1, -1)
    
    path <- seq(from = start, to = end - remainder, by = sign * angle)
    if (remainder != 0) path <- c(path, end)
    
    path
  }
  
  phi_path <- c(find_path(start = phi_start, end = phi_min),
                find_path(start = phi_min,   end = phi_max),
                find_path(start = phi_max, end = phi_start))
  
  ## Make projected basis array
  n_frames <- length(phi_path)
  
  basis_set <- array(NA, dim = c(p, d, n_frames))
  for (i in 1:n_frames) {
    thisFrame <- rotate_manip_space(manip_space = manip_space, theta = theta,
                                    phi = phi_path[i])
    basis_set[,, i] <- thisFrame[, 1:d]
  }

  attr(basis_set, "manip_var") <- manip_var

  basis_set
}