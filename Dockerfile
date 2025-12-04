FROM bellsoft/liberica-runtime-container:jdk-25-stream-musl as builder
WORKDIR /home/app
COPY pom.xml .
COPY src ./src
# Install Maven 3.9
RUN apk add --no-cache maven
RUN mvn clean compile spring-boot:process-aot package -DskipTests=true

FROM bellsoft/liberica-runtime-container:jdk-25-cds-slim-musl as optimizer
WORKDIR /app
COPY --from=builder /home/app/target/demo-1.0-SNAPSHOT.jar app.jar
RUN java -Djarmode=tools -jar app.jar extract --destination extracted
RUN ls -l /app/extracted

FROM bellsoft/liberica-runtime-container:jdk-25-cds-slim-musl
WORKDIR /app
EXPOSE 8080
ENV MONGODB_COLLECTION_NAME=persons
ENTRYPOINT ["java", "-Dspring.aot.enabled=true", "-XX:AOTCache=app.aot", "-Dspring.profiles.active=docker", "-jar", "/app/app.jar"]
COPY --from=optimizer /app/extracted/lib/ ./lib/
COPY --from=optimizer /app/extracted/app.jar ./
RUN ls -l /app
RUN java -Dspring.aot.enabled=true -Dspring.context.exit=onRefresh -XX:AOTCacheOutput=app.aot -jar /app/app.jar
