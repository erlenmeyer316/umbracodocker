################################
# Define deployment container
################################
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
# Set the working directory
WORKDIR /app
# set environment variables
ENV ASPNETCORE_URLS="http://+:80"
# expose container ports
EXPOSE 80

################################
# Define build container
################################ 
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
# Set the working directory for subsequent COPY and RUN commands
WORKDIR /src
# Copy source files from host to container
COPY ../src .
# Execute dotnet restore to restore dependencies specified in the .csproj file on the container
RUN dotnet restore "/src/UmbracoDockerProject/UmbracoDockerProject.csproj"
# Execute project build with all of its dependencies on the container
RUN dotnet publish "/src/UmbracoDockerProject/UmbracoDockerProject.csproj" -c Release -o /app/publish

################################
# Define runtime container
################################
FROM base AS runtime
# Create a nonroot group and user with explicit UMBRACO_RUNTIME_USER_ID 
RUN groupadd -r umbraco -g 1000
RUN useradd -u 1000 -r -g umbraco -m -d /home/umbraco -s /sbin/nologin -c "umbraco user" umbraco
RUN chmod -R 755 /home/umbraco
# Set the working directory for the subsequent COPY command
WORKDIR /app
# Copy from the build image /app/publish directory to the container filesystem
COPY --from=build /app/publish .
# create necessary directory for runtime template compilation
RUN mkdir -p /app/umbraco/Data/TEMP/InMemoryAuto
RUN mkdir -p /app/uSync
RUN mkdir -p /app/wwwroot/css
RUN mkdir -p /app/wwwroot/fonts
RUN mkdir -p /app/wwwroot/media
# give non-root user ownership of the app folder
RUN chmod -R 755 /app
RUN chown -R 1000:1000 /home/umbraco
RUN chown -R 1000:1000 /app
# make the non-root user the executing user of the container
USER umbraco
# Specify the command executed when the container is started
ENTRYPOINT ["dotnet", "UmbracoDockerProject.dll"]