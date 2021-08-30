## Terrafom Commands:
#### initialize

    terraform init

#### preview terraform actions

    terraform plan

#### apply configuration

    terraform apply

#### apply configuration with auto approve

    terraform apply -auto-approve

#### apply configuration with variables

    terraform apply -var-file terraform-dev.tfvars

#### destroy a single resource

    terraform destroy -target aws_vpc.myapp-vpc

#### destroy everything from tf files

    terraform destroy

#### show resources and components from current state

    terraform state list

#### show current state of a specific resource/data

    terraform state show aws_vpc.myapp-vpc    

#### set avail_zone as custom tf environment variable - before apply

    export TF_VAR_avail_zone="eu-west-3a"


## Terraform File Names:

As mentioned, Terraform will combine all files ending in .tf or .tf.json within a single directory. What those files are named before the extension is purely up to the user. That flexibility has resulted in a lot of confusion, and demand for prescription. In nearly all cases, the following are all the files which should exist, although not all of them need to exist if they wouldn’t have any content.

**main.tf:** Contains all data, local, provider, and resource blocks

**outputs.tf:** Contains all output blocks in alphabetical order

**terraform.tf:** Contains a single terraform block which defines backend, required_version, required_providers, and experiments parameters.

**variables.tf:** Contains all variable blocks in alphabetical order


## Code Formatting:

The Terraform parser allows you some flexibility in how you lay out the elements in your configuration files, but the Terraform language also has some idiomatic style conventions which we recommend users always follow for consistency between files and modules written by different teams. Automatic source code formatting tools such as “terraform fmt” may apply these conventions automatically.



*   Indent two spaces for each nesting level.
*   Any non-empty, multiline set of curly braces or square braces should end with a closing brace on its own line.
*   When multiple arguments with single-line values appear on consecutive lines at the same nesting level, align their equals signs:

        ```
        ami           = "abc123"
        instance_type = "t2.micro"
        ```


*   When both arguments and blocks appear together inside a block body, place all of the arguments together at the top and then place nested blocks below them. Use one blank line to separate the arguments from the blocks.
*   Use empty lines to separate logical groups of arguments within a block.
*   For blocks that contain both arguments and "meta-arguments" (as defined by the Terraform language semantics), list meta-arguments first and separate them from other arguments with one blank line. Place meta-argument blocks last and separate them from other blocks with one blank line.

    ```
    resource "aws_instance" "example" {

      		  count = 2 # meta-argument first

      		  ami           = "abc123"
      		  instance_type = "t2.micro"

          network_interface {
        		    # ...
      		  }

      		  lifecycle { # meta-argument block last
        		    create_before_destroy = true
      		  }
        }

    ```



*   Top-level blocks should always be separated from one another by one blank line. Nested blocks should also be separated by blank lines, except when grouping together related blocks of the same type (like multiple provisioner blocks in a resource).
*   Avoid separating multiple blocks of the same type with other blocks of a different type, unless the block types are defined by semantics to form a family. (For example: root_block_device, ebs_block_device and ephemeral_block_device on aws_instance form a family of block types describing AWS block devices, and can therefore be grouped together and mixed.)

## Ordering:

Ordering inside the file should be relatively linear. While Terraform is multithreaded, humans usually are not. The best order is likely the same order a person might have gone through all the steps were they planned out. General best practices:



*   Dependent resources are defined in the file before those that depend on them
*   Providers at the top of the file to “set the scene”
*   Globally used items at the top of the file after providers:
    *   Randomly generated strings used throughout the file for naming
    *   Globally useful data sources like azurerm_client_config
    *   Locals
*   Terraform code files should logically “build”. While we don’t enforce ordering, the file should be ordered.
*   Similar resources should be grouped if it doesn’t disrupt the logic. I.E. group a bunch of IAM policies for the same resources together, but if your code builds two distinct things, the IAM policies for each of those shouldn’t be merged into a single IAM section


## Comments:

Comments are crucial for understanding complicated code. They however can also become distracting when adding more verbosity than necessary. It’s crucial to consider the audience when considering comments. I typically recommend writing code oriented towards someone else with a solid but not necessarily complete mastery of Terraform. Terraform is already “documentation” so the recommended guidelines are:



*   Consider the audience when writing comments. Typically the recommendation is writing code oriented towards someone else with a solid but not necessarily complete mastery of Terraform. Do not write to the lowest common denominator
*   Comments should add additional detail, often the “why”, not restate something which the resource clearly demonstrates.
*   Be consistent with types of comment delimiters used. General preference by populatority:
    *   Use hash (#) exclusively over double slash (//)
    *   Prefer hash (#) to multiline comments (/* */) unless the comment is very long, such as or for use while commenting out resources
*   Metadata often requires comments
    *   Metadata including lifecycle or count usually represent a lot of additional information regarding their purpose, but which typically can’t be understood from reaching just the singular resource block. Add a quick comment that addresses why this is used.
*   Loops, counts, and other complicated dynamic code almost always deserves a comment.
*   It should never take longer than a minute from someone adept in Terraform, but not familiar with a certain codebase to understand what a particular resource or data source is doing.

## Secrets in Terraform Code:

Due to the nature of configuring infrastructure, there are almost always secrets which Terraform is or could be exposed to. Terraform's CLI considers the entire state to be a sensitive artifact, assuming the user will keep it secure, and so doesn't do anything special beyond hiding values in the CLI output. Terraform Enterprise and Terraform Cloud improves on this process via encryption of the state file through HashiCorp Vault. However there are still several other considerations:



*   Secrets should be passed to providers via provider specific environment variables whenever possible. This is the only way to keep these secrets out of the state file. While Terraform variables will keep them out of the code, those variables will be loaded into the state file.
*   When used in a pipeline within a CI tool or Terraform Enterprise, there is still a risk that a malicious Terraform code committer could use local_exec provisioner or external data source to use “printenv” to access the credentials. Terraform Enterprise should always include a Sentinel policy to prevent the use of the local_exec provisioner or external data source from being used by default. Those, as well as third party providers should be treated as items which need to be whitelisted per workspace.
*   Another option is to use the Terraform Vault provider to query dynamic cloud credentials for each run. The problem of this method is determining how to authenticate. The easiest method is to provide each workspace with its own token, but this is obviously a lot of manual effort. Instead Vault Agent could be used to authenticate the entire server, but there would be no way to provide different cloud permissions per workspace. Additionally Terraform code needs to be inserted for Terraform to know to make this call. Finally Terraform providers don’t have a way to signal to Vault that the run has finished, meaning that the dynamic credentials need to live longer than the maximum expected run, but in many instances someone with access to the state file could retrieve the credentials before they expire. Likewise Terraform doesn’t have a way to refresh the credential so defining too short of a validity period could result in a long run failing.
