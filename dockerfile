FROM ubuntu as builder

ARG GODOT_VERSION
ARG EXPORT_PROFILE

RUN apt update && \
    apt install -y \
        curl \
        unzip \
        sed

RUN curl -Ls --fail "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_linux_headless.64.zip" -o godot.zip
RUN unzip godot.zip Godot_*
RUN mv Godot_* /usr/bin/godot

RUN mkdir -p /root/.local/share/godot
WORKDIR /root/.local/share/godot
RUN curl -Ls --fail "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/Godot_v${GODOT_VERSION}_export_templates.tpz" -o godot.tpz
RUN unzip godot.tpz
RUN mkdir -p /root/.local/share/godot/$(echo "${GODOT_VERSION}" | sed 's/-/./')
RUN mv templates/* $(echo "${GODOT_VERSION}" | sed 's/-/./')
RUN mv $(echo "${GODOT_VERSION}" | sed 's/-/./') templates/

RUN mkdir -p /opt/src/project
COPY . /opt/src/project


RUN godot --path /opt/src/project --export "${EXPORT_PROFILE}"
