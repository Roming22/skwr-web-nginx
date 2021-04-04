#!/bin/bash -e

sudo nginx -T
curl -s --fail -k https://127.0.0.1/ > /dev/null
