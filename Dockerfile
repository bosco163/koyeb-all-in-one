FROM python:3.10-slim

# 安装基础工具、Nginx 和 Supervisor
RUN apt-get update && apt-get install -y \
    nginx \
    supervisor \
    git \
    && rm -rf /var/lib/apt/lists/*

# --- 项目 1: OpenAI Edge TTS ---
WORKDIR /app/tts
# 拉取 travisvn/openai-edge-tts 的源码 (它本质是 Python 脚本)
RUN git clone https://github.com/travisvn/openai-edge-tts.git .
RUN pip install --no-cache-dir -r requirements.txt

# --- 项目 2: 2025doubao-free-api ---
WORKDIR /app/doubao
# 拉取 doubao 项目源码
RUN git clone https://github.com/1994qrq/2025doubao-free-api.git .
# 如果该项目有依赖文件则安装，没有则跳过
RUN if [ -f requirements.txt ]; then pip install --no-cache-dir -r requirements.txt; fi
# 豆包项目可能需要额外的依赖，根据常见情况补充（如 bottle, requests 等）
RUN pip install bottle requests

# --- 配置 Nginx 和 Supervisor ---
# 复制配置文件 (假设这些文件在你的 git 根目录)
COPY nginx.conf /etc/nginx/sites-available/default
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# 设置环境变量
ENV PORT=8000

# 暴露端口 (Koyeb 默认检测 8000)
EXPOSE 8000

# 启动 Supervisor (它会同时启动 Nginx 和两个 Python 项目)
CMD ["/usr/bin/supervisord"]
