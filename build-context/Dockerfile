ARG greengrass_version=1.11.6
FROM arm32v7/alpine as base
LABEL maintainer = Wago <dirk.meihoefer@wago.com>
LABEL maintainer = Wago <sergei.ikkert@wago.com>


# Set ENV_VAR for Greengrass RC to be untarred inside Docker Image
ARG greengrass_version
ENV gg_version=1.11.6
ARG GREENGRASS_RELEASE_URL=https://d1onfpft10uf5o.cloudfront.net/greengrass-core/downloads/${greengrass_version}/greengrass-linux-armv7l-${greengrass_version}.tar.gz

# Insert your own interception certificate for operation behind a corporate firewall
# COPY <yourCertificate.cer> /usr/local/share/ca-certificates/<yourCertificate.cer>

# Install Greengrass Core Dependencies
RUN apk update && \
    apk add curl jq tar gzip wget xz shadow libc6-compat ca-certificates iproute2 python3 && \
    wget $GREENGRASS_RELEASE_URL

    
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

FROM scratch as slim
ARG greengrass_version
ENV GG_VERSION=${greengrass_version}
COPY --from=base / /
EXPOSE 8883
ENTRYPOINT [ "/greengrass-entrypoint.sh" ]

FROM slim as full
ARG greengrass_version
ENV GG_VERSION=${greengrass_version}
RUN apk add openjdk8-jre nodejs && \
    ln -s /usr/bin/java /usr/local/bin/java8
EXPOSE 8883
ENTRYPOINT [ "/greengrass-entrypoint.sh" ]
