FROM python:3.10-slim

# 1. 安装基础工具
RUN apt-get update && apt-get install -y \
    nginx \
    supervisor \
    git \
    curl \
    gnupg \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# 2. 安装 Node.js 20 (为了运行豆包项目)
RUN mkdir -p /etc/apt/keyrings
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
RUN echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
RUN apt-get update && apt-get install -y nodejs && npm install -g yarn

# ===========================
# 3. 部署 OpenAI Edge TTS (Python)
# ===========================
WORKDIR /app/tts
RUN git clone https://github.com/travisvn/openai-edge-tts.git .
# 安装依赖
RUN pip install --no-cache-dir -r requirements.txt

# ===========================
# 4. 部署 Doubao Free API (Node.js)
# ===========================
WORKDIR /app/doubao
RUN git clone https://github.com/1994qrq/2025doubao-free-api.git .
# 安装 Node 依赖并构建
RUN yarn install
RUN yarn run build

# --- 关键：修改豆包端口 ---
# 豆包默认监听 8000，我们需要把它改为 3000 以便给 Nginx 让路
# 我们尝试通过环境变量 PORT=3000 控制，但为了保险，用 sed 暴力替换源码中的端口
RUN grep -rl "8000" . | xargs sed -i 's/8000/3000/g'

# ===========================
# 5. 配置 Nginx 和 Supervisor
# ===========================
# 切换回根目录复制配置
WORKDIR /app
# 假设 nginx.conf 和 supervisord.conf 在仓库根目录
COPY nginx.conf /etc/nginx/sites-available/default
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# 方便调试：列出所有文件结构，这样如果出错看日志能知道文件在哪
RUN echo "Listing directories for debug:" && ls -R /app

# 环境变量
ENV PORT=8000
EXPOSE 8000

# 启动
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
