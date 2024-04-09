FROM ubuntu:20.04
ARG DEBIAN_FRONTEND=noninteractive 
ARG node_default_version="18"

RUN DEBIAN_FRONTEND=noninteractive apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends \
    apt-transport-https \
    apt-utils \
    ca-certificates \
    curl \
    git \
    iputils-ping \
    jq \
    lsb-release \
    software-properties-common \
    gnupg \
    netcat \
    wget \
    libcurl4 \
    libunwind8

# Installing MS dependencies and powershell
RUN wget -q https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
RUN dpkg -i packages-microsoft-prod.deb
RUN DEBIAN_FRONTEND=noninteractive apt-get -y update

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y tzdata
RUN ln -fs /usr/share/zoneinfo/Australia/Sydney /etc/localtime
RUN dpkg-reconfigure --frontend noninteractive tzdata

RUN apt-get -y install powershell

# Installing Azure Powershell module
RUN pwsh -c "Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force"

# Installing bicep
RUN curl -Lo bicep https://github.com/Azure/bicep/releases/latest/download/bicep-linux-x64
RUN chmod +x ./bicep
RUN mv ./bicep /usr/local/bin/bicep
RUN bicep --help


# Installing Dotnet
ARG DOTNET_CLI_TELEMETRY_OPTOUT=1
COPY scripts/apt_preferences_dotnet.txt /etc/apt/preferences.d/dotnet
RUN DEBIAN_FRONTEND=noninteractive apt-get update

RUN apt-get install dotnet-sdk-6.0 -y
RUN apt-get install dotnet-sdk-7.0 -y
RUN apt-get install dotnet-sdk-8.0 -y

RUN rm /etc/apt/preferences.d/dotnet
RUN DEBIAN_FRONTEND=noninteractive apt-get update

# Install .Net tools
ARG DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1
ARG DOTNET_NOLOGO=1
ARG DOTNET_MULTILEVEL_LOOKUP=0
# prepend_etc_environment_path '$HOME/.dotnet/tools'
RUN dotnet tool install nbgv --tool-path '/etc/skel/.dotnet/tools'
RUN dotnet tool install GitVersion.Tool --version 5.* --tool-path '/etc/skel/.dotnet/tools'

# Installing NODE.JS
RUN curl -fsSL https://raw.githubusercontent.com/tj/n/master/bin/n -o ~/n
RUN bash ~/n "$node_default_version"
# Installing node modules
# RUN npm install -g grunt gulp n parcel tsc newman vercel webpack webpack-cli netlify lerna yarn
RUN echo "Creating the symlink for [now] command to vercel CLI"
RUN ln -s /usr/local/bin/vercel /usr/local/bin/now
# fix global modules installation as regular user; related issue https://github.com/actions/runner-images/issues/3727
RUN chmod -R 777 /usr/local/lib/node_modules 
RUN chmod -R 777 /usr/local/bin
RUN rm -rf ~/n

# RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash -
# RUN curl -fsSL https://deb.nodesource.com/setup_17.x | bash -
# RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
# RUN curl -fsSL https://deb.nodesource.com/setup_19.x | bash -
# RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
# RUN curl -fsSL https://deb.nodesource.com/setup_21.x | bash -

# Installing az and bicep in az
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash
RUN az bicep install

# Cleaning up
RUN rm -rf /var/lib/apt/lists/*
RUN apt-get clean all

# Can be 'linux-x64', 'linux-arm64', 'linux-arm', 'rhel.6-x64'.
ENV TARGETARCH=linux-x64

WORKDIR /azp

COPY azure-pipelines-agent/start.sh .
RUN chmod +x start.sh

ENTRYPOINT [ "./start.sh" ]