FROM ubuntu as builder

ARG GODOT_VERSION
ARG EXPORT_PROFILE
ARG FILE_EXTENSION

RUN apt update && \
    apt install -y \
        curl \
        unzip

RUN curl -Ls --fail "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_linux_headless.64.zip" -o godot.zip
RUN unzip godot.zip Godot_*
RUN mv Godot_* /usr/bin/godot

ADD [".", "."]

RUN godot --path . --export "${EXPORT_PROFILE}" "game.${FILE_EXTENSION}"
