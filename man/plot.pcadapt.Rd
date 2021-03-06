% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/plotUtils.R
\name{plot.pcadapt}
\alias{plot.pcadapt}
\title{pcadapt visualization tool}
\usage{
\method{plot}{pcadapt}(x, ..., option = "manhattan", K = NULL, i = 1,
  j = 2, pop, gg.col, snp.info = NULL, chr.info = NULL, chr = 1,
  threshold = NULL, by.step = 10, hline = 3, plt.pkg = "ggplot")
}
\arguments{
\item{x}{an object of class "pcadapt" generated with \code{pcadapt}.}

\item{...}{\dots}

\item{option}{a character string specifying the figures to be displayed. If 
\code{NULL} (the default), all three plots are printed.}

\item{K}{an integer specifying the principal component of interest. \code{K} 
has to be specified only when using the \code{loadings} option.}

\item{i}{an integer indicating onto which principal component the individuals
are projected when the "scores" option is chosen.
Default value is set to \code{1}.}

\item{j}{an integer indicating onto which principal component the individuals 
are projected when the "scores" option is chosen.
Default value is set to \code{2}.}

\item{pop}{a list of integers or strings specifying which subpopulation the 
individuals belong to.}

\item{gg.col}{a list of colors to be used in the score plot.}

\item{snp.info}{a list containing the names of all genetic markers present in
the input.}

\item{chr.info}{a list containing the chromosome information for each marker.}

\item{chr}{an integer specifying the chromosome to display.}

\item{threshold}{for the \code{"qqplot"} option, it displays an additional 
bar which shows the \code{threshold} percent of SNPs with smallest p-values
and separates them from SNPs with higher p-values.}

\item{by.step}{an integer.}

\item{hline}{a numeric value specifying the number of standard deviations 
above which the z-scores are considered extreme.}

\item{plt.pkg}{a character string specifying the package to be used to 
display the graphical outputs. Use \code{"plotly"} for interactive plots, or 
\code{"ggplot"} for static plots.}
}
\description{
\code{plot.pcadapt} is a method designed for objects of class \code{pcadapt}.
It provides a plotting utile for quick visualization of \code{pcadapt} 
objects. Different options are currently available : \code{"screeplot"}, 
\code{"scores"}, \code{"stat.distribution"}, \code{"manhattan"} and 
\code{"qqplot"}. \code{"screeplot"} shows the decay of the genotype matrix 
singular values and provides a figure to help with the choice of \code{K}.
\code{"scores"} plots the projection of the individuals onto the first two 
principal components. \code{"stat.distribution"} displays the histogram of 
the selected test statistics, as well as the estimated distribution for the 
neutral SNPs. \code{"manhattan"} draws the Manhattan plot of the p-values 
associated with the statistic of interest. \code{"qqplot"} draws a Q-Q plot 
of the p-values associated with the statistic of interest.
}
\examples{
## see ?pcadapt for examples

}
