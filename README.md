# benzene_mapping
Implementation instructions for a benzene mapping method for uncovering cryptic pockets in membrane-bound proteins.

## Overview
This file explains how to set up simulations for detecting cryptic pockets in your proteins of interest, especially if they are membrane-bound. It has been tested for simulations performed in Gromacs with charmm36 force field, with modified benzene probes and membranes composed out of POPC, POPE, and POPS lipids. The same methodology, however, is generally applicable to different probes, lipid types and force fields (but it requires preliminary testing). 

## Citing
If you use this method, please cite: 
Zuzic, L., Marzinek, J. K., Warwicker, J., Bond, P. J. (2020)
A benzene-mapping approach for uncovering cryptic pockets in membrane-bound proteins. Under review.

## 1) Force field modification
First, we need to modify our force field to include a) repulsions between benzene virtual sites; b) new atom type that has all the 

## 2) Benzene probes
A coordinate file of a benzene probe with a central virtual site can be found in benzene_vs.pdb. To insert a desired number of benzene molecules (e.g. 50) into a simulation box, use:

gmx insert-molecules -f protein.gro -ci benzene_vs.pdb -nmol 50 -scale 0.9 -o protein_50bnz.gro

Make sure that the benzenes are not embedded in the membrane or in the protein interior!

Next, we need to generate a benzene topology .itp file which will contain information for all benzenes in a system (treated as a single molecule). The reason for this is for us to be able to add exclusions into the topology file.

echo "q" | gmx make_ndx -f protein_50bnzv.gro -o index.ndx

echo "BNZV" | gmx editconf -f protein_50bnzv.gro -n index.ndx -o 50bnzv.gro 

echo "1 1" | gmx pdb2gmx -f 50bnzv.gro -p Benzene_1.itp -i posre_Benzene_50.itp -o 50bnzv.gro




## 3) 

## To upload:
benzene_vs.pdb
