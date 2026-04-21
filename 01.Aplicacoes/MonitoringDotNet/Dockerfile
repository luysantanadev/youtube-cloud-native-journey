# See https://aka.ms/customizecontainer to learn how to customize your debug container and how Visual Studio uses this Dockerfile to build your images for faster debugging.

# This stage is used when running from VS in fast mode (Default for Debug configuration)
FROM mcr.microsoft.com/dotnet/aspnet:10.0-alpine AS base
USER $APP_UID
WORKDIR /app
EXPOSE 8080


# This stage is used to build the service project
FROM mcr.microsoft.com/dotnet/sdk:10.0-alpine AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src
COPY ["src/Mvc/Mvc.csproj", "src/Mvc/"]
RUN dotnet restore "./src/Mvc/Mvc.csproj"
COPY . .
WORKDIR "/src/src/Mvc"
RUN dotnet build "./Mvc.csproj" -c $BUILD_CONFIGURATION -o /app/build

# This stage is used to publish the service project to be copied to the final stage
FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "./Mvc.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false

# This stage is used in production or when running from VS in regular mode (Default when not using the Debug configuration)
FROM base AS final

COPY --from=pyroscope/pyroscope-dotnet:0.14.5-musl /Pyroscope.Profiler.Native.so /dotnet/Pyroscope.Profiler.Native.so
COPY --from=pyroscope/pyroscope-dotnet:0.14.5-musl /Pyroscope.Linux.ApiWrapper.x64.so /dotnet/Pyroscope.Linux.ApiWrapper.x64.so

# Activate the CLR native profiler. PYROSCOPE_PROFILING_ENABLED is intentionally
# omitted here (defaults to false) — enable it via ConfigMap/env at deploy time.
# For .NET 8+: allow profiling while disabling IPC and debug sockets for security.
ENV CORECLR_ENABLE_PROFILING=1 \
    CORECLR_PROFILER={BD1A650D-AC5D-4896-B64F-D6FA25D6B26A} \
    CORECLR_PROFILER_PATH=/dotnet/Pyroscope.Profiler.Native.so \
    LD_PRELOAD=/dotnet/Pyroscope.Linux.ApiWrapper.x64.so \
    LD_LIBRARY_PATH=/dotnet \
    DOTNET_EnableDiagnostics=1 \
    DOTNET_EnableDiagnostics_IPC=0 \
    DOTNET_EnableDiagnostics_Debugger=0 \
    DOTNET_EnableDiagnostics_Profiler=1 \
    PYROSCOPE_PROFILING_LOG_DIR=/tmp/pyroscope

WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "Mvc.dll"]