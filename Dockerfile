ARG CLI_VERSION=2.41.0
FROM mcr.microsoft.com/azure-cli:${CLI_VERSION}
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
