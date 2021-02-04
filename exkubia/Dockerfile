ARG ELIXIR_VERSION=1.11
ARG DEBIAN_VERSION=buster-slim

#----------------------------------------------------------------#
FROM elixir:${ELIXIR_VERSION} AS builder

# prepare build dir
RUN mkdir /app
WORKDIR /app

# install hex + rebar
RUN mix local.hex --force &&\
    mix local.rebar --force

# set build ENV
ENV MIX_ENV=prod

COPY config ./config
COPY lib ./lib
COPY mix.exs .
COPY mix.lock .

RUN mix deps.get --only prod &&\
    mix deps.compile

# build and release project
RUN mix release

#----------------------------------------------------------------#
FROM debian:${DEBIAN_VERSION}

RUN apt-get update &&\
    apt-get install -y openssl inotify-tools

ENV LANG=C.UTF-8

RUN useradd --create-home app
WORKDIR /home/app
COPY --from=builder /app/_build/prod/rel/exkubia ./
RUN chown -R app: ./
USER app

EXPOSE 8080

# docker run\
#   --env KUBIA_HTTP_PORT=8080\
#   --env KUBIA_FORTUNE_PATH=/fortune_dir/fortune.txt\
#   --env KUBIA_SECRETS_DIR_PATH=/secrets\
#   -v /host/path/to/fortune_dir:/fortune_dir\
#   -v /host/path/to/secrets:/secrets\
#   -p 8080:8080\
#   -ti
#   exkubia

ENTRYPOINT ["./bin/exkubia"]
CMD ["start"]

#----------------------------------------------------------------#
