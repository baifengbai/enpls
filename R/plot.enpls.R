#' Plot cv.enpls object
#'
#' Plot cv.enpls object
#'
#' @param x An object of class \code{cv.enpls}.
#' @param xlim x vector of lenght 2, x axis limits of the plot
#' @param ylim y vector of lenght 2, y axis limits of the plot
#' @param main Plot title, not used.
#' @param ... Additional graphical parameters, not used.
#'
#' @author Nan Xiao <\url{http://nanx.me}>
#'
#' @seealso See \code{\link{cv.enpls}} for ensemble
#' partial least squares regression.
#'
#' @method plot cv.enpls
#'
#' @importFrom ggplot2 ggplot aes_string geom_point geom_abline
#' coord_fixed xlab ylab
#'
#' @export
#'
#' @examples
#' data("alkanes")
#' x = alkanes$x
#' y = alkanes$y
#'
#' set.seed(42)
#' cvfit = cv.enpls(x, y, reptimes = 10)
#' plot(cvfit)

plot.cv.enpls = function(x, xlim = NULL, ylim = NULL, main = NULL, ...) {

  if (!inherits(x, 'cv.enpls'))
    stop('This function only works for objects of class "cv.enpls"')

  df = as.data.frame(x$'ypred')

  xrange = range(df$'y.real')
  yrange = range(df$'y.pred')
  # make sure x and y have same range, so ratio can be fixed at 1
  fixrange = c(min(xrange[1L], yrange[1L]), max(xrange[2L], yrange[2L]))

  if (is.null(xlim)) xlim = fixrange
  if (is.null(ylim)) ylim = fixrange

  ggplot(df, aes_string(x = 'y.real', y = 'y.pred',
                        xmin = xlim[1L], xmax = xlim[2L],
                        ymin = ylim[1L], ymax = ylim[2L])) +
    geom_abline(slope = 1, intercept = 0, colour = 'darkgrey') +
    geom_point(size = 3, shape = 1, alpha = 0.8) +
    coord_fixed(ratio = 1) +
    xlab('Observed Response') +
    ylab('Predicted Response')

}

#' Plot enpls.fs object
#'
#' Plot enpls.fs object
#'
#' @param x An object of class \code{enpls.fs}.
#' @param nvar How many variables to show? Ignored if \code{sort = FALSE}.
#' @param type Plot type, can be \code{dotplot} or \code{boxplot}.
#' @param limits Vector of length 2. Set boxplot limits (in quantile) to
#' remove the extreme outlier coefficients.
#' @param main Plot title, not used.
#' @param ... Additional graphical parameters, not used.
#'
#' @author Nan Xiao <\url{http://nanx.me}>
#'
#' @seealso See \code{\link{enpls.fs}} for feature selection with
#' ensemble partial least squares regression.
#'
#' @method plot enpls.fs
#'
#' @importFrom ggplot2 ggplot geom_point aes_string theme
#' element_blank element_line scale_y_continuous geom_boxplot coord_flip
#' @importFrom reshape2 melt
#'
#' @export
#'
#' @examples
#' data("alkanes")
#' x = alkanes$x
#' y = alkanes$y
#'
#' set.seed(42)
#' fs = enpls.fs(x, y, reptimes = 50)
#' plot(fs)
#' plot(fs, nvar = 10)
#' plot(fs, type = "boxplot")
#' plot(fs, type = "boxplot", limits = c(0.05, 0.95))

plot.enpls.fs = function(x, nvar = NULL,
                         type = c('dotplot', 'boxplot'),
                         limits = c(0, 1),
                         main = NULL, ...) {

  if (!inherits(x, 'enpls.fs'))
    stop('This function only works for objects of class "enpls.fs"')

  type = match.arg(type)
  imp = x$'variable.importance'
  if (is.null(nvar)) nvar = length(imp)

  if (type == 'dotplot') {

    # sort variables in decreasing order
    df = data.frame(sort(imp, TRUE)[nvar:1])
    df[, 2L] = row.names(df)
    names(df) = c('varimp', 'varname')
    # make ggplot2 plot in original order instead of alphabetical order
    df$'varname' = factor(df$'varname', levels = df$'varname')

    p = ggplot(df) +
      geom_point(aes_string(x = 'varimp', y = 'varname')) +
      theme(panel.grid.major.x = element_blank(),
            panel.grid.major.y = element_line(linetype = 3, color = 'darkgray')) +
      xlab('Variable Importance Score') +
      ylab('Variable Name')

  }

  if (type == 'boxplot') {

    mat = x$'coefficient.matrix'
    df = as.data.frame(mat[, names(sort(imp, TRUE)[nvar:1])])
    df = suppressMessages(melt(df))
    p = ggplot(df, aes_string(x = 'variable', y = 'value')) +
      scale_y_continuous(limits = quantile(df$'value', limits)) +
      geom_boxplot() + coord_flip() +
      xlab('Coefficients') +
      ylab('Variable Name')

  }

  p

}

