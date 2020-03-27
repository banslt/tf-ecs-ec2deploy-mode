#!/bin/bash
for mod in $@
do
terraform plan -target=module.$mod -out deploy-history/$mod.out && terraform apply deploy-history/$mod.out
sleep 1
if ["$?" -ne "0" ]
then 
echo "smth wrong with ${mod^^}"
exit 1
fi
done