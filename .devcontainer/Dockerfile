FROM ghcr.io/browserless/chromium

# Get latest Flutter
USER root
RUN mkdir -p /usr/bin/flutter
RUN chown blessuser:blessuser /usr/bin/flutter -R

USER blessuser
RUN git clone -v -b stable https://github.com/flutter/flutter /usr/bin/flutter
RUN git -C /usr/bin/flutter fetch --tags && git -C /usr/bin/flutter checkout 3.35.1
RUN chmod +x /usr/bin/flutter/bin/flutter
ENV PATH="/usr/bin/flutter/bin:${PATH}"

# Disable telemetry
RUN flutter --disable-analytics

# Install flutter bash completion
RUN mkdir ~/.bash-completion -p
RUN flutter bash-completion > ~/.bash-completion/flutter
RUN chmod +x ~/.bash-completion/flutter

# Source flutter bash completion
RUN echo 'source ~/.bash-completion/flutter' >> ~/.bashrc
RUN /usr/bin/flutter/bin/flutter config --enable-web && /usr/bin/flutter/bin/flutter precache --web
ENV CHROME_BIN=/usr/bin/chromium
ENV CHROME_PATH=/usr/bin/chromium

