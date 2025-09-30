FROM ghcr.io/browserless/chromium

# Install unzip
USER root
RUN apt-get update && apt-get install -y unzip
RUN mkdir /flutter && chown -R 1000:1000 /flutter

# Change to default user
USER 1000

# Get latest Flutter
RUN git clone -v -b stable https://github.com/flutter/flutter /flutter
ENV PATH="/flutter/bin:${PATH}"

# Disable telemetry
RUN flutter --disable-analytics

# Install flutter bash completion
RUN mkdir ~/.bash-completion -p
RUN flutter bash-completion > ~/.bash-completion/flutter
RUN chmod +x ~/.bash-completion/flutter

# Source flutter bash completion
RUN echo 'source ~/.bash-completion/flutter' >> ~/.bashrc