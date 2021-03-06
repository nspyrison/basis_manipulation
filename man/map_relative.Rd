% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/0_util.r
\name{map_relative}
\alias{map_relative}
\title{Returns the axis scale and position.}
\usage{
map_relative(
  x,
  position = c("center", "left", "right", "bottomleft", "topright", "off"),
  to = NULL
)
}
\arguments{
\item{x}{Numeric matrix or data.frame, first 2 columns and scaled and offset
the \code{to} object.}

\item{position}{Text specifying the position the axes should go to.
Defaults to "center" expects one of: "center", "left", "right",
"bottomleft", "topright", or "off".}

\item{to}{Table to appropriately set the size and position of the axes to.
Based on the min/max of the first 2 columns. If left NULL defaults to
data.frame(x = c(-1L, 1L), y = c(-1L, 1L).}
}
\value{
Transformed values of \code{x}, dimension and class unchanged.
}
\description{
Internal function. Typically called by other functions to scale the position
of the axes data.frame or another data.frame to plot relative to the data.
}
\examples{
## !!This function is not meant for external use!!
rb <- tourr::basis_random(4, 2)

map_relative(x = rb, position = "bottomleft")
map_relative(x = rb, position = "right", to = wine[, 2:3])
}
\seealso{
\code{\link{map_absolute}} for more manual control.

Other Linear mapping: 
\code{\link{map_absolute}()}
}
\concept{Linear mapping}
