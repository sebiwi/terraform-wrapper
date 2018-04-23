#!/usr/bin/env ruby

require_relative './terraform_mock.rb'

terraform = Terraform.new

terraform.run ARGV.join(' ')
