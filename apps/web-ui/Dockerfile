FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY . .
RUN dotnet restore
RUN dotnet publish -c Release -o /app/publish

FROM mcr.microsoft.com/dotnet/aspnet:8.0
RUN apt-get update -qq && apt-get install -y -qq curl && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=build /app/publish .

HEALTHCHECK --interval=15s --timeout=3s --start-period=15s --retries=3 \
    CMD curl -f http://localhost:5000/health || exit 1

ENV ASPNETCORE_URLS=http://+:5000
EXPOSE 5000

ENTRYPOINT ["dotnet", "web-ui.dll"]
