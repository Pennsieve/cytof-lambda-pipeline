FROM public.ecr.aws/lambda/provided:latest-x86_64

ENV R_VERSION=4.3.0

RUN yum -y install wget

RUN echo "START DOCKER SETUP"

RUN yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm \
  && wget https://cdn.rstudio.com/r/centos-7/pkgs/R-${R_VERSION}-1-1.x86_64.rpm \
  && yum -y install R-${R_VERSION}-1-1.x86_64.rpm \
  && rm R-${R_VERSION}-1-1.x86_64.rpm \
  && yum -y install tar \
  && yum -y install golang

# Install Pennsieve

RUN wget https://github.com/Pennsieve/pennsieve-agent/archive/refs/tags/1.4.5.tar.gz

RUN tar -xvzf 1.4.5.tar.gz

WORKDIR /var/task/pennsieve-agent-1.4.5

RUN go install
RUN go build

RUN mv /var/task/pennsieve-agent-1.4.5/pennsieve-agent /usr/bin/
RUN ln -s /usr/bin/pennsieve-agent /usr/bin/pennsieve

RUN mkdir ~/.pennsieve
RUN touch ~/.pennsieve/config.ini

RUN mkdir /tmp/modified_files


ENV PATH="${PATH}:/opt/R/${R_VERSION}/bin/"

# System requirements for R packages
RUN yum -y install openssl-devel

RUN echo "INSTALL R PACKAGES"
RUN Rscript -e "install.packages(c('httr', 'jsonlite', 'logger', 'logging','stringr'), repos = 'https://cloud.r-project.org/')"


COPY runtime.R functions.R bootstrap.R ${LAMBDA_TASK_ROOT}/
RUN chmod 755 -R ${LAMBDA_TASK_ROOT}/

RUN printf '#!/bin/sh\ncd $LAMBDA_TASK_ROOT\nRscript bootstrap.R' > /var/runtime/bootstrap \
  && chmod +x /var/runtime/bootstrap

# Run function
CMD [ "functions.cytofDemo" ]