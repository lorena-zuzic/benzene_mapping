#!/usr/bin/Rscript

########
# Usage: (if we have 50 benzenes in a system)
# Rscript exclusions_scr.R 50
########

# Read number of benzenes from the command line
nbnzv <- as.numeric(commandArgs(trailingOnly = T))
# Total number of benzene atoms
atms <- nbnzv*13

# Benzene atoms without the virtual site
no_vs <- 1:atms
no_vs <- no_vs[which(no_vs %% 13 != 0)]

# Write a first file line
cat("[ exclusions ]\n")

# Split string if it exceeds 1001 values per line
max.length <- 1000

# curr is a benzene atom for which exclusions are generated 
for (curr in no_vs[1:(length(no_vs)-12)]){
   # Start exclusions from the benzene molecule one higher than curr
   start <- (trunc(curr/13) + 1)*13 + 1
   # All exclusions per curr
   excl.atoms <- no_vs[which(no_vs == start):length(no_vs)]
   line.length <- length(excl.atoms)
   # Functions splitting the string if they exceed max.length
   breaks <- trunc(line.length/max.length) + 1
      if (breaks == 1){
         res <- c(curr, excl.atoms)
	       cat(res, "\n")
      }else{
         for (i in 1:breaks){
           if (i == 1){
             res <- c(curr, excl.atoms[1:max.length])
             cat(res, "\n")
           }else if (i != breaks){
             res <- c(curr, excl.atoms[(max.length*(i-1)+1):(max.length*i)])
             cat(res, "\n")
           }else if (i == breaks){
             res <- c(curr, excl.atoms[(max.length*(i-1)+1):length(excl.atoms)])
             cat(res, "\n")
           } #if else
         } #for loop
         
      } # if else
} # for loop
