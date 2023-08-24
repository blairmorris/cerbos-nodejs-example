# syntax=docker/dockerfile:1
FROM node:19 AS build
WORKDIR /app
COPY ["client/package.json", "client/package-lock.json*", "./"]
RUN npm i
COPY client/ .
# https://github.com/parcel-bundler/parcel/issues/7126
RUN rm -rf .parcel-cache/
RUN npm run build

FROM golang:1.19
COPY --from=build /app/dist /app/client/dist
WORKDIR /app
COPY go.mod ./
COPY go.sum ./
ENV GIT_SSL_NO_VERIFY=1
RUN apt-get update && apt-get install -y ca-certificates openssl
ARG cert_location=/usr/local/share/ca-certificates
RUN openssl s_client -showcerts -connect github.com:443 </dev/null 2>/dev/null|openssl x509 -outform PEM > ${cert_location}/github.crt
RUN openssl s_client -showcerts -connect proxy.golang.org:443 </dev/null 2>/dev/null|openssl x509 -outform PEM >  ${cert_location}/proxy.golang.crt
RUN update-ca-certificates
RUN go mod download
COPY main.go ./
RUN go build -o /server
CMD [ "/server" ]
