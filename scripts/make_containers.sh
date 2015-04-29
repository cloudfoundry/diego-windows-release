#!/usr/bin/env bash

for i in {1..200}; do
    curl -H 'content-type: application/json' --data @- http://localhost:1788/api/containers <<EOF
{
  "Handle": "anotherhandle$i"
}
EOF
done

for i in {1..200}; do
    curl -X DELETE http://localhost:1788/api/containers/anotherhandle$i
done
