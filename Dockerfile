FROM bellsoft/liberica-runtime-container:jdk-25-stream-musl as builder
WORKDIR /home/app
COPY pom.xml .
COPY src ./src
# Install Maven 3.9
RUN apk add --no-cache maven
RUN mvn -Dmaven.test.skip=true clean package

FROM bellsoft/liberica-runtime-container:jdk-25-cds-slim-musl as optimizer
WORKDIR /app
COPY --from=builder /home/app/target/demo-1.0-SNAPSHOT.jar app.jar
RUN java -Djarmode=tools -jar app.jar extract --layers --destination extracted


FROM bellsoft/liberica-runtime-container:jdk-25-cds-slim-musl
WORKDIR /app
EXPOSE 8080
ENTRYPOINT ["java", "-Dspring.aot.enabled=true", "-XX:AOTCache=app.aot", "-Dspring.profiles.active=docker", "-jar", "/app/app.jar"]
COPY --from=optimizer /app/extracted/dependencies/ ./
COPY --from=optimizer /app/extracted/spring-boot-loader/ ./
COPY --from=optimizer /app/extracted/snapshot-dependencies/ ./
COPY --from=optimizer /app/extracted/application/ ./

RUN java -Dspring.aot.enabled=true -XX:AOTMode=record -XX:AOTConfiguration=app.aotconf -Dspring.context.exit=onRefresh -jar /app/app.jar
RUN java -Dspring.aot.enabled=true -XX:AOTMode=create -XX:AOTConfiguration=app.aotconf -XX:AOTCache=app.aot -jar /app/app.jar