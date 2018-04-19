class TerraformWrapper

  def get_layers
    list_dirs.map { |dir| dir.gsub("/.terraform/", "") }
  end

  def list_dirs
    Dir.glob("**/.terraform/")
  end
end
