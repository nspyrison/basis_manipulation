% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/3_visualize.r
\name{view_manip_space}
\alias{view_manip_space}
\title{Plot projection frame and return the axes table.}
\usage{
view_manip_space(
  basis,
  manip_var,
  tilt = 0.1 * pi,
  basis_label = abbreviate(row.names(basis), 3L),
  manip_col = "blue",
  manip_sp_col = "red",
  line_size = 1L,
  text_size = 5L,
  ggproto = list(theme_spinifex())
)
}
\arguments{
\item{basis}{A (p, d) orthonormal numeric matrix.
The linear combination the original variables contribute to projection space.
Required, no default.}

\item{manip_var}{Number of the column/dimension to rotate.}

\item{tilt}{angle in radians to rotate the projection plane.
Defaults to .1 * pi.}

\item{basis_label}{Optional, character vector of \code{p} length, add name to the axes
in the frame, defaults to 3 letter abbriviation of the orginal variable names.}

\item{manip_col}{String of the color to highlight the \code{manip_var}.}

\item{manip_sp_col}{Color to illustrate the z direction, orthogonal to the
projection plane.}

\item{line_size}{The size of the lines of the unit circle and variable
contributions of the basis. Defaults to 1.}

\item{text_size}{The size of the text labels of the variable
contributions of the basis. Defaults to 5.}

\item{ggproto}{A list of ggplot2 function calls.
Anything that would be "added" to ggplot(); in the case of applying a theme,
\code{ggplot() + theme_bw()} becomes \code{ggproto = list(theme_bw())}.
Intended for aesthetic ggplot2 functions (not geom_* family).}
}
\value{
ggplot object of the basis.
}
\description{
Uses base graphics to plot the circle with axes representing
the projection frame. Returns the corresponding table.
}
\examples{
dat_std <- scale_sd(wine[, 2:6])
bas <- basis_pca(dat_std)
mv <- manip_var_of(bas)

view_manip_space(basis = bas, manip_var = mv)

view_manip_space(basis = bas, manip_var = mv,
                 tilt = 2/12 * pi, basis_label = paste0("MyNm", 1:ncol(dat_std)),
                 manip_col = "purple", manip_sp_col = "orange", 
                 ggproto = list(ggplot2::theme_void(), ggplot2::ggtitle("My title")))
}
