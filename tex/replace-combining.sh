#!/usr/bin/env bash

sed -E 's/(.)⃗/\\vec{\1}/g;s/(.)̲/\\ul{\1}/g;s/(.)̅/\\ol{\1}/g;s/(.)̂/\\hat{\1}/g;s/(.)̇/\\dot{\1}/g;s/(.)̈/\\ddot{\1}/g;s/(.)̃/\\tilde{\1}/g'
