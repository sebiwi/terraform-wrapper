#!/usr/bin/env ruby

require_relative './terraform_wrapper.rb'

tf = TerraformWrapper.new

begin
  tf.run ARGV
rescue
  exit 1
end
