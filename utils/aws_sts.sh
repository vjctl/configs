#! /bin/bash
set -euo pipefail

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  cat <<'EOF'
Usage:   aws_sts.sh <AWS_PROFILE>
EOF
    exit 0
fi

aws_profile=$1

if [[ -z $AWS_CONFIG_FILE ]]; 
then 
    echo "AWS_CONFIG_FILE VARIABLE IS NOT SET"; 
    read -p "Provide the path to aws-vault.cfg: " cfg_path
    echo '' >> ~/.zshrc
    echo "export AWS_CONFIG_FILE=$cfg_path" >> ~/.zshrc
fi
source ~/.zshrc
mkdir -p ~/.aws
AWS_CRED_FILE=~/.aws/credentials

# Check if AWS_CRED_FILE is empty and if not, ask for overwrite. If yes, delete the existing file.
if [ -s "$AWS_CRED_FILE" ]; then
    read -p "AWS credentials file is not empty. Do you want to overwrite it? [y/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm "$AWS_CRED_FILE"
    else
        exit 1
    fi
fi

unset AWS_VAULT
aws-vault clear
envs=$(aws-vault exec $aws_profile -- env)

# truncate -s 0 ~/.aws/credentials
echo "[default]" > ~/.aws/credentials
echo "$envs" | grep AWS_DEFAULT_REGION >> ~/.aws/credentials
echo "$envs" | grep AWS_ACCESS_KEY_ID >> ~/.aws/credentials
echo "$envs" | grep AWS_SECRET_ACCESS_KEY >> ~/.aws/credentials
echo "$envs" | grep AWS_SESSION_TOKEN >> ~/.aws/credentials
exit 0
