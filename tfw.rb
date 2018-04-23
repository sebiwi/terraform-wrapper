class TerraformWrapper

  def get_layers
    list_dirs.sort
      .map { |file| File.dirname(file) }
      .select{ |dirname| ! dirname.include? 'modules/' }
  end

  def list_dirs
    Dir.glob("**/*.tf").map{ |dir| Dir.getwd + '/' + dir }
  end

  def terraform
    'terraform'
  end

  def terraform_init
    get_layers.each do |layer|
      Dir.chdir(layer)
      %x{ #{terraform} init }
    end
  end

end
