#include <RcppArmadillo.h>

// [[Rcpp::depends("RcppArmadillo")]]

using namespace Rcpp;

arma::mat cart2bary_cpp(arma::mat &X, arma::mat &P);