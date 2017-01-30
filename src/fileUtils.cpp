#include <RcppArmadillo.h>

// [[Rcpp::depends("RcppArmadillo")]]

using namespace Rcpp;

#define NA 9

//' File size
//' 
//' \code{get_size_file} returns the number of genetic markers and the number of individuals present in the data.
//' 
//' @param path a character string specifying the name of the file to be processed with \code{pcadapt}.
//' 
//' @return The returned value is a numeric vector of length 2.
//' 
//' @export
//' 
// [[Rcpp::export]]
NumericVector get_size_file(std::string path){
  NumericVector file_size(2);
  FILE *input;
  int nbbn = 0;
  int nbsp = 0;
  if ((input = fopen(path.c_str(), "r")) == NULL){
    Rprintf("Error, invalid input file.\n");
  }
  int currentchar;
  int prevchar;
  currentchar = fgetc(input);
  while(currentchar != EOF){
    if (currentchar == 10){
      nbbn++;
      if (prevchar != 32 && prevchar != '\t'){
        nbsp++;
      }
    }
    if ((currentchar == 32 || prevchar == '\t') && (prevchar != 32 || prevchar != '\t')){
      nbsp++;
    }
    prevchar = currentchar;
    currentchar = fgetc(input);
  }
  fclose(input);
  file_size[0] = nbbn;
  file_size[1] = nbsp / nbbn;
  return file_size;
}

void add_to_cov(arma::mat &cov, arma::mat &genoblock){
  double tmp = 0;
  for (int i = 0; i < cov.n_rows; i++){
    for (int j = i; j < cov.n_rows; j++){
      if (i != j){
        tmp = arma::dot(genoblock.col(i), genoblock.col(j));
        cov(i, j) += tmp;
        cov(j, i) += tmp;
      } else {
        tmp = arma::dot(genoblock.col(i), genoblock.col(j));
        cov(i, j) += tmp;
      }
    }
  }
}

int get_rows_arma(arma::mat &xs, FILE *input, int nIND, int ploidy, double min_maf, int blocksize, double *maf_i, arma::vec &missing_i){
  double mean = 0;
  double var = 0;
  double af = 0;
  int na = 0;
  float value;
  
  for (int i = 0; i < blocksize; i++){
    var = 0;
    mean = 0;
    na = 0;
    for (int j = 0; j < nIND; j++){
      if (fscanf(input, "%g", &value) != EOF){
        xs(i, j) = (double) value;
        if (value != NA){
          mean += (double) value;
        } else {
          missing_i[j] = 1.0;
          na += 1;
        }
      }
    }
    
    if (na >= nIND){
      Rcpp::stop("Detected SNP with missing values only, please remove it before proceeding."); 
    } else {
      mean /= (nIND - na);
      if (ploidy == 2){
        af = mean / 2.0;
        var = 2.0 * af * (1 - af);
      } else {
        af = mean;
        var = af * (1 - af);
      }
      if (af > 0.5){
        double tmp_af = af;
        af = 1.0 - tmp_af;
      }
    }
    
    if (af >= min_maf){
      for (int j = 0; j < nIND; j++){
        if (xs(i, j) != NA){
          if (var > 0){
            xs(i, j) -= mean;
            xs(i, j) /= sqrt(var);
          }
        } else {
          xs(i, j) = 0.0; 
        }
      }
    } else {
      for (int j = 0; j < nIND; j++){
        xs(i, j) = 0;  
      }
    }
  }
  
  if (blocksize == 1){
    *maf_i = af;
  } else {
    *maf_i = 0;
  }
  return(na);
}

//' Covariance for genotype data stored in an external file
//' 
//' \code{cmpt_cov_arma} computes the covariance matrix of a genotype matrix when the genotype matrix is stored in an external file.
//' 
//' @param path a character string specifying the name of the file to be processed with \code{pcadapt}.
//' @param min_maf a value between \code{0} and \code{0.45} specifying the threshold of minor allele frequencies above which p-values are computed.
//' @param ploidy an integer specifying the ploidy of the individuals.
//' 
//' @return The returned value is a Rcpp::List containing the covariance matrix, the number of individuals and the number of genetic markers present in the data.
//' 
//' @export
//' 
// [[Rcpp::export]]
Rcpp::List cmpt_cov_file(std::string path, double min_maf, int ploidy){
  FILE *input;
  input = fopen(path.c_str(), "r");
  Rprintf("Reading file %s...\n", path.c_str());
  NumericVector file_size = get_size_file(path);
  int nSNP = file_size[0];
  int nIND = file_size[1];
  Rprintf("Number of SNPs: %i\n", nSNP);
  Rprintf("Number of individuals: %i\n", nIND);
  
  int unused_na = 0;
  double unused_maf = 0;
  int blocksize = 120;
  int b;
  arma::mat xcov(nIND, nIND, arma::fill::zeros);
  arma::vec unused_missing(nIND, arma::fill::zeros);

  for (int i = 0; i < nSNP; i += blocksize){
    if (nSNP - i < blocksize){
      b = nSNP - i;
    } else {
      b = blocksize;
    }
    arma::mat geno(b, nIND, arma::fill::zeros);
    unused_na = get_rows_arma(geno, input, nIND, ploidy, min_maf, b, &unused_maf, unused_missing);
    add_to_cov(xcov, geno);
  }
  fclose(input);
  return Rcpp::List::create(Rcpp::Named("xcov") = xcov,
                            Rcpp::Named("nIND") = nIND,
                            Rcpp::Named("nSNP") = nSNP);
}

