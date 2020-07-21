#!/bin/bash
################################################################
# USAGE
# bash ./Mandy.sh -f md.xtc -s md.tpr -n index.ndx -o max_distance -x Voronoi_diagram
################################################################

# Read arguments from the command line
set -e
while getopts f:s:n:o:x: option
do
 case "${option}"
 in
 f) FILE=${OPTARG};;
 s) TPR=${OPTARG};;
 n) INDEX=${OPTARG};;
 o) OUTPUT=${OPTARG};;
 x) PLOT=${OPTARG};;
 esac
done

# What to do if there is no input file.
if [ -z "$FILE" ]
   then
      echo "Trajectory file needs to be supplied."
      exit 1
fi

# What to do if there is no .tpr file.
if [ -z "$TPR" ]
    then 
	echo "Run input file (.tpr) needs to be supplied."
	exit 1
fi

# What to do if there is no index file.
if [ -z "$INDEX" ]
    then 
	echo "Index file containing a membrane selection needs to be supplied."
	exit 1
fi

# What to do if there is no output file.
if [ -z "$OUTPUT" ]
   then
      FOO=${OUTPUT:=max_dist}
fi

# What to do if there is no plot file.
if [ -z "$PLOT" ]
    then
	FOO=${PLOT:=Voronoi_diagram}
fi

# Backup a previous run
if [ -f $OUTPUT ]
    then
	mv $OUTPUT \#$OUTPUT\#
fi


# Dividing membrane into two leaflets using centre of mass (COM) - based on a first frame
echo "Automatic selection of leaflets:"
echo ""
echo "If execution of this part takes more than ~10 seconds, you might consider reducing a number of frames in the trajectory (see: gmx trjconv -h)."
echo ""
echo 0 | gmx trjconv -quiet -f $FILE -s $TPR -o md_trajectory.gro >& /dev/null
echo 0 | gmx trjconv -quiet -f $FILE -s $TPR -dump 0 -o md_firstframe.gro >& /dev/null
echo "Select a group which represents a Membrane:"
echo ""
gmx traj -quiet -f md_firstframe.gro -s $TPR -com -n $INDEX -ox
COM=$(grep "^[^#@]" coord.xvg | cut -f4)
rm coord.xvg
echo "Centre of mass: $COM"
echo ""

# Select lower leaflet
echo "Lower leaflet selection"
gmx select -quiet -f md_firstframe.gro -s $TPR -on Plower.ndx -select "name P and z<$COM" >& /dev/null
gmx trjconv -quiet -f md_trajectory.gro -s $TPR -n Plower.ndx -o Plower_trajectory.gro >& /dev/null
gmx convert-tpr -quiet -s $TPR -n Plower.ndx -o md_Plower.tpr >& /dev/null
rm Plower.ndx
echo "Lower leaflet trajectory saved as: Plower_trajectory.gro"
echo "Lower leaflet .tpr file saved as: md_Plower.tpr"
echo ""

# Select upper leaflet
echo "Upper leaflet selection"
gmx select -quiet -f md_firstframe.gro -s $TPR -on Pupper.ndx -select "name P and z>$COM" >& /dev/null
gmx trjconv -quiet -f md_trajectory.gro -s $TPR -n Pupper.ndx -o Pupper_trajectory.gro >& /dev/null
gmx convert-tpr -quiet -s $TPR -n Pupper.ndx -o md_Pupper.tpr >& /dev/null
rm Pupper.ndx
rm md_firstframe.gro
echo "Upper leaflet trajectory saved as: Pupper_trajectory.gro"
echo "Upper leaflet .tpr file saved as: md_Pupper.tpr"
echo ""

# Extracting a list of time steps from gro file 
TIMESTEP=$(grep -i "t=" md_trajectory.gro | cut -d'=' -f2 | cut -d'.' -f1)
if [ -z "$TIMESTEP" ]
   then
	TIMESTEP=0
fi
rm md_trajectory.gro

# XMGRACE options
echo "@ title \"Maximum lipid neighbour distance\"" > ${OUTPUT}_lower.xvg
echo "@ xaxis label \"Time (ps)\"" >> ${OUTPUT}_lower.xvg
echo "@ yaxis label \"Maximum neighbour distance (nm)\"" >> ${OUTPUT}_lower.xvg
echo "@ TYPE XY" >> ${OUTPUT}_lower.xvg
echo "@ subtitle \"Lower leaflet\"" >> ${OUTPUT}_lower.xvg
echo "@ view 0.15, 0.15, 0.75, 0.85" >> ${OUTPUT}_lower.xvg
echo "@ legend on" >> ${OUTPUT}_lower.xvg
echo "@ legend loctype view" >> ${OUTPUT}_lower.xvg
echo "@ legend 0.78, 0.8" >> ${OUTPUT}_lower.xvg
echo "@ legend length 2" >> ${OUTPUT}_lower.xvg
echo "@ s0 legend \"Lower leaflet\"" >> ${OUTPUT}_lower.xvg
echo "" >> ${OUTPUT}_lower.xvg

echo "@ title \"Maximum lipid neighbour distance\"" > ${OUTPUT}_upper.xvg
echo "@ xaxis label \"Time (ps)\"" >> ${OUTPUT}_upper.xvg
echo "@ yaxis label \"Maximum neighbour distance (nm)\"" >> ${OUTPUT}_upper.xvg
echo "@ TYPE XY" >> ${OUTPUT}_upper.xvg
echo "@ subtitle \"Upper leaflet\"" >> ${OUTPUT}_upper.xvg
echo "@ view 0.15, 0.15, 0.75, 0.85" >> ${OUTPUT}_upper.xvg
echo "@ legend on" >> ${OUTPUT}_upper.xvg
echo "@ legend loctype view" >> ${OUTPUT}_upper.xvg
echo "@ legend 0.78, 0.8" >> ${OUTPUT}_upper.xvg
echo "@ legend length 2" >> ${OUTPUT}_upper.xvg
echo "@ s0 legend \"Upper leaflet\"" >> ${OUTPUT}_upper.xvg
echo "" >> ${OUTPUT}_upper.xvg

# Running R script on each frame (also compatible with a single frame) 
for i in $TIMESTEP
do
	# Extracting frames and running calculations on the lower leaflet
	echo "0" | gmx trjconv -quiet -s md_Plower.tpr -f Plower_trajectory.gro -dump $i -o Plower_$i.gro >& /dev/null
	echo -n -e "Calculating maximum neighbour distance at $i ps ... \r"
	(head Plower_$i.gro -n -1 | tail -n +3) > forR_Plower_$i.gro
	Rscript --vanilla lipid_distances.R forR_Plower_$i.gro lower ${PLOT}_lower.pdf >> ${OUTPUT}_lower.xvg
	rm forR_Plower_$i.gro
        rm Plower_$i.gro

	# Extracting frames and running calculations on the upper leaflet
	echo "0" | gmx trjconv -quiet -s md_Pupper.tpr -f Pupper_trajectory.gro -dump $i -o Pupper_$i.gro >& /dev/null
	(head Pupper_$i.gro -n -1 | tail -n +3) > forR_Pupper_$i.gro
	Rscript --vanilla lipid_distances.R forR_Pupper_$i.gro upper ${PLOT}_upper.pdf >> ${OUTPUT}_upper.xvg
	rm forR_Pupper_$i.gro
        rm Pupper_$i.gro
done
echo ""
echo "Creating a Voronoi diagram of the last frame..."
rm md_Plower.tpr
rm md_Pupper.tpr
rm Plower_trajectory.gro
rm Pupper_trajectory.gro

