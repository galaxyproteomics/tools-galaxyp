#***************************************************************************************************************************************
# Functions: Start
#***************************************************************************************************************************************

#===============================================================================
# PCA
#===============================================================================
multisample_PCA = function(df, sampleinfo_df, outfile)
{
  tempdf = df[,-1];
  tempcol = colnames(tempdf);
  tempgrp = sampleinfo_df[tempcol,2];
  tempdf = t(tempdf) %>% as.data.frame();
  tempdf[is.na(tempdf)] = 0;
  tempdf$Group = tempgrp;
  png(outfile, width = 6, height = 6, units = 'in', res=300);
  # bitmap(outfile, "png16m");
  g = autoplot(prcomp(select(tempdf, -Group)), data = tempdf, colour = 'Group', size=3);
  saveWidget(ggplotly(g), file.path(gsub("\\.png", "\\.html", outplot)))
  plot(g);
  dev.off();
}

#===============================================================================
# Regression and Cook's distance
#===============================================================================
singlesample_regression = function(PE_TE_data,htmloutfile, append=TRUE)
{
  rownames(PE_TE_data) = PE_TE_data$PE_ID;
  regmodel = lm(PE_abundance~TE_abundance, data=PE_TE_data);
  regmodel_summary = summary(regmodel);
  
  cat("<font><h3>Linear Regression model fit between Proteome and Transcriptome data</h3></font>\n",
      "<p>Assuming a linear relationship between Proteome and Transcriptome data, we here fit a linear regression model.</p>\n",
      '<table  border=1 cellspacing=0 cellpadding=5 style="table-layout:auto; "> <tr bgcolor="#7a0019"><th><font color=#ffcc33>Parameter</font></th><th><font color=#ffcc33>Value</font></th></tr>\n',
      file = htmloutfile, append = TRUE);
  
  cat("<tr><td>Formula</td><td>","PE_abundance~TE_abundance","</td></tr>\n",
      "<tr><td colspan='2' align='center'> <b>Coefficients</b></td>","</tr>\n",
      "<tr><td>",names(regmodel$coefficients[1]),"</td><td>",regmodel$coefficients[1]," (Pvalue:", regmodel_summary$coefficients[1,4],")","</td></tr>\n",
      "<tr><td>",names(regmodel$coefficients[2]),"</td><td>",regmodel$coefficients[2]," (Pvalue:", regmodel_summary$coefficients[2,4],")","</td></tr>\n",
      "<tr><td colspan='2' align='center'> <b>Model parameters</b></td>","</tr>\n",
      "<tr><td>Residual standard error</td><td>",regmodel_summary$sigma," (",regmodel_summary$df[2]," degree of freedom)</td></tr>\n",
      "<tr><td>F-statistic</td><td>",regmodel_summary$fstatistic[1]," ( on ",regmodel_summary$fstatistic[2]," and  ",regmodel_summary$fstatistic[3]," degree of freedom)</td></tr>\n",
      "<tr><td>R-squared</td><td>",regmodel_summary$r.squared,"</td></tr>\n",
      "<tr><td>Adjusted R-squared</td><td>",regmodel_summary$adj.r.squared,"</td></tr>\n",
      file = htmloutfile, append = TRUE);
  
  cat("</table>\n", file = htmloutfile, append = TRUE);
  
  cat(
    "<font color='#ff0000'><h3>Regression and diagnostics plots</h3></font>\n",
    file = htmloutfile, append = TRUE);
  
  outplot = paste(outdir,"/PE_TE_lm_1.png",sep="",collapse="");
  png(outplot, width = 10, height = 10, units = 'in',res=300);
  # bitmap(outplot, "png16m");
  par(mfrow=c(1,1));
  plot(regmodel, 1, cex.lab=1.5);
  dev.off();
  
  suppressWarnings(g <- autoplot(regmodel, label = FALSE)[[1]] +
    geom_point(aes(text=sprintf("Residual: %.2f<br>Fitted value: %.2f<br>Gene: %s", .fitted, .resid, PE_TE_data$PE_ID)),
               shape = 1, size = .1, stroke = .2) +
    theme_light())
  saveWidget(ggplotly(g, tooltip= c("text")), file.path(gsub("\\.png", "\\.html", outplot)))
  
  outplot = paste(outdir,"/PE_TE_lm_2.png",sep="",collapse="");
  png(outplot,width = 10, height = 10, units = 'in', res=300);
  # bitmap(outplot, "png16m");
  par(mfrow=c(1,1));
  g <- plot(regmodel, 2, cex.lab=1.5);
  ggplotly(g)
  dev.off();
  
  suppressWarnings(g <- autoplot(regmodel, label = FALSE)[[2]] +
    geom_point(aes(text=sprintf("Standarized residual: %.2f<br>Theoretical quantile: %.2f<br>Gene: %s", .qqx, .qqy, PE_TE_data$PE_ID)),
               shape = 1, size = .1) +
    theme_light())
  saveWidget(ggplotly(g, tooltip = "text"), file.path(gsub("\\.png", "\\.html", outplot)))
  
  
  outplot = paste(outdir,"/PE_TE_lm_5.png",sep="",collapse="");
  png(outplot, width = 10, height = 10, units = 'in',res=300);
  # bitmap(outplot, "png16m");
  par(mfrow=c(1,1));
  plot(regmodel, 5, cex.lab=1.5);
  dev.off();
  
  cd_cont_pos <- function(leverage, level, model) {sqrt(level*length(coef(model))*(1-leverage)/leverage)}
  cd_cont_neg <- function(leverage, level, model) {-cd_cont_pos(leverage, level, model)}
  
  suppressWarnings(g <- autoplot(regmodel, label = FALSE)[[4]] +
    aes(label = PE_TE_data$PE_ID) + 
    geom_point(aes(text=sprintf("Leverage: %.2f<br>Standardized residual: %.2f<br>Gene: %s", .hat, .stdresid, PE_TE_data$PE_ID))) +
    theme_light())
  saveWidget(ggplotly(g, tooltip = "text"), file.path(gsub("\\.png", "\\.html", outplot)))
  
  cat('<table border=1 cellspacing=0 cellpadding=5 style="table-layout:auto; ">', file = htmloutfile, append = TRUE);
  
  cat(
    '<tr bgcolor="#7a0019"><th>', "<font color='#ffcc33'><h4>1) <u>Residuals vs Fitted plot</h4></font></u></th>\n",
    '<th><font color=#ffcc33><h4>2) <u>Normal Q-Q plot of residuals</h4></font></u></th></tr>\n',
    file = htmloutfile, append = TRUE);
  
  cat(
    '<tr><td align=center><img src="PE_TE_lm_1.png" width=600 height=600>',
    gsub("width:500px;height:500px", "width:600px;height:600px", extractWidgetCode(paste(outdir,"/PE_TE_lm_1.png",sep="",collapse=""))$widget_div),
    '</td><td align=center><img src="PE_TE_lm_2.png" width=600 height=600>',
    gsub("width:500px;height:500px", "width:600px;height:600px", extractWidgetCode(paste(outdir,"/PE_TE_lm_2.png",sep="",collapse=""))$widget_div),
    '</td></tr>\n', file = htmloutfile, append = TRUE);
  
  cat(
    '<tr><td align=center>This plot checks for linear relationship assumptions.<br>If a horizontal line is observed without any distinct patterns, it indicates a linear relationship.</td>\n',
    '<td align=center>This plot checks whether residuals are normally distributed or not.<br>It is good if the residuals points follow the straight dashed line i.e., do not deviate much from dashed line.</td></tr></table>\n',
    file = htmloutfile, append = TRUE);
  
  
  #@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  # Residuals data
  #@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  res_all = regmodel$residuals;
  res_mean = mean(res_all);
  res_sd = sd(res_all);
  res_diff = (res_all-res_mean);
  res_zscore = res_diff/res_sd;
  # res_outliers = res_all[which((res_zscore > 2)|(res_zscore < -2))]
  
  
  tempind = which((res_zscore > 2)|(res_zscore < -2));
  res_PE_TE_data_no_outlier = PE_TE_data[-tempind,];
  res_PE_TE_data_no_outlier$residuals = res_all[-tempind];
  res_PE_TE_data_outlier = PE_TE_data[tempind,];
  res_PE_TE_data_outlier$residuals = res_all[tempind];
  
  # Save the complete table for download (influential_observations)
  temp_outlier_data = data.frame(res_PE_TE_data_outlier$PE_ID, res_PE_TE_data_outlier$TE_abundance, res_PE_TE_data_outlier$PE_abundance, res_PE_TE_data_outlier$residuals)
  colnames(temp_outlier_data) = c("Gene", "Transcript abundance", "Protein abundance", "Residual value")
  outdatafile = paste(outdir,"/PE_TE_outliers_residuals.txt", sep="", collapse="");
  write.table(temp_outlier_data, file=outdatafile, row.names=F, sep="\t", quote=F);
  
  
  # Save the complete table for download (non influential_observations)
  temp_all_data = data.frame(PE_TE_data$PE_ID, PE_TE_data$TE_abundance, PE_TE_data$PE_abundance, res_all)
  colnames(temp_all_data) = c("Gene", "Transcript abundance", "Protein abundance", "Residual value")
  outdatafile = paste(outdir,"/PE_TE_abundance_residuals.txt", sep="", collapse="");
  write.table(temp_all_data, file=outdatafile, row.names=F, sep="\t", quote=F);
  
  
  cat('<br><h2 id="inf_obs"><font color=#ff0000>Outliers based on the residuals from regression analysis</font></h2>\n',
      file = htmloutfile, append = TRUE);
  cat('<table border=1 cellspacing=0 cellpadding=5 style="table-layout:auto; ">\n',
      '<tr bgcolor="#7a0019"><th colspan=2><font color=#ffcc33>Residuals from Regression</font></th></tr>\n',
      '<tr bgcolor="#7a0019"><th><font color=#ffcc33>Parameter</font></th><th><font color=#ffcc33>Value</font></th></tr>\n',
      file = htmloutfile, append = TRUE);
  
  cat("<tr><td>Mean Residual value</td><td>",res_mean,"</td></tr>\n",
      "<tr><td>Standard deviation (Residuals)</td><td>",res_sd,"</td></tr>\n",
      '<tr><td>Total outliers (Residual value > 2 standard deviation from the mean)</td><td>',length(tempind),' <font size=4>(<b><a href="PE_TE_outliers_residuals.txt" target="_blank">Download these ',length(tempind),' data points with high residual values here</a></b>)</font></td>\n',
      '<tr><td colspan=2 align=center>',
      '<font size=4>(<b><a href="PE_TE_abundance_residuals.txt" target="_blank">Download the complete residuals data here</a></b>)</font>',
      "</td></tr>\n</table><br><br>\n",
      file = htmloutfile, append = TRUE);
  
  #@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  
  
  cat('<br><br><table border=1 cellspacing=0 cellpadding=5 style="table-layout:auto; ">', file = htmloutfile, append = TRUE);
  
  cat(
    '<tr bgcolor="#7a0019"><th><font color=#ffcc33><h4>3) <u>Residuals vs Leverage plot</h4></font></u></th></tr>\n',
    file = htmloutfile, append = TRUE);
  
  cat(
    '<tr><td align=center><img src="PE_TE_lm_5.png" width=600 height=600>', 
    gsub("width:500px;height:500px", "width:600px;height:600px", extractWidgetCode(paste(outdir,"/PE_TE_lm_5.png",sep="",collapse=""))$widget_div)
    , '</td></tr>\n',
    file = htmloutfile, append = TRUE);
  
  cat(
    '<tr><td align=center>This plot is useful to identify any influential cases, that is outliers or extreme values.<br>They might influence the regression results upon inclusion or exclusion from the analysis.</td></tr></table><br>\n',
    file = htmloutfile, append = TRUE);
  
  
  
  #^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  # Cook's Distance
  #^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  cat('<hr/><h2 id="inf_obs"><font color=#ff0000>INFLUENTIAL OBSERVATIONS</font></h2>\n',
      file = htmloutfile, append = TRUE);
  cat(
    '<p><b>Cook\'s distance</b> computes the influence of each data point/observation on the predicted outcome. i.e. this measures how much the observation is influencing the fitted values.<br>In general use, those observations that have a <b>Cook\'s distance > than ', cookdist_upper_cutoff,' times the mean</b> may be classified as <b>influential.</b></p>\n',
    file = htmloutfile, append = TRUE);
  
  cooksd <- cooks.distance(regmodel);
  
  outplot = paste(outdir,"/PE_TE_lm_cooksd.png",sep="",collapse="");
  png(outplot, width = 10, height = 10, units = 'in', res=300);
  # bitmap(outplot, "png16m");
  par(mfrow=c(1,1));
  plot(cooksd, main="Influential Obs. by Cook\'s distance", ylab="Cook\'s distance", xlab="Observations", type="n")  # plot cooks distance
  sel_outlier=which(cooksd>=as.numeric(cookdist_upper_cutoff)*mean(cooksd, na.rm=T))
  sel_nonoutlier=which(cooksd<as.numeric(cookdist_upper_cutoff)*mean(cooksd, na.rm=T))
  points(sel_outlier, cooksd[sel_outlier],pch="*", cex=2, cex.lab=1.5, col="red")
  points(sel_nonoutlier, cooksd[sel_nonoutlier],pch="*", cex=2, cex.lab=1.5, col="black")
  abline(h = as.numeric(cookdist_upper_cutoff)*mean(cooksd, na.rm=T), col="red")  # add cutoff line
  #text(x=1:length(cooksd)+1, y=cooksd, labels=ifelse(cooksd>as.numeric(cookdist_upper_cutoff)*mean(cooksd, na.rm=T),names(cooksd),""), col="red", pos=2)  # add labels
  dev.off();
  
  cooksd_df <- data.frame(cooksd)
  cooksd_df$genes <- row.names(cooksd_df)
  cooksd_df$index <- 1:nrow(cooksd_df)
  cooksd_df$colors <- "black"
  cutoff <- as.numeric(cookdist_upper_cutoff)*mean(cooksd, na.rm=T)
  cooksd_df[cooksd_df$cooksd > cutoff,]$colors <- "red"
  
  g <- ggplot(cooksd_df, aes(x = index, y = cooksd, label = row.names(cooksd_df), color=as.factor(colors), 
          text=sprintf("Gene: %s<br>Cook's Distance: %.3f", row.names(cooksd_df), cooksd))) +
    ggtitle("Influential Obs. by Cook's distance") + xlab("Observations") + ylab("Cook's Distance") + 
    #xlim(0, 3000) + ylim(0, .15) + 
    scale_shape_discrete(solid=F) +
    geom_point(size = 2, shape = 8)  + 
    geom_hline(yintercept = cutoff, 
               linetype = "dashed", color = "red") + 
    scale_color_manual(values = c("black" = "black", "red" = "red")) + 
    theme_light() + theme(legend.position="none")
  saveWidget(ggplotly(g, tooltip= "text"), file.path(gsub("\\.png", "\\.html", outplot)))
  
  cat(
    '<img src="PE_TE_lm_cooksd.png" width=800 height=800>',
    gsub("width:500px;height:500px", "width:800px;height:800px", extractWidgetCode(outplot)$widget_div),
    '<br>In the above plot, observations above red line (',cookdist_upper_cutoff,' * mean Cook\'s distance) are influential. Genes that are outliers could be important. These observations influences the correlation values and regression coefficients<br><br>',
    file = htmloutfile, append = TRUE);    
  
  tempind = which(cooksd>as.numeric(cookdist_upper_cutoff)*mean(cooksd, na.rm=T));
  PE_TE_data_no_outlier = PE_TE_data[-tempind,];
  PE_TE_data_no_outlier$cooksd = cooksd[-tempind];
  PE_TE_data_outlier = PE_TE_data[tempind,];
  PE_TE_data_outlier$cooksd = cooksd[tempind];
  a = sort(PE_TE_data_outlier$cooksd, decreasing=T, index.return=T);
  PE_TE_data_outlier_sorted = PE_TE_data_outlier[a$ix,];
  
  cat(
    '<table border=1 cellspacing=0 cellpadding=5 style="table-layout:auto; "> <tr bgcolor="#7a0019"><th><font color=#ffcc33>Parameter</font></th><th><font color=#ffcc33>Value</font></th></tr>\n',
    file = htmloutfile, append = TRUE);
  
  # Save the complete table for download (influential_observations)
  temp_outlier_data = data.frame(PE_TE_data_outlier$PE_ID, PE_TE_data_outlier$TE_abundance, PE_TE_data_outlier$PE_abundance, PE_TE_data_outlier$cooksd)
  colnames(temp_outlier_data) = c("Gene", "Transcript abundance", "Protein abundance", "Cook's distance")
  outdatafile = paste(outdir,"/PE_TE_influential_observation.txt", sep="", collapse="");
  write.table(temp_outlier_data, file=outdatafile, row.names=F, sep="\t", quote=F);
  
  
  # Save the complete table for download (non influential_observations)
  temp_no_outlier_data = data.frame(PE_TE_data_no_outlier$PE_ID, PE_TE_data_no_outlier$TE_abundance, PE_TE_data_no_outlier$PE_abundance, PE_TE_data_no_outlier$cooksd)
  colnames(temp_no_outlier_data) = c("Gene", "Transcript abundance", "Protein abundance", "Cook's distance")
  outdatafile = paste(outdir,"/PE_TE_non_influential_observation.txt", sep="", collapse="");
  write.table(temp_no_outlier_data, file=outdatafile, row.names=F, sep="\t", quote=F);
  
  
  cat("<tr><td>Mean Cook\'s distance</td><td>",mean(cooksd, na.rm=T),"</td></tr>\n",
      "<tr><td>Total influential observations (Cook\'s distance > ",cookdist_upper_cutoff," * mean Cook\'s distance)</td><td>",length(tempind),"</td>\n",
      
      "<tr><td>Observations with Cook\'s distance < ",cookdist_upper_cutoff," * mean Cook\'s distance</td><td>",length(which(cooksd<as.numeric(cookdist_upper_cutoff)*mean(cooksd, na.rm=T))),"</td>\n",
      "</table><br><br>\n",
      file = htmloutfile, append = TRUE);
  
  
  #@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  # Scatter plot after removal of influential points
  #@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  outplot = paste(outdir,"/AbundancePlot_scatter_without_outliers.png",sep="",collapse="");
  min_lim = min(c(PE_TE_data$PE_abundance,PE_TE_data$TE_abundance));
  max_lim = max(c(PE_TE_data$PE_abundance,PE_TE_data$TE_abundance));
  png(outplot, width = 10, height = 10, units = 'in', res=300);
  # bitmap(outplot,"png16m");
  suppressWarnings(g <- ggplot(PE_TE_data_no_outlier, aes(x=TE_abundance, y=PE_abundance, label=PE_ID)) + geom_smooth() + 
    xlab("Transcript abundance log fold-change") + ylab("Protein abundance log fold-change") + 
    xlim(min_lim,max_lim) + ylim(min_lim,max_lim) +
    geom_point(aes(text=sprintf("Gene: %s<br>Transcript Abundance (log fold-change): %.3f<br>Protein Abundance (log fold-change): %.3f",
                                PE_ID, TE_abundance, PE_abundance))))
  suppressMessages(plot(g))
  suppressMessages(saveWidget(ggplotly(g, tooltip="text"), file.path(gsub("\\.png", "\\.html", outplot))))
  dev.off();
  
  
  cat('<table  border=1 cellspacing=0 cellpadding=5 style="table-layout:auto; "> <tr bgcolor="#7a0019"><th><font color=#ffcc33>Scatterplot: Before removal</font></th><th><font color=#ffcc33>Scatterplot: After removal</font></th></tr>\n', file = htmloutfile, append = TRUE);
  # Before
  cat("<tr><td align=center><!--<font color='#ff0000'><h3>Scatter plot between Proteome and Transcriptome Abundance</h3></font>\n-->",
      '<img src="TE_PE_scatter.png" width=600 height=600>',
      gsub('id="html', 'id="secondhtml"',
           gsub("width:500px;height:500px", "width:600px;height:600px", extractWidgetCode(paste(outdir,"/TE_PE_scatter.png",sep="",collapse=""))$widget_div)),
      '</td>\n',
      file = htmloutfile, append = TRUE);
  
  # After
  cat("<td align=center>\n",
      '<img src="AbundancePlot_scatter_without_outliers.png" width=600 height=600>',
      gsub("width:500px;height:500px", "width:600px;height:600px", extractWidgetCode(outplot)$widget_div),
      
      '</td></tr>\n',
      file = htmloutfile, append = TRUE);
  #@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  
  
  cor_result_pearson = cor.test(PE_TE_data_no_outlier[,"TE_abundance"], PE_TE_data_no_outlier[,"PE_abundance"], method = "pearson");
  cor_result_spearman = cor.test(PE_TE_data_no_outlier[,"TE_abundance"], PE_TE_data_no_outlier[,"PE_abundance"], method = "spearman");
  cor_result_kendall = cor.test(PE_TE_data_no_outlier[,"TE_abundance"], PE_TE_data_no_outlier[,"PE_abundance"], method = "kendall");
  
  cat('<tr><td>\n', file = htmloutfile, append=TRUE);
  singlesample_cor(PE_TE_data, htmloutfile, append=TRUE);
  cat('</td>\n', file = htmloutfile, append=TRUE);
  
  
  cat('<td><table border=1 cellspacing=0 cellpadding=5 style="table-layout:auto; "> <tr bgcolor="#7a0019"><th><font color=#ffcc33>Parameter</font></th><th><font color=#ffcc33>Method 1</font></th><th><font color=#ffcc33>Method 2</font></th><th><font color=#ffcc33>Method 3</font></th></tr>\n',
      file = htmloutfile, append = TRUE);
  
  cat(
    "<tr><td>Correlation method</td><td>",cor_result_pearson$method,"</td><td>",cor_result_spearman$method,"</td><td>",cor_result_kendall$method,"</td></tr>\n",
    "<tr><td>Correlation coefficient</td><td>",cor_result_pearson$estimate,"</td><td>",cor_result_spearman$estimate,"</td><td>",cor_result_kendall$estimate,"</td></tr>\n",
    file = htmloutfile, append = TRUE)
  cat("</table></td></tr></table>\n", file = htmloutfile, append = TRUE)
  
  
  
  if(dim(PE_TE_data_outlier)[1]<10)
  {
    tab_n_row = dim(PE_TE_data_outlier)[1];
  }else{
    tab_n_row = 10;
  }
  
  cat("<br><br><font size=5><b><a href='PE_TE_influential_observation.txt' target='_blank'>Download the complete list of influential observations</a></b></font>&nbsp;&nbsp;&nbsp;&nbsp;",
      "<font size=5><b><a href='PE_TE_non_influential_observation.txt' target='_blank'>Download the complete list (After removing influential points)</a></b></font><br>\n",
      '<br><font color="brown"><h4>Top ',as.character(tab_n_row),' Influential observations (Cook\'s distance > ',cookdist_upper_cutoff,' * mean Cook\'s distance)</h4></font>\n',
      file = htmloutfile, append = TRUE);
  
  cat('<table border=1 cellspacing=0 cellpadding=5> <tr bgcolor="#7a0019">\n', sep = "",file = htmloutfile, append = TRUE);
  cat("<th><font color=#ffcc33>Gene</font></th><th><font color=#ffcc33>Protein Log Fold-Change</font></th><th><font color=#ffcc33>Transcript Log Fold-Change</font></th><th><font color=#ffcc33>Cook's Distance</font></th></tr>\n",
      file = htmloutfile, append = TRUE);
  
  
  for(i in 1:tab_n_row)
  {
    cat(
      '<tr>','<td>',as.character(PE_TE_data_outlier_sorted[i,1]),'</td>\n',
      '<td>',format(PE_TE_data_outlier_sorted[i,2], scientific=F),'</td>\n',
      '<td>',PE_TE_data_outlier_sorted[i,4],'</td>\n',
      '<td>',format(PE_TE_data_outlier_sorted[i,5], scientific=F),'</td></tr>\n',
      file = htmloutfile, append = TRUE);
  }
  cat('</table><br><br>\n',file = htmloutfile, append = TRUE);
  
  
}



