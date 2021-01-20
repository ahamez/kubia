# ---------------------------------------------------------------- #
FROM rust:1.49 as builder

RUN USER=root cargo new --bin kubia
WORKDIR ./kubia

COPY ./Cargo.toml ./Cargo.toml
COPY ./Cargo.lock ./Cargo.lock

RUN cargo build --release
RUN rm src/*.rs

COPY ./src ./src

RUN rm ./target/release/deps/kubia*
RUN cargo build --release


# ---------------------------------------------------------------- #
FROM debian:buster-slim
ARG APP=/usr/src/app

EXPOSE 8080

ENV APP_USER=appuser

RUN groupadd $APP_USER \
    && useradd -g $APP_USER $APP_USER \
    && mkdir -p ${APP}

COPY --from=builder /kubia/target/release/kubia ${APP}/kubia

RUN chown -R $APP_USER:$APP_USER ${APP}

USER $APP_USER
WORKDIR ${APP}

ENTRYPOINT ["./kubia"]
