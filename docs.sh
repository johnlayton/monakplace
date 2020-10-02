#!/usr/bin/env zsh

. ~/.zshrc

logger title "Build and open docs"

logger info "Start docs server"
open "http://localhost:8080" && \
  npm install && \
  npm run docs:dev &
