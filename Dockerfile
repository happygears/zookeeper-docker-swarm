FROM zookeeper:3.5

ARG version

RUN apt-get update && apt-get install -y \
  bash \
  curl \
  dnsutils \
  jq \
  net-tools \
  procps \
  && apt-get clean all && rm -rf /var/lib/apt/lists/*


ARG DIR=/usr/local/bin
COPY docker-healthcheck \
docker-swarm-entrypoint.sh \
zookeeper-cleanup.sh \
$DIR/

RUN chgrp 0 $DIR/docker-healthcheck && \
chmod +x $DIR/docker-healthcheck \
$DIR/docker-swarm-entrypoint.sh \
$DIR/zookeeper-cleanup.sh && \
echo 0 | tee $DIR/HEALTHY $DIR/INITIALIZED 1>/dev/null

# Install Zookeeper client
RUN curl -Lfs --retry 5 https://github.com/let-us-go/zkcli/releases/download/v0.3.0/zkcli-0.3.0-linux-amd64.tar.gz | tar zxf - && \
  mv zkcli-0.3.0-linux-amd64/zkcli /usr/local/bin && \
  rm -fr zkcli-0.3.0-linux-amd64 && \
  chown root:root /usr/local/bin/zkcli

ENV ZOO_TICK_TIME 2000
ENV ZOO_INIT_LIMIT 5
ENV ZOO_SYNC_LIMIT 2
ENV ZOO_RECONFIG_ENABLED true
ENV ZOO_SKIP_ACL yes
ENV ZOO_DYNAMIC_CONFIG_FILE $ZOO_CONF_DIR/zoo.cfg.dynamic
ENV ZOO_PORT 2181

ENV image_version $version

HEALTHCHECK --interval=10s --timeout=5s CMD ["docker-healthcheck"]

ENTRYPOINT ["docker-swarm-entrypoint.sh"]
CMD ["zkServer.sh", "start-foreground"]
