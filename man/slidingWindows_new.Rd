% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/RcppExports.R
\name{slidingWindows_new}
\alias{slidingWindows_new}
\title{Introgression statistics}
\usage{
slidingWindows_new(sgeno, d, v, pop, popUnique, admixed, window_size, map,
  with_map)
}
\arguments{
\item{sgeno}{a scaled genotype matrix.}

\item{d}{a numeric vector.}

\item{v}{a numeric matrix.}

\item{pop}{a string vector.}

\item{popUnique}{a string vector.}

\item{admixed}{a character vector.}

\item{window_size}{a numeric value.}

\item{map}{a numeric vector.}

\item{with_map}{an integer.}
}
\value{
The returned value is a numeric matrix.
}
\description{
\code{slidingWindows_new}
}
