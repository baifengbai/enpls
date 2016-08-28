#' Ensemble Partial Least Squares for Outlier Detection
#'
#' Outlier detection with ensemble partial least squares.
#'
#' @param x predictor matrix
#' @param y response vector
#' @param maxcomp Maximum number of components included within the models,
#' if not specified, default is the variable (column) numbers in x.
#' @param reptimes Number of models to build with Monte-Carlo resampling
#' or bootstrapping.
#' @param method \code{"mc"} or \code{"bootstrap"}. Default is \code{"mc"}.
#' @param ratio sample ratio used when \code{method = "mc"}
#' @param parallel Integer. Number of CPU cores to use.
#' Default is \code{1} (not parallelized).
#'
#' @return A list containing four components:
#' \itemize{
#' \item \code{error.mean} - error mean for all samples (absolute value)
#' \item \code{error.median} - error median for all samples
#' \item \code{error.sd} - error sd for all samples
#' \item \code{predict.error.matrix} - the original prediction error matrix
#' }
#'
#' @author Nan Xiao <\url{http://nanx.me}>
#'
#' @note To maximize the probablity that each observation can
#' be selected in the test set (thus the prediction uncertainty
#' can be measured), please try setting a large \code{reptimes}.
#'
#' @seealso See \code{\link{enpls.fs}} for feature selection with
#' ensemble partial least squares regression.
#' See \code{\link{enpls.fit}} for ensemble partial least squares regression.
#'
#' @export enpls.od
#'
#' @importFrom doParallel registerDoParallel
#' @importFrom foreach foreach "%dopar%"
#'
#' @examples
#' data("alkanes")
#' x = alkanes$x
#' y = alkanes$y
#'
#' set.seed(42)
#' od = enpls.od(x, y, reptimes = 100)
#' print(od)
#' plot(od)
#' plot(od, criterion = 'sd')

enpls.od = function(x, y,
                    maxcomp = NULL,
                    reptimes = 500L,
                    method = c('mc', 'bootstrap'), ratio = 0.8,
                    parallel = 1L) {

  if (missing(x) | missing(y)) stop('Please specify both x and y')

  if (is.null(maxcomp)) maxcomp = ncol(x)

  method = match.arg(method)

  x.row = nrow(x)
  samp.idx = vector('list', reptimes)
  samp.idx.remain = vector('list', reptimes)

  if (method == 'mc') {
    for (i in 1L:reptimes) {
      samp.idx[[i]] = sample(1L:x.row, round(x.row * ratio))
      samp.idx.remain[[i]] = setdiff(1L:x.row, samp.idx[[i]])
    }
  }

  if (method == 'bootstrap') {
    for (i in 1L:reptimes) {
      samp.idx[[i]] = sample(1L:x.row, x.row, replace = TRUE)
      samp.idx.remain[[i]] = setdiff(1L:x.row, unique(samp.idx[[i]]))
    }
  }

  plsdf = as.data.frame(cbind(x, y))

  if (parallel < 1.5) {

    errorlist = vector('list', reptimes)
    for (i in 1L:reptimes) {
      plsdf.sample = plsdf[samp.idx[[i]], ]
      plsdf.remain = plsdf[samp.idx.remain[[i]], ]
      errorlist[[i]] = suppressWarnings(enpls.od.core(plsdf.sample, plsdf.remain, maxcomp))
    }

  } else {

    registerDoParallel(parallel)
    errorlist = foreach(i = 1L:reptimes) %dopar% {
      plsdf.sample = plsdf[samp.idx[[i]], ]
      plsdf.remain = plsdf[samp.idx.remain[[i]], ]
      enpls.od.core(plsdf.sample, plsdf.remain, maxcomp)
    }

  }

  prederrmat = matrix(NA, ncol = x.row, nrow = reptimes)
  for (i in 1L:reptimes) {
    for (j in 1L:length(samp.idx.remain[[i]])) {
      prederrmat[i, samp.idx.remain[[i]][j]] = errorlist[[i]][j]
    }
  }

  errmean   = abs(colMeans(prederrmat, na.rm = TRUE))
  errmedian = apply(prederrmat, 2L, median, na.rm = TRUE)
  errsd     = apply(prederrmat, 2L, sd, na.rm = TRUE)

  object = list('error.mean'    = errmean,
                'error.median'  = errmedian,
                'error.sd'      = errsd,
                'predict.error.matrix' = prederrmat)
  class(object) = 'enpls.od'
  return(object)

}

#' core function for enpls.od
#'
#' select the best ncomp with cross-validation and
#' use it to fit the complete training set,
#' then predict on the test set. scale = TRUE
#'
#' @return the error vector between predicted y and real y
#'
#' @keywords internal

enpls.od.core = function(plsdf.sample, plsdf.remain, maxcomp) {

  plsr.cvfit = plsr(y ~ ., data = plsdf.sample,
                    ncomp  = maxcomp,
                    scale  = TRUE,
                    method = 'simpls',
                    validation = 'CV', segments = 5L)

  # select best component number using adjusted CV
  cv.bestcomp = which.min(RMSEP(plsr.cvfit)[['val']][2L, 1L, -1L])

  plsr.fit = plsr(y ~ ., data = plsdf.sample,
                  ncomp  = cv.bestcomp,
                  scale  = TRUE,
                  method = 'simpls',
                  validation = 'none')

  pred = predict(plsr.fit, ncomp = cv.bestcomp,
                 newdata = plsdf.remain[, !(colnames(plsdf.remain) %in% c('y'))])[, 1L, 1L]

  error = plsdf.remain[, 'y'] - pred
  names(error) = NULL

  return(error)

}