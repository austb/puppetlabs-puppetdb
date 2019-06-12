#!/usr/bin/env bash
set -e

confdir="$(/opt/puppetlabs/bin/puppet config print confdir)"

echo "{ \"confdir\": \"$confdir\" }"
