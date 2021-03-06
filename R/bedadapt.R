################################################################################

#' Class bedadapt
#'
#' @exportClass bedadapt
#'
bedadapt_RC <- methods::setRefClass(
  
  "bedadapt",
  
  fields = list(
    extptr = "externalptr",
    nIND = "integer",
    nSNP = "integer",
    path = "character",
    
    # Same idea as in package phaverty/bigmemoryExtras
    address = function() {
      if (identical(.self$extptr, methods::new("externalptr"))) { # nil
        .self$extptr <- bedadaptXPtr(.self$path,
                                     .self$nIND,
                                     .self$nSNP)
      }
      .self$extptr
    }
  ),
  
  methods = list(
    initialize = function(path,
                          nIND = NULL, 
                          nSNP = NULL) {
      
      xpath <- path.expand(path)
      if (!file.exists(xpath)) {
        # Try to add extension (common in PLINK)
        xpath <- paste0(xpath, ".bed")
        if (!file.exists(xpath)) {
          stop("File not found.")
        }
      }
      
      dir <- substr(xpath, 1L, nchar(xpath) - 4L)
      if (is.null(nIND)) {
        # Check if FAM file exists
        famPath <- paste0(dir, ".fam")
        if (!file.exists(famPath)) {
          stop("FAM file of same name not found. Provide number of samples (n).")
        } else {
          message("Extracting number of samples and rownames from FAM file...")
          if (requireNamespace("data.table", quietly = TRUE)) {
            fam <- data.table::fread(famPath, select = c(1L, 2L), data.table = FALSE, showProgress = FALSE)
            # Determine n
            xIND <- nrow(fam)
            # Determine rownames
            rownames <- paste0(fam[, 1L], "_", fam[, 2L])
          } else {
            fam <- readLines(famPath)
            # Determine n
            xIND <- length(fam)
            # Determine rownames
            rownames <- sapply(strsplit(fam, delims), function(line) {
              # Concatenate family ID and subject ID
              return(paste0(line[1L], "_", line[2L]))
            })
          }
        }
      } else {
        xIND <- as.integer(nIND)
        rownames <- NULL
      }
      if (is.null(nSNP)) {
        # Check if BIM file exists
        bimPath <- paste0(dir, ".bim")
        if (!file.exists(bimPath)) {
          stop("BIM file of same name not found. Provide number of variants (p).")
        } else {
          message("Extracting number of variants and colnames from BIM file...")
          if (requireNamespace("data.table", quietly = TRUE)) {
            bim <- data.table::fread(bimPath, select = c(2L, 5L), data.table = FALSE, showProgress = FALSE)
            # Determine p
            xSNP <- nrow(bim)
            # Determine colnames
            colnames <- paste0(bim[, 1L], "_", bim[, 2L])
          } else {
            bim <- readLines(bimPath)
            # Determine p
            xSNP <- length(bim)
            # Determine colnames
            colnames <- sapply(strsplit(bim, delims), function(line) {
              # Concatenate SNP name and minor allele (like --recodeA)
              return(paste0(line[2L], "_", line[5L]))
            })
          }
        }
      } else {
        xSNP <- as.integer(nSNP)
        colnames <- NULL
      }
      
      .self$path <- normalizePath(path)
      .self$nIND <- as.integer(xIND)
      .self$nSNP <- as.integer(xSNP)
      .self$address  # connect once
      
    }
  )
)

#' Wrapper constructor for class `bedadapt`.
#'
#' @param path path to the .bed file.
#' @param nIND number of individuals.
#' @param nSNP number of SNPs.
#'
#' @rdname bedadapt-class
#' 
#' @importFrom methods new
#'
#' @export
#'
bedadapt <- function(path = tempfile(),
                     nIND = NULL, 
                     nSNP = NULL) {
  
  do.call(methods::new, args = c(Class = "bedadapt", as.list(environment())))
}

#' SVD for genotype matrices stored in .bed files
#'
#' \code{BED_rsvd}
#'
#' @param X an object of class bedadapt.
#' @param k an integer specifying the number of principal components to retain.
#' 
#' @export
#' 
# single core implementation
BED_rsvd <- function(X, k) {
  nIND <- X$nIND
  nSNP <- X$nSNP
  m <- cmpt_minor_af_BED(X$address)
  s <- pmax(1e-6, sqrt(2 * m * (1 - m)))
  
  A <- function(x, args) {
    # Input vector of length p
    x <- x / s
    return(prodMatVec_export(X$address, x) - 2 * sum(x * m))
  }
  Atrans <- function(x, args) {
    # Input vector of length n
    return((prodtMatVec_export(X$address, x) - 2 * sum(x) * m) / s)
  }
  res <- RSpectra::svds(A, k, nu = k, nv = 0, Atrans = Atrans,
                        opts = list(tol = 1e-4, maxitr = 100),
                        dim = c(nIND, nSNP))
  return(res)
}

#' SVD for genotype matrices stored in .bed files with missing values
#'
#' \code{BED_rsvd_missing}
#'
#' @param X an object of class bedadapt.
#' @param k an integer specifying the number of principal components to retain.
#' @param miss.ind a vector indicating the number of missing values for each 
#' individual.
#' @param miss.snp a vector indicating the number of missing values for each 
#' SNP.
#' 
#' @export
#' 
# single core implementation
BED_rsvd_missing <- function(X, k, miss.ind, miss.snp) {
  nIND <- X$nIND
  nSNP <- X$nSNP
  m <- cmpt_minor_af_BED(X$address)
  s <- pmax(1e-6, sqrt(2 * m * (1 - m)))
  
  A <- function(x, args) {
    # Input vector of length p
    x <- x / s
    return((prodMatVec_export(X$address, x) - 2 * sum(x * m)) * miss.ind)
  }
  Atrans <- function(x, args) {
    # Input vector of length n
    return(((prodtMatVec_export(X$address, x) - 2 * sum(x) * m) / s) * miss.snp)
  }
  res <- RSpectra::svds(A, k, nu = k, nv = 0, Atrans = Atrans,
                        opts = list(tol = 1e-4, maxitr = 100),
                        dim = c(nIND, nSNP))
  return(res)
}
