#!/bin/bash

while getopts v:g:s:o:t: flag
do
    case "${flag}" in
        v) vm=${OPTARG};;
        g) rg=${OPTARG};;
        s) sub=${OPTARG};;
        o) os=${OPTARG};;
        t) script=${OPTARG};;
    esac
done

if [ "$os" = "windows" ]; then
  command="RunPowerShellScript"
else
  command="RunShellScript"
fi

az vm run-command invoke --command-id $command --name $vm --resource-group $rg --subscription $sub --scripts @$script
