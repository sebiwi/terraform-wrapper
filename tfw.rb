class TerraformWrapper

  def get_layers
    list_dirs.sort.map { |dir| dir.gsub("/.terraform/", "").gsub(".terraform", ".") }
  end

  def list_dirs
    Dir.glob("**/.terraform/")
  end
end
