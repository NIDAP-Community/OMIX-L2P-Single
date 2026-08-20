# hash:sha256:daf017e516838b4815679f7e79227530ce6b0ce62854ce0e61cb4102dd86cb5f
ARG REGISTRY_HOST
FROM $REGISTRY_HOST/codeocean/omix-r-pathway:r4.4.3-bioconductor3.20-v1

ARG DEBIAN_FRONTEND=noninteractive
ARG GIT_ASKPASS
COPY git-ask-pass /

ARG RCACHE_OPTIONS
RUN echo $RCACHE_OPTIONS >> $(Rscript -e 'cat(R.home())')/etc/Rprofile.site
RUN Rscript -e 'remotes::install_version("RCurl", "1.98-1.19")'

COPY postInstall /
RUN --mount=type=secret,id=secrets . /run/secrets/secrets \
    && /postInstall