#===============================================================================
# Heatmap
#===============================================================================
singlesample_heatmap=function(PE_TE_data, htmloutfile, hm_nclust){
  cat('<br><table border=1 cellspacing=0 cellpadding=5 style="table-layout:auto; "> <tr bgcolor="#7a0019"><th><font color=#ffcc33>Heatmap of PE and TE abundance values (Hierarchical clustering)</font></th><th><font color=#ffcc33>Number of clusters to extract: ',hm_nclust,'</font></th></tr>\n',
      file = htmloutfile, append = TRUE);
  
  hc=hclust(dist(as.matrix(PE_TE_data[,c("PE_abundance","TE_abundance")])))
  hm_cluster = cutree(hc,k=hm_nclust);
  
  outplot = paste(outdir,"/PE_TE_heatmap.png",sep="",collapse="");
  png(outplot, width = 10, height = 10, units = 'in', res=300);
  # bitmap(outplot, "png16m");
  par(mfrow=c(1,1));
  hmap = heatmap.2(as.matrix(PE_TE_data[,c("PE_abundance","TE_abundance")]),
                   trace="none", cexCol=1, col=greenred(100),Colv=F, 
                   labCol=c("Proteins","Transcripts"), scale="col", 
                   hclustfun = hclust, distfun = dist);
  
  dev.off();
  
  
  p <- d3heatmap(as.matrix(PE_TE_data[,c("PE_abundance","TE_abundance")]), scale = "col",
                 dendrogram = "row", colors = greenred(100),
                 hclustfun = hclust, distfun = dist,
                 show_grid = FALSE)
  saveWidget(p, file.path(gsub("\\.png", "\\.html", outplot)))
  
  cat('<tr><td align=center colspan="2">',
      '<img src="PE_TE_heatmap.png" width=800 height=800>',
      gsub("width:960px;height:500px", "width:800px;height:800px", extractWidgetCode(outplot)$widget_div),
      '</td></tr>\n',
      file = htmloutfile, append = TRUE);
  
  
  temp_PE_TE_data = data.frame(PE_TE_data$PE_ID, PE_TE_data$TE_abundance, PE_TE_data$PE_abundance, hm_cluster);
  colnames(temp_PE_TE_data) = c("Gene", "Transcript abundance", "Protein abundance", "Cluster (Hierarchical clustering)")
  tempoutfile = paste(outdir,"/PE_TE_hc_clusterpoints.txt",sep="",collapse="");
  write.table(temp_PE_TE_data, file=tempoutfile, row.names=F, quote=F, sep="\t", eol="\n")
  
  
  cat('<tr><td colspan="2" align=center><font size=5><a href="PE_TE_hc_clusterpoints.txt" target="_blank"><b>Download the hierarchical cluster list</b></a></font></td></tr></table>\n',
      file = htmloutfile, append = TRUE);
}


