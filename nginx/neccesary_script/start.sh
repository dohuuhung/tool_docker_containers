#!/bin/bash

# Start nginx service
nginx -s reload
nginx -g 'daemon off;'
