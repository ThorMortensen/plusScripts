#!/bin/bash

graphql-client introspect-schema "https://api.connectedcars.io/graphql" --output "scma.json"
graphql-client generate query -s scma.json