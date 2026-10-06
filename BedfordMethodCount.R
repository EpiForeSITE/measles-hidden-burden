# Using sourced functions to read log and get times
source("plotEBSP.R")
df1 <- removeBurnin(read.table("EBSP.log", header=T, sep='\t', as.is=T), 0.1)
res <- processEBSPdata(df1, T)
target_dates <- seq(from = min(res$allTimes), 
                    to = max(res$allTimes), 
                    by = generation_time)
sampled_data_all <- data.frame(date = target_dates)

R0s <- c(5:18)
for (R in R0s) {
  res_2 <- processEBSPdata(df1, T)
  
  # Get and format dates
  MRSD_date <- as.Date("2026-02-28")
  res_2$allYears <- as.numeric(format(MRSD_date, "%Y")) - res_2$allTimes
  res_2$allCalendarDates <- MRSD_date - (res_2$allTimes*365.25)
  
  # Point Prevalence
  sigma <- (1/R)+(1/0.34)+1
  generation_time <- 11.9/365 # pulled from average time from rash onset to secondary case
  factor <- sigma/generation_time
  res_2$Nmedian <- res_2$Nmedian*factor
  res_2$NlowerCPD <- res_2$NlowerCPD*factor
  res_2$NupperCPD <- res_2$NupperCPD*factor
  
  df <- data.frame("date" = res_2$allTimes , "prevalence_med" = res_2$Nmedian, "prevalence_low" = res_2$NlowerCPD, "prevalence_high" = res_2$NupperCPD)
  
  get_median_prevalence <- function(target_time, df, col_name) {
    window_values <- df[[col_name]][df$date >= (target_time - 0.015) & 
                                      df$date <= (target_time + 0.015)]
    return(max(window_values, na.rm = TRUE))
  }
  
  target_dates <- seq(from = min(df$date), to = max(df$date), by = generation_time)
  prev_cols <- setdiff(names(df), "date")
  
  sampled_data <- data.frame(date = target_dates)
  
  for (col in prev_cols) {
    results <- numeric(length(target_dates))
    for (i in 1:length(target_dates)) {
      results[i] <- get_median_prevalence(target_dates[i], df, col)
    }
    results[results == -Inf] <- 0
    sampled_data[[col]] <- results
    sampled_data[[paste0(col, "_total")]] <- cumsum(results)
  }
  
  sampled_data_all[[paste0("med_total_",R)]] <- sampled_data$prevalence_med_total
  sampled_data_all[[paste0("low_total_",R)]] <- sampled_data$prevalence_low_total
  sampled_data_all[[paste0("high_total_",R)]] <- sampled_data$prevalence_high_total
  
}