class TerraformWrapper

  def get_layers
    list_dirs.sort
      .map { |file| File.dirname(file) }
      .select{ |dirname| ! dirname.include? 'modules/' }
  end

  def list_dirs
    Dir.glob("**/*.tf")
  end
end
