% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/manhattan-plot.R
\name{manhattan.plotting}
\alias{manhattan.plotting}
\title{Manhattan Plot}
\usage{
manhattan.plotting(x, K, snp.info, chr.info, plt.pkg)
}
\arguments{
\item{x}{an object of class "pcadapt" generated with \code{pcadapt} 
containing the p-values of interest.}

\item{K}{an integer specifying the number of components to take into account 
in the scree plot.}

\item{snp.info}{a list containing the names of all genetic markers present in
the input.}

\item{chr.info}{a list containing the chromosome information for each marker.}

\item{plt.pkg}{a character string specifying the package to be used to 
display the graphical outputs. Use \code{"plotly"} for interactive plots, or 
\code{"ggplot"} for static plots.}
}
\description{
\code{manhattan.plotting} displays a Manhattan plot which represents the p-values 
for each SNP for a particular test statistic.
}
\examples{
## see ?pcadapt for examples

}
\keyword{internal}
