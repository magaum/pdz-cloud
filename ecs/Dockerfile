FROM mcr.microsoft.com/dotnet/aspnet:5.0 AS base
WORKDIR /app
EXPOSE 80
ENV ASPNETCORE_URLS http://+:80

FROM mcr.microsoft.com/dotnet/sdk:5.0 AS build
WORKDIR /src
COPY ["/src/Contagem.Api/Contagem.Api.csproj", "./Contagem.Api/Contagem.Api.csproj"]
RUN dotnet restore "Contagem.Api/Contagem.Api.csproj"
COPY "./src/" .
WORKDIR "/src/."
RUN dotnet build "Contagem.Api/Contagem.Api.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "Contagem.Api/Contagem.Api.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "Contagem.Api/Contagem.Api.dll"]