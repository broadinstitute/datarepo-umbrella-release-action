FROM alpine:latest

ENV HELM_VERSION="v3.2.4" \
    YQ_VERSION="3.2.1" \
    KUBE_LATEST_VERSION="v1.18.3"

RUN apk add --no-cache ca-certificates bash git openssh curl \
  && wget -q https://storage.googleapis.com/kubernetes-release/release/${KUBE_LATEST_VERSION}/bin/linux/amd64/kubectl -O /usr/local/bin/kubectl \
  && chmod +x /usr/local/bin/kubectl \
  && wget -q https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz -O - | tar -xzO linux-amd64/helm > /usr/local/bin/helm \
  && chmod +x /usr/local/bin/helm

# install yq
RUN wget -O /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64" && \
  chmod +x /usr/local/bin/yq

# copy down action functions
COPY ["src", "/src/"]
RUN chmod -R +x /src

ENTRYPOINT ["/src/main.sh"]
