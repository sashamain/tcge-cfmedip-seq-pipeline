# TCGE cfMeDIP-seq pipeline

## Intoduction

At the Cancer Genetics and Epigenetics (TCGE) program, we have designed a cfMeDIP-seq pipeline for automated end-to-end quality control and processing of cfMeDIP-seq and MeDIP-seq data. We developed the pipeline using [Snakemake](https://snakemake.readthedocs.io/en/stable/index.html), which automatically sets up the execution environments.  The input sequencing data can be single-end or paired-end with or without spike-in or UMIs. The pipeline inputs the raw FASTQ file(s) and outputs quality metrics, fragment profiles, and methylation quantifications. You can also run the pipeline on [compute clusters](https://carpentries-incubator.github.io/hpc-intro/) with job submission engines or stand-alone machines. 

The pipeline was developed by [Yong Zeng](mailto:yzeng@uhnresearch.ca) based on some prior work of Wenbin Ye, [Eric Zhao](https://github.com/pughlab/cfMeDIP-seq-analysis-pipeline). The pipeline is available on [COBE](https://www.pmcobe.ca/pipeline/624d0bb4002b11003426f7d8) as well.


### Features

- **Portability**: The pipeline run can be performed across different cluster engines such as SLURM (tested). For other platforms, please refer to [here](https://snakemake.readthedocs.io/en/stable/executing/cluster.html).
- **Supported genomes**: We provide a genome database. This includes downloads for hg38, hg19, and the Arabidopsis thaliana genome (TAIR10). We also offer the alignment indices and blacklist references for these. We supply spike-in fasta sequences for two BACs ([F19K16](https://www.arabidopsis.org/servlets/TairObject?type=assembly_unit&id=362) from Arabidopsis Chr1 and [F24B22](https://www.arabidopsis.org/servlet/TairObject?type=AssemblyUnit&name=F24B22) from Arabidopsis Chr3) and [sythetic DNAs](https://github.com/hoffmangroup/2020spikein). If this is insufficient, you can also build a genome database from FASTA for your custom genomes. 

### How it works
This schematic diagram shows you how pipeline works:

<img src="figures/cfmedip-seq-pipeline.png" alt="Schematic_diagram" style="width:100.0%" />

## Installation

**A step-by-step guide to set up**

1) **Make sure you have internet.** Many compute clusters with high memory nodes do not have access to the internet due to patient data privacy and safety concerns. Do not perform the setup on this type of node. 

2) **Install Conda.** Conda is the best way to work with Snakemake since its environments can handle all the required package dependencies. We recommend using the [Miniconda installer](https://docs.conda.io/en/latest/miniconda.html), since it is a simplified version of conda without many pre-installed packages. Snakemake can automatically build its own conda environments with required packages, so it does not need many pre-installed.

- Create a directory on your drive where you want to install conda.  

	```bash
	$ mkdir ~/software/conda
	```
- Obtain the linux bash file from the miniconda repository available at https://docs.conda.io/en/latest/miniconda.html# and ensure it is in your proper directory.  

	```bash
	$ cd ~/software/conda
	$ wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh

	```
- Run the bash script of the installer and follow the installation instructions.  

	```bash
	$ bash Miniconda3-latest-Linux-x86_64.sh

	```
	
3) **Install Mamba.** We recommend installing [Mamba](https://github.com/mamba-org/mamba) into your base environment since it is better at handling environments and installations. We prefer [Mambaforge](https://github.com/conda-forge/miniforge#mambaforge). 

	```bash
	$ conda install -n base -c conda-forge mamba
	```

4) **Git clone the pipeline.** Ensure it is in your desired directory.

	```bash
	$ cd ~
	$ git clone https://github.com/yzeng-lol/tcge-cfmedip-seq-pipeline
	```

5) **Install pipeline\'s core enviroments**

	```bash
	$ cd tcge-cfmedip-seq-pipeline
	$ conda activate base
	$ mamba env create --file conda_env.yaml
	```

**Perform a test run**

1) **Again, make sure you have internet.** This test run will finish setting up the sub-environments required to run the full pipeline.

2) **Activate the environment.**
	```bash
	$ conda activate tcge-cfmedip-seq-pipeline
	```

