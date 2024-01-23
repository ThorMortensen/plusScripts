#!/bin/bash

graphql-client introspect-schema "https://api.connectedcars.io/graphql" --output "scma.json"