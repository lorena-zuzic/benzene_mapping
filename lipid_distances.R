#!/usr/bin/Rscript

# CREATING VORONOI PLOT FOR LIPID LEAFLETS
# Assumptions: 
# 1) membrane is not curved and all atoms are in the same xy-plane
# 1.5) membrane is a bilayer
# 2) lipid layer is continouous - there is no protein inserted in the bilayer
# 3) .gro file contains x and y coordinates in columns 4 and 5
# 4) Gromacs installed and functioning
# 5) R with deldir package intsalled and functioning
if (!require("deldir")) install.packages("deldir")
suppressMessages(library(deldir))
args <- commandArgs(trailingOnly = TRUE)
picosecond <- as.numeric(regmatches(args[1], gregexpr("[[:digit:]]+", args[1])))
leaflet <- args[2]
plotfile <- args[3]

P.atoms <- read.table(args[1], stringsAsFactors = F)

P.atoms <- P.atoms[ ,c(4,5)]
colnames(P.atoms) <- c("x", "y")

# Create Voronoi data points
data <- deldir(P.atoms, suppressMsge = T)

# Plotting Voronoi areas
pdf(plotfile, width=6, height=6, paper='special')
plot(data, main = paste("Lipid Voronoi areas (",  leaflet, " leaflet)", sep = ""),
     sub = paste(picosecond/1000, " ns", sep = ""))
garbage <- dev.off()

# Calculating distances between neighbours
distance <- apply(data$delsgs, 1, function(x) sqrt((x[3]-x[1])^2+(x[4]-x[2])^2))
data$delsgs$distance <- distance

# Average neighbour lipid distance
avg.distance <- sum(data$delsgs$distance)/nrow(data$delsgs)

# Maximum neighbour lipid distance
max.distances <- data.frame(lipid=as.numeric(), max_neighbour_distance = as.numeric())
for (i in 1:nrow(P.atoms)){
  distances.per.lipid <- data$delsgs[(data$delsgs$ind1 == i | data$delsgs$ind2 == i), ]  
  max.distance.per.lipid <- max(distances.per.lipid$distance)
  max.distances <- rbind(max.distances, c(i, max.distance.per.lipid))
}
colnames(max.distances) <- c("lipid", "max_neighbour_distance") 

# Remove edge points - information is stored in $disrsgs$bp1 and $bp2 - true means that it is a border lipid
border.points <- union(data$dirsgs$ind1[data$dirsgs$bp1], data$dirsgs$ind2[data$dirsgs$bp2])
is.border.lipid <- unlist(lapply(max.distances$lipid, function(x) sum(x==border.points)>0))
max.distances$is_border_lipid <- is.border.lipid

# Calculate average max.distances without edge points, including standard deviation
avg.max.distance <- mean(max.distances$max_neighbour_distance[!max.distances$is_border_lipid])
se <- function(x) sd(x)/sqrt(length(x))
se.max.distance <- se(max.distances$max_neighbour_distance[!max.distances$is_border_lipid])

if ((length(picosecond) != 1) | (length(avg.max.distance) != 1) | (length(se.max.distance) != 1)){
  stop("Maximum neighbour distance calculation encountered an error. Check the validity of your input files!")
}
cat(c(picosecond, avg.max.distance, se.max.distance), "\n")

