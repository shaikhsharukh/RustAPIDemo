#!/bin/sh


# Working Version 1 (minified build)
#!/bin/sh

ARG RUST_VERSION=1.71.0
ARG APP_NAME=serverapi
FROM rust:${RUST_VERSION}-slim-bullseye AS build
ARG APP_NAME
WORKDIR /app
COPY . .
ENV DATABASE_URL=sqlite:database.sqlite

RUN cargo build --release
EXPOSE 8000
CMD ["/app/target/release/serverapi"]

FROM debian:bullseye-slim AS final

COPY --from=build app/target/release/serverapi /serverapi
COPY --from=build app/database.sqlite /database.sqlite


EXPOSE 8000
ENV DATABASE_URL=sqlite:database.sqlite
ENV RUST_BACKTRACE=full
ENV RUST_LIB_BACKTRACE=1

CMD ["/serverapi"]

# Working Version 1

# comands to build and publish
#docker build -t serverapi .
#docker images
#docker tag serverapi devdocked/serverapi:v1
#docker push devdocked/serverapi:v1



# RUN sudo chmod -R 777 /database.sqlite
# Build the application.
# Leverage a cache mount to /usr/local/cargo/registry/
# for downloaded dependencies and a cache mount to /app/target/ for 
# compiled dependencies which will speed up subsequent builds.
# Leverage a bind mount to the src directory to avoid having to copy the
# source code into the container. Once built, copy the executable to an
# output directory before the cache mounted /app/target is unmounted.
# RUN --mount=type=bind,source=src,target=src \
#     --mount=type=bind,source=Cargo.toml,target=Cargo.toml \
#     --mount=type=bind,source=Cargo.lock,target=Cargo.lock \
#     --mount=type=bind,source=database.sqlite,target=database.sqlite \
#     --mount=type=cache,target=/app/target/ \
#     --mount=type=cache,target=/usr/local/cargo/registry/ \
#     <<EOF
# set -e
# cargo build --locked --release
# cp ./target/release/$APP_NAME /bin/server
# cp database.sqlite /bin/server
# EOF



# ################################################################################
# # Create a new stage for running the application that contains the minimal
# # runtime dependencies for the application. This often uses a different base
# # image from the build stage where the necessary files are copied from the build
# # stage.
# #
# # The example below uses the debian bullseye image as the foundation for running the app.
# # By specifying the "bullseye-slim" tag, it will also use whatever happens to be the
# # most recent version of that tag when you build your Dockerfile. If
# # reproducability is important, consider using a digest
# # (e.g., debian@sha256:ac707220fbd7b67fc19b112cee8170b41a9e97f703f588b2cdbbcdcecdd8af57).
# FROM debian:bullseye-slim AS final

# # Create a non-privileged user that the app will run under.
# # See https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#user
# ARG UID=10001
# RUN adduser \
#     --disabled-password \
#     --gecos "" \
#     --home "/nonexistent" \
#     --shell "/sbin/nologin" \
#     --no-create-home \
#     --uid "${UID}" \
#     appuser
# USER appuser

# #RUN ["ls","/bin/server"]
# # Copy the executable from the "build" stage.
# COPY --from=build /bin/server /bin/

# # Expose the port that the application listens on.
# EXPOSE 8000
# # ENV DATABASE_URL=sqlite:database.sqlite
# # ENV RUST_BACKTRACE=full
# # ENV RUST_LIB_BACKTRACE=1

# # What the container should run when it is started.
# CMD ["/bin/server"]
# #["ls","/bin","-a"]
# #,"/bin/server"]
