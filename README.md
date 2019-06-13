# Terraform wrapper

## Purpose
This wrapper's purpose is to run Terraform on a layered terraform project.

# Installation

Just clone the project, and symlink the tf.rb file somewhere in your path, like so:
 * `ln -s <terraform_wrapper_directory>/tf.rb /usr/local/bin/tf`
 
Remember to use the full path to your terraform-wrapper’s directory.

# Usage

A layered Terraform project looks somewhat like this:

```
layers/
├── 00_rg
│   ├── apg.tf
│   └── config.tf
├── 01_network
│   └── network.tf
├── 02_vms
│   └── vm.tf
├── dev.tfvars
├── modules
│   └── apg
│       └── apg.tf
└── prod.tfvars
```

If you're using the wrapper, there are many things you can do at this point.
You can put yourself at the root of the project (the `layers` dir) and then
type the following:

```
tf init # terraform init on each layer
tf plan --var-file prod.tfvars # terraform plan on each layer, using the specified var file
tf apply --var-file prod.tfvars # terraform apply on each layer. Beware, the apply option auto approves by default
tf destroy --var-file prood.tfvars # terraform destroy on each layer. Same as before, the destroy option approves by default
```

You can also do the aforementioned actions within a layer, like so:

```
cd 00_rf
tf plan --var-file ../prod.tfvars
```

What's really interesting (and the reason why we created this wrapper in the
first place) is the possibility of using a worskpace when applying Terraform
commands on a layered project. For example, with this layout:

```
terraform_tests/test_layers/
├── 00_rg
│   ├── .terraform
│   │   └── environment
│   ├── apg.tf
│   └── config.tf
├── 01_network
│   ├── .terraform
│   │   └── environment
│   └── network.tf
├── 02_vms
│   ├── .terraform
│   │   └── environment
│   └── vm.tf
├── modules
│   └── apg
│       └── apg.tf
└── prod.tfvars
├── dev.tfvars
```

You can launch Terraform actions by doing the following:

```
tf prod plan # terraform plan on each layer, using the prod.tfvars file at the root of the project
tf prod apply # terraform apply on each layer, using the prod.tfvars file at the root of the project. Beware, the apply action approves by default
tf dev destroy # terraform destroy on each layer, using the dev.tfvars file at the root of the project. Same as before, the destroy action approves by default
```

A small caveat is that the tfvars file must have the same name as the workspace you're using,
and that it must be placed at the root of the project.

The wrapper will warn you if there is a workspace in one of the layers and you don't specify one, or if the
workspace on one layer is different from the one you specified in the terminal. This helps you stay safe.

# Contributing

Do a pull request! Make sure you test your functionality though.

# License

MIT
