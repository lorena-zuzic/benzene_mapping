#!/usr/bin/Rscript
if (!require("stringr")) install.packages("stringr")
if (!require("gtools")) install.packages("gtools")
library(stringr)
library(gtools)
################################
# This is a script that can be used to modify force field files with new atom types. It finds old atoms in the file,
# copies them and changes the next line into a new atom type. Lines that contain more than one occurence of the pattern
# are treated specially - all permutations are explored.
# Usage: Rscript --vanilla atom_modification_in_ff.R inputfile old.atom new.atom

# If the script does not work, make sure that stringr and gtools packages are installed correctly.
################################

# Reading argument as an input file
arguments <- commandArgs(trailingOnly = T)
file.to.modify <- arguments[1]
old.atom <- arguments[2]
new.atom <- arguments[3]
inputfile <- readLines(file.to.modify)


# Number of pattern matches per line
pattern.match.per.line <- str_count(string = inputfile, pattern = old.atom)
for (z in 1:length(pattern.match.per.line)){
  if (pattern.match.per.line[z] > 0){
    line <- inputfile[z]

    #Check if line contains dihedrals and is symmetrical. If yes, remove some of the permutations.
    splitted <- unlist(strsplit(line, split = " "))
    splitted <- splitted[splitted != ""]
    splitted <- splitted[grep(pattern = "[A-z]", x = splitted)]
    # Permutations. r is equal to pattern.match.per.line
    permut <- permutations(n = 2, r = pattern.match.per.line[z], v = c(old.atom, new.atom), repeats.allowed = T) 
    if ((length(splitted) == 4) & identical(splitted, rev(splitted))){
      l <- 1
      while (l < ((nrow(permut)-1))){
         l <- l + 1
         to.delete <- !(sapply(1:nrow(permut), function(m) identical(rev(permut[l, ]), permut[m, ])))
         if (to.delete[l] == F){
           to.delete[l] <- T
         }
         permut <- permut[to.delete, ]
       }
    }
    
    # Copy the line n times, where n is the number of permutations (nrow(permut))
    repeated.line <- paste(replicate(nrow(permut), line), collapse = "\n")
    # Location of atoms in the string that have to be replaced
    loc <- as.data.frame(str_locate_all(pattern = old.atom, string = repeated.line))
    # Replace
    k <- 0
    for (j in 1:nrow(permut)){
      for (i in 1:ncol(permut)){
        k <- k + 1
        substring(repeated.line, loc$start[k], loc$end[k]) <- permut[j,i]
      }
    }
    inputfile[z] <- repeated.line
  }
}


# Reorder lines so that all dihedral types are written in the same line.
write(x = inputfile, file = "temporary.txt")
inputfile <- readLines("temporary.txt")

relevant.index <- grep(pattern = "\\[ dihedraltypes \\]", x = inputfile)
# Condition that skips this section if it does not contain dihedrals
if (length(relevant.index)>1){
  relevant.section <- inputfile[relevant.index[1]:(relevant.index[2]-1)]
  relevant.section <- substring(relevant.section, first = 1, last = 41)
  for (i in 1:(length(relevant.section))){
    matching <- which(relevant.section[i] == relevant.section)
    if ((length(matching) > 1) & !(identical(seq(from = matching[1], to = matching[length(matching)], by = 1), matching))){
      must.sort <- which(relevant.section[i] == relevant.section)
      # Reorder elements in vector according to must.sort. Number of matching elements is > 1
      for (j in 2:length(must.sort)){
        inputfile <- inputfile[c( (1:(must.sort[1]+relevant.index[1]-1+j-2)),
                                 (must.sort[j]+relevant.index[1]-1),
                                 ((must.sort[1]+relevant.index[1]+j-2):length(inputfile)) )]
        inputfile <- inputfile[-(must.sort[j]+relevant.index[1])]
      }
      relevant.section <- inputfile[relevant.index[1]:(relevant.index[2]-1)]
      relevant.section <- substring(relevant.section, first = 1, last = 41)
    }  
  }
}

# Writing output
outputfile <- paste(sub("\\..*", "", file.to.modify), "_modified.itp", sep = "")
write(x = inputfile, file = outputfile)
cat(paste("File", outputfile, "successfully created!\n", sep = " "))
cat(paste("Number of ", old.atom, " atoms:\n", sep = ""))
system(paste("grep -i '", old.atom, "' ", outputfile, " | wc -l", sep = ""))
cat(paste("Number of ", new.atom, " atoms:\n", sep = ""))
system(paste("grep -i '", new.atom, "' ", outputfile, " | wc -l", sep = ""))
system("rm temporary.txt")
