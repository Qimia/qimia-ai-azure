FROM debian:stable-slim
RUN apt update && apt install -y git curl unzip
RUN git clone https://github.com/tfutils/tfenv.git ~/.tfenv
RUN ls ~/.tfenv
RUN ls ~/.tfenv/bin
RUN echo 'export PATH="$HOME/.tfenv/bin:$PATH"' >> ~/.bash_profile
RUN ln -s ~/.tfenv/bin/* /usr/local/bin

RUN tfenv install 1.6.0
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash
ENTRYPOINT []