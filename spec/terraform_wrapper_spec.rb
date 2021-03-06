require_relative '../terraform_wrapper.rb'

describe TerraformWrapper do
  let(:wrapper) { described_class.new }
  let(:mock_file) { '/tmp/terraform_mock_output' }
  let(:working_dir) { File.expand_path('..', File.dirname(__FILE__)) }
  let(:layers_dir) { working_dir + '/terraform_tests/test_layers' }
  let(:flat_dir) { working_dir + '/terraform_tests/test_flat' }
  let(:no_workspace_layers_dir) { working_dir + '/terraform_tests/test_no_workspace_layers' }
  let(:no_workspace_flat_dir) { working_dir + '/terraform_tests/test_no_workspace_flat' }
  let(:lines) { File.readlines(mock_file).map{ |line| line.gsub("\n",'') } }

  describe '#layers' do

    subject { wrapper.layers }

    context 'when current directory is the root of a layered terraform project' do
      before do
        Dir.chdir(layers_dir)
      end
      let(:result) { [ layers_dir + '/00_rg', layers_dir + '/01_network', layers_dir + '/02_vms'] }
      it { is_expected.to eq result }
    end

    context 'when current directory is a terraform dir and module dir is present' do
      before do
        Dir.chdir(flat_dir)
      end
      let(:result) { [ flat_dir ] }
      it { is_expected.to eq result }
    end
  end

  describe '#terraform_bin' do
    subject { wrapper.terraform_bin }
    it { is_expected.to eq 'terraform' }
  end

  describe '#run' do
    before do
      File.delete(mock_file) if File.exist?(mock_file)
      allow(wrapper).to receive(:terraform_bin).and_return("#{working_dir}/terraform.rb")
    end

    context 'in the root directory of a layered project' do
      let(:expected_lines) {
        ["#{layers_dir}/00_rg", 'init',
        "#{layers_dir}/01_network", 'init',
        "#{layers_dir}/02_vms", 'init'
        ] }
      it 'goes through all directories in the right order' do
        Dir.chdir(layers_dir)
        wrapper.run ['init']
        expect(lines).to eq expected_lines
      end
    end

    context 'in the root directory of a flat project' do
      let(:expected_lines) { ["#{flat_dir}", 'init' ] }
      it 'runs terraform init on the current (flat) directory' do
        Dir.chdir(flat_dir)
        wrapper.run ['init']
        expect(lines).to eq expected_lines
      end
    end


    context 'when workspace new dev' do
      it 'calls terraform with workspace new dev' do
        Dir.chdir(layers_dir)
        expect(Dir).to receive(:chdir).ordered
        expect(wrapper).to receive(:terraform).with("workspace new dev").ordered
        expect(Dir).to receive(:chdir).ordered
        expect(wrapper).to receive(:terraform).with("workspace new dev").ordered
        expect(Dir).to receive(:chdir).ordered
        expect(wrapper).to receive(:terraform).with("workspace new dev").ordered
        wrapper.run ['workspace', 'new', 'dev']
      end
    end

    context 'when workspace new prod' do
      it 'calls terraform with workspace new prod' do
        Dir.chdir(layers_dir)
        expect(wrapper).to receive(:terraform).with("workspace new prod").exactly(3).times
        wrapper.run ['workspace', 'new', 'prod']
      end
    end

    context 'when workspace select dev' do
      it 'calls terraform with workspace select prod' do
        Dir.chdir(layers_dir)
        expect(wrapper).to receive(:terraform).with("workspace select prod").exactly(3).times
        wrapper.run ['workspace', 'select', 'prod']
      end
    end

    context 'when taint resource' do

      context 'when executing on right workspace' do
        it 'calls terraform taint on the resource' do
          Dir.chdir flat_dir
          expect(wrapper).to receive(:terraform).with("taint azurerm_apg.my_apg").once
          wrapper.run ['prod', 'taint', 'azurerm_apg.my_apg']
        end
      end

      context 'when executing on wrong workspace' do

        it 'sends a warning as the workspace is wrong' do
          Dir.chdir flat_dir
          expect(wrapper).to receive(:print_stdout)
          expect{ wrapper.run ['dev', 'taint', 'azurerm_apg.my_apg'] }.to raise_error('Workspace exception')
        end
      end

    end

    context 'when var file is needed (plan)' do

      context 'in flat dir' do
        let(:expected_params) { "plan --var-file #{flat_dir}/prod.tfvars" }

        it 'adds the var file with the same workspace name in command line' do
          Dir.chdir flat_dir
          expect(wrapper).to receive(:terraform).with(expected_params).once
          wrapper.run ['prod', 'plan']
        end
      end

      context 'in layered dir' do
        let(:expected_params) { "plan --var-file #{layers_dir}/prod.tfvars" }

        it 'adds the var file with the same workspace name in command line' do
          Dir.chdir layers_dir
          expect(wrapper).to receive(:terraform).with(expected_params).exactly(3).times
          wrapper.run ['prod', 'plan']
        end
      end
    end
    context 'when var file and autoconfirmation are needed (apply/destroy)' do

      context 'in flat dir apply' do
        let(:expected_params) { "apply --var-file #{flat_dir}/prod.tfvars --auto-approve" }

        it 'adds the var file with the same workspace name in command line' do
          Dir.chdir flat_dir
          expect(wrapper).to receive(:terraform).with(expected_params).once
          wrapper.run ['prod', 'apply']
        end
      end

      context 'in layered dir apply' do
        let(:expected_params) { "apply --var-file #{layers_dir}/prod.tfvars --auto-approve" }

        it 'adds the var file with the same workspace name in command line' do
          Dir.chdir layers_dir
          expect(wrapper).to receive(:terraform).with(expected_params).exactly(3).times
          wrapper.run ['prod', 'apply']
        end
      end
      context 'in flat dir destroy' do
        let(:expected_params) { "destroy --var-file #{flat_dir}/prod.tfvars --auto-approve" }

        it 'adds the var file with the same workspace name in command line' do
          Dir.chdir flat_dir
          expect(wrapper).to receive(:terraform).with(expected_params).once
          wrapper.run ['prod', 'destroy']
        end
      end

      context 'in layered dir destroy' do
        let(:expected_params) { "destroy --var-file #{layers_dir}/prod.tfvars --auto-approve" }

        it 'adds the var file with the same workspace name in command line' do
          Dir.chdir layers_dir
          expect(wrapper).to receive(:terraform).with(expected_params).exactly(3).times
          wrapper.run ['prod', 'destroy']
        end
      end

    end
    context 'when workspaces are not used' do
      context 'when terraform plan' do
        it 'calls terraform plan' do
          allow(wrapper).to receive(:print_stdout)
          Dir.chdir no_workspace_layers_dir
          expect(wrapper).to receive(:terraform).with('plan').exactly(3).times
          wrapper.run ['plan']
        end
      end
      context 'when terraform apply' do
        it 'calls terraform apply' do
          allow(wrapper).to receive(:print_stdout)
          Dir.chdir no_workspace_layers_dir
          expect(wrapper).to receive(:terraform).with('apply --auto-approve').exactly(3).times
          wrapper.run ['apply']
        end
      end
      context 'when terraform destroy' do
        it 'calls terraform destroy' do
          allow(wrapper).to receive(:print_stdout)
          Dir.chdir no_workspace_layers_dir
          expect(wrapper).to receive(:terraform).with('destroy --auto-approve').exactly(3).times
          wrapper.run ['destroy']
        end
      end
      context 'and .terraform/environment file exists' do
        it 'displays an error message' do
          allow(wrapper).to receive(:print_stdout)
          Dir.chdir(layers_dir)
          expect(wrapper).to receive(:missing_workspace).and_raise('Error')
          expect{ wrapper.run ['plan']}.to raise_error('Error')
        end
      end
      context 'when varfile is specified' do
        it 'calls terraform plan' do
          allow(wrapper).to receive(:print_stdout)
          Dir.chdir no_workspace_layers_dir
          expect(wrapper).to receive(:terraform).with("plan --var-file #{no_workspace_layers_dir}/vars.tfvars").exactly(3).times
          wrapper.run ['plan', '--var-file', 'vars.tfvars']
        end
      context 'when varfile is specified and is in current directory' do
        it 'calls terraform plan' do
          allow(wrapper).to receive(:print_stdout)
          Dir.chdir no_workspace_flat_dir
          expect(wrapper).to receive(:terraform).with("plan --var-file #{no_workspace_flat_dir}/vars.tfvars").exactly(1).times
          wrapper.run ['plan', '--var-file', 'vars.tfvars']
        end
        it 'calls terraform apply' do
          allow(wrapper).to receive(:print_stdout)
          Dir.chdir no_workspace_flat_dir
          expect(wrapper).to receive(:terraform).with("apply --var-file #{no_workspace_flat_dir}/vars.tfvars --auto-approve").exactly(1).times
          wrapper.run ['apply', '--var-file', 'vars.tfvars']
        end
      end
      end
    end
  end
  describe '#current_workspace' do
    before { Dir.chdir flat_dir }
    subject { wrapper.current_workspace }
    it { is_expected.to eq 'prod' }
  end
end
