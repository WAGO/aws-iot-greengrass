# How to setup AWS IoT Greengrass on a Wago Device

## Prerequisites for tutorial
- Preinstalled SSH Client (e.g. https://www.putty.org/)
- Wago Device e.g. PFC200 G2 or Wago Touch Panel with minimal Firmware 12
  - Firmware you can find here: https://github.com/WAGO/pfc-firmware
  - Docker IPKG you can find here: https://github.com/WAGO/docker-ipk
- AWS account 
 

# Running AWS IoT Greengrass in a Docker Container
## Overview
AWS IoT Greengrass can run in a Docker container. You can use the Dockerfile in this package to build a container image that runs on ```arm32``` platforms. The resulting Greengrass Docker image is 90 MB in size. 
* To build a Docker image that runs on other platforms supported by the AWS IoT Greengrass Core software (such as Armv7l or AArch64), edit the Dockerfile as described in the "Enable Multi-Platform Support for the AWS IoT Greengrass Docker Image" section. 
* To reduce the size of the Greengrass Docker image, see the "Reduce the Size of the AWS IoT Greengrass Docker Image" section.  

 Note: To learn how to run a Greengrass Docker image for ```x86_64``` platform instead of building one, see the "Running AWS IoT Greengrass in a Docker Container" tutorial (https://docs.aws.amazon.com/greengrass/latest/developerguide/run-gg-in-docker-container.html).


### WAGO Device Configuration
To run the Greengrass IOT Core in Docker on a WAGO device, you must enable symlink and hardlink protection. 

Run the following commands in the host computer's terminal.

* To enable the settings only for the current boot:

```
echo 1 > /proc/sys/fs/protected_hardlinks
echo 1 > /proc/sys/fs/protected_symlinks
```

* To enable the settings to persist across restarts:

```
echo '# AWS Greengrass' >> /etc/sysctl.conf
echo 'fs.protected_hardlinks = 1' >> /etc/sysctl.conf
echo 'fs.protected_symlinks = 1' >> /etc/sysctl.conf

sysctl -p
```


## Reduce the Size of the AWS IoT Greengrass Docker Image (Optional)
Currently, the Greengrass Docker image is about 532 MB. Most of this size is attributed to the heavy ```amazonlinux``` Docker base image that AWS IoT Greengrass runs on. 

Use following techniques to reduce the size of your Greengrass Docker image. Otherwise, continue to the "Running AWS IoT Greengrass in a Docker Container" procedure.

### Reduce Lambda Runtime Installations
You can reduce the number of Lambda runtimes that are installed inside the Greengrass Docker image. The Nodejs-6.10 and Java-1.8.0 Lambda runtimes are installed by default, but if you only plan to run Python Lambda functions on your image, you can save up to 200 MB by not installing the other runtimes. (Python-2.7 comes pre-installed with the ```amazonlinux``` Docker image, so you don't need to install it.) The final Docker image with only the Python-2.7 Lambda runtime is 372 MB.  

1- Open ```aws-greengrass-docker-1.8.1/Dockerfile``` in a text editor.  

2- In the Dockerfile, replace the following block: 
```
RUN yum update -y && \
    yum install -y shadow-utils tar.x86_64 gzip xz wget iproute java-1.8.0 && \
    ln -s /usr/bin/java /usr/local/bin/java8 && \
    wget $GREENGRASS_RELEASE_URL && \
    wget https://nodejs.org/dist/v6.10.2/node-v6.10.2-linux-x64.tar.xz && \
    tar xf node-v6.10.2-linux-x64.tar.xz && \
    cp node-v6.10.2-linux-x64/bin/node /usr/bin/node && \
    ln -s /usr/bin/node /usr/bin/nodejs6.10 && \
    rm -rf node-v6.10.2-linux-x64.tar.xz node-v6.10.2-linux-x64 && \
    yum remove -y wget
```
with
```
RUN yum update -y && \
    yum install -y wget shadow-utils tar.x86_64 gzip xz iproute && \
    wget $GREENGRASS_RELEASE_URL && \
    yum remove -y wget
```
Note: As you can see, this doesn't install the Nodejs-6.10 and Java-1.8.0 Lambda runtimes in the Docker image.

3- Save the file and close the editor.

4- Continue to the "Running AWS IoT Greengrass in a Docker Container" procedure.

### Change the Base Docker Image
You can change the base Docker image in the Dockerfile from ```amazonlinux:2``` to ```alpine:3.8```. The ```amazonlinux:2``` image is about 162 MB as compared to ```alpine:3.8```, which is only about 4.4 MB.  

1- Open ```aws-greengrass-docker-1.8.1/Dockerfile``` in a text editor.  

2- In the Dockerfile, replace the following line:
```
FROM amazonlinux:2
```
with
```
FROM alpine:3.8
```

3- In the Dockerfile, replace the following block:
```
RUN yum update -y && \
    yum install -y shadow-utils tar.x86_64 gzip xz wget iproute java-1.8.0 && \
    ln -s /usr/bin/java /usr/local/bin/java8 && \
    wget $GREENGRASS_RELEASE_URL && \
    wget https://nodejs.org/dist/v6.10.2/node-v6.10.2-linux-x64.tar.xz && \
    tar xf node-v6.10.2-linux-x64.tar.xz && \
    cp node-v6.10.2-linux-x64/bin/node /usr/bin/node && \
    ln -s /usr/bin/node /usr/bin/nodejs6.10 && \
    rm -rf node-v6.10.2-linux-x64.tar.xz node-v6.10.2-linux-x64 && \
    yum remove -y wget
```
 with
```
RUN apk update && \
    apk add tar gzip xz shadow libc6-compat ca-certificates iproute2 python && \
    wget $GREENGRASS_RELEASE_URL && \
    apk del wget
```
Note: As you can see, this installs only the Python-2.7 Lambda runtime in the Alpine Docker image. If you want to install other runtimes, refer to the package management documentation for the Alpine Linux System (https://pkgs.alpinelinux.org/packages).

4- Save the file and close the editor. 

5- Continue to the "Running AWS IoT Greengrass in a Docker Container" procedure.

## Running AWS IoT Greengrass in a Docker Container
The following steps show how to build the Docker image from the Dockerfile and configure AWS IoT Greengrass to run in a Docker container.


### Step 1. Build the AWS IoT Greengrass Docker Image
#### On Linux or Mac OSX
1- Download and decompress the ```aws-greengrass-docker-1.8.1``` package.  

2- In a terminal, run the following commands in the location where you decompressed the ```aws-greengrass-docker-1.8.1``` package. 
 - To use the default x86_64 configuration, replace ```<platform>``` with ```x86-64```.
 - If you followed "Enable Multi-Platform Support for the AWS IoT Greengrass Docker Image", replace ```<platform>``` with ```armv7l```.
```
docker login
cd ~/Downloads/aws-greengrass-docker-1.8.1 
docker build -t "<platform>/aws-iot-greengrass:1.8.1" --build-arg "greengrass_version=1.8.1" --build-arg "os_platform=<platform>" ./
```

 Note: If you have ```docker-compose``` installed, you can run the following commands instead:
```
docker login
cd ~/Downloads/aws-greengrass-docker-1.8.1 
PLATFORM=<platform> GREENGRASS_VERSION=1.8.1 docker-compose build
```

3- Verify that the Greengrass Docker image was built.
```
docker images
REPOSITORY                          TAG                 IMAGE ID            CREATED             SIZE
x86-64/aws-iot-greengrass           1.8.1               3f152d6707c8        17 seconds ago      532MB
```

#### On a Windows Computer
1- Download and decompress the ```aws-greengrass-docker-1.8.1``` package using a utility like WinZip or 7-Zip.  

2- Using Notepad++, convert the ```greengrass-entrypoint.sh``` file to use Unix-style line endings. For more information, see "Converting from Windows-style to UNIX-style line endings" (https://support.nesi.org.nz/hc/en-gb/articles/218032857-Converting-from-Windows-style-to-UNIX-style-line-endings).   
Otherwise, you will get this error while running the build Docker image: ```[FATAL tini (6)] exec /greengrass-entrypoint.sh failed: No such file or directory```.
    
 a. Open ```greengrass-entrypoint.sh``` in Notepad++.   
 b. In the "Edit" menu, choose "EOL Conversion", and then choose "UNIX (LF)".   
 c. Save the file.
    
3- In a command prompt, run the following command in the location where you decompressed the ```aws-greengrass-docker-1.8.1``` package.
```
docker login
cd C:\Users\%USERNAME%\Downloads\aws-greengrass-docker-1.8.1
docker build -t "<platform>/aws-iot-greengrass:1.8.1" --build-arg "greengrass_version=1.8.1" --build-arg "os_platform=<platform>" ./
```

 Note: If you have ```docker-compose``` installed, you can run the following commands instead:
```
docker login
cd C:\Users\%USERNAME%\Downloads\aws-greengrass-docker-1.8.1
set GREENGRASS_VERSION=1.8.1
set PLATFORM=x86-64
docker-compose build
```

4- Verify that the Greengrass Docker image was built.
```
docker images
REPOSITORY                          TAG                 IMAGE ID            CREATED             SIZE
x86-64/aws-iot-greengrass           1.8.1               3f152d6707c8        17 seconds ago      532MB
```

### Step 2. Run AWS IoT Greengrass Locally
#### On Linux or Mac OSX
1- Use the AWS IoT Greengrass console to create a Greengrass group. Follow the steps in "Configure AWS IoT Greengrass on AWS IoT" (https://docs.aws.amazon.com/greengrass/latest/developerguide/gg-config.html). This process includes downloading certificates and the core configuration file.   
Skip step 8b of the procedure because AWS IoT Greengrass core and its runtime dependencies are already set up in the Docker image.   

2- Decompress the certificates and config file that you downloaded into your working directory where ```Dockerfile``` and ```docker-compose.yml``` are located. For example: (replace ```guid``` in your command)
```
cp ~/Downloads/guid-setup.tar.gz ~/Downloads/aws-greengrass-docker-1.8.1
cd ~/Downloads/aws-greengrass-docker-1.8.1
tar xvzf guid-setup.tar.gz
```

3- Download the root CA certificate into the directory where you decompressed the certificates and configuration file. The certificates enable your device to communicate with AWS IoT using the MQTT messaging protocol over TLS. For more information, including how to choose the appropriate root CA certificate, see the documentation on "Server Authentication in AWS IoT Core" (https://docs.aws.amazon.com/iot/latest/developerguide/managing-device-certs.html).  

**Important**: Your root CA certificate must match your endpoint, which uses Amazon Trust Services (ATS) server authentication (preferred) or legacy server authentication. You can find your endpoint on the **Settings** page in the AWS IoT Core console.   
 - For ATS endpoints, you must use an ATS root CA certificate. ATS endpoints include the ```ats``` segment (for example: ```<prefix>-ats.iot.us-west-2.amazonaws.com```).  
 Make sure the Docker host is connected to the internet, and run the following command. This example uses the ```AmazonRootCA1.pem``` root CA certificate.
```
cd ~/Downloads/aws-greengrass-docker-1.8.1/certs 
sudo wget -O root.ca.pem https://www.amazontrust.com/repository/AmazonRootCA1.pem
```
 - For legacy endpoints, you must use a Verisign root CA certificate. Legacy endpoints **do not** include the ```ats``` segment (for example: ```<prefix>.iot.us-west-2.amazonaws.com```).
 Make sure the Docker host is connected to the internet, and run the following command.
```
cd ~/Downloads/aws-greengrass-docker-1.8.1/certs 
sudo wget -O root.ca.pem https://www.symantec.com/content/en/us/enterprise/verisign/roots/VeriSign-Class%203-Public-Primary-Certification-Authority-G5.pem
``` 

4- Run the following command to confirm that the ```root.ca.pem``` file is not empty.
```
cat ~/Downloads/aws-greengrass-docker-1.8.1/certs/root.ca.pem
```

#### On a Windows Computer
1- Use the AWS IoT Greengrass console to create a Greengrass group. Follow the steps in "Configure AWS IoT Greengrass on AWS IoT" (https://docs.aws.amazon.com/greengrass/latest/developerguide/gg-config.html). This process includes downloading certificates and the core configuration file.   
Skip step 8b of the procedure because AWS IoT Greengrass core and its runtime dependencies are already set up in the Docker image.   

2- Decompress the certificates and config file that you downloaded into your working directory where ```Dockerfile``` and ```docker-compose.yml``` are located. Use a utility like WinZip or 7-Zip to decompress ```<guid>-setup.tar.gz``` to ```C:\Users\%USERNAME%\Downloads\aws-greengrass-docker-1.8.1\```.

3- Download the root CA certificate into the directory where you decompressed the certificates and configuration file. The certificates enable your device to communicate with AWS IoT using the MQTT messaging protocol over TLS. For more information, including how to choose the appropriate root CA certificate, see the documentation on "Server Authentication in AWS IoT Core" (https://docs.aws.amazon.com/iot/latest/developerguide/managing-device-certs.html).  

**Important**: Your root CA certificate must match your endpoint, which uses Amazon Trust Services (ATS) server authentication (preferred) or legacy server authentication. You can find your endpoint on the **Settings** page in the AWS IoT Core console.   
 - For ATS endpoints, you must use an ATS root CA certificate. ATS endpoints include the ```ats``` segment (for example: ```<prefix>-ats.iot.us-west-2.amazonaws.com```).  
 Make sure the Docker host is connected to the internet. If you have ```curl``` installed, run the following commands in your command prompt. This example uses the ```AmazonRootCA1.pem``` root CA certificate.
```
cd C:\Users\%USERNAME%\Downloads\aws-greengrass-docker-1.8.1\certs
curl https://www.amazontrust.com/repository/AmazonRootCA1.pem -o root.ca.pem
```
 - For legacy endpoints, you must use a Verisign root CA certificate. Legacy endpoints **do not** include the ```ats``` segment (for example: ```<prefix>.iot.us-west-2.amazonaws.com```).  
 Make sure the Docker host is connected to the internet. If you have ```curl``` installed, run the following commands in your command prompt.
```
cd C:\Users\%USERNAME%\Downloads\aws-greengrass-docker-1.8.1\certs
curl https://www.symantec.com/content/en/us/enterprise/verisign/roots/VeriSign-Class%203-Public-Primary-Certification-Authority-G5.pem -o root.ca.pem
```

Note: If you don't have ```curl``` installed, follow these steps:
- In a web browser, open the root CA certificate:
 - For ATS endpoints, open an ATS root CA certificate (such as ```AmazonRootCA1.pem``` https://www.amazontrust.com/repository/AmazonRootCA1.pem).
 - For legacy endpoints, open the VeriSign Class 3 Public Primary G5 root CA certificate (https://www.symantec.com/content/en/us/enterprise/verisign/roots/VeriSign-Class%203-Public-Primary-Certification-Authority-G5.pem)
- Save the document as ```root.ca.pem``` in the ```C:\Users\%USERNAME%\Downloads\aws-greengrass-docker-1.8.1\certs``` directory, which contains the decompressed certificates. Depending on your browser, save the file directly from the browser or copy the displayed key to the clipboard and save it in Notepad.

4- Run the following command to confirm that the ```root.ca.pem``` file is not empty.
```
type C:\Users\%USERNAME%\Downloads\aws-greengrass-docker-1.8.1\certs\root.ca.pem
```

### Step 3. Run the Docker Container 
#### On Linux or Mac OSX
1- In the terminal, run the following command:
 -  To run the container using the default x86_64 configuration, replace ```<platform>``` with ```x86-64```.
 -  If you followed "Enable Multi-Platform Support for the AWS IoT Greengrass Docker Image", replace ```<platform>``` with ```armv7l```.
```
docker run --rm --init -it --name aws-iot-greengrass \
--entrypoint /greengrass-entrypoint.sh \
-v ~/Downloads/aws-greengrass-docker-1.8.1/certs:/greengrass/certs \
-v ~/Downloads/aws-greengrass-docker-1.8.1/config:/greengrass/config \
-p 8883:8883 \
<platform>/aws-iot-greengrass:1.8.1
```

 Note: If you have ```docker-compose``` installed, you can run the following commands instead:
```
cd ~/Downloads/aws-greengrass-docker-1.8.1
PLATFORM=<platform> GREENGRASS_VERSION=1.8.1 docker-compose down
PLATFORM=<platform> GREENGRASS_VERSION=1.8.1 docker-compose up
```

The output should look like this example:
```
Setting up greengrass daemon
Validating hardlink/softlink protection
Waiting for up to 30s for Daemon to start

Greengrass successfully started with PID: 10
```
Note: This command starts AWS IoT Greengrass and bind-mounts the certificates and config file. This will keep the interactive shell open, so that the Greengrass container can be removed/released later. You can find "Debugging" steps below if the container doesn't open the shell and exits immediately.

#### On a Windows Computer
1- In the command prompt, run the following command:
```
docker run --rm --init -it --name aws-iot-greengrass --entrypoint /greengrass-entrypoint.sh -v c:/Users/%USERNAME%/Downloads/aws-greengrass-docker-1.8.1/certs:/greengrass/certs -v c:/Users/%USERNAME%/Downloads/aws-greengrass-docker-1.8.1/config:/greengrass/config -p 8883:8883 x86-64/aws-iot-greengrass:1.8.1
```

Note: If you have ```docker-compose``` installed, you can run the following commands instead:
```
cd C:/Users/%USERNAME%/Downloads/aws-greengrass-docker-1.8.1
set PLATFORM=x86-64
set GREENGRASS_VERSION=1.8.1
docker-compose down
docker-compose up
```

Docker will prompt you to share your ```C:\``` drive with the Docker daemon. Allow it to bind-mount the ```C:\``` directory inside the Docker container. For more information, see "Shared drives" (https://docs.docker.com/docker-for-windows/#shared-drives) in the Docker documentation.

The output should look like this example:
```
Setting up greengrass daemon
Validating hardlink/softlink protection
Waiting for up to 30s for Daemon to start

Greengrass successfully started with PID: 10
```
Note: This command starts AWS IoT Greengrass and bind-mounts the certificates and config file. This will keep the interactive shell open, so that the Greengrass container can be removed/released later. You can find "Debugging" steps below if the container doesn't open the shell and exits immediately.

### Step 4: Configure "No container" Containerization for the Greengrass Group

When you run AWS IoT Greengrass in a Docker container, all Lambda functions must run without containerization. In this step, you set the the default containerization for the group to "No container". You must do this before you deploy the group for the first time.

1- In the AWS IoT console, choose "Greengrass", and then choose "Groups".  
2- Choose the group whose settings you want to change.  
3- Choose "Settings".  
4- Under "Lambda runtime environment", choose "No container".

For more information, see "Setting Default Containerization for Lambda Functions in a Group" (https://docs.aws.amazon.com/greengrass/latest/developerguide/lambda-group-config.html#lambda-containerization-groupsettings).

  Note: By default, Lambda functions use the group containerization setting. If you override the "No container" setting for any Lambda functions when AWS IoT Greengrass is running in a Docker container, the deployment fails.


### Step 5: Deploy Lambda Functions to the AWS IoT Greengrass Docker Container

You can deploy long-lived Lambda functions to the Greengrass Docker container.

1- Follow the steps in "Module 3 (Part 1): Lambda Functions on AWS IoT Greengrass" (https://docs.aws.amazon.com/greengrass/latest/developerguide/module3-I.html) to deploy a long-lived Hello-World Lambda function to the container.

### Debugging the Docker Container
To debug issues with the container, you can persist the runtime logs or attach an interactive shell.

#### Persist Greengrass Runtime Logs outside the Greengrass Docker Container
You can run the AWS IoT Greengrass Docker container after bind-mounting the ```/greengrass/ggc/var/log``` directory to persist logs even after the container has exited or is removed.
##### On Linux or Mac OSX
Run the following command in the terminal.

```
docker run --rm --init -it --name aws-iot-greengrass \
--entrypoint /greengrass-entrypoint.sh \
-v ~/Downloads/aws-greengrass-docker-1.8.1/certs:/greengrass/certs \
-v ~/Downloads/aws-greengrass-docker-1.8.1/config:/greengrass/config \
-v ~/Downloads/aws-greengrass-docker-1.8.1/log:/greengrass/ggc/var/log \
-p 8883:8883 \
<platform>/aws-iot-greengrass:1.8.1
```
You can then check your logs at ```~/Downloads/aws-greengrass-docker-1.8.1/log``` on your host to see what happened while Greengrass was running inside the Docker container.
##### On a Windows Computer
Run the following command in the command prompt.
```
cd C:\Users\%USERNAME%\Downloads\aws-greengrass-docker-1.8.1
mkdir log
docker run --rm --init -it --name aws-iot-greengrass --entrypoint /greengrass-entrypoint.sh -v c:/Users/%USERNAME%/Downloads/aws-greengrass-docker-1.8.1/certs:/greengrass/certs -v c:/Users/%USERNAME%/Downloads/aws-greengrass-docker-1.8.1/config:/greengrass/config -v c:/Users/%USERNAME%/Downloads/aws-greengrass-docker-1.8.1/log:/greengrass/ggc/var/log -p 8883:8883 x86-64/aws-iot-greengrass:1.8.1
```
You can then check your logs at ```c:/Users/%USERNAME%/Downloads/aws-greengrass-docker-1.8.1/log``` on your host to see what happened while Greengrass was running inside the Docker container.

#### Attach an Interactive Shell to the Greengrass Docker Container
You can attach an interactive shell to a running AWS IoT Greengrass Docker container. This can help you to investigate the state of the Greengrass Docker container.
##### On Linux or Mac OSX
Run the following command in the terminal.
```
docker exec -it $(docker ps -a -q -f "name=aws-iot-greengrass") /bin/bash
```

##### On a Windows Computer
Run the following commands in the command prompt.
```
docker ps -a -q -f "name=aws-iot-greengrass"
```

Replace ```<GG_CONTAINER_ID>``` with the ```container_id``` result from the previous command.
```
docker exec -it <GG_CONTAINER_ID> /bin/bash
```
### Stopping the Docker Container
To stop the AWS IoT Greengrass Docker Container, press Ctrl+C in your terminal or command prompt. 

This action will send SIGTERM to the Greengrass daemon process to tear down the Greengrass daemon process and all Lambda processes that were started by the daemon process. The Docker container is initialized with ```/dev/init``` process as PID 1, which helps in removing any leftover zombie processes. For more information, see the Docker run reference: https://docs.docker.com/engine/reference/commandline/run/#options.

## Troubleshooting
* If you see the message ```Firewall Detected while Sharing Drives``` when running Docker on a Windows computer, see the following Docker article for troubleshooting help: https://success.docker.com/article/error-a-firewall-is-blocking-file-sharing-between-windows-and-the-containers. This error can also occur if you are logged in on a Virtual Private Network (VPN) and your network settings are preventing the shared drive from being mounted. In that situation, turn off VPN and re-run the Docker container.
* If you receive an error like ```Cannot create container for the service greengrass: Conflict. The container name "/aws-iot-greengrass" is already in use.``` This is because the container name is used by the older run. To resolve this, remove the old Docker container by running: ```docker rm -f $(docker ps -a -q -f "name=aws-iot-greengrass")```
