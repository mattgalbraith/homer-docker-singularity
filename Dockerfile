FROM ubuntu:focal

LABEL description="Image for homer software"
LABEL maintainer="Matthew Galbraith <matthew.galbraith@cuanschutz.edu>"

ENV DEBIAN_FRONTEND=noninteractive

# Update apt-get
RUN apt-get update \
    ## Install HOMER dependencies
    && apt-get install -y libnss-sss samtools r-base r-base-dev tabix wget libssl-dev libcurl4-openssl-dev libxml2-dev \
    ## Remove packages in '/var/cache/' and 'var/lib'
    ## to remove side-effects of apt-get update
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install required Bioconductor package(s) # SLOW and MAY NOT NEED THESE for tagdir and ucsc file creation
RUN R -e 'install.packages("BiocManager")'
RUN R -e 'BiocManager::install("edgeR")'
RUN R -e 'BiocManager::install("DESeq2")'

# Install and configure Homer
RUN mkdir /opt/homer/ && cd /opt/homer && wget http://homer.ucsd.edu/homer/configureHomer.pl && /usr/bin/perl configureHomer.pl -install 
# Genome information is too large
# RUN cd /opt/homer && /usr/bin/perl configureHomer.pl -install hg38 && /usr/bin/perl configureHomer.pl -install human-o

# Annotation data is too large to include in this image, so it
# requires a directory to be mounted at /opt/homerdata/ containing
#  - config.txt - homer configuration file with directories pointing to paths like "data/accession"
#  - data  - folder containing homer annotation data files

# Add softlinks for config file and data directory
RUN rm -rf /opt/homer/data && ln -s /opt/homerdata/data /opt/homer/data
RUN rm -f /opt/homer/config.txt && ln -s /opt/homerdata/config.txt /opt/homer/config.txt

# Add homer installation dir to PATH
ENV PATH=${PATH}:/opt/homer/bin/