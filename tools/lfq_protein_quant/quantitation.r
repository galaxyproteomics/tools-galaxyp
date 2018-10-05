#################################
library(tidyverse)
library(furrr)
library(lme4)
library(MSnbase)
library(MSqRob)

##Import and preprocess data
############################
MSnSet2df = function(msnset){
  ## Converts Msnset to a tidy dataframe
  ## Always creates feature and vector column so these shouldn't be defined by user.
  ## convenient for downstream analysis steps.
  if(any(c("sample", "feature", "expression") %in% c(colnames(fData(msnset)),colnames(pData(msnset))))){
    stop("Column names in the \"fData\" or \"pData\" slot of the \"msnset\" object cannot be named
         \"sample\", \"feature\" or \"expression\". Please rename these columns before running the analysis.")
  }

  dt <- as.data.frame(Biobase::exprs(msnset)) %>% mutate(feature = rownames(.)) %>%
    gather(sample, expression, - feature, na.rm=TRUE)
  dt <- fData(msnset) %>% mutate(feature = rownames(.)) %>% left_join(dt,. , by = 'feature')
  dt <- pData(msnset) %>% mutate(sample = rownames(.)) %>% left_join(dt,. , by = 'sample')
  as_data_frame(dt)
}

## robust summarisation
do_robust_summaristion = function(msnset, group_var = Proteins, keep_fData_cols = NULL, nIter = 20,
                                  sum_fun = summarizeRobust){
  ## TODO use funture_map instead of mutate to speed up
  ## Uses assumption that featureNames and sampleNames exist in every msnset
  ## Can also be used for multiple rounds of normalization, e.g. first from PSMs to peptides, then from peptides to proteins
  system.time({## Time how long it takes
    group_var <- enquo(group_var) ;#group_var = quo(Proteins)
  ## Make tidy dataframe from Msnset
    df <- MSnSet2df(msnset)
    ## Do summarisision according defined groups
    dt <- filter(df, !is.na(expression)) %>% group_by(!!group_var) %>%
      mutate(expression = sum_fun(expression, feature, sample, nIter = nIter)) %>%
      dplyr::select(!!group_var, sample, expression) %>%
      ## collapse to one value per group
      distinct
    ## Construct an Msnset object from dataframe
    dt_exprs <- spread(dt, sample, expression) %>% ungroup
    exprs_data <- dplyr::select(dt_exprs, - !!group_var) %>% as.matrix
    rownames(exprs_data) <- as.character(pull(dt_exprs, !!group_var))

    fd <- dplyr::select(dt_exprs,!!group_var)

    ##Select the group variable and all variables you want to keep
    if (!is.null(keep_fData_cols)){
      fd_ext <- dplyr::select(df, !!group_var, one_of(keep_fData_cols)) %>% distinct
      if(nrow(fd)!=nrow(fd_ext)){
        stop("Values in the \"group_var\" column can only correspond to a single value in the \"keep_fData_cols\" column.")
      }
      fd <- left_join(fd,fd_ext)
    }

    fd <- as.data.frame(fd)
    rownames(fd) <- as.character(pull(fd, !!group_var))
    out <- MSnSet(exprs_data, fData = AnnotatedDataFrame(fd) , pData = pData(msnset)[colnames(exprs_data),,drop = FALSE])
  }) %>% print
  out
}

summarizeRobust <- function(expression, feature, sample, nIter=100,...) {
  ## Assumes that intensities mx are already log-transformed
  ## characters are faster to construct and work with then factors
  feature <- as.character(feature)
  ##If there is only one 1 peptide for all samples return expression of that peptide
  if (length(unique(feature)) == 1L) return(expression)
  sample <- as.character(sample)
  ## modelmatrix breaks on factors with 1 level so make vector of ones (will be intercept)
  if (length(unique(sample)) == 1L) sample = rep(1,length(sample))

  ## sum contrast on peptide level so sample effect will be mean over all peptides instead of reference level
  X = model.matrix(~ -1 + sample + feature,contrasts.arg = list(feature = 'contr.sum'))
  ## MasS::rlm breaks on singulare values.
  ## check with base lm if singular values are present.
  ## if so, these coefficients will be zero, remove this collumn from model matrix
  ## rinse and repeat on reduced modelmatrx till no singular values are present
  repeat {
    fit = .lm.fit(X,expression)
    id = fit$coefficients != 0
    X = X[ , id, drop =FALSE]
    if (!any(!id)) break
  }
  ## Last step is always rlm
  fit = MASS::rlm(X,expression,maxit = nIter,...)
  ## Only return the estimated effects effects as summarised values
  sampleid = seq_along(unique(sample))
  return(X[,sampleid,drop = FALSE] %*% fit$coefficients[sampleid])
}








