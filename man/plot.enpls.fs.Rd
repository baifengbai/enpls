% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/plot.enpls.R
\name{plot.enpls.fs}
\alias{plot.enpls.fs}
\title{Plot enpls.fs object}
\usage{
\method{plot}{enpls.fs}(x, nvar = NULL, type = c("dotplot", "boxplot"),
  limits = c(0, 1), main = NULL, ...)
}
\arguments{
\item{x}{An object of class \code{enpls.fs}.}

\item{nvar}{Number of top variables to show. Ignored if \code{sort = FALSE}.}

\item{type}{Plot type. \code{"dotplot"} or \code{"boxplot"}.}

\item{limits}{Vector of length 2. Set boxplot limits (in quantile) to
remove the extreme outlier coefficients.}

\item{main}{Plot title, not used currently.}

\item{...}{Additional graphical parameters, not used currently.}
}
\description{
Plot enpls.fs object
}
\examples{
data("alkanes")
x = alkanes$x
y = alkanes$y

set.seed(42)
fs = enpls.fs(x, y, reptimes = 50)
plot(fs)
plot(fs, nvar = 10)
plot(fs, type = "boxplot")
plot(fs, type = "boxplot", limits = c(0.05, 0.95))
}
\seealso{
See \code{\link{enpls.fs}} for measuring feature importance with
ensemble partial least squares regressions.
}
\author{
Nan Xiao <\url{https://nanx.me}>
}
