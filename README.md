# benzene_mapping
Implementation instructions for a benzene mapping method for uncovering cryptic pockets in membrane-bound proteins.

## Overview
This file contains instructions how to set up simulations for detecting cryptic pockets in proteins of interest, particularly if they are membrane-bound. The method has been tested for simulations performed in Gromacs with charmm36 force field, with modified benzene probes and membranes composed out of POPC, POPE, and POPS lipids. The same methodology is generally applicable for different probes, lipid types and force fields (but it requires additional testing). 

## Citation
If you use this method, please cite: 
Zuzic, L., Marzinek, J. K., Warwicker, J., Bond, P. J. (2020)
A benzene-mapping approach for uncovering cryptic pockets in membrane-bound proteins. Under review.

## 1) Force field modification
First, we need to modify our force field to include: 

a) a benzene topology with a central virtual site in the .rtp file

b) a virtual site (VS) defined as an atom type

c) a new atom type that will act as a lipid repulsion point

d) modified lipids that contain a new atom type

e) repulsions between benzene virtual sites

f) repulsions between lipid repulsion points and benzene virtual sites

### 1a) a benzene topology with a central virtual site in the .rtp file

Add bnzv.rtp into the force field folder. It will be read in addition to the already present merged.rtp file. Benzene will be recognised under the name BNZV (denoting BeNZene with a Virtual site).

### 1b) a virtual site (VS) defined as an atom type
Add the line in the atomtypes.atp file:

VS          0.000000      ; Virtual site for BNZV

### 1c) a new atom type that will act as a repulsion point

A choice of a lipid repulsion point is a critical step which ensures that benzene remains outside the simulated membrane. This method has been verified for repulsion points placed on OSL or PL atom types of membrane lipids. However, if these atoms are not present in your lipid system, you will have to choose another atom that appears in all membrane components. If this is the case, testing benzene behaviour in the presence of a smaller membrane is a necessity! We will use OSL atoms as our repulsion points because they are present in POPC, POPE, and POPS lipids as O21/O31 oxygen atoms (for details, see Zuzic et al. 2020). The new atom type is called ODM.

Add the line in the atomtypes.atp file:

ODM     15.99940 ; ester oxygen - acting as a repulsion site

Use the atom_modification_in_ff.R script on ffbonded.itp and ffnonbonded.itp files:

Rscript atom_modification_in_ff.R ffbonded.itp OSL ODM

Rscript atom_modification_in_ff.R ffnonbonded.itp OSL ODM

Outputs are modified force field files ffbonded_modified.itp and ffnonbonded_modified.itp. If satisfied with the results, rename those files into ffbonded.itp and ffnonbonded.itp. The old files will be overwritten.

### 1d) modified lipids that contain a new atom type

Add pop_modified.rtp into the force field folder. If not using ODL as a point of repulsion, you will have to create this file by yourself by following the same principle (creating a new lipid type name to differentiate from the unmodified lipid; replacing old atom name with a new atom name). Modified lipids are named PODC, PODE, and PODS.

### 1e-1f) repulsions between benzene virtual sites; repulsions between lipid repulsion points and benzene virtual sites

Add lines at the bottom of ffnonbonded.itp file:

[ nonbond_params ]

; i     j       func    V(c6)   W(c12)

VS      VS      1       0.45    0.008

VS      ODM     1       1.20    0.008

Finally, don't forget to place this modified force field folder in the same location where you will be creating your simulation system.

## 2) Benzene probes
A coordinate file of a benzene probe with a central virtual site can be found in benzene_vs.pdb. To insert a desired number of benzene molecules (e.g. 50) into a simulation box, use:

gmx insert-molecules -f protein.gro -ci benzene_vs.pdb -nmol 50 -scale 0.9 -o protein_50bnz.gro

Make sure that the benzenes are not embedded in the membrane or in the protein interior!

Next, we need to generate a benzene topology file which will contain information for all benzenes in the system. They are treated as separate residues of a same "molecule" because this allows us to add exclusions between different benzene molecules.

echo "BNZV" | gmx editconf -f protein_50bnzv.gro -n index.ndx -o 50bnzv.gro 

echo "1 1" | gmx pdb2gmx -f 50bnzv.gro -p Benzene_50.top -i posre_Benzene_50.itp -o 50bnzv.gro

We need to edit Benzene_50.top topology file by excluding force field parameters (these should be specified in a main topology file), water and ion parameters, and [ system ] and [ molecules ] sections. We also need to include [ virtual_sitesn ] and [ exclusions ]. 

To generate virtual sites, use a vs_gen.py script:

python vs_gen.py 50

Copy script output and insert it into Benzene_50.top file.

To generate exclusions, use exclusions_scr.R script. Note, this step might take a while and can generate a very large output.

Rscript exclusions_scr.R 50

Copy script output and insert it into Benzene_50.top file.

Finally, don't forget to include Benzene_50.top into your main topology file (topol.top).

## 3) Customising parameters for different membrane compositions

In most cases, your membrane composition will not be identical to ours (POPC/POPE/POPS in 6:3:1 ratio). Depending on the lipid types used, average gaps between lipid headgroups might be larger or smaller, which might affect the value of a sigma term that defines repulsive forces between probes and lipids (set at 1.20 nm in section 1e-1f). To quickly assess the size of lateral gaps between the lipids, place Mandy.sh and lipid_distances.R in the same folder and run:

bash ./Mandy.sh -f md.xtc -s md.tpr -n index.ndx -o max_distance -x Voronoi_diagram

-o: output prefix (.xvg)

-x: Voronoi diagram prefix (.pdf)

If the plotted result is fluctuating around 1.2 nm, the default sigma setting of 1.20 nm can be used. If the value is lower or higher, consider changing the sigma value accordingly. Finally, don't forget to test your parameters on a small membrane sample!  
