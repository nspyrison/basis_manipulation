#' Create a manipulation space
#'
#' Typically called by `manual_tour()`. Creates a (p, d) orthonormal matrix,
#' the manipulation space from the given basis right concatenated with a zero 
#' vector, with manip_var set to 1.
#'
#' @param basis A (p, d) orthonormal matrix.
#' @param manip_var Number of the dimension (numeric variable) to rotate.
#' @return A (p, d+1) orthonormal matrix, the manipulation space.
#' @export
#' @examples
#' flea_std <- tourr::rescale(tourr::flea[,1:6])
#' 
#' rb <- tourr::basis_random(n = ncol(flea_std))
#' create_manip_space(basis = rb, manip_var = 4)
create_manip_space <- function(basis, 
                               manip_var) {
  if (!is.matrix(basis)) as.matrix(basis)

  e            <- rep(0, len = nrow(basis))
  e[manip_var] <- 1
  manip_space  <- tourr::orthonormalise(cbind(basis, e))
  colnames(manip_space) <- NULL
  
  return(manip_space)
}

#' Rotate and return the manipulation space
#'
#' Typically called by `manual_tour()`. Rotates a (p, d+1) manipulation space 
#' matrix by (d+1, d+1) rotation matrix, returning (p, d+1) matrix rotation 
#' space. The first 2 variables of which are the linear combination of the 
#' variables for a 2d projection.
#'
#' @param manip_space A (p, d+1) dim manipulation space to be rotated.
#' @param theta Angle in radians of rotation "in-plane", on the XY plane of the 
#'   reference frame. Typically set from manip_type in `proj_data()`.
#' @param phi Angle in radians of rotation "out-of-plane", the z axis of the 
#'   reference frame. Effectively changes the norm of XY contributions of the 
#'   manip_var.
#' @return A (p, d+1) orthonormal matrix of the rotated (manipulation) space.
#' @export
#' @examples
#' flea_std <- tourr::rescale(tourr::flea[,1:6])
#' 
#' rb <- tourr::basis_random(n = ncol(flea_std))
#' msp <- create_manip_space(basis = rb, manip_var = 4) 
#' rotate_manip_space(msp, theta = runif(1, max = 2 * pi), 
#'                    phi = runif(1, max = 2 * pi) )
rotate_manip_space <- function(manip_space, theta, phi) {
  # Initialize
  s_theta <- sin(theta)
  c_theta <- cos(theta)
  s_phi   <- sin(phi)
  c_phi   <- cos(phi)
  
  # Rotation matrix, [3, 3], a function of theta and phi.
  R <- matrix(c(c_theta^2 * c_phi + s_theta^2,
                -c_theta * s_theta * (1 - c_phi),
                -c_theta * s_phi,                      # 3 of 9
                -c_theta * s_theta * (1 - c_phi),
                s_theta^2 * c_phi + c_theta^2,
                -s_theta * s_phi,                      # 6 of 9
                c_theta * s_phi,
                s_theta * s_phi,
                c_phi)                                 # 9 of 9
              ,nrow = 3, ncol = 3, byrow = TRUE)
  
  rotation_space <- manip_space %*% R
  colnames(rotation_space) <- colnames(manip_space)
  rownames(rotation_space) <- rownames(manip_space)
  
  return(rotation_space)
}

#' Produce the series of projection bases to rotate a variable into and out 
#' of a projection
#'
#' Typically called by `create_slides()`. An array of projections, 
#' the manual tour of the `manip_var`, which is rotated from phi's starting 
#' position to `phi_max`, to `phi_min`, and back to the start position.
#'
#' @param basis A (p, d) dim orthonormal matrix. Required, no default.
#' @param manip_var Integer column number or string exact column name of the.
#'   variable to manipulate. Required, no default.
#' @param manip_type String of the type of manipulation to use. 
#'   Defaults to "radial". Alternatively accepts "horizontal" or "vertical". 
#'   Yields to `theta` if set. Must set either `manip_type` or `theta`.
#' @param theta Angle in radians of "in-plane" rotation, on the XY plane of the 
#'   reference frame. Typically set from manip_type in `proj_data`. Supersedes 
#'   `manip_type`. Must set either `manip_type` or `theta`.
#' @param phi_min Minimum value phi should move to. Phi is angle in radians of 
#'   the "out-of-plane" rotation, the z-axis of the reference frame. 
#'   Required, defaults to 0.
#' @param phi_max Maximum value phi should move to. Phi is angle in radians of 
#'   the "out-of-plane" rotation, the z-axis of the reference frame. 
#'   Required, defaults to pi/2.
#' @param n_slides Number of slides to create. Defaults to 20.
#' @return A (p, d, n_slides) dim array of the manual tour. Containing
#'   `n_slides` interpolations varying phi from it's start to `phi_min`, to 
#'   `phi_max`, and back to start.
#' @export
#' @examples
#' flea_std <- tourr::rescale(tourr::flea[,1:6])
#' 
#' rb <- tourr::basis_random(n = ncol(flea_std))
#' manual_tour(basis = rb, manip_var = 4)
manual_tour <- function(basis = NULL,
                        manip_var,  # column number
                        # manip_type = "radial", #alt: "horizontal" and "vertical"
                        theta = NULL,      # (radians)
                        phi_min = 0,       # (radians)
                        phi_max = .5 * pi, # (radians)
                        n_slides = 20) {
  
  if (!is.matrix(basis)) basis <- as.matrix(basis)
  if (is.null(theta))    theta <- atan(basis[manip_var, 2] / basis[manip_var, 1])
  stopifnot(phi_start < phi_min | phi_start > phi_max)
  
  # Initalize
  manip_space    <- create_manip_space(basis = basis, manip_var = manip_var)
  p              <- nrow(basis)
  d              <- ncol(basis)
  phi_start      <- acos(sqrt(basis[manip_var, 1]^2 + basis[manip_var, 2]^2))
  phi_start_sign <- phi_start * sign(manip_space[manip_var, 1])
  phi_inc        <- 2 * abs(phi_max - phi_min) / (n_slides - 3)
  
  interpolate_walk <- function(seq_start, seq_end){
    # Initialize for interpolate_slides()
    slide        <- 0
    new_slide    <- NULL
    seq_start    <- seq_start + phi_start_sign # Transform such that phi is relative to Z=0, rather than phi_start
    seq_end      <- seq_end   + phi_start_sign
    phi_inc_sign <- phi_inc * ifelse(seq_end > seq_start, 1, -1) 
    phi_len      <- length(seq(seq_start, seq_end, phi_inc_sign))
    interp       <- array(dim = c(p, d, phi_len))
    
    # Create slide, store in interpolation
    for (phi in seq(seq_start, seq_end, phi_inc_sign)) {
      slide <- slide + 1
      interp[,, slide] <- rotate_manip_space(manip_space, theta, phi)[, 1:2]
    }
    return(interp)
  }
  
  walk1 <- interpolate_walk(phi_start, phi_min)
  walk2 <- interpolate_walk(phi_min, phi_max)
  walk3 <- interpolate_walk(phi_max, phi_start)
  walk4 <- interpolate_walk(phi_start, phi_start)
  
  m_tour <- array(c(walk1, walk2, walk3, walk4), dim = c(p, d, n_slides))
  attr(m_tour, "manip_var") <- manip_var
  
  return(m_tour)
}