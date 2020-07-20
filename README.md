# benzene_mapping
Implementation instructions for a benzene mapping method for uncovering cryptic pockets in membrane-bound proteins.

## Overview
This file explains how to set up simulations for detecting cryptic pockets in your proteins of interest, especially if they are membrane-bound. It has been tested for simulations performed in Gromacs with charmm36 force field, with modified benzene probes and membranes composed out of POPC, POPE, and POPS lipids. The same methodology, however, is generally applicable to different probes, lipid types and force fields (but it requires preliminary testing). 

## Citation
If you use this method, please cite: 
Zuzic, L., Marzinek, J. K., Warwicker, J., Bond, P. J. (2020)
A benzene-mapping approach for uncovering cryptic pockets in membrane-bound proteins. Under review.

## 1) Force field modification
First, we need to modify our force field to include: 

a) benzene molecule with a central virtual site in the .rtp file

b) a virtual site defined as an atom type

c) a new atom type that will be present only in lipids and will act as a repulsion point

d) modified lipids that contain a new atom type

e) repulsions between benzene virtual sites

f) repulsions between lipids and benzene virtual sites

### 1a) benzene molecule with a central virtual site in the .rtp file

Add bnzv.rtp in the force field folder. It will be read in addition to an already present merged.rtp file. Gromacs will recognise benzene under the name BNZV (denoting BeNZene + Virtual site).

### 1b) a virtual site defined as an atom type



Don't forget to place this modified force field in the same folder where you will be creating your simulation system.

## 2) Benzene probes
A coordinate file of a benzene probe with a central virtual site can be found in benzene_vs.pdb. To insert a desired number of benzene molecules (e.g. 50) into a simulation box, use:

gmx insert-molecules -f protein.gro -ci benzene_vs.pdb -nmol 50 -scale 0.9 -o protein_50bnz.gro

Make sure that the benzenes are not embedded in the membrane or in the protein interior!

Next, we need to generate a benzene topology .itp file which will contain information for all benzenes in a system (treated as a single molecule). The reason for this is for us to be able to add exclusions into the topology file.

echo "BNZV" | gmx editconf -f protein_50bnzv.gro -n index.ndx -o 50bnzv.gro 

echo "1 1" | gmx pdb2gmx -f 50bnzv.gro -p Benzene_50.top -i posre_Benzene_50.itp -o 50bnzv.gro

We need to edit Benzene_50.top topology file by excluding forcefiled parameters (these should be specified in a main topology file), water and ion parameters, and [ system ] and [ molecules ] sections. We also need to include [ virtual_sitesn ] and [ exclusions ]. 

To generate virtual sites, use a vs_gen.py script:

python vs_gen.py 50

Copy script output and insert it into Benzene_50.top file.

To generate exclusions, use exclusions_scr.R script. Note, this step might take a while.

Rscript exclusions_scr.R 50

Copy script output and insert it into Benzene_50.top file.

Finally, don't forget to include Benzene_50.top into your main topology file (topol.top).



## 3) 

## To upload:
benzene_vs.pdb
vs_gen.py
exclusions_scr.R 
bnzv.rtp
