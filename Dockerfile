FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

COPY src/BlueGreenApi/BlueGreenApi.csproj src/BlueGreenApi/
RUN dotnet restore src/BlueGreenApi/BlueGreenApi.csproj

COPY src/BlueGreenApi/ src/BlueGreenApi/
RUN dotnet publish src/BlueGreenApi/BlueGreenApi.csproj -c Release -o /app/publish /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app

RUN useradd --create-home --uid 10001 appuser
COPY --from=build /app/publish .
RUN chown -R appuser:appuser /app
USER appuser

ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080

ENTRYPOINT ["dotnet", "BlueGreenApi.dll"]
