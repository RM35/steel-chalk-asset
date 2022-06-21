FROM ubuntu as builder

ARG GODOT_VERSION
ARG EXPORT_PROFILE

RUN apt update && \
    apt install -y \
        curl \
        unzip

RUN curl -Ls --fail "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_linux_headless.64.zip" -o godot.zip
RUN unzip godot.zip Godot_*
RUN mv Godot_* /usr/bin/godot

RUN mkdir -p /opt/src/project
COPY . /opt/src/project

RUN godot --path /opt/src/project --export "${EXPORT_PROFILE}"
