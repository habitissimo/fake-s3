#!/bin/sh

set -e

ARGS="$@"

if [ -n "$FAKES3_ROOT" ]; then
  ARGS="$ARGS --root $FAKES3_ROOT"
fi


if [ -n "$FAKES3_CREATE_BUCKETS" ]; then
  ARGS="$ARGS --create_buckets"
fi

if [ -n "$FAKES3_REPLICATE" ]; then
  ARGS="$ARGS --replicate"
fi

bin/fakes3 $ARGS
