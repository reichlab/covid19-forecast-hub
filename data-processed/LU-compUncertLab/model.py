#mcandrew

class VAR(object):
    def __init__(self,data,F=28,L=2):
        self.F=F
        self.L=L

        self.T = data.shape[1]
        self.P = data.shape[0]

        self.data=data

    def varmodeldesc(self):
        modelDesc = """
            functions {
                matrix transform(data matrix y,int t, int P){
                     // Build matrix of zeros
                     matrix [P,P*P] A = rep_matrix(0, P, P*P);  // with an intercept this was P*(P+1) dim

                     // Fill matrix with y data
                     for (row in 1:P){
                        for (col in 1:P*P){
                           if ( col >= ( ((row-1)*P)+1)  && col <= row*P){
                             A[row,col] = y[ ((col-1)%P)+1 ,t];
                           } 
                        }
                     }
                   return A;
                }
              vector Z (int N){
                 return rep_vector(0,N);
              }
              matrix Zm (int M, int N){
                 return rep_matrix(0,M,N);
              }
            }
            data {
               int T;
               int P;
               int F;
               int L;
               matrix[P,T] y;
            }
            transformed data {
               // array of matrices that are all zero 
               matrix [P, P*P] A [T]; 
               for (t in 1:T){
                  A[t] = transform(y,t,P);
               }
           }
           parameters {
               simplex [L] theta;
               vector [P] intercept; 
               vector <lower=-1,upper=1> [P*P] b [L];
        
               vector <lower=0> [P] sigma;
               //corr_matrix [P] Omega; 
               cholesky_factor_corr[P] Lcorr; 

           }
           transformed parameters {
                //cov_matrix [P] E;
                //E = quad_form_diag(Omega,sigma);
                //E = diag_pre_multiply(sigma, Lcorr);
           }
           model {
              sigma~cauchy(0,2.5);
              //Omega~lkj_corr(1);
              Lcorr ~ lkj_corr_cholesky(1);

              for (t in (L+1):T){
                 vector [P] mu = intercept;  // reset mu at every time step (important!)
                 for (l in 1:L){
                    mu+= A[t-l]*b[l];
                 }
                 y[:,t]~multi_normal_cholesky( mu, diag_pre_multiply(sigma, Lcorr) );
              }
           }
           generated quantities {
               matrix [P,F+L] ytilde = rep_matrix(0,P,F+L);
               ytilde[:,1:L] = y[:, T-(L-1):T];
               matrix [P,P*P] Atilde;

               corr_matrix [P] Omega; 
               Omega = multiply_lower_tri_self_transpose(Lcorr);

               for (f in 1:F){
                   vector [P] mutilde = intercept; // reset mutilde at every time step (important!)
                 
                   //Ltilde = categorical_rng(theta);
                   for (l in 1:L){
                      Atilde = transform( ytilde,l+(f-1),P);
                      mutilde += Atilde*b[l];
                   }
                   ytilde[:,(f+L)] = multi_normal_cholesky_rng(mutilde,diag_pre_multiply(sigma, Lcorr));
                }
           }
            """
        return modelDesc


    def varmodeldesc_new(self):
        modelDesc = """
            functions {
                matrix transform(data matrix y,int t, int P){
                     // Build matrix of zeros
                     matrix [P,P*P] A = rep_matrix(0, P, P*P);  // with an intercept this was P*(P+1) dim

                     // Fill matrix with y data
                     for (row in 1:P){
                        for (col in 1:P*P){
                           if ( col >= ( ((row-1)*P)+1)  && col <= row*P){
                             A[row,col] = y[ ((col-1)%P)+1 ,t];
                           } 
                        }
                     }
                   return A;
                }
              vector Z (int N){
                 return rep_vector(0,N);
              }
              matrix Zm (int M, int N){
                 return rep_matrix(0,M,N);
              }
            }
            data {
               int T;
               int P;
               int F;
               int L;
               matrix[P,T] y;
            }
            transformed data {
               // array of matrices that are all zero 
               matrix [P, P*P] A [T]; 
               for (t in 1:T){
                  A[t] = transform(y,t,P);
               }
           }
           parameters {
               vector [P] intercept; 
               vector <lower=-1,upper=1> [P*P] b [L];
        
               vector <lower=0> [P] sigma;
               cholesky_factor_corr[P] Lcorr; 

           }
           model {
              sigma~cauchy(0,2.5);
              Lcorr ~ lkj_corr_cholesky(1);

              intercept~normal(0,10);
              for (l in 1:L){
                 b[l]~normal(0,10);
              }

              for (t in (L+1):T){
                 vector [P] mu = intercept;  // reset mu at every time step (important!)
                 for (l in 1:L){
                    mu+= A[t-l]*b[l];
                 }
                 y[:,t]~multi_normal_cholesky( mu, diag_pre_multiply(sigma, Lcorr) );
              }
           }
           generated quantities {
               matrix [P,F+L] ytilde = rep_matrix(0,P,F+L);
               ytilde[:,1:L] = y[:, T-(L-1):T];
               matrix [P,P*P] Atilde;

               corr_matrix [P] Omega; 
               Omega = multiply_lower_tri_self_transpose(Lcorr);

               for (f in 1:F){
                   vector [P] mutilde = intercept; // reset mutilde at every time step (important!)
                 
                   for (l in 1:L){
                      Atilde = transform( ytilde,l+(f-1),P);
                      mutilde += Atilde*b[l];
                   }
                   ytilde[:,(f+L)] = multi_normal_cholesky_rng(mutilde,diag_pre_multiply(sigma, Lcorr));
                }
           }
            """
        return modelDesc
    
    def varmodeldesc_old(self):
        modelDesc = """
            data {
               int T;
               int P;
               int F;
               int L;
               matrix[P,T] y;
            }
            parameters {
              matrix<lower=-1,upper=1>[P,P] B [L] ;
              vector [P] C;
              cov_matrix[P] Epsilon;
            }
            model {
               vector [P] M;
               //fitting
               for(t in (L+1):T){
                  M = C;
                  for (l in 1:L){
                     M += B[l]*y[:,(t-l)];
                  }
                  y[:,(t)]~multi_normal(M,Epsilon);
               }
            }
             generated quantities {
               matrix [P,F+L] ytilde = rep_matrix(0,P,F+L); // constrained to be at or above 0 to model counts
               vector [P] M;
               ytilde[:,1:L] = y[:,(T-(L-1)):T]; 

               //predicting
               for (f in (L+1):(L+F)){
                  M=C;
                  for (l in 1:L){
                     M += B[l]*ytilde[:,(f-l)];
                   }
                   ytilde[:,f] = multi_normal_rng(M,Epsilon);
                }
            }
            """
        return modelDesc
        
    def fit(self):
        import stan
        data = {"y":self.data,"T":self.T,"P":self.P,"F":self.F,"L":self.L}
        model = self.varmodeldesc_new()
        
        posterior = stan.build(model, data=data)
        fit = posterior.sample(num_samples=5*10**3,num_chains=4)

        self.fit = fit
   
    def createUnitedStatesForecast(self):
        from glob import glob

        import numpy as np
        import pandas as pd
        
        predictionFile = sorted(glob("*-allPredictions.csv"))[-1]

        allPredictions = pd.read_csv(predictionFile)

        def addUpCounts(x):
            return pd.Series({"value":x.value.sum()})
        allTtlPredictions = allPredictions.groupby(["forecast_date","target_end_date","sample","target"]).apply(addUpCounts).reset_index()
        allTtlPredictions["location"] = "US"
        
        USquantiles = allTtlPredictions.groupby(["forecast_date","target_end_date","location","target"]).apply(lambda x: self.createQuantiles(x) ).reset_index().drop(columns="level_4")
        USquantiles["type"] = "quantile"
        return USquantiles
 

if __name__ == "__main__":
    pass

