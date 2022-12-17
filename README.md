# Terraform Examples 

Find below terraform commands

terraform init : Initialize terraform
terraform apply : Apply the changes to terraform 
terraform destroy -target {resource_type}.{resource_name} : Destroy specific resources by resource name
terraform plan : Gives you the desired state 
terraform apply -auto-approve : Apply the changes to terraform without confirming
terraform state list : List resources in the state
terraform apply -var-file terraform-dev.tfvars : If have multiple environments need to pass the file when applying
