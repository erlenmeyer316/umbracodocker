####################################################
# Define global build variables with default values
####################################################
ARG UMBRACO_RUNTIME_DOTNET_VER=8.0

################################
# Define deployment container
################################
FROM mcr.microsoft.com/dotnet/aspnet:${UMBRACO_RUNTIME_DOTNET_VER} AS base
# scope necessary global build variables into stage     
ARG UMBRACO_RUNTIME_PORT
# Set the working directory
WORKDIR /app
# set environment variables
ENV ASPNETCORE_URLS="http://+:${UMBRACO_RUNTIME_PORT}"
# expose container ports
EXPOSE ${UMBRACO_RUNTIME_PORT}

################################
# Define build container
################################ 
FROM mcr.microsoft.com/dotnet/sdk:${UMBRACO_RUNTIME_DOTNET_VER} AS build
# Set the working directory for subsequent COPY and RUN commands
WORKDIR /src
# Copy source files from host to container
COPY ../../src .
# Execute dotnet restore to restore dependencies specified in the .csproj file on the container
RUN dotnet restore "/src/UmbracoDockerProject/UmbracoDockerProject.csproj"
# Execute project build with all of its dependencies on the container
RUN dotnet publish "/src/UmbracoDockerProject/UmbracoDockerProject.csproj" -c Release -o /app/publish

################################
# Define runtime container
################################
FROM base AS runtime

# Set the working directory for the subsequent COPY command
WORKDIR /app
# Copy from the build image /app/publish directory to the container filesystem
COPY --from=build /app/publish .
# Specify the command executed when the container is started
ENTRYPOINT ["dotnet", "UmbracoDockerProject.dll"]