## mixed models
###############
setGeneric (
  name= "getBetaB",
  def=function(model,...){standardGeneric("getBetaB")}
)

.getBetaBMermod = function(model) {
  betaB <- c(as.vector(getME(model,"beta")),as.vector(getME(model,"b")))
  names(betaB) <- c(colnames(getME(model,"X")),rownames(getME(model,"Zt")))
  betaB
}
setMethod("getBetaB", "lmerMod", .getBetaBMermod)

.getBetaBGlm = function(model) 
  model$coefficients

setGeneric (
  name= "getVcovBetaBUnscaled",
  def=function(model,...){standardGeneric("getVcovBetaBUnscaled")}
)

setMethod("getBetaB", "glm", .getBetaBGlm)

.getVcovBetaBUnscaledMermod = function(model){
  ## TODO speed up (see code GAM4)
  p <- ncol(getME(model,"X"))
  q <- nrow(getME(model,"Zt"))
  Ct <- rbind2(t(getME(model,"X")),getME(model,"Zt"))
  Ginv <- solve(tcrossprod(getME(model,"Lambda"))+Diagonal(q,1e-18))
  vcovInv <- tcrossprod(Ct)
  vcovInv[((p+1):(q+p)),((p+1):(q+p))] <- vcovInv[((p+1):(q+p)),((p+1):(q+p))]+Ginv

 solve(vcovInv)
}

setMethod("getVcovBetaBUnscaled", "lmerMod", .getVcovBetaBUnscaledMermod)

.getVcovBetaBUnscaledGlm = function(model)
  ## cov.scaled is scaled with the dispersion, "cov.scaled" is without the dispersion!
  ## MSqRob::getSigma is needed because regular "sigma" function can return "NaN" when sigma is very small!
  ## This might cause contrasts that can be estimated using summary() to be NA with our approach!
  summary(model)$cov.scaled/MSqRob::getSigma(model)^2

setMethod("getVcovBetaBUnscaled", "glm", .getVcovBetaBUnscaledGlm)

## Estimate pvalues contrasts
contrast_helper = function(formula, msnset, contrast = NULL){
  ## Gives back the coefficients you can use to make contrasts with given the formula and dataset
  ## If a factor variable is specified (that is present in the formula) all the possible contrasts
  ## within this variable are returned
  contrast <- enquo(contrast) ;#contrast = quo(condition)
  df <- MSnSet2df(msnset)
  all_vars <- formula %>% terms %>% delete.response %>% all.vars
  names(all_vars) <- all_vars
  df[,all_vars] <- map2_dfr(all_vars,df[,all_vars],paste0)
  coefficients <- c("(Intercept)", df %>% dplyr::select(all_vars) %>% unlist %>% unique %>% as.character)
  if (contrast != ~NULL) {
    c <- pull(df,!! contrast) %>% unique %>% sort %>% as.factor
    comp <- combn(c,2,simplify = FALSE)
    ## condIds = map(comp,~which( coefficients %in% .x))
    ## L = rep(0,length(coefficients))
    ## L = sapply(condIds,function(x){L[x]=c(-1,1);L})
    ## rownames(L) = coefficients
    ## colnames(L) = map_chr(comp, ~paste(.x,collapse = '-'))
    condIds <- map(comp, ~which(coefficients %in% .x))
    L <- rep(0,nlevels(c))
    L <- sapply(comp,function(x){L[x]=c(-1,1);L})
    rownames(L) <- levels(c)
    colnames(L) <- map_chr(comp, ~paste(rev(.x),collapse = '-'))
    L
  } else coefficients
}