//' Linear regression
//' 
//' \code{lrfunc_arma} performs the multiple linear regression of the genotype matrix on the scores when the genotype matrix is stored in an external file.
//' 
//' @param filename a character string specifying the name of the file to be processed with \code{pcadapt}.
//' @param scores a matrix containing the scores.
//' @param nIND an integer specifying the number of individuals present in the data.
//' @param nSNP an integer specifying the number of genetic markers present in the data.
//' @param K an integer specifying the number of principal components to retain.
//' @param ploidy an integer specifying the ploidy of the individuals.
//' @param min_maf a value between \code{0} and \code{0.45} specifying the threshold of minor allele frequencies above which p-values are computed.
//' 
//' @return The returned value is a Rcpp::List containing the multiple linear regression z-scores, the minor allele frequencies and the number of missing values for each genetic marker.
//' 
//' @export
//' 
// [[Rcpp::export]]
Rcpp::List lrfunc_file(std::string filename, arma::mat &scores, int nIND, int nSNP, int K, int ploidy, double min_maf){
  FILE *input;
  input = fopen(filename.c_str(), "r");
  double maf_i;
  double residual;
  arma::mat Y(1, nIND, arma::fill::zeros);
  arma::mat GenoRowScale(1, nIND, arma::fill::zeros);
  arma::vec sum_scores_sq(K, arma::fill::zeros);
  arma::mat Z(nSNP, K, arma::fill::zeros);
  
  NumericVector missing(nSNP);
  NumericVector maf(nSNP);
  arma::vec check_na(nIND, arma::fill::zeros);
  
  for (int i = 0; i < nSNP; i++){
    missing[i] = get_rows_arma(GenoRowScale, input, nIND, ploidy, min_maf, 1, &maf_i, check_na);
    maf[i] = maf_i;
    Z.row(i) = GenoRowScale * scores;
    Y = Z.row(i) * scores.t();
    residual = dot(GenoRowScale - Y, (GenoRowScale - Y).t());
    Y.zeros();
    if ((nIND - K - missing[i]) <= 0){
      residual = 0.0;
    } else {
      residual /= nIND - K - missing[i];
    }
    
    /* Correcting for missing values */
    sum_scores_sq.zeros();
    for (int k = 0; k < K; k++){
      for (int j = 0; j < nIND; j++){
        if (check_na[j] != 1.0){
          sum_scores_sq[k] +=  (double) scores(j ,k) * scores(j, k);
        }
      }
      if (residual == 0.0){
        Z(i, k) = 0.0;
      } else {
        Z(i ,k) /= sqrt(residual);
      }
      if (sum_scores_sq[k] > 0){
        Z(i ,k) /= sqrt(sum_scores_sq[k]);
      }
    }
    check_na.zeros();
  }
  fclose(input);
  
  return Rcpp::List::create(Rcpp::Named("zscores") = Z,
                            Rcpp::Named("maf") = maf,
                            Rcpp::Named("missing") = missing);
}

//' Sample genotype matrix from pooled samples
//' 
//' \code{sample_geno_file} sample genotypes based on observed allelic frequencies.
//' 
//' @param input a character string specifying the name of the file containing the allele frequencies.
//' @param output a character string specifying the name of the output file.
//' @param ploidy an integer specifying the ploidy of the sampled individuals.
//' @param sample_size a vector specifying the number of individuals to be sampled for each pool.
//' 
//' @return The returned value is a numeric vector of length 2.
//' 
//' @export
//' 
// [[Rcpp::export]]
NumericVector sample_geno_file(std::string input, std::string output, double ploidy, IntegerVector sample_size){
  FILE *file_in;
  file_in = fopen(input.c_str(), "r");
  FILE *file_out;
  file_out = fopen(output.c_str(), "w");
  NumericVector file_size = get_size_file(input);
  int nSNP = file_size[1];
  int nPOOL = file_size[0];
  IntegerVector na(nSNP);
  NumericVector v = no_init(nSNP);
  NumericVector prob = no_init(nSNP);
  float value;
  
  for (int k = 0; k < nPOOL; k++){
    for (int fill = 0; fill < nSNP; fill++){
      if (fscanf(file_in, "%g", &value) != EOF){
        if ((value != 9.0) || !NumericVector::is_na(value)){
          prob[fill] = (double) value;
          na[fill] = 0;
        } else {
          prob[fill] = 0.0;
          na[fill] = 1;
        }
      }
    }
    for (int j = 0; j < sample_size[k]; j++){
      std::transform(prob.begin(), prob.end(), v.begin(), [=](double p){return R::rbinom(ploidy, p);}); 
      for (int i = 0; i < nSNP; i++){
        int tmp = v[i];
        if (i < (nSNP - 1)){
          if (na[i] != 1){
            fprintf(file_out, "%d ", tmp);
          } else {
            fprintf(file_out, "%d ", 9);
          }
        } else if (i == (nSNP - 1)){
          if (na[i] != 1){
            fprintf(file_out, "%d", tmp);
          } else {
            fprintf(file_out, "%d", 9);
          }  
        }
      }
      fprintf(file_out, "\n");
    }
  }
  fclose(file_in);
  fclose(file_out);
  return(file_size);
}
