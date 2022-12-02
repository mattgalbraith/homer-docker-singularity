# homer-docker-singularity
Build Docker container for homer software and (optionally) convert to Apptainer/Singularity  
Dockerfile modified from https://github.com/chrisamiller/docker-homer

## Build docker container:  

### 1. For homer installation instructions:  
http://homer.ucsd.edu/homer/introduction/install.html   

### 2. Build the Docker Image

#### To build your image from the command line:
* Can do this on [Google shell](https://shell.cloud.google.com) - docker is installed and available

```bash
WORKING_DIR=`pwd` # capture current working directory (should be the top-level homer-docker-singularity directory)
cd homer-docker
docker build -t homer .
```

Due to space limitations, especially on Google Cloud Shell, need to symlink to external Homer annotation directory  

#### To test this tool from the command line:
Mount and use your current directory and call the tool now encapsulated within the container
```bash
docker run --rm -it -v $PWD:$PWD -w $PWD homer homer
```

### 3. Download and mount homer data
```bash
cd $WORKING_DIR
mkdir homer_data && cd homer_data
wget http://homer.ucsd.edu/homer/configureHomer.pl
perl ./configureHomer.pl install hg38 # this will download "hg38" and "human" annotation packages

# Optional: archive and compress archive for transfer to eg HPC without internet access
cd .. && tar -czvf homer_data.tar.gz homer_data
# Transfer to final location and extract
tar -xzvf homer_data.tar.gz
```

#### Check if homer can see mounted reference and annotation data
```bash
# first set up path to homer_data
HOMER_DATA = path/to/homer_data
# Mount homer data in container at /opt/homerdata (see symlinks created in Dockerfile)
docker run --rm -it -v $HOMER_DATA:/opt/homerdata -v $PWD:$PWD -w $PWD homer /usr/bin/perl /opt/homer/configureHomer.pl -list
# output should indicate that correct genome packages are installed
```

## Optional: Conversion of Docker image to Singularity

### 4. Build a Docker image to run Singularity

```bash
cd $WORKING_DIR/singularity-docker
docker build -t singularity .
```

#### Test singularity container
```bash
docker run --rm -it -v $PWD:$PWD -w $PWD singularity singularity
```

### 5. Save Docker image as tar and convert to sif
```bash
cd $WORKING_DIR
docker save <Image_ID> -o homer-docker.tar # = IMAGE_ID of homer image
docker run -v "$PWD:/out" --rm -it singularity bash -c "singularity build /out/homer.sif docker-archive:///out/homer-docker.tar"
```
NB: may build with arm64 architecture if run on M1/M2 Macbook  

Next, transfer the homer.sif file to the system on which you want to run Homer from the Singularity container

### 6. Test singularity container with mounted homer data on (HPC) system with Singularity/Apptainer available
```bash
# set up path to the homer Singularity container
HOMER_SIF=path/to/homer.sif
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

