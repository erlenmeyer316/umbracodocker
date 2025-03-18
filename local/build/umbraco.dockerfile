####################################################
# Define global build variables with default values
####################################################
ARG UMBRACO_RUNTIME_PORT=80
ARG UMBRACO_RUNTIME_USER=umbraco-user
ARG UMBRACO_RUNTIME_USER_ID=1000
ARG UMBRACO_RUNTIME_GROUP=umbraco-group
ARG UMBRACO_RUNTIME_GROUP_ID=1000
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
# scope necessary global build variables into stage
ARG UMBRACO_RUNTIME_USER
ARG UMBRACO_RUNTIME_USER_ID
ARG UMBRACO_RUNTIME_GROUP
ARG UMBRACO_RUNTIME_GROUP_ID
# Create a nonroot group and user with explicit UMBRACO_RUNTIME_USER_ID 
RUN groupadd -r ${UMBRACO_RUNTIME_GROUP} -g ${UMBRACO_RUNTIME_GROUP_ID}
RUN useradd -u ${UMBRACO_RUNTIME_USER_ID} -r -g ${UMBRACO_RUNTIME_GROUP} -m -d /home/${UMBRACO_RUNTIME_USER} -s /sbin/nologin ${UMBRACO_RUNTIME_USER}
RUN chown -R ${UMBRACO_RUNTIME_USER_ID}:${UMBRACO_RUNTIME_GROUP_ID} /home/${UMBRACO_RUNTIME_USER}
RUN chown -R ${UMBRACO_RUNTIME_USER_ID}:${UMBRACO_RUNTIME_GROUP_ID} /home/${UMBRACO_RUNTIME_USER}
RUN chmod -R 755 /home/${UMBRACO_RUNTIME_USER}
# Set the working directory for the subsequent COPY command
WORKDIR /app
# Copy from the build image /app/publish directory to the container filesystem
COPY --from=build /app/publish .
# create necessary directory for runtime template compilation
#RUN mkdir -p /app/umbraco/Data/TEMP/InMemoryAuto
# give non-root user ownership of the app folder
RUN chown -R ${UMBRACO_RUNTIME_USER_ID}:${UMBRACO_RUNTIME_GROUP_ID} /app
# make the non-root user the executing user of the container
USER ${UMBRACO_RUNTIME_USER}
# Specify the command executed when the container is started
ENTRYPOINT ["dotnet", "UmbracoDockerProject.dll"]