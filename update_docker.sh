#!/usr/bin/env bash


fail() {
    echo configuration failed
    exit 1
}

export AWS_DEFAULT_REGION=${AWS_REGION:-us-west-2}
identifier='daghanaltasivcr202003291657'

# Get the EB API environment value
apieid=$(jq -r '.EnvironmentId' tmp/$identifier/ebcreateapienv.json)
echo "API environment is $apieid"


# Deploy the new docker container to the instances
aws elasticbeanstalk update-environment \
    --application-name $identifier \
    --environment-id $apieid \
    --version-label invoicer-api > tmp/$identifier/$apieid.json

url="$(jq -r '.CNAME' tmp/$identifier/$apieid.json)"
echo "Environment is being deployed. Public endpoint is http://$url"

# Wait for the environment to be ready (green)
echo -n "waiting for environment"
while true; do
    aws elasticbeanstalk describe-environments --environment-id $apieid > tmp/$identifier/$apieid.json
    health="$(jq -r '.Environments[0].Health' tmp/$identifier/$apieid.json)"
    if [ "$health" == "Green" ]; then break; fi
    echo -n '.'
    sleep 10
done
echo
cat tmp/$identifier/$apieid.json
echo "Environment is deployed. Public endpoint is http://$url"