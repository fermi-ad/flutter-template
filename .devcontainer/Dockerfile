FROM ghcr.io/browserless/chromium

# Get latest Flutter
USER blessuser
RUN mkdir -p ~/flutter
RUN git clone -v -b stable https://github.com/flutter/flutter ~/flutter
ENV PATH="/home/blessuser/flutter/bin:${PATH}"

# Disable telemetry
RUN flutter --disable-analytics

# Install flutter bash completion
RUN mkdir ~/.bash-completion -p
RUN flutter bash-completion > ~/.bash-completion/flutter
RUN chmod +x ~/.bash-completion/flutter

# Source flutter bash completion
RUN echo 'source ~/.bash-completion/flutter' >> ~/.bashrc
