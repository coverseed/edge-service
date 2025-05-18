# 第一阶段的 OpenJDK 基础镜像
FROM eclipse-temurin:17 AS builder
# 将当前工作目录改为 "workspace"
WORKDIR workspace
# 构建参数，指定应用程序 JAR 文件在项目中的位置
ARG JAR_FILE=target/*.jar
# 将应用程序 JAR 文件从本地机器复制到 workspace 文件夹内的镜像中
COPY ${JAR_FILE} edge-service.jar
# 应用分层 JAR 模式从存档中提取镜像层
RUN java -Djarmode=layertools -jar edge-service.jar extract

# 第二阶段的 OpenJDK 基础镜像
FROM eclipse-temurin:17
# 创建一个 "spring" 用户
RUN useradd spring
# 将 "spring" 配置为当前用户
USER spring
# 将当前工作目录改为 "workspace"
WORKDIR workspace
# 将每个 JAR 层从第一阶段复制到第二阶段的 "workspace" 文件夹内
COPY --from=builder workspace/dependencies/ ./
COPY --from=builder workspace/spring-boot-loader/ ./
COPY --from=builder workspace/snapshot-dependencies/ ./
COPY --from=builder workspace/application/ ./
# 使用 Spring Boot Launcher 从层中启动应用程序
ENTRYPOINT ["java", "org.springframework.boot.loader.JarLauncher"]