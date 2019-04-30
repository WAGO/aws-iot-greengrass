FROM arm32v7/alpine as base
LABEL maintainer = Wago <dirk.meihoefer@wago.com>
LABEL maintainer = Wago <sergei.ikkert@wago.com>


# Set ENV_VAR for Greengrass RC to be untarred inside Docker Image
ARG greengrass_version=1.8.1
ARG GREENGRASS_RELEASE_URL=https://d1onfpft10uf5o.cloudfront.net/greengrass-core/downloads/${greengrass_version}/greengrass-linux-armv7l-${greengrass_version}.tar.gz

COPY resources / 

# Insert your own interception certificate for operation behind a corporate firewall
# COPY <yourCertificate.cer> /usr/local/share/ca-certificates/<yourCertificate.cer>

# Install Greengrass Core Dependencies
RUN apk update && \
    apk add tar gzip wget xz shadow libc6-compat ca-certificates iproute2 python && \
    wget $GREENGRASS_RELEASE_URL

# RUN apk add openjdk8-jre && \
#     ln -s /usr/bin/java /usr/local/bin/java8
# RUN wget https://nodejs.org/dist/v6.10.2/node-v6.10.2-linux-x64.tar.xz && \
#     tar xf node-v6.10.2-linux-x64.tar.xz && \
#     cp node-v6.10.2-linux-x64/bin/node /usr/bin/node && \
#     ln -s /usr/bin/node /usr/bin/nodejs6.10
    
RUN apk del wget

# Copy Greengrass Licenses AWS IoT Greengrass Docker Image
COPY greengrass-license-v1.pdf /

# Copy start-up script
COPY "greengrass-entrypoint.sh" /
RUN chmod +x /greengrass-entrypoint.sh

# Setup Greengrass inside Docker Image
RUN export GREENGRASS_RELEASE=$(basename $GREENGRASS_RELEASE_URL) && \
    tar xzf $GREENGRASS_RELEASE -C / && \
    rm $GREENGRASS_RELEASE && \
    useradd -r ggc_user && \
    groupadd -r ggc_group

FROM scratch as final
COPY --from=base / /

# Expose 8883 to pub/sub MQTT messages
EXPOSE 8883

ENTRYPOINT [ "/greengrass-entrypoint.sh" ]
