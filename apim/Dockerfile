FROM wso2/wso2am:4.5.0-rocky

# Install apictl based on architecture
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
        curl -sSL -O https://github.com/wso2/product-apim-tooling/releases/download/v4.5.0/apictl-4.5.0-linux-amd64.tar.gz && \
        tar -xzf apictl-4.5.0-linux-amd64.tar.gz && \
        rm apictl-4.5.0-linux-amd64.tar.gz; \
    elif [ "$ARCH" = "aarch64" ]; then \
        curl -sSL -O https://github.com/wso2/product-apim-tooling/releases/download/v4.5.0/apictl-4.5.0-linux-arm64.tar.gz && \
        tar -xzf apictl-4.5.0-linux-arm64.tar.gz && \
        rm apictl-4.5.0-linux-arm64.tar.gz; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi

# Add apictl to PATH (it extracts into /home/wso2carbon/apictl by default)
ENV PATH="/home/wso2carbon/apictl:$PATH"

COPY PizzaShackAPI /home/wso2carbon/PizzaShackAPI/
COPY secrets.env /home/wso2carbon/secrets.env
COPY update-tenant-admin-key.sh /home/wso2carbon/update-tenant-admin-key.sh
COPY create-commercial-sub-policy.sh /home/wso2carbon/create-commercial-sub-policy.sh
COPY custom-entrypoint.sh /home/wso2carbon/custom-entrypoint.sh

USER root
RUN chmod +x /home/wso2carbon/update-tenant-admin-key.sh && \
    chmod +x /home/wso2carbon/create-commercial-sub-policy.sh && \
    chmod +x /home/wso2carbon/custom-entrypoint.sh
# Permissions: 400 (read-only for owner) - Safer for secrets
RUN chown 10001:10001 /home/wso2carbon/secrets.env && \
    chmod 400 /home/wso2carbon/secrets.env
USER wso2carbon

ENTRYPOINT ["/home/wso2carbon/custom-entrypoint.sh"]
