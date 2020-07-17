# benzene_mapping
Implementation instructions for a benzene mapping method for uncovering cryptic pockets in membrane-bound proteins.

## Overview
This file explains how to set up simulations for detecting cryptic pockets in your proteins of interest, especially if they are membrane-bound. It has been tested for simulations performed in Gromacs with charmm36 force field, with modified benzene probes and membranes composed out of POPC, POPE, and POPS lipids. The same methodology, however, is generally applicable to different probes, lipid types and force fields (but it requires preliminary testing). 

## Citing
If you use this method, please cite: 
Zuzic, L., Marzinek, J. K., Warwicker, J., Bond, P. J. (2020)
A benzene-mapping approach for uncovering cryptic pockets in membrane-bound proteins. Under review.

## Force field modification

## Benzene probes
A coordinate file of a benzene probe with a central virtual site can be found in benzene_vs.pdb. To insert a desired number of benzene molecules (e.g. 50) into a simulation box, use:
gmx insert-molecules -f protein.gro -ci benzene_vs.pdb -nmol 50 -scale 0.9 -o protein_50bnz.gro


## To upload:
benzene_vs.pdb
