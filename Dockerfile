FROM mcr.microsoft.com/dotnet/sdk:8.0 AS base
WORKDIR /app

# Install Petabridge.Cmd client so it can be invoked remotely via
# Docker or K8s 'exec` commands
RUN dotnet tool install --global pbm

FROM mcr.microsoft.com/dotnet/runtime:8.0 AS app
WORKDIR /app

# copy .NET Core global tool
COPY --from=base /root/.dotnet /root/.dotnet/

# Needed because https://stackoverflow.com/questions/51977474/install-dotnet-core-tool-dockerfile
ENV PATH="${PATH}:/root/.dotnet/tools"

# Set the entrypoint to keep the container running
ENTRYPOINT ["tail", "-f", "/dev/null"]