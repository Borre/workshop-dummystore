FROM gradle:8.7-jdk21 AS builder
WORKDIR /app
COPY build.gradle settings.gradle gradlew gradlew.bat ./
COPY gradle gradle
COPY src src
RUN ./gradlew build -x test --no-daemon

FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY --from=builder /app/build/libs/catalog-api-0.0.1-SNAPSHOT.jar app.jar
RUN apk add --no-cache curl
EXPOSE 8080
HEALTHCHECK --interval=15s --timeout=3s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:8080/actuator/health || exit 1
ENTRYPOINT ["java", "-jar", "app.jar"]