#===============================================================================
# K-means clustering
#===============================================================================
singlesample_kmeans=function(PE_TE_data, htmloutfile, nclust){
  PE_TE_data_kdata = PE_TE_data;
  k1 = kmeans(PE_TE_data_kdata[,c("PE_abundance","TE_abundance")], nclust);
  outplot = paste(outdir,"/PE_TE_kmeans.png",sep="",collapse="");
  png(outplot, width = 10, height = 10, units = 'in', res=300);
  # bitmap(outplot, "png16m");
  par(mfrow=c(1,1));
  scatter.smooth(PE_TE_data_kdata[,"TE_abundance"], PE_TE_data_kdata[,"PE_abundance"], xlab="Transcript Abundance", ylab="Protein Abundance", cex.lab=1.5);
  legend(1, 95, legend=c("Cluster 1", "Line 2"), col="red", lty=1:1, cex=0.8)
  legend(1, 95, legend="Cluster 2", col="green", lty=1:1, cex=0.8)
  
  ind=which(k1$cluster==1);
  points(PE_TE_data_kdata[ind,"TE_abundance"], PE_TE_data_kdata[ind,"PE_abundance"], col="red", pch=16);
  ind=which(k1$cluster==2);
  points(PE_TE_data_kdata[ind,"TE_abundance"], PE_TE_data_kdata[ind,"PE_abundance"], col="green", pch=16);
  ind=which(k1$cluster==3);
  points(PE_TE_data_kdata[ind,"TE_abundance"], PE_TE_data_kdata[ind,"PE_abundance"], col="blue", pch=16);
  ind=which(k1$cluster==4);
  points(PE_TE_data_kdata[ind,"TE_abundance"], PE_TE_data_kdata[ind,"PE_abundance"], col="cyan", pch=16);
  ind=which(k1$cluster==5);
  points(PE_TE_data_kdata[ind,"TE_abundance"], PE_TE_data_kdata[ind,"PE_abundance"], col="black", pch=16);
  ind=which(k1$cluster==6);
  points(PE_TE_data_kdata[ind,"TE_abundance"], PE_TE_data_kdata[ind,"PE_abundance"], col="brown", pch=16);
  ind=which(k1$cluster==7);
  points(PE_TE_data_kdata[ind,"TE_abundance"], PE_TE_data_kdata[ind,"PE_abundance"], col="gold", pch=16);
  ind=which(k1$cluster==8);
  points(PE_TE_data_kdata[ind,"TE_abundance"], PE_TE_data_kdata[ind,"PE_abundance"], col="thistle", pch=16);
  ind=which(k1$cluster==9);
  points(PE_TE_data_kdata[ind,"TE_abundance"], PE_TE_data_kdata[ind,"PE_abundance"], col="yellow", pch=16);
  ind=which(k1$cluster==10);
  points(PE_TE_data_kdata[ind,"TE_abundance"], PE_TE_data_kdata[ind,"PE_abundance"], col="orange", pch=16);
  dev.off();
  
  # Interactive plot for k-means clustering
  g <- ggplot(PE_TE_data, aes(x = TE_abundance, y = PE_abundance, label = row.names(PE_TE_data),
                text=sprintf("Gene: %s<br>Transcript Abundance: %.3f<br>Protein Abundance: %.3f",
                PE_ID, TE_abundance, PE_abundance),
                color=as.factor(k1$cluster))) +
    xlab("Transcript Abundance") + ylab("Protein Abundance") + 
    scale_shape_discrete(solid=F) + geom_smooth(method = "loess", span = 2/3) +
    geom_point(size = 1, shape = 8) +
    theme_light() + theme(legend.position="none")
  saveWidget(ggplotly(g, tooltip=c("text")), file.path(gsub("\\.png", "\\.html", outplot)))
  
  cat('<br><br><table border=1 cellspacing=0 cellpadding=5 style="table-layout:auto; "> <tr bgcolor="#7a0019"><th><font color=#ffcc33>K-mean clustering</font></th><th><font color=#ffcc33>Number of clusters: ',nclust,'</font></th></tr>\n',
      file = htmloutfile, append = TRUE);
  
  tempind = order(k1$cluster);
  tempoutfile = paste(outdir,"/PE_TE_kmeans_clusterpoints.txt",sep="",collapse="");
  write.table(data.frame(PE_TE_data_kdata[tempind, ], Cluster=k1$cluster[tempind]), file=tempoutfile, row.names=F, quote=F, sep="\t", eol="\n")
  
  #paste(outdir,"/PE_TE_heatmap.png",sep="",collapse="");
  cat('<tr><td colspan="2" align=center><img src="PE_TE_kmeans.png" width=800 height=800>',
      gsub("width:500px;height:500px", "width:800px;height:800px", extractWidgetCode(outplot)$widget_div), '</td></tr>\n',
      file = htmloutfile, append = TRUE);
  cat('<tr><td colspan="2" align=center><font size=5><a href="PE_TE_kmeans_clusterpoints.txt" target="_blank"><b>Download the cluster list</b></a></font></td></tr></table><br><hr/>\n',
      file = htmloutfile, append = TRUE);
  
}

