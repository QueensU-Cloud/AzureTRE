#!/bin/bash

while getopts a:s: flag
do
    case "${flag}" in
        a) account=${OPTARG};;
        s) sub=${OPTARG};;
    esac
done

az storage fs create --auth-mode login --subscription $sub--account-name $account --name monai-data
az storage fs access set --auth-mode login --subscription $sub --account-name $account --file-system monai-data --path "/" --permissions "rwxrwxrwx"

