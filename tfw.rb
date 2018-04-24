require 'open3'
class TerraformWrapper

  NO_WORKSPACE_ACTIONS = ['init', 'workspace']
  NEED_VARFILE_ACTIONS = ['plan', 'apply', 'destroy']

  def run params
    get_params params
    get_layers.each do |layer|
      Dir.chdir(layer)
      check_workspace!
      exec_terraform
    end
  end

  def get_params params
    if NO_WORKSPACE_ACTIONS.include? params.first
      @params = params
      @action = params.first
      @action_type = :no_workspace
    else
      @workspace = params.shift
      @action = params.first
      @params = params
      @action_type = :workspace
    end
  end

  def exec_terraform
    if NEED_VARFILE_ACTIONS.include? @action
      terraform(@params.join(' ') + ' --var-file ' + var_file)
    else
      terraform (@params.join(' '))
    end
  end

  def check_workspace!
    return nil if @action_type == :no_workspace
    wrong_layer if @workspace != current_workspace
  end

  def wrong_layer
    print_stdout("Working on wrong workspace (#{current_workspace}) on layer " + current_dir)
  end

  def current_dir
    Dir.getwd
  end

  def var_file
    file_name = "#{current_workspace}.tfvars"
    return file_name if File.exists? file_name
    "../#{file_name}"
  end

  def print_stdout msg
    puts msg
    exit 1
  end

  def current_workspace
    if File.exists?('.terraform/environment')
       return File.readlines('.terraform/environment').first.gsub("\n",'')
    end
  end

  def get_layers
    list_dirs.sort
      .map { |file| File.dirname(file) }
      .select{ |dirname| ! dirname.include? 'modules/' }
      .uniq
  end

  def list_dirs
    Dir.glob("**/*.tf").map{ |dir| Dir.getwd + '/' + dir }
  end

  def terraform_bin
    'terraform'
  end

  def terraform params
      #%x{ #{terraform_bin + ' ' + params} }
    Open3.popen3 "#{terraform_bin + ' ' + params}" do |stdin, stdout, stderr, thread|
      while line = stdout.gets
        puts line
      end
    end
  end
end