#===============================================================================
# scatter plot
#===============================================================================
singlesample_scatter = function(PE_TE_data, outfile)
{
  min_lim = min(c(PE_TE_data$PE_abundance,PE_TE_data$TE_abundance));
  max_lim = max(c(PE_TE_data$PE_abundance,PE_TE_data$TE_abundance));
  png(outfile, width = 10, height = 10, units = 'in', res=300);
  # bitmap(outfile, "png16m");
  suppressWarnings(g <- ggplot(PE_TE_data, aes(x=TE_abundance, y=PE_abundance, label=PE_ID)) + geom_smooth() + 
    xlab("Transcript abundance log fold-change") + ylab("Protein abundance log fold-change") + 
    xlim(min_lim,max_lim) + ylim(min_lim,max_lim) +
    geom_point(aes(text=sprintf("Gene: %s<br>Transcript Abundance (log fold-change): %.3f<br>Protein Abundance (log fold-change): %.3f",
                                PE_ID, TE_abundance, PE_abundance)),
              size = .5))
  suppressMessages(plot(g))
  suppressMessages(saveWidget(ggplotly(g, tooltip = "text"), file.path(gsub("\\.png", "\\.html", outfile))))
  dev.off();
}

#===============================================================================
# Correlation table
#===============================================================================
singlesample_cor = function(PE_TE_data, htmloutfile, append=TRUE)
{
  cor_result_pearson = cor.test(PE_TE_data$TE_abundance, PE_TE_data$PE_abundance, method = "pearson");
  cor_result_spearman = cor.test(PE_TE_data$TE_abundance, PE_TE_data$PE_abundance, method = "spearman");
  cor_result_kendall = cor.test(PE_TE_data$TE_abundance, PE_TE_data$PE_abundance, method = "kendall");
  
  cat(
    '<table  border=1 cellspacing=0 cellpadding=5 style="table-layout:auto; "> <tr bgcolor="#7a0019"><th><font color=#ffcc33>Parameter</font></th><th><font color=#ffcc33>Method 1</font></th><th><font color=#ffcc33>Method 2</font></th><th><font color=#ffcc33>Method 3</font></th></tr>\n',
    file = htmloutfile, append = TRUE);
  
  cat(
    "<tr><td>Correlation method</td><td>",cor_result_pearson$method,"</td><td>",cor_result_spearman$method,"</td><td>",cor_result_kendall$method,"</td></tr>\n",
    "<tr><td>Correlation coefficient</td><td>",cor_result_pearson$estimate,"</td><td>",cor_result_spearman$estimate,"</td><td>",cor_result_kendall$estimate,"</td></tr>\n",
    file = htmloutfile, append = TRUE)
  cat("</table>\n", file = htmloutfile, append = TRUE);
  
}

#===============================================================================
# Boxplot
#===============================================================================
multisample_boxplot = function(df, sampleinfo_df, outfile, fill_leg, user_xlab, user_ylab)
{
  tempdf = df[,-1, drop=FALSE];
  tempdf = t(tempdf) %>% as.data.frame();
  tempdf[is.na(tempdf)] = 0;
  tempdf$Sample = rownames(tempdf);
  tempdf1 = melt(tempdf, id.vars = "Sample");
  
  if("Gene" %in% colnames(df)){
    tempdf1$Name = df$Gene;
  } else if ("Protein" %in% colnames(df)){
    tempdf1$Name = df$Protein;
  } else if ("Genes" %in% colnames(df)){
    tempdf1$Name = df$Genes;
  }
  
  tempdf1$Group = sampleinfo_df[tempdf1$Sample,2];
  png(outplot, width = 6, height = 6, units = 'in', res=300);
  # bitmap(outplot, "png16m");
  if(fill_leg=="No"){
    tempdf1$Group = c("case", "control")
  }
  
  g = ggplot(tempdf1, aes(x=Sample, y=value, fill=Group)) + 
    geom_boxplot()+
    labs(x=user_xlab) + labs(y=user_ylab)
  saveWidget(ggplotly(g), file.path(gsub("\\.png", "\\.html", outfile)))
  plot(g);
  dev.off();
}

## A wrapper to saveWidget which compensates for arguable BUG in
## saveWidget which requires `file` to be in current working
## directory.
saveWidget <- function (widget,file,...) {
  wd<-getwd()
  on.exit(setwd(wd))
  outDir<-dirname(file)
  file<-basename(file)
  setwd(outDir);
  htmlwidgets::saveWidget(widget,file=file,selfcontained = FALSE)
}

#===============================================================================
# Mean or Median of Replicates
#===============================================================================

mergeReplicates = function(TE_df,PE_df, sampleinfo_df, method)
{
  grps = unique(sampleinfo_df[,2]);
  
  TE_df_merged <<- sapply(grps, function(x){
    tempsample = sampleinfo_df[which(sampleinfo_df$Group==x),1]
    if(length(tempsample)!=1){
      apply(TE_df[,tempsample],1,method);
    }else{
      return(TE_df[,tempsample]);
    }
  });
  TE_df_merged <<-   data.frame(as.character(TE_df[,1]), TE_df_merged);
  colnames(TE_df_merged) = c(colnames(TE_df)[1], grps);
  
  PE_df_merged <<- sapply(grps, function(x){
    tempsample = sampleinfo_df[which(sampleinfo_df$Group==x),1]
    if(length(tempsample)!=1){
      apply(PE_df[,tempsample],1,method);
    }else{
      return(PE_df[,tempsample]);
    }
  });
  
  PE_df_merged <<-   data.frame(as.character(PE_df[,1]), PE_df_merged);
  colnames(PE_df_merged) = c(colnames(PE_df)[1], grps);
  
  #sampleinfo_df_merged =  data.frame(Sample = grps, Group = grps, stringsAsFactors = F);
  sampleinfo_df_merged =  data.frame(Sample = grps, Group = "Group", stringsAsFactors = F);
  
  return(list(TE_df_merged = TE_df_merged, PE_df_merged = PE_df_merged, sampleinfo_df_merged = sampleinfo_df_merged));
}

#===============================================================================
# (T-Test or Wilcoxon ranksum test) and Volcano Plot
#===============================================================================

