### initialize

    terraform init

### preview terraform actions

    terraform plan

### apply configuration

    terraform apply

### apply configuration with auto approve

    terraform apply -auto-approve

### apply configuration with variables

    terraform apply -var-file terraform-dev.tfvars

### destroy a single resource

    terraform destroy -target aws_vpc.myapp-vpc

### destroy everything from tf files

    terraform destroy

### show resources and components from current state

    terraform state list

### show current state of a specific resource/data

    terraform state show aws_vpc.myapp-vpc    

### set avail_zone as custom tf environment variable - before apply

    export TF_VAR_avail_zone="eu-west-3a"
    
