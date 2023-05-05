[![Docker Image CI](https://github.com/mattgalbraith/homer-docker-singularity/actions/workflows/docker-image.yml/badge.svg)](https://github.com/mattgalbraith/homer-docker-singularity/actions/workflows/docker-image.yml)

# homer-docker-singularity

## Build Docker container for Homer and (optionally) convert to Apptainer/Singularity.  

HOMER (Hypergeometric Optimization of Motif EnRichment) is a suite of tools for Motif Discovery and next-gen sequencing analysis. It is a collection of command line programs for UNIX-style operating systems written in Perl and C++. HOMER was primarily written as a de novo motif discovery algorithm and is well suited for finding 8-20 bp motifs in large scale genomics data. HOMER contains many useful tools for analyzing ChIP-Seq, GRO-Seq, RNA-Seq, DNase-Seq, Hi-C and numerous other types of functional genomics sequencing data sets.  
http://homer.ucsd.edu/homer/  


### Requirements:  
gcc
g++
make
perl
zip/unzip
gzip/gunzip
wget
samtools (optional)
R (optional)

## Build docker container:  

### 1. For homer installation instructions:  
http://homer.ucsd.edu/homer/introduction/install.html   
http://homer.ucsd.edu/homer/download.html  


### 2. Build the Docker Image
``` bash
# Assumes current working directory is the top-level tophat2-docker-singularity directory
docker build -t homer:4.11.1 . # tag should match software version (configureHomer.pl can specify version version)
```
* Can do this on [Google shell](https://shell.cloud.google.com)

#### To test this tool from the command line:
Mount and use your current directory and call the tool now encapsulated within the container
```bash
docker run --rm -it homer:4.11.1 homer
docker run --rm -it homer:4.11.1 perl /opt/homer/configureHomer.pl -list | grep homer
docker run --rm -it homer:4.11.1 perl /opt/homer/configureHomer.pl -check
```

### 3. Download and mount homer data
Due to space limitations, especially on Google Cloud Shell, need to link/mount Homer annotation data from outside containers  
```bash
mkdir homer_data && cd homer_data
wget http://homer.ucsd.edu/homer/configureHomer.pl
perl ./configureHomer.pl -install hg38 # this will download "hg38" and "human" annotation packages

# Optional: archive and compress for transfer to eg HPC without internet access
cd .. && tar -czvf homer_data.tar.gz homer_data
# Transfer to final location and extract
tar -xzvf homer_data.tar.gz
```

#### Check if homer can see mounted reference and annotation data
```bash
# first set up path to homer_data
HOMER_DATA=path/to/homer_data
# Mount homer data in container at /opt/homerdata (see symlinks created in Dockerfile)
docker run --rm -it -v $HOMER_DATA:/opt/homerdata homer:4.11.1 /usr/bin/perl /opt/homer/configureHomer.pl -list
# output should indicate that correct genome packages are installed
```

## Optional: Conversion of Docker image to Singularity

### 4. Build a Docker image to run Singularity  
(skip if this image is already on your system)  
https://github.com/mattgalbraith/singularity-docker  


### 5. Save Docker image as tar and convert to sif (using singularity run from Docker container)  
``` bash
docker images
docker save <Image_ID> -o homer4.11.1-docker.tar && gzip homer4.11.1-docker.tar # = IMAGE_ID of tophat image
docker run -v "$PWD":/data --rm -it singularity:1.1.5 bash -c "singularity build /data/homer4.11.1.sif docker-archive:///data/homer4.11.1-docker.tar.gz"
```
NB: On Apple M1/M2 machines ensure Singularity image is built with x86_64 architecture or sif may get built with arm64  

Next, transfer the homer.sif file to the system on which you want to run Homer from the Singularity container

### 6. Test singularity container with mounted homer data on (HPC) system with Singularity/Apptainer available
```bash
# set up path to the homer Singularity container
HOMER_SIF=path/to/homer4.11.1.sif
# set up path to homer_data
HOMER_DATA=path/to/homer_data

# Test that Homer can run from Singularity container
singularity run $HOMER_SIF homer # depending on system/version, singularity is now apptainer

# Mount homer data in container at /opt/homerdata (see symlinks created in Dockerfile)
singularity run --bind $HOMER_DATA:/opt/homerdata $HOMER_SIF bash # depending on system/version, singularity is now apptainer
ls -lah /opt/homer/ # should show symlinks to homerdata
ls -lah /opt/homerdata/ # should see data and config.txt
perl /opt/homer/configureHomer.pl -list # output should indicate that correct genome packages are installed
```

