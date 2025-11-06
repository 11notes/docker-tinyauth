# ╔═════════════════════════════════════════════════════╗
# ║                       SETUP                         ║
# ╚═════════════════════════════════════════════════════╝
# GLOBAL
  ARG APP_UID=1000 \
      APP_GID=1000 \
      BUILD_SRC=https://github.com/steveiliop56/tinyauth.git \
      BUILD_ROOT=/go/tinyauth
  ARG BUILD_BIN=${BUILD_ROOT}/tinyauth

# :: FOREIGN IMAGES
  FROM 11notes/distroless AS distroless
  FROM 11notes/distroless:localhealth AS distroless-localhealth

# ╔═════════════════════════════════════════════════════╗
# ║                       BUILD                         ║
# ╚═════════════════════════════════════════════════════╝
# :: TINYAUTH FRONTEND
  FROM oven/bun:alpine AS frontend
  ARG APP_VERSION \
      BUILD_SRC \
      BUILD_ROOT=/home/bun/app/tinyauth/frontend

  RUN set -ex; \
    apk --update --no-cache add \
      git;

  RUN set -ex; \
    git clone ${BUILD_SRC} -b v${APP_VERSION};

  RUN set -ex; \
    cd ${BUILD_ROOT}; \
    bun install; \
    bun run build;

# :: TINYAUTH
  FROM 11notes/go:1.25 AS build
  ARG APP_VERSION \
      BUILD_SRC \
      BUILD_ROOT \
      BUILD_BIN

  RUN set -ex; \
    git clone ${BUILD_SRC} -b v${APP_VERSION};

  COPY --from=frontend /home/bun/app/tinyauth/frontend/dist ${BUILD_ROOT}/internal/assets/dist

  RUN set -ex; \
    cd ${BUILD_ROOT}; \
    sed -i 's|var Version = "development"|var Version = "'${APP_VERSION}'"|' ./internal/config/config.go; \
    # disable telemetry
    sed -i 's|go app.heartbeat()|// go app.heartbeat()|' ./internal/bootstrap/app_bootstrap.go;

  RUN set -ex; \
    cd ${BUILD_ROOT}; \
    eleven go build ${BUILD_BIN} main.go; \
    eleven distroless ${BUILD_BIN};

# :: FILE SYSTEM
  FROM alpine AS file-system
  ARG APP_ROOT
  
  RUN set -ex; \
    mkdir -p /distroless${APP_ROOT}/var;


# ╔═════════════════════════════════════════════════════╗
# ║                       IMAGE                         ║
# ╚═════════════════════════════════════════════════════╝
# :: HEADER
  FROM scratch

  # :: default arguments
    ARG TARGETPLATFORM \
        TARGETOS \
        TARGETARCH \
        TARGETVARIANT \
        APP_IMAGE \
        APP_NAME \
        APP_VERSION \
        APP_ROOT \
        APP_UID \
        APP_GID \
        APP_NO_CACHE

  # :: default environment
    ENV APP_IMAGE=${APP_IMAGE} \
        APP_NAME=${APP_NAME} \
        APP_VERSION=${APP_VERSION} \
        APP_ROOT=${APP_ROOT}

  # :: app specific environment
    ENV RESOURCES_DIR=${APP_ROOT}/var \
        DATABASE_PATH=${APP_ROOT}/var/tinyauth.db \
        DISABLE_ANALYTICS=true

  # :: multi-stage
    COPY --from=distroless / /
    COPY --from=distroless-localhealth / /
    COPY --from=build /distroless/ /
    COPY --from=file-system --chown=${APP_UID}:${APP_GID} /distroless/ /

# :: PERSISTENT DATA
  VOLUME ["${APP_ROOT}/var"]

# :: HEALTH
  HEALTHCHECK --interval=5s --timeout=2s --start-period=5s \
    CMD ["/usr/local/bin/localhealth", "http://127.0.0.1:3000/api/health", "-I"]

# :: EXECUTE
  USER ${APP_UID}:${APP_GID}
  ENTRYPOINT ["/usr/local/bin/tinyauth"]