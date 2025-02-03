git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch Terraform/.terraform/* Terraform/terraform.exe' \
  --prune-empty --tag-name-filter cat -- --all
