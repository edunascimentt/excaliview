#!/bin/sh
# Bundles the Excalidraw renderer into ../Shared/Web (copied into both extensions).
set -e
cd "$(dirname "$0")"
OUT=../Shared/Web
rm -rf "$OUT" && mkdir -p "$OUT"
npx esbuild src/render.js --bundle --minify --format=iife --target=safari16 \
  --define:process.env.NODE_ENV='"production"' --loader:.woff2=file --outfile="$OUT/render.js"
cp src/index.html "$OUT/"
cp -R node_modules/@excalidraw/excalidraw/dist/prod/fonts "$OUT/fonts"
