class Terraform

  def run params

    File.open('/tmp/terraform_mock_output', 'a') do |file|
      file.puts(Dir.getwd)
      file.puts(params)
    end
  end

end