perform_Test_Volcano = function(TE_df_data,PE_df_data,TE_df_logfold, PE_df_logfold,sampleinfo_df, method, correction_method,volc_with)
{
  
  PE_colnames = colnames(PE_df_data);
  control_sample = sampleinfo_df[which(sampleinfo_df$Group=="control"),1];
  control_ind <<- sapply(control_sample, function(x){temp_ind = which(PE_colnames==x); as.numeric(temp_ind)});
  condition_sample = sampleinfo_df[which(sampleinfo_df$Group=="case"),1];
  condition_ind <<- sapply(condition_sample, function(x){temp_ind = which(PE_colnames==x); as.numeric(temp_ind)});
  
  if(method=="mean"){
    #PE_pval = apply(PE_df_data[2:length(colnames(PE_df_data))],1,function(x) t.test(x[condition_ind-1], x[control_ind-1])$p.value);
    PE_pval = apply(PE_df_data[2:length(colnames(PE_df_data))],1,function(x) {obj<-try(t.test(x[condition_ind-1], x[control_ind-1]),silent=TRUE); if(is(obj, "try-error")){return(NA)}else{return(obj$p.value)}})
  }else{
    if(method=="median"){
      PE_pval = apply(PE_df_data[2:length(colnames(PE_df_data))],1,function(x) {obj<-try(wilcox.test(x[condition_ind-1], x[control_ind-1]),silent=TRUE); if(is(obj, "try-error")){return(NA)}else{return(obj$p.value)}})
      # PE_pval = apply(PE_df_data[2:length(colnames(PE_df_data))],1,function(x) wilcox.test(x[condition_ind-1], x[control_ind-1])$p.value);
    }
  }
  PE_adj_pval = p.adjust(PE_pval, method = correction_method, n = length(PE_pval))
  
  
  TE_colnames = colnames(TE_df_data);
  control_sample = sampleinfo_df[which(sampleinfo_df$Group=="control"),1];
  control_ind <<- sapply(control_sample, function(x){temp_ind = which(TE_colnames==x); as.numeric(temp_ind)});
  condition_sample = sampleinfo_df[which(sampleinfo_df$Group=="case"),1];
  condition_ind <<- sapply(condition_sample, function(x){temp_ind = which(TE_colnames==x); as.numeric(temp_ind)});
  
  if(method=="mean"){
    # TE_pval = apply(TE_df_data[2:length(colnames(TE_df_data))],1,function(x) t.test(x[condition_ind-1], x[control_ind-1])$p.value);
    TE_pval = apply(TE_df_data[2:length(colnames(TE_df_data))],1,function(x) {obj<-try(t.test(x[condition_ind-1], x[control_ind-1]),silent=TRUE); if(is(obj, "try-error")){return(NA)}else{return(obj$p.value)}})
  }else{
    if(method=="median"){
      TE_pval = apply(TE_df_data[2:length(colnames(TE_df_data))],1,function(x) {obj<-try(wilcox.test(x[condition_ind-1], x[control_ind-1]),silent=TRUE); if(is(obj, "try-error")){return(NA)}else{return(obj$p.value)}})
      # TE_pval = apply(TE_df_data[2:length(colnames(TE_df_data))],1,function(x) wilcox.test(x[condition_ind-1], x[control_ind-1])$p.value);
    }
  }
  TE_adj_pval = p.adjust(TE_pval, method = correction_method, n = length(TE_pval))
  
  
  PE_TE_logfold_pval = data.frame(TE_df_logfold$Gene, TE_df_logfold$LogFold, TE_pval, TE_adj_pval, PE_df_logfold$LogFold, PE_pval, PE_adj_pval);
  colnames(PE_TE_logfold_pval) = c("Gene", "Transcript log fold-change", "p-value (transcript)", "adj p-value (transcript)", "Protein log fold-change", "p-value (protein)", "adj p-value (protein)");
  outdatafile = paste(outdir,"/PE_TE_logfold_pval.txt", sep="", collapse="");
  write.table(PE_TE_logfold_pval, file=outdatafile, row.names=F, sep="\t", quote=F);
  cat("<br><br><font size=5><b><a href='PE_TE_logfold_pval.txt' target='_blank'>Download the complete fold change data here</a></b></font><br>\n",
      file = htmloutfile, append = TRUE);
  
  if(length(condition_ind)!=1)
  {
    # Volcano Plot
    
    if(volc_with=="adj_pval")
    {
      PE_pval = PE_adj_pval
      TE_pval = TE_adj_pval
      volc_ylab = "-log10 Adjusted p-value";
    }else{
      if(volc_with=="pval")
      {
        volc_ylab = "-log10 p-value";
      }
    }
    outplot_PE = paste(outdir,"/PE_volcano.png",sep="",collapse="");
    png(outplot_PE, width = 10, height = 10, units = 'in', res=300);
    # bitmap(outplot, "png16m");
    par(mfrow=c(1,1));
    
    plot(PE_df_logfold$LogFold, -log10(PE_pval),
         xlab="log2 fold change", ylab=volc_ylab,
         type="n")
    sel <- which((PE_df_logfold$LogFold<=log(2,base=2))&(PE_df_logfold$LogFold>=log(0.5, base=2))) # or whatever you want to use
    points(PE_df_logfold[sel,"LogFold"], -log10(PE_pval[sel]),col="black")
    PE_df_logfold$color <- "black"
    #sel <- which((PE_df_logfold$LogFold>log(2,base=2))&(PE_df_logfold$LogFold<log(0.5,base=2))) # or whatever you want to use
    sel <- which((PE_df_logfold$LogFold>log(2,base=2))|(PE_df_logfold$LogFold<log(0.5, base=2)))
    sel1 <- which(PE_pval<=0.05)
    sel=intersect(sel,sel1)
    points(PE_df_logfold[sel,"LogFold"], -log10(PE_pval[sel]),col="red")
    PE_df_logfold[sel,]$color <- "red"
    sel <- which((PE_df_logfold$LogFold>log(2,base=2))|(PE_df_logfold$LogFold<log(0.5, base=2)))
    sel1 <- which(PE_pval>0.05)
    sel=intersect(sel,sel1)
    points(PE_df_logfold[sel,"LogFold"], -log10(PE_pval[sel]),col="blue")
    PE_df_logfold[sel,]$color <- "blue"
    abline(h = -log(0.05,base=10), col="red", lty=2)
    abline(v = log(2,base=2), col="red", lty=2)
    abline(v = log(0.5,base=2), col="red", lty=2)
    dev.off();
    
    g <- ggplot(PE_df_logfold, aes(x = LogFold, -log10(PE_pval), color = as.factor(color),
            text=sprintf("Gene: %s<br>Log2 Fold-Change: %.3f<br>-log10 p-value: %.3f<br>p-value: %.3f",
              Genes, LogFold, -log10(PE_pval), PE_pval))) +
      xlab("log2 fold change") + ylab("-log10 p-value") + 
      geom_point(shape=1, size = 1.5, stroke = .2) +
      scale_color_manual(values = c("black" = "black", "red" = "red", "blue" = "blue")) + 
      geom_hline(yintercept = -log(0.05,base=10), linetype="dashed", color="red") +
      geom_vline(xintercept = log(2,base=2), linetype="dashed", color="red") +
      geom_vline(xintercept = log(0.5,base=2), linetype="dashed", color="red") +
      theme_light() + theme(legend.position="none")
    saveWidget(ggplotly(g, tooltip="text"), file.path(gsub("\\.png", "\\.html", outplot_PE)))
    
    outplot_TE = paste(outdir,"/TE_volcano.png",sep="",collapse="");
    png(outplot_TE, width = 10, height = 10, units = 'in', res=300);
    # bitmap(outplot, "png16m");
    par(mfrow=c(1,1));
    
    plot(TE_df_logfold$LogFold, -log10(TE_pval),
         xlab="log2 fold change", ylab=volc_ylab,
         type="n")
    
    sel <- which((TE_df_logfold$LogFold<=log(2,base=2))&(TE_df_logfold$LogFold>=log(0.5, base=2))) # or whatever you want to use
    points(TE_df_logfold[sel,"LogFold"], -log10(TE_pval[sel]),col="black")
    TE_df_logfold$color <- "black"
    #sel <- which((TE_df_logfold$LogFold>log(2,base=2))&(TE_df_logfold$LogFold<log(0.5,base=2))) # or whatever you want to use
    sel <- which((TE_df_logfold$LogFold>log(2,base=2))|(TE_df_logfold$LogFold<log(0.5, base=2)))
    sel1 <- which(TE_pval<=0.05)
    sel=intersect(sel,sel1)
    points(TE_df_logfold[sel,"LogFold"], -log10(TE_pval[sel]),col="red")
    TE_df_logfold[sel,]$color <- "red"
    sel <- which((TE_df_logfold$LogFold>log(2,base=2))|(TE_df_logfold$LogFold<log(0.5, base=2)))
    sel1 <- which(TE_pval>0.05)
    sel=intersect(sel,sel1)
    points(TE_df_logfold[sel,"LogFold"], -log10(TE_pval[sel]),col="blue")
    TE_df_logfold[sel,]$color <- "blue"
    abline(h = -log(0.05,base=10), col="red", lty=2)
    abline(v = log(2,base=2), col="red", lty=2)
    abline(v = log(0.5,base=2), col="red", lty=2)
    dev.off();
    
    g <- ggplot(TE_df_logfold, aes(x = LogFold, -log10(TE_pval), color = as.factor(color),
          text=sprintf("Gene: %s<br>Log2 Fold-Change: %.3f<br>-log10 p-value: %.3f<br>p-value: %.3f",
                                                Genes, LogFold, -log10(TE_pval), TE_pval))) +
      xlab("log2 fold change") + ylab("-log10 p-value") + 
      geom_point(shape=1, size = 1.5, stroke = .2) +
      scale_color_manual(values = c("black" = "black", "red" = "red", "blue" = "blue")) + 
      geom_hline(yintercept = -log(0.05,base=10), linetype="dashed", color="red") +
      geom_vline(xintercept = log(2,base=2), linetype="dashed", color="red") +
      geom_vline(xintercept = log(0.5,base=2), linetype="dashed", color="red") +
      theme_light() + theme(legend.position="none")
    saveWidget(ggplotly(g, tooltip="text"), file.path(gsub("\\.png", "\\.html", outplot_TE)))
    
    
    cat('<br><table  border=1 cellspacing=0 cellpadding=5 style="table-layout:auto; "> <tr bgcolor="#7a0019"><th><font color=#ffcc33>Transcript Fold-Change</font></th><th><font color=#ffcc33>Protein Fold-Change</font></th></tr>\n', file = htmloutfile, append = TRUE);
    cat("<tr><td align=center>", 
        '<img src="TE_volcano.png" width=600 height=600>',
        extractWidgetCode(outplot_TE)$widget_div,
        '</td>\n', file = htmloutfile, append = TRUE);
    cat("<td align=center>",
        '<img src="PE_volcano.png" width=600 height=600>',
        extractWidgetCode(outplot_PE)$widget_div,
        '</td></tr></table><br>\n',
        file = htmloutfile, append = TRUE);
    
    
  }else{
    cat('<br><br><b><font color=red>!!! No replicates found. Cannot perform test to check significance of differential expression. Thus, no Volcano plot generated !!!</font></b><br><br>',
        file = htmloutfile, append = TRUE);
  }
  
}