setGeneric (
  name= "getXLevels",
  def=function(model,...){standardGeneric("getXLevels")}
)

.getXLevelsGlm = function(model)
  map2(names(model$xlevels), model$xlevels, paste0) %>% unlist

setMethod("getXLevels", "glm", .getXLevelsGlm)

.getXLevelsMermod = function(model)
  getME(model,"flist") %>% map(levels) %>% unlist %>% unname

setMethod("getXLevels", "lmerMod", .getXLevelsMermod)

contEst <- function(model, contrasts, var, df, lfc = 0){
  #TODO only contrast of random effect possible and not between fixed regression terms
  betaB <- getBetaB(model)
  vcov <- getVcovBetaBUnscaled(model)
  coefficients <- names(betaB)
  id <- coefficients %in% rownames(contrasts)

  coefficients <- coefficients[id]
  vcov <- vcov[id,id]
  betaB <- betaB[id]

  xlevels <- getXLevels(model)
  id <- !apply(contrasts,2,function(x){any(x[!(rownames(contrasts) %in% xlevels)] !=0)})
  contrasts <- contrasts[coefficients, id, drop = FALSE]
  ## If no contrasts could be found, terminate
  if (is.null(colnames(contrasts))) return(new_tibble(list()))

  se <- sqrt(diag(t(contrasts)%*%vcov%*%contrasts)*var)
  logFC <- (t(contrasts)%*%betaB)[,1]
  
  ### Addition to allow testing against another log FC (lfc)
  ### See https://www.ncbi.nlm.nih.gov/pmc/articles/PMC2654802/
  
  lfc <- abs(lfc)
  aest <- abs(logFC)
  
  Tval <- setNames(rep(0, length(logFC)),names(se))
  tstat.right <- (aest - lfc)/se
  tstat.left <- (aest + lfc)/se
  pval <- pt(tstat.right, df = df, lower.tail = FALSE) +
    pt(tstat.left, df = df, lower.tail = FALSE)
  tstat.right <- pmax(tstat.right, 0)
  fc.up <- (logFC >= lfc)
  fc.up[is.na(fc.up)] <- FALSE
  fc.down <- (logFC < -lfc)
  fc.down[is.na(fc.down)] <- FALSE
  Tval[fc.up] <- tstat.right[fc.up]
  Tval[fc.down] <- -tstat.right[fc.down]
  Tval[is.na(logFC)] <- NA
  
  new_tibble(list(contrast = colnames(contrasts),
                  logFC = logFC,
                  se = se,
                  t = Tval,
                  df = rep(df, length(se)),
                  pvalue = pval))
}

do_lmerfit = function(df, form, nIter = 10, tol = 1e-6, control = lmerControl(calc.derivs = FALSE)){
  fit <- lmer(form, data = df, control = control)
  ##Initialize SSE
  res <- resid(fit)
  ## sseOld=sum(res^2)
  sseOld <- fit@devcomp$cmp['pwrss']
  while (nIter > 0){
    nIter = nIter-1
    fit@frame$`(weights)` <- MASS::psi.huber(res/(mad(res)))
    fit <- refit(fit)
    res <- resid(fit)
    ## sse=sum(res^2)
    sse <- fit@devcomp$cmp['pwrss']
    if(abs(sseOld-sse)/sseOld <= tol) break
    sseOld <- sse
  }
  return(fit)
}

calculate_df = function(df, model, vars){
  ## Get all the variables in the formula that are not defined in vars
  form <- attributes(model@frame)$formula
  vars_formula <- all.vars(form)
  vars_drop <- vars_formula[!vars_formula %in% vars]
  ## Sum of number of columns -1 of Zt mtrix of each random effect that does not involve a variable in vars_drop
  mq <- getME(model,'q_i')
  id <- !map_lgl(names(mq),~{any(stringr::str_detect(.x,vars_drop))})
  p <- sum(mq[id]) - sum(id)
  ## Sum of fixed effect parameters that do not involve a variable in vars_drop
  mx <- getME(model,'X')
  id <- !map_lgl(colnames(mx),~{any(stringr::str_detect(.x,vars_drop))})
  p <- p + sum(id)

  ## n is number of sample because 1 protein defined per sample
  n <- n_distinct(df$sample)
  n-p
}