#' Plot enpls.od object
#'
#' Plot enpls.od object
#'
#' @param x An object of class \code{enpls.od}.
#' @param criterion Criterion of being outlier,
#' could be \code{"quantile"} or \code{"sd"}.
#' @param prob Quantile probability as cut-off.
#' @param sdtimes Times of standard deviation as cut-off.
#' @param main Plot title.
#' @param ... Additional graphical parameters for \code{\link{plot}}.
#'
#' @author Nan Xiao <\url{http://nanx.me}>
#'
#' @seealso See \code{\link{enpls.od}} for outlier detection with
#' ensemble partial least squares regression.
#'
#' @importFrom graphics axis grid par points rect
#'
#' @method plot enpls.od
#'
#' @export
#'
#' @examples
#' data("alkanes")
#' x = alkanes$x
#' y = alkanes$y
#'
#' set.seed(42)
#' od = enpls.od(x, y, reptimes = 50)
#' plot(od, criterion = 'quantile')
#' plot(od, criterion = 'sd')

plot.enpls.od = function(x,
                         criterion = c('quantile', 'sd'),
                         prob = 0.05, sdtimes = 3L,
                         main = NULL, ...) {

  if (!inherits(x, 'enpls.od'))
    stop('This function only works for objects of class "enpls.od"')

  criterion = match.arg(criterion)

  error.mean = x$'error.mean'
  error.sd = x$'error.sd'

  if (criterion == 'quantile') {
    vpos = quantile(error.mean, 1 - prob, na.rm = TRUE)
    hpos = quantile(error.sd, 1 - prob, na.rm = TRUE)
  } else {
    vpos = mean(error.mean, na.rm = TRUE) + (sdtimes * sd(error.mean, na.rm = TRUE))
    hpos = mean(error.sd, na.rm = TRUE) + (sdtimes * sd(error.sd, na.rm = TRUE))
  }

  yout = intersect(which(error.mean >= vpos), which(error.sd <= hpos))
  Xout = intersect(which(error.mean <= vpos), which(error.sd >= hpos))
  abnormal = intersect(which(error.mean >= vpos), which(error.sd >= hpos))

  plot(error.mean, error.sd,
       xlab = 'Error Mean', ylab = 'Error SD',
       bty = 'n', xaxt = 'n', yaxt = 'n', main = main, ...)

  # fill
  rect(par('usr')[1], par('usr')[3],
       par('usr')[2], par('usr')[4],
       col = '#EBEBEB', border = NA)
  # box
  rect(par('usr')[1], par('usr')[3],
       par('usr')[2], par('usr')[4],
       border = 'darkgrey', lwd = 0.5)
  # grid lines
  grid(col = 'white', lty = 1)

  points(error.mean, error.sd)

  axis(side = 1, labels = TRUE, col = 'darkgrey', lwd = 0.3, cex.axis = 0.8)
  axis(side = 2, labels = TRUE, col = 'darkgrey', lwd = 0.3, cex.axis = 0.8)

  abline(h = hpos, col = 'black', lty = 2)
  abline(v = vpos, col = 'black', lty = 2)

  if (length(yout) != 0L) {
    points(error.mean[yout], error.sd[yout], pch = 21, bg = '#d62728')
    text(error.mean[yout], error.sd[yout],
         labels = as.character(yout),
         col = '#d62728', cex = 0.8, font = 2, pos = 3)
  }

  if (length(Xout) != 0L) {
    points(error.mean[Xout], error.sd[Xout], pch = 21, bg = '#1f77b4')
    text(error.mean[Xout], error.sd[Xout],
         labels = as.character(Xout),
         col = '#1f77b4', cex = 0.8, font = 2, pos = 1)
  }

  if (length(abnormal) != 0L) {
    points(error.mean[abnormal], error.sd[abnormal], pch = 21, bg = '#2ca02c')
    text(error.mean[abnormal], error.sd[abnormal],
         labels = as.character(abnormal),
         col = '#2ca02c', cex = 0.8, font = 2, pos = 1)
  }

}