#***************************************************************************************************************************************
# Functions: End
#***************************************************************************************************************************************


#===============================================================================
# Arguments
#===============================================================================
noargs = 12;
args = commandArgs(trailingOnly = TRUE);
if(length(args) != noargs)
{
  stop(paste("Please check usage. Number of arguments is not equal to ",noargs,sep="",collapse=""));
}

mode = args[1]; # "multiple" or "logfold"
method = args[2]; # "mean" or "median"
sampleinfo_file = args[3];
proteome_file = args[4];
transcriptome_file = args[5];
correction_method = args[6];
cookdist_upper_cutoff = args[7];
numCluster = args[8];
hm_nclust = args[9];
volc_with = args[10];

htmloutfile = args[11]; # html output file
outdir = args[12]; # html supporting files

#===============================================================================
# Check for file existance
#===============================================================================
if(! file.exists(proteome_file))
{
  stop(paste("Proteome Data file does not exists. Path given: ",proteome_file,sep="",collapse=""));
}
if(! file.exists(transcriptome_file))
{
  stop(paste("Transcriptome Data file does not exists. Path given: ",transcriptome_file,sep="",collapse=""));
}

#===============================================================================
# Load library
#===============================================================================
options(warn=-1);

suppressPackageStartupMessages(library(dplyr));
suppressPackageStartupMessages(library(data.table));
suppressPackageStartupMessages(library(gplots));
suppressPackageStartupMessages(library(ggplot2));
suppressPackageStartupMessages(library(ggfortify));
suppressPackageStartupMessages(library(plotly));
suppressPackageStartupMessages(library(d3heatmap));

#===============================================================================
# Select mode and parse experiment design file
#===============================================================================
if(mode=="multiple")
{
  expDesign = fread(sampleinfo_file, header = FALSE, stringsAsFactors = FALSE, sep="\t") %>% data.frame();
  expDesign_cc = expDesign[1:2,];
  
  sampleinfo_df = expDesign[3:nrow(expDesign),];
  rownames(sampleinfo_df)=1:nrow(sampleinfo_df);
  colnames(sampleinfo_df) =  c("Sample","Group");
  
  condition_cols = sampleinfo_df[which(sampleinfo_df[,2]==expDesign_cc[which(expDesign_cc[,1]=="case"),2]),1];
  condition_g_name = "case";
  control_cols = sampleinfo_df[which(sampleinfo_df[,2]==expDesign_cc[which(expDesign_cc[,1]=="control"),2]),1];
  control_g_name = "control";
  sampleinfo_df[which(sampleinfo_df[,2]==expDesign_cc[which(expDesign_cc[,1]=="case"),2]),2] = "case";
  sampleinfo_df[which(sampleinfo_df[,2]==expDesign_cc[which(expDesign_cc[,1]=="control"),2]),2] = "control";
  sampleinfo_df_orig = sampleinfo_df;
}

if(mode=="logfold")
{
  sampleinfo_df = data.frame("Sample"= c("LogFold"), "Group"=c("Fold_Change"))
}

#===============================================================================
# Parse Transcriptome data
#===============================================================================
TE_df_orig = fread(transcriptome_file, sep="\t", stringsAsFactor=F, header=T) %>% data.frame();
if(mode=="multiple")
{
  TE_df = TE_df_orig[,c(colnames(TE_df_orig)[1],condition_cols,control_cols)];
}
if(mode=="logfold")
{
  TE_df = TE_df_orig;
  colnames(TE_df) = c("Genes", "LogFold");
}
#===============================================================================
# Parse Proteome data
#===============================================================================
PE_df_orig = fread(proteome_file, sep="\t", stringsAsFactor=F, header=T) %>% data.frame();
if(mode=="multiple")
{
  PE_df = PE_df_orig[,c(colnames(PE_df_orig)[1],condition_cols,control_cols)];
}
if(mode=="logfold")
{
  PE_df = PE_df_orig;
  colnames(PE_df) = c("Genes", "LogFold");
}

#=============================================================================================================
# Create directory structures and then set the working directory to output directory
#=============================================================================================================
if(! file.exists(outdir))
{
  dir.create(outdir);
}
#===============================================================================
# Write initial data summary in html outfile
#===============================================================================
cat("<html><head></head><body>\n", file = htmloutfile);

cat("<h1><u>QuanTP: Association between abundance ratios of transcript and protein</u></h1><hr/>\n",
    "<font><h3>Input data summary</h3></font>\n",
    "<ul>\n",
    "<li>Abbreviations used: PE (Proteome data) and TE (Transcriptome data)","</li><br>\n",
    "<li>Input Proteome data dimension (Row Column): ", dim(PE_df)[1]," x ", dim(PE_df)[2],"</li>\n",
    "<li>Input Transcriptome data dimension (Row Column): ", dim(TE_df)[1]," x ", dim(TE_df)[2],"</li></ul><hr/>\n",
    file = htmloutfile, append = TRUE);

cat("<h3 id=table_of_content>Table of Contents:</h3>\n",
    "<ul>\n",
    "<li><a href=#sample_dist>Sample distribution</a></li>\n",
    "<li><a href=#corr_data>Correlation</a></li>\n",
    "<li><a href=#regression_data>Regression analysis</a></li>\n",
    "<li><a href=#inf_obs>Influential observations</a></li>\n",
    "<li><a href=#cluster_data>Cluster analysis</a></li></ul><hr/>\n",
    file = htmloutfile, append = TRUE);
#===============================================================================
# Find common samples
#===============================================================================
common_samples = intersect(sampleinfo_df[,1], colnames(TE_df)[-1]) %>% intersect(., colnames(PE_df)[-1]);

if(length(common_samples)==0)
{
  stop("No common samples found ");
  cat("<b>Please check your experiment design file. Sample names (column names) in the Transcriptome and the Proteome data do not match. </b>\n",file = htmloutfile, append = TRUE);
}

#===============================================================================
# Create subsets based on common samples
#===============================================================================
TE_df =  select(TE_df, 1, common_samples);
PE_df =  select(PE_df, 1, common_samples);
sampleinfo_df = filter(sampleinfo_df, Sample %in% common_samples);
rownames(sampleinfo_df) = sampleinfo_df[,1];

#===============================================================================
# Check for number of rows similarity
#===============================================================================
if(nrow(TE_df) != nrow(PE_df))
{
  stop("Number of rows in Transcriptome and Proteome data are not same i.e. they are not paired");
  cat("<b>The correlation analysis expects paired TE and PE data i.e. (i)th gene/transcript of TE file should correspond to (i)th protein of PE file. In the current input provided there is mismatch in terms of number of rows of TE and PE file. Please make sure you provide paired data.</b>\n",file = htmloutfile, append = TRUE);
}

#===============================================================================
# Number of groups
#===============================================================================
ngrps = unique(sampleinfo_df[,2]) %>% length();
grps = unique(sampleinfo_df[,2]);
names(grps) = grps;

#===============================================================================
# Change column1 name
#===============================================================================
colnames(TE_df)[1] = "Gene";
colnames(PE_df)[1] = "Protein";

#===============================================================================
# Treat missing values
#===============================================================================
TE_nacount = sum(is.na(TE_df));
PE_nacount = sum(is.na(PE_df));

TE_df[is.na(TE_df)] = 0;
PE_df[is.na(PE_df)] = 0;

#===============================================================================
# Obtain JS/HTML lines for interactive visualization
#===============================================================================
extractWidgetCode = function(outplot){
  lines <- readLines(gsub("\\.png", "\\.html", outplot))
  return(list(
    'prescripts'  = c('',
                      gsub('script', 'script',
                           lines[grep('<head>',lines) + 3
                                 :grep('</head>' ,lines) - 5]),
                      ''),
    'widget_div'  = paste('<!--',
                          gsub('width:100%;height:400px',
                               'width:500px;height:500px',
                               lines[grep(lines, pattern='html-widget')]),
                          '-->', sep=''),
    'postscripts' = paste('',
                          gsub('script', 'script',
                               lines[grep(lines, pattern='<script type')]),
                          '', sep='')));
}
prescripts <- list()
postscripts <- list()