do_mm = function(formulas, msnset, group_vars = feature,type_df = 'traceHat'
                  , contrasts = NULL, lfc = 0, p.adjust.method = "BH", max_iter = 20L
                  , squeeze_variance = TRUE
               , control = lmerControl(calc.derivs = FALSE)
                 ## choose parallel = plan(sequential) if you don't want parallelisation
               ## , parallel_plan = plan(cluster, workers = makeClusterPSOCK(availableCores()))
               , parallel = TRUE, cores = availableCores()
                 ){
  if(!(type_df %in% c("conservative", "traceHat")))
    stop("Invalid input `type_df`.")
                   
  system.time({## can take a while
    if (parallel){
      cl <- makeClusterPSOCK(cores)
      plan(cluster, workers = cl)   
    } else {
    plan(sequential)}

    ## future::plan(parallel_plan,gc = TRUE)
    formulas <-  map(c(formulas), ~update(.,expression ~ . ))
    group_vars <- enquo(group_vars) # group_var = quo(protein)
    df <- MSnSet2df(msnset)

    ## Glm adds variable name to levels in catogorical (eg for contrast) 
    ## lme4 doesnt do this for random effect, so add beforehand
    ## Ludger needs this for Hurdle 
    df = formulas %>% map(lme4:::findbars) %>% unlist %>% map_chr(all.vars) %>% unique %>%
      purrr::reduce(~{mutate_at(.x,.y,funs(paste0(.y,.)))}, .init=df)

    cat("Fitting mixed models\n")
    ## select only columns needed for fitting
    df_prot <- df %>%
      group_by_at(vars(!!group_vars)) %>% nest %>%
      mutate(model = furrr::future_map(data,~{
        for (form in formulas){
          fit = try(do_lmerfit(.x, form, nIter = max_iter,control = control))
          if (class(fit) == "lmerMod") return(fit)
        }
        fit
      }))

    ## Return also failed ones afterward
    df_prot_failed <- filter(df_prot, map_lgl(model,~{class(.x) != "lmerMod"}))
    df_prot <- filter(df_prot, map_lgl(model, ~{class(.x)=="lmerMod"}))

    if(nrow(df_prot) == 0) {print("No models could be fitted"); return(df_prot_failed)}

    df_prot <-
      mutate(df_prot
           , formula = map(model,~{attributes(.@frame)$formula})
             ## get trace hat df for squeezeVar
           , df = map_dbl(model, ~getDf(.x))
           , sigma = map_dbl(model,~{MSqRob::getSigma(.x)})) %>%
      ## Squeeze variance
      bind_cols(as_data_frame(MSqRob::squeezeVarRob(.$sigma^2, .$df, robust = TRUE))) %>%
      ## mutate(var_protein = ifelse(squeeze_variance,var.post,sigma^2),
      mutate(var_protein = if (squeeze_variance) var.post else sigma^2,
             df_post = df + df.prior
           , df_protein =
               if (type_df == "conservative")
                 ## Calculate df on protein level, assumption is that there is only one protein value/run,
                 map2_dbl(data, model,~calculate_df(.x,.y, vars = colnames(pData(msnset))))
               else if (type_df == "traceHat")
                 ## Alternative: MSqRob implementation with trace(Hat):
                 if(squeeze_variance) df_post else df
             )
   
    ## Calculate fold changes and p values for contrast
    cat("Estimating p-values contrasts\n")
    df_prot <- df_prot %>%
      mutate(contrasts =  furrr::future_pmap(list(model = model, contrasts = list(contrasts),
                                                     var = var_protein,
                                                     df = df_protein, lfc = lfc), contEst))  %>%
      ## Calculate qvalues BH
      select_at(vars(!!group_vars, contrasts)) %>%
      unnest %>% 
      group_by(contrast) %>%
      mutate(qvalue = p.adjust(pvalue, method = p.adjust.method)) %>%
      group_by_at(vars(!!group_vars)) %>% nest(.key = contrasts) %>%
      left_join(df_prot,.)
  }
  ) %>% print
  if (parallel) stopCluster(cl)
  bind_rows(df_prot,df_prot_failed)
}

