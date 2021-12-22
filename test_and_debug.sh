##################################################
##### conda_env.yaml and conda_env_r.yaml  #######

## conda_env.ymal


conda install -c anaconda graphviz
conda env export -c bioconda  --from-history | grep -v "^prefix" >  conda_env.yaml


## conda_env_r.yaml
conda install -c bioconda bioconductor-medips
conda env export -c bioconda  --from-history | grep -v "^prefix" >  conda_env_r.yaml




###############################
##### test run on H4H  #######
###############################

conda activate tcge-cfmedip-seq-pipeline


########################################
## generate the DGA plots with dot -Tsvg
## for paired-end inputs
snakemake --snakefile /cluster/home/yzeng/snakemake/tcge-cfmedip-seq-pipeline/workflow/Snakefile \
          --configfile /cluster/home/yzeng/snakemake/tcge-cfmedip-seq-pipeline/workflow/config/config_pe_template.yaml \
          -p --dag | dot -Tpdf > /cluster/home/yzeng/snakemake/tcge-cfmedip-seq-pipeline/figures/dag_pe.pdf

## for single-end inputs
snakemake --snakefile /cluster/home/yzeng/snakemake/tcge-cfmedip-seq-pipeline/workflow/Snakefile \
          --configfile /cluster/home/yzeng/snakemake/tcge-cfmedip-seq-pipeline/workflow/config/config_se_template.yaml \
          -p --dag | dot -Tpdf > /cluster/home/yzeng/snakemake/tcge-cfmedip-seq-pipeline/figures/dag_se.pdf


#####################
# stand-alone testing
snakemake --snakefile /cluster/home/yzeng/snakemake/tcge-cfmedip-seq-pipeline/workflow/Snakefile \
          --configfile /cluster/home/yzeng/snakemake/tcge-cfmedip-seq-pipeline/workflow/config/config_pe_template.yaml \
          --use-conda  --conda-prefix /cluster/home/yzeng/miniconda3/envs/tcge-cfmedip-seq-pipeline-sub \
          --cores 4 -p


################################
#### test run on H4H with sbatch

## sbatch /cluster/home/yzeng/snakemake/tcge-cfmedip-seq-pipeline/workflow/sbatch_snakemake_template.sh

## using the --unlock flag to unlock workdir

snakemake --snakefile /cluster/home/yzeng/snakemake/tcge-cfmedip-seq-pipeline/workflow/Snakefile \
          --configfile /cluster/home/yzeng/snakemake/tcge-cfmedip-seq-pipeline/workflow/config/config_pe_template.yaml \
          --use-conda  --conda-prefix /cluster/home/yzeng/miniconda3/envs/tcge-cfmedip-seq-pipeline-sub \
          --cluster-config /cluster/home/yzeng/snakemake/tcge-cfmedip-seq-pipeline/workflow/config/cluster_std_err.json \
          --cluster "sbatch -p all --mem=16G -o {cluster.std} -e {cluster.err}" \
          --latency-wait 60 --cores 8 --jobs 4 -p



#############################################
#### test run with real tcge-cfmedip-seq data
#############################################


## sbatch /cluster/home/yzeng/snakemake/tcge-cfmedip-seq-pipeline/workflow/sbatch_snakemake_real_run.sh

snakemake --snakefile /cluster/home/yzeng/snakemake/tcge-cfmedip-seq-pipeline/workflow/Snakefile \
          --configfile /cluster/projects/tcge/cell_free_epigenomics/test_run/config_test.yaml \
          --use-conda  --conda-prefix /cluster/home/yzeng/miniconda3/envs/tcge-cfmedip-seq-pipeline-sub \
          --cluster-config /cluster/home/yzeng/snakemake/tcge-cfmedip-seq-pipeline/workflow/config/cluster_std_err.json \
          --cluster "sbatch -p all --mem=16G -o {cluster.std} -e {cluster.err}" \
          --latency-wait 60 --cores 8 --jobs 4 -p
