# 第 1 阶段：构建环境
# 使用官方 Node.js 镜像作为构建环境的基础。
# 建议使用 LTS (Long Term Support) 版本，并指定具体版本以确保构建的可重复性。
# Alpine Linux 是一个轻量级的选择，可以减小最终镜像的大小。
FROM node:18-alpine AS build

# 设置工作目录
WORKDIR /usr/src/app

# 将 package.json 和 package-lock.json (或 yarn.lock) 复制到工作目录
# 使用通配符 *.json 可以同时匹配 package.json 和 package-lock.json
COPY package*.json ./

# 安装生产环境依赖
# 使用 npm ci 而不是 npm install 来确保使用 package-lock.json 中的精确版本，
# 并且清理已有的 node_modules 目录，这对于 CI/CD 环境更可靠。
# --only=production 标志确保只安装生产依赖，避免不必要的开发依赖。
RUN npm ci --only=production

# 复制应用程序的其余源代码
COPY . .

# 如果你的项目有构建步骤 (例如，TypeScript 编译、前端资源打包)
# 请在此处添加构建命令
# RUN npm run build

# 第 2 阶段：生产环境
# 使用一个更小的基础镜像来运行应用程序，以减少攻击面和镜像大小。
FROM node:18-alpine

# 设置工作目录
WORKDIR /usr/src/app

# 从构建环境复制生产依赖 (node_modules)
COPY --from=build /usr/src/app/node_modules ./node_modules

# 从构建环境复制应用程序代码
# 如果有构建步骤，请确保复制的是构建后的产物
COPY --from=build /usr/src/app/dist ./dist  # 假设构建产物在 dist 目录
COPY --from=build /usr/src/app/package*.json ./

# 或者，如果不需要构建步骤，直接复制源代码
# COPY --from=build /usr/src/app .

# 设置生产环境变量
ENV NODE_ENV=production

# 暴露应用程序运行的端口
# 这只是一个元数据声明，实际端口映射在 `docker run` 时进行
EXPOSE 3000 # 将 3000 替换为你的应用程序实际使用的端口

# 创建一个非 root 用户来运行应用程序，以增强安全性
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

# 启动应用程序的命令
# 直接使用 node 启动，而不是通过 npm start，这样可以更好地处理信号 (如 SIGTERM, SIGINT)
# 将 'dist/server.js' 替换为你的应用程序入口文件路径
CMD [ "node", "dist/server.js" ] # 如果有构建步骤
# CMD [ "node", "server.js" ] # 如果没有构建步骤
