% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/cv.enpls.R
\name{cv.enpls}
\alias{cv.enpls}
\title{Cross Validation for Ensemble Partial Least Squares Regression}
\usage{
cv.enpls(x, y, nfolds = 5L, verbose = TRUE, ...)
}
\arguments{
\item{x}{Predictor matrix.}

\item{y}{Response vector.}

\item{nfolds}{Number of cross-validation folds, default is \code{5}.
Note that this is the CV folds for the ensemble PLS model,
not the individual PLS models. To control the CV folds for
single PLS models, please use the argument \code{cvfolds}.}

\item{verbose}{Shall we print out the progress of cross-validation?}

\item{...}{Arguments to be passed to \code{\link{enpls.fit}}.}
}
\value{
A list containing:
\itemize{
\item \code{ypred} - a matrix containing two columns: real y and predicted y
\item \code{residual} - cross validation result (y.pred - y.real)
\item \code{RMSE} - RMSE
\item \code{MAE} - MAE
\item \code{Rsquare} - Rsquare
}
}
\description{
K-fold cross validation for ensemble partial least squares regression.
}
\note{
To maximize the probablity that each observation can
be selected in the test set (thus the prediction uncertainty
can be measured), please try setting a large \code{reptimes}.
}
\examples{
data("alkanes")
x = alkanes$x
y = alkanes$y

set.seed(42)
cvfit = cv.enpls(x, y, reptimes = 10)
print(cvfit)
plot(cvfit)
}
\seealso{
See \code{\link{enpls.fit}} for ensemble
partial least squares regressions.
}
\author{
Nan Xiao <\url{https://nanx.me}>
}
