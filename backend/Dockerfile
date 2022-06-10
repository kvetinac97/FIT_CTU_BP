FROM maven:3.8.4-openjdk-17 AS backend-build

COPY . /backend
WORKDIR /backend
RUN mvn package
