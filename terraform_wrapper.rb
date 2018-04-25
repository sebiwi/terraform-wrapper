require 'open3'

class TerraformWrapper

  TERRAFORM_ACTIONS = ['init', 'workspace', 'plan', 'apply', 'destroy']
  TERRAFORM_ACTIONS_WITHOUT_WORKSPACE = ['init', 'workspace']
  NEED_VARFILE_ACTIONS = ['plan', 'apply', 'destroy']
  NEED_APPROVAL_ACTIONS = ['apply', 'destroy']

  def run params
    get_params params
    get_layers.each do |layer|
      Dir.chdir(layer)
      check_workspace!
      exec_terraform
    end
  end

  def get_params params
    if TERRAFORM_ACTIONS.include? params.first
      @use_varfile = false
    else
      @workspace = params.shift
      @use_varfile = true
    end
    @params = params
    @action = params.first
  end

  def exec_terraform
    parameter_buffer = @params
    parameter_buffer += ['--var-file', var_file] if NEED_VARFILE_ACTIONS.include?(@action) && @use_varfile
    parameter_buffer += ['--auto-approve'] if NEED_APPROVAL_ACTIONS.include? @action
    terraform(parameter_buffer.join(' '))
  end

  def check_workspace!
    return nil if TERRAFORM_ACTIONS_WITHOUT_WORKSPACE.include? @action
    missing_workspace if @workspace == nil && current_workspace != nil
    wrong_workspace if @workspace != current_workspace
  end

  def missing_workspace
    print_stdout("Workspace detected within your files. You should provide a workspace, dumbass.")
    raise 'Workspace exception'
  end

  def wrong_workspace
    print_stdout("Working on wrong workspace (#{current_workspace}) on layer " + current_dir)
    raise 'Workspace exception'
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
    Open3.popen3 "#{terraform_bin + ' ' + params}" do |stdin, stdout, stderr, thread|
      while line = stdout.gets
        puts line
      end
    end
  end
end
