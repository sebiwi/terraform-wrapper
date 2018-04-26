require 'open3'

class TerraformWrapper

  TERRAFORM_ACTIONS = ['init', 'workspace', 'plan', 'apply', 'destroy']
  TERRAFORM_ACTIONS_WITHOUT_WORKSPACE = ['init', 'workspace']
  NEED_VARFILE_ACTIONS = ['plan', 'apply', 'destroy']
  NEED_APPROVAL_ACTIONS = ['apply', 'destroy']
  attr_reader :working_dir

  def run params
    @working_dir = Dir.getwd
    prepare_params params
    layers.each do |layer|
      Dir.chdir(layer)
      check_workspace!
      terraform @params.join(' ')
    end
  end

  def prepare_params params
    @params = params
    if workspace_provided? @params
      @workspace = @params.shift
      @params += ['--var-file', var_file] if NEED_VARFILE_ACTIONS.include?(action)
    else
      if @params.include?('--var-file')
        index = @params.index('--var-file')
        var_file_path = Dir.getwd + '/' +  @params[ index + 1]
        @params[index + 1 ] = var_file_path
      end
    end
    @params += ['--auto-approve'] if NEED_APPROVAL_ACTIONS.include? action
  end

  def action
    @params.first
  end

  def workspace_provided? params
    !TERRAFORM_ACTIONS.include?(params.first)
  end

  def check_workspace!
    return nil if TERRAFORM_ACTIONS_WITHOUT_WORKSPACE.include? action
    missing_workspace if @workspace.nil?  && !current_workspace.nil?
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
    file_name = "#{@workspace}.tfvars"
    return working_dir + '/' +  file_name if File.exists?(working_dir + '/' + file_name)
    return working_dir + '/../' + file_name if File.exists?(working_dir + '/../' + file_name)
    raise 'Error'
  end

  def print_stdout msg
    puts msg
  end

  def current_workspace
    if File.exists?('.terraform/environment')
       return File.readlines('.terraform/environment').first.gsub("\n",'')
    end
  end

  def layers
    @layers ||= list_dirs.sort
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
    Open3.popen3 [terraform_bin, params].join(' ') do |stdin, stdout, stderr, thread|
      while line = stdout.gets
        puts line
      end
    end
  end
end
