#
#   Methods for class "mcmcRocPrc", generated by mcmcRocPrc()
#

#' @rdname mcmcRocPrc
#' 
#' @export
print.mcmcRocPrc <- function(x, ...) {
  
  auc_roc <- x$area_under_roc
  auc_prc <- x$area_under_prc
  
  has_curves <- !is.null(x$roc_dat)
  has_sims   <- length(auc_roc) > 1
  
  if (!has_sims) {
    roc_msg <- sprintf("%.3f", round(auc_roc, 3))
    prc_msg <- sprintf("%.3f", round(auc_prc, 3))
  } else {
    roc_msg <- sprintf("%.3f [80%%: %.3f - %.3f]",
                       round(mean(auc_roc), 3), 
                       round(quantile(auc_roc, 0.1), 3), 
                       round(quantile(auc_roc, 0.9), 3))
    prc_msg <- sprintf("%.3f [80%%: %.3f - %.3f]",
                       round(mean(auc_prc), 3), 
                       round(quantile(auc_prc, 0.1), 3), 
                       round(quantile(auc_prc, 0.9), 3))
  }
  
  cat("mcmcRocPrc object\n")
  cat(sprintf("curves: %s; fullsims: %s\n", has_curves, has_sims))
  cat(sprintf("AUC-ROC: %s\n", roc_msg))
  cat(sprintf("AUC-PR:  %s\n", prc_msg))
  
  invisible(x)
}

#' @rdname mcmcRocPrc
#' 
#' @param n plot method: if `fullsims = TRUE`, how many sample curves to draw?
#' @param alpha plot method: alpha value for plotting sampled curves; between 0 and 1
#' 
#' @export
plot.mcmcRocPrc <- function(x, n = 40, alpha = .5, ...) {
  
  stopifnot(
    "Use mcmcRocPrc(..., curves = TRUE) to generate data for plots" = (!is.null(x$roc_dat)),
    "alpha must be between 0 and 1" = (alpha >= 0 & alpha <= 1),
    "n must be > 0" = (n > 0)
  )
  
  obj<- x
  fullsims <- length(obj$roc_dat) > 1
  
  if (!fullsims) {
    
    graphics::par(mfrow = c(1, 2))
    plot(obj$roc_dat[[1]], type = "s", xlab = "FPR", ylab = "TPR")
    graphics::abline(a = 0, b = 1, lty = 3, col = "gray50")
    
    prc_dat <- obj$prc_dat[[1]]
    # use first non-NaN y-value for y[1]
    prc_dat$y[1] <- prc_dat$y[2]
    plot(prc_dat, type = "l", xlab = "TPR", ylab = "Precision",
         ylim = c(0, 1))
    graphics::abline(a = attr(x, "y_pos_rate"), b = 0, lty = 3, col = "gray50")
    
  } else {
    
    graphics::par(mfrow = c(1, 2))
    
    roc_dat <- obj$roc_dat
    
    x <- lapply(roc_dat, `[[`, 1)
    x <- do.call(cbind, x)
    colnames(x) <- paste0("sim", 1:ncol(x))
    
    y <- lapply(roc_dat, `[[`, 2)
    y <- do.call(cbind, y)
    colnames(y) <- paste0("sim", 1:ncol(y))
    
    xavg <- rowMeans(x)
    yavg <- rowMeans(y)
    
    plot(xavg, yavg, type = "n", xlab = "FPR", ylab = "TPR")
    samples <- sample(1:ncol(x), n)
    for (i in samples) {
      graphics::lines(
        x[, i], y[, i], type = "s",
        col = grDevices::rgb(127, 127, 127, alpha = alpha*255, maxColorValue = 255)
      )
    }
    graphics::lines(xavg, yavg, type = "s")
    
    # PRC
    # The elements of prc_dat have different lengths, unlike roc_dat, so we
    # have to do the central curve differently.
    prc_dat <- obj$prc_dat
    
    x <- lapply(prc_dat, `[[`, 1)
    y <- lapply(prc_dat, `[[`, 2)
    
    # Instead of combining the list of curve coordinates from each sample into
    # two x and y matrices, we can first make a point cloud with all curve 
    # points from all samples, and then average the y values at all distinct
    # x coordinates. The x-axis plots recall (TPR), which will only have as 
    # many distinct values as there are positives in the data, so this does 
    # not lose any information about the x coordinates. 
    point_cloud <- data.frame(
      x = unlist(x),
      y = unlist(y)
    )
    point_cloud <- stats::aggregate(point_cloud[, "y", drop = FALSE], 
                                    # factor implicitly encodes distinct values only,
                                    # since they will get the same labels
                                    by = list(x = as.factor(point_cloud$x)), 
                                    FUN = mean)
    point_cloud$x <- as.numeric(as.character(point_cloud$x))
    xavg <- point_cloud$x
    yavg <- point_cloud$y
    
    plot(xavg, yavg, type = "n", xlab = "TPR", ylab = "Precision", ylim = c(0, 1))
    samples <- sample(1:length(prc_dat), n)
    for (i in samples) {
      graphics::lines(
        x[[i]], y[[i]], 
        col = grDevices::rgb(127, 127, 127, alpha = alpha*255, maxColorValue = 255)
      )
    }
    graphics::lines(xavg, yavg)
    
  }
  
  invisible(x)
}

#' @rdname mcmcRocPrc
#' 
#' @param row.names see [base::as.data.frame()] 
#' @param optional see [base::as.data.frame()]
#' @param what which information to extract and convert to a data frame?
#' 
#' @export
as.data.frame.mcmcRocPrc <- function(x, row.names = NULL, optional = FALSE,
                                     what = c("auc", "roc", "prc"), ...) {
  what <- match.arg(what)
  if (what=="auc") {
    # all 4 output types have AUC, so this should work across the board
    return(as.data.frame(x[c("area_under_roc", "area_under_prc")]))
    
  } else if (what %in% c("roc", "prc")) {
    if (what=="roc") element <- "roc_dat" else element <- "prc_dat"
    
    # if curves was FALSE, there will be no curve data...
    if (is.null(x[[element]])) {
      stop("No curve data; use mcmcRocPrc(..., curves = TRUE)")
    }
    
    # Otherwise, there will be either one set of coordinates if mcmcmRegPrc()
    # was called with fullsims = FALSE, or else N_sims curve data sets.
    # If the latter, we can return a long data frame with an identifying 
    # "sim" column to delineate the sim sets. To ensure consistency in output,
    # also add this column when fullsims = FALSE.
    
    # averaged, single coordinate set
    if (length(x[[element]])==1L) {
      return(data.frame(sim = 1L, x[[element]][[1]]))
    }
    
    # full sims
    # add a unique ID to each coordinate set
    outlist <- x[[element]]
    outlist <- Map(cbind, sim = (1:length(outlist)), outlist)
    # combine into long data frame
    outdf <- do.call(rbind, outlist)
    return(outdf)
  } 
  stop("Developer error (I should not be here): please file an issue on GitHub")  # nocov
}