#===============================================================================
# Decide based on analysis mode
#===============================================================================
if(mode=="logfold")
{
  cat('<h2 id="sample_dist"><font color=#ff0000>SAMPLE DISTRIBUTION</font></h2>\n',
      file = htmloutfile, append = TRUE);
  
  # TE Boxplot
  outplot = paste(outdir,"/Box_TE.png",sep="",collape="");
  multisample_boxplot(TE_df, sampleinfo_df, outplot, "Yes", "Samples", "Transcript Abundance data");
  lines <- extractWidgetCode(outplot)
  prescripts <- c(prescripts, lines$prescripts)
  postscripts <- c(postscripts, lines$postscripts)
  cat('<table border=1 cellspacing=0 cellpadding=5 style="table-layout:auto; ">\n',
      '<tr bgcolor="#7a0019"><th><font color=#ffcc33>Boxplot: Transcriptome data</font></th><th><font color=#ffcc33>Boxplot: Proteome data</font></th></tr>\n',
      "<tr><td align=center>", '<img src="Box_TE.png" width=500 height=500>', lines$widget_div, '</td>\n', file = htmloutfile, append = TRUE);
  
  # PE Boxplot
  outplot = paste(outdir,"/Box_PE.png",sep="",collape="");
  multisample_boxplot(PE_df, sampleinfo_df, outplot, "Yes", "Samples", "Protein Abundance data");
  lines <- extractWidgetCode(outplot)
  postscripts <- c(postscripts, lines$postscripts)
  cat("<td align=center>", '<img src="Box_PE.png" width=500 height=500>', lines$widget_div, 
      '</td></tr></table>\n', file = htmloutfile, append = TRUE);
  cat('<hr/><h2 id="corr_data"><font color=#ff0000>CORRELATION</font></h2>\n',
      file = htmloutfile, append = TRUE);
  
  # TE PE scatter
  PE_TE_data = data.frame(PE_df, TE_df);
  colnames(PE_TE_data) = c("PE_ID","PE_abundance","TE_ID","TE_abundance");
  outplot = paste(outdir,"/TE_PE_scatter.png",sep="",collape="");
  cat('<table border=1 cellspacing=0 cellpadding=5 style="table-layout:auto; "> <tr bgcolor="#7a0019"><th><font color=#ffcc33>Scatter plot between Proteome and Transcriptome Abundance</font></th></tr>\n', file = htmloutfile, append = TRUE);
  singlesample_scatter(PE_TE_data, outplot);  
  lines <- extractWidgetCode(outplot);
  postscripts <- c(postscripts, lines$postscripts);
  cat("<tr><td align=center>", '<img src="TE_PE_scatter.png" width=800 height=800>', gsub('width:500px;height:500px', 'width:800px;height:800px' , lines$widget_div), '</td></tr>\n', file = htmloutfile, append = TRUE);
  
  # TE PE Cor
  cat("<tr><td align=center>", file = htmloutfile, append = TRUE);
  singlesample_cor(PE_TE_data, htmloutfile, append=TRUE);
  cat('<font color="red">*Note that <u>correlation</u> is <u>sensitive to outliers</u> in the data. So it is important to analyze outliers/influential observations in the data.<br> Below we use <u>Cook\'s distance based approach</u> to identify such influential observations.</font>\n',
      file = htmloutfile, append = TRUE);
  cat('</td></table>',
      file = htmloutfile, append = TRUE);
  
  cat('<hr/><h2 id="regression_data"><font color=#ff0000>REGRESSION ANALYSIS</font></h2>\n',
      file = htmloutfile, append = TRUE);
  
  # TE PE Regression
  singlesample_regression(PE_TE_data,htmloutfile, append=TRUE);
  postscripts <- c(postscripts, c(extractWidgetCode(paste(outdir,"/PE_TE_lm_1.png",sep="",collapse=""))$postscripts,
                                  extractWidgetCode(paste(outdir,"/PE_TE_lm_2.png",sep="",collapse=""))$postscripts,
                                  extractWidgetCode(paste(outdir,"/PE_TE_lm_5.png",sep="",collapse=""))$postscripts,
                                  extractWidgetCode(paste(outdir,"/PE_TE_lm_cooksd.png",sep="",collapse=""))$postscripts,
                                  extractWidgetCode(paste(outdir,"/AbundancePlot_scatter_without_outliers.png",sep="",collapse=""))$postscripts,
                                  gsub('data-for="html', 'data-for="secondhtml"', 
                                       extractWidgetCode(paste(outdir,"/TE_PE_scatter.png",sep="",collapse=""))$postscripts)))
  
  cat('<hr/><h2 id="cluster_data"><font color=#ff0000>CLUSTER ANALYSIS</font></h2>\n',
      file = htmloutfile, append = TRUE);
  
  # TE PE Heatmap
  singlesample_heatmap(PE_TE_data, htmloutfile, hm_nclust);
  lines <- extractWidgetCode(paste(outdir,"/PE_TE_heatmap.png",sep="",collapse=""))
  postscripts <- c(postscripts, lines$postscripts)
  prescripts <- c(prescripts, lines$prescripts)
  
  
  # TE PE Clustering (kmeans)
  singlesample_kmeans(PE_TE_data, htmloutfile, nclust=as.numeric(numCluster))
  postscripts <- c(postscripts, extractWidgetCode(paste(outdir,"/PE_TE_kmeans.png",sep="",collapse=""))$postscripts)
  
}else{
  if(mode=="multiple")
  {
    cat('<h2 id="sample_dist"><font color=#ff0000>SAMPLE DISTRIBUTION</font></h2>\n',
        file = htmloutfile, append = TRUE);
    
    # TE Boxplot
    outplot = paste(outdir,"/Box_TE_all_rep.png",sep="",collape="");
    temp_df_te_data = data.frame(TE_df[,1], log(TE_df[,2:length(TE_df)]));
    colnames(temp_df_te_data) = colnames(TE_df);
    multisample_boxplot(temp_df_te_data, sampleinfo_df, outplot, "Yes", "Samples", "Transcript Abundance (log)");
    lines <- extractWidgetCode(outplot)
    prescripts <- c(prescripts, lines$prescripts)
    postscripts <- c(postscripts, lines$postscripts)
    cat('<table  border=1 cellspacing=0 cellpadding=5 style="table-layout:auto; ">\n',
        '<tr bgcolor="#7a0019"><th><font color=#ffcc33>Boxplot: Transcriptome data</font></th><th><font color=#ffcc33>Boxplot: Proteome data</font></th></tr>\n',
        "<tr><td align=center>", file = htmloutfile, append = TRUE);
    cat('<img src="Box_TE_all_rep.png" width=500 height=500>', 
        lines$widget_div, '</td>', file = htmloutfile, append = TRUE);
    
    # PE Boxplot
    outplot = paste(outdir,"/Box_PE_all_rep.png",sep="",collape="");
    temp_df_pe_data = data.frame(PE_df[,1], log(PE_df[,2:length(PE_df)]));
    colnames(temp_df_pe_data) = colnames(PE_df);
    multisample_boxplot(temp_df_pe_data, sampleinfo_df, outplot, "Yes", "Samples", "Protein Abundance (log)");
    lines <- extractWidgetCode(outplot)
    #prescripts <- c(prescripts, lines$prescripts)
    postscripts <- c(postscripts, lines$postscripts)
    cat("<td align=center>", '<img src="Box_PE_all_rep.png" width=500 height=500>',
        lines$widget_div, '</td></tr></table>\n', file = htmloutfile, append = TRUE);
    
    # Calc TE PCA
    outplot = paste(outdir,"/PCA_TE_all_rep.png",sep="",collape="");
    multisample_PCA(TE_df, sampleinfo_df, outplot);
    PCA_TE <- extractWidgetCode(outplot)
    postscripts <- c(postscripts, PCA_TE$postscripts)
    
    # Calc PE PCA
    outplot = paste(outdir,"/PCA_PE_all_rep.png",sep="",collape="");
    multisample_PCA(PE_df, sampleinfo_df, outplot);
    PCA_PE <- extractWidgetCode(outplot)
    postscripts <- c(postscripts, PCA_PE$postscripts)
    
    # Replicate mode
    templist = mergeReplicates(TE_df,PE_df, sampleinfo_df, method);
    TE_df = templist$TE_df_merged;
    PE_df = templist$PE_df_merged;
    sampleinfo_df = templist$sampleinfo_df_merged;
    rownames(sampleinfo_df) = sampleinfo_df[,1];
    
    # TE Boxplot
    outplot = paste(outdir,"/Box_TE_rep.png",sep="",collape="");
    temp_df_te_data = data.frame(TE_df[,1], log(TE_df[,2:length(TE_df)]));
    colnames(temp_df_te_data) = colnames(TE_df);
    multisample_boxplot(temp_df_te_data, sampleinfo_df, outplot, "No", "Sample Groups", "Mean Transcript Abundance (log)");
    lines <- extractWidgetCode(outplot)
    #prescripts <- c(prescripts, lines$prescripts)
    postscripts <- c(postscripts, lines$postscripts)
    cat('<br><font color="#ff0000"><h3>Sample wise distribution (Box plot) after using ',method,' on replicates </h3></font><table border=1 cellspacing=0 cellpadding=5 style="table-layout:auto; "> <tr bgcolor="#7a0019"><th><font color=#ffcc33>Boxplot: Transcriptome data</font></th><th><font color=#ffcc33>Boxplot: Proteome data</font></th></tr>\n',
        "<tr><td align=center>", '<img src="Box_TE_rep.png" width=500 height=500>', lines$widget_div, '</td>\n', file = htmloutfile, append = TRUE);
    
    # PE Boxplot
    outplot = paste(outdir,"/Box_PE_rep.png",sep="",collape="");
    temp_df_pe_data = data.frame(PE_df[,1], log(PE_df[,2:length(PE_df)]));
    colnames(temp_df_pe_data) = colnames(PE_df);
    multisample_boxplot(temp_df_pe_data, sampleinfo_df, outplot, "No", "Sample Groups", "Mean Protein Abundance (log)");
    lines <- extractWidgetCode(outplot)
    #prescripts <- c(prescripts, lines$prescripts)
    postscripts <- c(postscripts, lines$postscripts)
    cat("<td align=center>", '<img src="Box_PE_rep.png" width=500 height=500>', lines$widget_div, '</td></tr></table>\n', file = htmloutfile, append = TRUE);
    
    #===============================================================================
    # Calculating log fold change and running the "single" code part 
    #===============================================================================
    
    TE_df = data.frame("Genes"=TE_df[,1], "LogFold"=apply(TE_df[,c(which(colnames(TE_df)==condition_g_name),which(colnames(TE_df)==control_g_name))],1,function(x) log(x[1]/x[2],base=2)));
    PE_df = data.frame("Genes"=PE_df[,1], "LogFold"=apply(PE_df[,c(which(colnames(PE_df)==condition_g_name),which(colnames(PE_df)==control_g_name))],1,function(x) log(x[1]/x[2],base=2)));
    
    #===============================================================================
    # Treat missing values
    #===============================================================================
    
    TE_df[is.infinite(TE_df[,2]),2] = NA;
    PE_df[is.infinite(PE_df[,2]),2] = NA;
    TE_df[is.na(TE_df)] = 0;
    PE_df[is.na(PE_df)] = 0;
    
    sampleinfo_df = data.frame("Sample"= c("LogFold"), "Group"=c("Fold_Change"))
    #===============================================================================
    # Find common samples
    #===============================================================================
    
    common_samples = intersect(sampleinfo_df[,1], colnames(TE_df)[-1]) %>% intersect(., colnames(PE_df)[-1]);
    TE_df =  select(TE_df, 1, common_samples);
    PE_df =  select(PE_df, 1, common_samples);
    sampleinfo_df = filter(sampleinfo_df, Sample %in% common_samples);
    rownames(sampleinfo_df) = sampleinfo_df[,1];
    
    # TE Boxplot
    outplot = paste(outdir,"/Box_TE.png",sep="",collape="");
    multisample_boxplot(TE_df, sampleinfo_df, outplot, "Yes", "Sample (log2(case/control))", "Transcript Abundance fold-change (log2)");
    lines <- extractWidgetCode(outplot)
    postscripts <- c(postscripts, lines$postscripts)
    cat('<br><font color="#ff0000"><h3>Distribution (Box plot) of log fold change </h3></font>', file = htmloutfile, append = TRUE);
    cat('<table border=1 cellspacing=0 cellpadding=5 style="table-layout:auto; "> <tr bgcolor="#7a0019"><th><font color=#ffcc33>Boxplot: Transcriptome data</font></th><th><font color=#ffcc33>Boxplot: Proteome data</font></th></tr>\n',
        "<tr><td align=center>", '<img src="Box_TE.png" width=500 height=500>', lines$widget_div, '</td>\n', file = htmloutfile, append = TRUE);
    
    # PE Boxplot
    outplot = paste(outdir,"/Box_PE.png",sep="",collape="");
    multisample_boxplot(PE_df, sampleinfo_df, outplot, "Yes", "Sample (log2(case/control))", "Protein Abundance fold-change(log2)");
    lines <- extractWidgetCode(outplot)
    postscripts <- c(postscripts, lines$postscripts)
    cat("<td align=center>", '<img src="Box_PE.png" width=500 height=500>', lines$widget_div,'</td></tr></table>\n', file = htmloutfile, append = TRUE);
    
    
    # Log Fold Data
    perform_Test_Volcano(TE_df_orig,PE_df_orig,TE_df, PE_df,sampleinfo_df_orig,method,correction_method,volc_with)
    postscripts <- c(postscripts, extractWidgetCode(paste(outdir,"/TE_volcano.png",sep="",collapse=""))$postscripts)
    postscripts <- c(postscripts, extractWidgetCode(paste(outdir,"/PE_volcano.png",sep="",collapse=""))$postscripts)
    
    # Print PCA
    
    cat('<br><br><table  border=1 cellspacing=0 cellpadding=5 style="table-layout:auto; "> <tr bgcolor="#7a0019"><th><font color=#ffcc33>PCA plot: Transcriptome data</font></th><th><font color=#ffcc33>PCA plot: Proteome data</font></th></tr>\n',
        "<tr><td align=center>", '<img src="PCA_TE_all_rep.png" width=500 height=500>', PCA_TE$widget_div, '</td>\n',
        "<td align=center>", '<img src="PCA_PE_all_rep.png" width=500 height=500>', PCA_PE$widget_div, '</td></tr></table>\n', 
        file = htmloutfile, append = TRUE);
    
    
    
    cat('<hr/><h2 id="corr_data"><font color=#ff0000>CORRELATION</font></h2>\n',
        file = htmloutfile, append = TRUE);
    
    PE_TE_data = data.frame(PE_df, TE_df);
    colnames(PE_TE_data) = c("PE_ID","PE_abundance","TE_ID","TE_abundance");
    
    # TE PE scatter
    outplot = paste(outdir,"/TE_PE_scatter.png",sep="",collape="");
    cat('<br><table border=1 cellspacing=0 cellpadding=5 style="table-layout:auto; "> <tr bgcolor="#7a0019"><th><font color=#ffcc33>Scatter plot between Proteome and Transcriptome Abundance</font></th></tr>\n', file = htmloutfile, append = TRUE);
    singlesample_scatter(PE_TE_data, outplot);  
    lines <- extractWidgetCode(outplot);
    postscripts <- c(postscripts, lines$postscripts);  
    cat("<tr><td align=center>", '<img src="TE_PE_scatter.png" width=800 height=800>', gsub('width:500px;height:500px', 'width:800px;height:800px' , lines$widget_div),
        '</td>\n', file = htmloutfile, append = TRUE);
    
    # TE PE Cor
    cat("<tr><td align=center>\n", file = htmloutfile, append = TRUE);
    singlesample_cor(PE_TE_data, htmloutfile, append=TRUE);
    cat('<font color="red">*Note that <u>correlation</u> is <u>sensitive to outliers</u> in the data. So it is important to analyze outliers/influential observations in the data.<br> Below we use <u>Cook\'s distance based approach</u> to identify such influential observations.</font>\n',
        file = htmloutfile, append = TRUE);
    cat('</td></table>',
        file = htmloutfile, append = TRUE);
    
    cat('<hr/><h2 id="regression_data"><font color=#ff0000>REGRESSION ANALYSIS</font></h2>\n',
        file = htmloutfile, append = TRUE);
    
    # TE PE Regression
    singlesample_regression(PE_TE_data,htmloutfile, append=TRUE);
    postscripts <- c(postscripts, c(extractWidgetCode(paste(outdir,"/PE_TE_lm_1.png",sep="",collapse=""))$postscripts,
                                    extractWidgetCode(paste(outdir,"/PE_TE_lm_2.png",sep="",collapse=""))$postscripts,
                                    extractWidgetCode(paste(outdir,"/PE_TE_lm_5.png",sep="",collapse=""))$postscripts,
                                    extractWidgetCode(paste(outdir,"/PE_TE_lm_cooksd.png",sep="",collapse=""))$postscripts,
                                    extractWidgetCode(paste(outdir,"/AbundancePlot_scatter_without_outliers.png",sep="",collapse=""))$postscripts,
                                    gsub('data-for="html', 'data-for="secondhtml"', 
                                         extractWidgetCode(paste(outdir,"/TE_PE_scatter.png",sep="",collapse=""))$postscripts)));
    
    cat('<hr/><h2 id="cluster_data"><font color=#ff0000>CLUSTER ANALYSIS</font></h2>\n',
        file = htmloutfile, append = TRUE);
    
    #TE PE Heatmap
    singlesample_heatmap(PE_TE_data, htmloutfile, hm_nclust);
    lines <- extractWidgetCode(paste(outdir,"/PE_TE_heatmap.png",sep="",collapse=""))
    postscripts <- c(postscripts, lines$postscripts)
    prescripts <- c(prescripts, lines$prescripts)
    
    #TE PE Clustering (kmeans)
    singlesample_kmeans(PE_TE_data, htmloutfile, nclust=as.numeric(numCluster))
    postscripts <- c(postscripts, extractWidgetCode(paste(outdir,"/PE_TE_kmeans.png",sep="",collapse=""))$postscripts);
  }
}
cat("<h3>Go To:</h3>\n",
    "<ul>\n",
    "<li><a href=#sample_dist>Sample distribution</a></li>\n",
    "<li><a href=#corr_data>Correlation</a></li>\n",
    "<li><a href=#regression_data>Regression analysis</a></li>\n",
    "<li><a href=#inf_obs>Influential observations</a></li>\n",
    "<li><a href=#cluster_data>Cluster analysis</a></li></ul>\n",
    "<br><a href=#>TOP</a>",
    file = htmloutfile, append = TRUE);
cat("</body></html>\n", file = htmloutfile, append = TRUE);


#===============================================================================
# Add masked-javascripts tags to HTML file in the head and end
#===============================================================================

htmllines <- readLines(htmloutfile)
htmllines[1] <- paste('<html>\n<head>\n', paste(prescripts, collapse='\n'), '\n</head>\n<body>')
cat(paste(htmllines, collapse='\n'), file = htmloutfile)
cat('\n', paste(postscripts, collapse='\n'), "\n",
    "</body>\n</html>\n", file = htmloutfile, append = TRUE);
