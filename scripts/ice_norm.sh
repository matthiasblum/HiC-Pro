#!/bin/bash
## HiC-Pro
## Copyleft 2015 Institut Curie                               
## Author(s): Nicolas Servant, Nelle Varoquaux
## Contact: nicolas.servant@curie.fr
## This software is distributed without any guarantee under the terms of the GNU General
## Public License, either Version 2, June 1991 or Version 3, June 2007.

##
## Launcher for ICE normalization scripts
##

dir=$(dirname $0)

#. $dir/hic.inc.sh

################### Initialize ###################

while [ $# -gt 0 ]
do
    case "$1" in
	(-c) conf_file=$2; shift;;
	(-h) usage;;
	(--) shift; break;;
	(-*) echo "$0: error - unrecognized option $1" 1>&2; exit 1;;
	(*)  break;;
    esac
    shift
done

################### Read the config file ###################

#read_config $ncrna_conf
CONF=$conf_file . $dir/hic.inc.sh

################### Define Variables ###################
input_data_type=$(get_data_type)
if [[ $input_data_type == "mat" ]]
then
    IN_DIR=${RAW_DIR}
else
    IN_DIR=${MAPC_OUTPUT}/matrix/
fi

################### Combine Bowtie mapping ###################

for RES_FILE_NAME in ${IN_DIR}/*
do
    RES_FILE_NAME=$(basename $RES_FILE_NAME)
    ## out
    MAT_DIR=${MAPC_OUTPUT}/matrix
    mkdir -p ${MAT_DIR}/${RES_FILE_NAME}

    ## Logs
    LDIR=${LOGS_DIR}/${RES_FILE_NAME}
    mkdir -p ${LDIR}


    ## Default
    if [[ -z ${FILTER_LOW_COUNT_PERC} ]]; then
	FILTER_LOW_COUNT_PERC=0.02
    fi
    if [[ -z ${FILTER_HIGH_COUNT_PERC} ]]; then
	FILTER_HIGH_COUNT_PERC=0
    fi


    if [ -d ${MAT_DIR}/${RES_FILE_NAME} ]; then
	NORM_DIR=${MAT_DIR}/${RES_FILE_NAME}/iced
	for bsize in ${BIN_SIZE}
	do
	    if [[ $bsize == -1 ]]; then
		bsize="rfbin"
	    fi

	    mkdir -p ${NORM_DIR}/${bsize}

	    if [[ ! -z ${ALLELE_SPECIFIC_SNP} ]]; then
		## Build haplotype contact maps if specified
	    	INPUT_MATRIX_G1=${IN_DIR}/${RES_FILE_NAME}/raw/${bsize}/${RES_FILE_NAME}_${bsize}_G1.matrix
		INPUT_MATRIX_G2=${IN_DIR}/${RES_FILE_NAME}/raw/${bsize}/${RES_FILE_NAME}_${bsize}_G2.matrix
		${PYTHON_PATH}/python ${SCRIPTS}/ice --results_filename ${NORM_DIR}/${bsize}/${RES_FILE_NAME}_${bsize}_G1_iced.matrix --filter_low_counts_perc ${FILTER_LOW_COUNT_PERC} --filter_high_counts_perc ${FILTER_HIGH_COUNT_PERC} --max_iter ${MAX_ITER} --eps ${EPS} --verbose 1 ${INPUT_MATRIX_G1} > ${LDIR}/ice.log
		${PYTHON_PATH}/python ${SCRIPTS}/ice --results_filename ${NORM_DIR}/${bsize}/${RES_FILE_NAME}_${bsize}_G2_iced.matrix --filter_low_counts_perc ${FILTER_LOW_COUNT_PERC} --filter_high_counts_perc ${FILTER_HIGH_COUNT_PERC} --max_iter ${MAX_ITER} --eps ${EPS} --verbose 1 ${INPUT_MATRIX_G2} >> ${LDIR}/ice.log
	    else
		INPUT_MATRIX=${IN_DIR}/${RES_FILE_NAME}/raw/${bsize}/${RES_FILE_NAME}_${bsize}.matrix
		#ln -f -s ../../raw/${bsize}/${RES_FILE_NAME}_${bsize}_abs.bed ${NORM_DIR}/${bsize}/${RES_FILE_NAME}_${bsize}_abs.bed
		#ln -f -s ../../raw/${bsize}/${RES_FILE_NAME}_${bsize}_ord.bed  ${NORM_DIR}/${bsize}/${RES_FILE_NAME}_${bsize}_ord.bed
		cmd="${PYTHON_PATH}/python ${SCRIPTS}/ice --results_filename ${NORM_DIR}/${bsize}/${RES_FILE_NAME}_${bsize}_iced.matrix --filter_low_counts_perc ${FILTER_LOW_COUNT_PERC} --filter_high_counts_perc ${FILTER_HIGH_COUNT_PERC} --max_iter ${MAX_ITER} --eps ${EPS} --verbose 1 ${INPUT_MATRIX} >> ${LDIR}/ice.log"
		echo $cmd > ${LDIR}/ice.log
		eval $cmd
 	    fi
	done
    fi
    wait
done