3) **Edit the config file.** Snakemake requires a configuration file to execute the pipeline. We recommend copying the template file, then editing the copy (below, it is called config_testrun.yaml). Below we use [vim](https://github.com/vim/vim) to edit, but other editors may be used. 
	```bash
	$ cp ./workflow/config/config_template.yaml ./workflow/config/config_testrun.yaml
	$ vi ./workflow/config/config_testrun.yaml
	```
- Once you are in the editor, you need to change all the paths within the config file to the appropriate location from your setup. For example, that means wherever /cluster/home/yzeng/snakemake/tcge-cfmedip-seq-pipeline is written, you must change it to your path (e.g., /cluster/janesmith/tcge-cfmedip-seq-pipeline). Specifically, you will need to change the paths on lines 3, 4, 5, 10, 16, and 21. 

4) **Edit the test.tsv file.** Again, you will need to edit the paths on lines 2, 3, and 4.
	```bash
	$ vi ./test/data/Reference/test.tsv
	```

5) **Edit the sample file.** Again, you will need to edit the paths on lines 2 and 3.
	```bash
	$ vi ./test/data/sample_pe.tsv
	```

6)  **Create a test run directory.** Again, you will need to edit the paths on lines 2 and 3.
	```bash
	$ cd tcge-cfmedip-seq-pipeline
	$ mkdir ../tcge-cfmedip-seq-pipeline-test-run
	```
7) **Run the pipeline.** The extra environments will be installed to tcge-cfmedip-seq-pipeline-sub. The pipeline will be killed in rule meth_qc_quant due to the current test dataset. This is expected and okay.

	```bash
	$ snakemake --snakefile ./workflow/Snakefile \
          	    --configfile ./workflow/config/config_template.yaml \
	            --conda-prefix /path/to/conda/envs/tcge-cfmedip-seq-pipeline-sub \
                    --use-conda --cores 4 -p
	```



## Input files specification

### Download reference genome data
You can download reference genome, pre-build BWA index and annotated regions (e.g., blacklist) from ENCODE for hg38 and hg19 on the command line. The manifest file hg38/hg19.tsv will be generated accordingly. Currently, the ENCODE black list and bwa index are mandatory for the manifest file, which you can also create it based on `workflow/config/hg38_template.tsv` with existing data.

```bash
## eg: ./download_build_reference.sh hg38 /your/genome/data/path/hg38
$ ./download_reference.sh [GENOME] [DEST_DIR]
```

### Build reference genomes index
If your sequencing libraries come with spike-ins, you can build new aligner index after combining spike-in genome with human genome. The new index information will be appended to corresponding manifest file.

```bash
## eg: ./build_reference_index.sh hg38 ./data/BAC_F19K16_F24B22.fa hg38_BAC_F19K16_F24B22 /your/genome/data/path/hg38
$ ./build_reference_index.sh [GENOME] [SPIKEIN_FA] [INDEX_PREFIX] [DEST_DIR]
```

### Set up the config file for input samples
> **IMPORTANT**: READ THROUGH THE GUIDE INFORMATION IN THE TEMPLATE TO MAKE A CORRECT CONFIG FILE. ESPECIALLY FOR SAMPLES WITH SPIKE-IN CONTROL AND/OR UMI BARCODES.

1) A config YAML file specifies all the input parameters and files that are necessary for successfully running this pipeline. This includes a specification of the path to the genome reference files. Please make sure to specify absolute paths rather than relative paths in your config files. The template can be found at [here](./workflow/config/config_template.yaml)

2) The samples's sequence data table template. Note:Prepare the table for single-end and paired-end samples separately and use exactly same table `header`, if there are multiple lanes, use comma to separate the list.

|	sample_id   |     R1	     |  R2(p.r.n.)|
|-------------|--------------|------------|
|  A	|  full/path/to/A_L001_R1.fq.gz |                              |
|  B	|  full/path/to/B_L001_R1.fq.gz | full/path/to/B_L001_R2.fq.gz |
|  C  |  path/C_L001_R1.fq.gz,path/C_L002_R1.fq.gz | path/C_L001_R2.fq.gz,path/C_L002_R2.fq.gz  |


## Run on HPCs

You can submit this pipeline on clusters after editing ./workflow/sbatch_snakemake_template.sh according different resource management system. The file must have the appropriate path names and parameters given the input data. The example here is for submitting a job with SLURM, however, this template could be modified according to different resource management systems. More details about cluster configuration can be found at [here](https://snakemake.readthedocs.io/en/stable/executing/cluster.html). For example:

```bash
$ vim ./workflow/sbatch_snakemake_template.sh
$ sbatch ./workflow/sbatch_snakemake_template.sh
```