read_moff = function(moff,meta){
  print('START READING MOFF DATA')
  set = readMSnSet2(moff, ecol = -c(1,2),fnames = 'peptide',
                    sep = '\t',stringsAsFactors = FALSE)
  colnames(fData(set)) = c('peptide','protein')
  pd = read_tsv(meta) %>% column_to_rownames('sample') %>% as.data.frame

  ## fix msnbase bug 1
  ## if there is only 1 sample. Msnbase doesn't name it 
  if (length(sampleNames(set) ==1))
    sampleNames(set) = rownames(pd)

  pData(set) = pd
  ## fix msnbase bug 2
  ## bug in msnbase in summarisation (samplenames should be alphabetically)
  sample_order = order(sampleNames(set))
  set = MSnSet(exprs(set)[,sample_order,drop = FALSE]
             , fData =  AnnotatedDataFrame(fData(set))
             , pData = AnnotatedDataFrame(pData(set)[sample_order,,drop = FALSE]))
  print('END READING MOFF DATA')
  set
}

preprocess = function(set){
  print('START PREPROCESSING')
  if (ncol(set) == 1){
    exprs(set)[0 == (exprs(set))] <- NA
    set = log(set, base = 2)
    ## keep smallest unique groups
    groups2 <- smallestUniqueGroups(fData(set)$protein,split = ',')
    sel <- fData(set)$protein %in% groups2
    set <- set[sel,]
  } else {
    ## normalisation
    exprs(set)[0 == (exprs(set))] <- NA
    set <- normalize(set, 'vsn')
    ## keep smallest unique groups
    groups2 <- smallestUniqueGroups(fData(set)$protein,split = ',')
    sel <- fData(set)$protein %in% groups2
    set <- set[sel,]
    ## remove peptides with less then 2 observations
    sel <- rowSums(!is.na(exprs(set))) >= 2
    set <- set[sel]
  }
  print('END PREPROCESSING')
  set
}

summarise = function(set){
  print('START SUMMARISATION')
  ## Summarisation
  if (ncol(set) == 1){
    set = combineFeatures(set,fun="median", groupBy = fData(set)$protein,cv = FALSE)
  } else {
    ## set = combineFeatures(set,fun="robust", groupBy = fData(set)$protein,cv = FALSE)
    set = do_robust_summaristion(set,protein)
  }
  exprs(set) %>% as.data.frame %>% rownames_to_column('protein') %>% write_tsv('summarised_proteins.tsv')
  print('END SUMMARISATION')
  set
}

quantify = function(set, cpu = 0){
  print('START QUANTITATION')
  if ((cpu == 0) | is.na(cpu)) cpu = availableCores()
  print(cpu)
  form = colnames(pData(set)) %>% paste0('(1|',.,')',collapse='+') %>% paste('~',.) %>% as.formula
  contrasts <- contrast_helper(form, set, condition)
  res = do_mm(formulas = form, set, group_vars = c(protein)
            , contrasts = contrasts,type_df = 'traceHat', parallel = TRUE,cores = cpu) %>%
    filter(!map_lgl(contrasts, is.null)) %>%
    transmute(protein, contrasts) %>% unnest %>%
    transmute(protein
            , comparison = str_replace_all(contrast, 'condition', '')
            , logFC,pvalue,qvalue) %>%
    write_tsv('quantitation.tsv')
  print('END QUANTITATION')
}

args = commandArgs(trailingOnly=TRUE)
moff = args[1]
meta = args[2]
summarise_only = args[3]
cpu = strtoi(args[4])

res = read_moff(moff, meta) %>%
  preprocess %>%
  summarise
if (summarise_only != 1)
  quantify(res, cpu)

