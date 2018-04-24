# Terraform wrapper

## Purpose
This wrapper purpose is to run terraform on a layered terraform project.
It only works on a project with workspace

## Usage
```
tf init
tf dev workspace select
tf prod taint azurerm_application_gateway.waf
tf dev apply
```
