% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/pcadaptClass.R
\name{create.pcadapt}
\alias{create.pcadapt}
\title{pcadapt objects}
\usage{
create.pcadapt(input, K, method, min.maf, ploidy, type)
}
\arguments{
\item{input}{a genotype matrix or a character string specifying the name of the file to be processed with \code{pcadapt}.}

\item{K}{an integer specifying the number of principal components to retain.}

\item{method}{a character string specifying the method to be used to compute
the p-values. Three statistics are currently available, \code{"mahalanobis"},
\code{"communality"}, and \code{"componentwise"}.}

\item{min.maf}{a value between \code{0} and \code{0.45} specifying the threshold
of minor allele frequencies above which p-values are computed.}

\item{ploidy}{an integer specifying the ploidy of the individuals.}

\item{type}{an integer specifying the input type.}
}
\value{
The returned value is a list containing all the numerical quantities needed to create an object of class \code{pcadapt}.
}
\description{
\code{create.pcadapt} computes the numerical quantities needed to compute the test
statistics, and stores them in an object of class \code{pcadapt}.
}
