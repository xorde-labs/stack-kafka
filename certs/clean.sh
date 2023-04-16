#!/bin/sh

pwd=$(dirname "$0")

echo "----- Cleaning up the build directory..."
rm -rf "$pwd"/build

echo "----- Done."
