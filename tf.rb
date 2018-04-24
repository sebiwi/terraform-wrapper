#!/usr/bin/env ruby

require_relative './tfw.rb'

tf = TerraformWrapper.new

tf.run ARGV
