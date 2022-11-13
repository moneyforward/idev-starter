#!/usr/bin/env bash

logged_in=$(aws sts get-caller-identity --profile idev)
if grep -q "UserId" <<< "$logged_in"
then
echo "Already logged in"
else
aws sso login --profile idev
fi
aws eks update-kubeconfig --profile idev --name idev;
