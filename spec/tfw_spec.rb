require_relative '../tfw.rb'
describe TerraformWrapper do
  let(:wrapper) { described_class.new }
  let(:mock_file) { '/tmp/terraform_mock_output' }
  let(:working_dir) { Dir.getwd }
  let(:layers_dir) { working_dir + '/terraform_tests/test_layers' }
  let(:flat_dir) { working_dir + '/terraform_tests/test_flat' }
  let(:lines) { File.readlines(mock_file).map{ |line| line.gsub("\n",'') } }

  after do
    Dir.chdir(working_dir)
  end

  describe '#get_layers' do

    subject { wrapper.get_layers }

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
        expect(wrapper).to receive(:terraform).with("workspace new dev").exactly(3).times
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
          wrapper.run ['dev', 'taint', 'azurerm_apg.my_apg']
        end
      end

    end

    context 'when var file is needed (plan)' do

      context 'in flat dir' do
        let(:expected_params) { 'plan --var-file prod.tfvars' }

        it 'adds the var file with the same workspace name in command line' do
          Dir.chdir flat_dir
          expect(wrapper).to receive(:terraform).with(expected_params).once
          wrapper.run ['prod', 'plan']
        end
      end

      context 'in layered dir' do
        let(:expected_params) { 'plan --var-file ../prod.tfvars' }

        it 'adds the var file with the same workspace name in command line' do
          Dir.chdir layers_dir
          expect(wrapper).to receive(:terraform).with(expected_params).exactly(3).times
          wrapper.run ['prod', 'plan']
        end
      end
    end
    context 'when var file and autoconfirmation are needed (apply/destroy)' do

      context 'in flat dir apply' do
        let(:expected_params) { 'apply --var-file prod.tfvars --auto-approve' }

        it 'adds the var file with the same workspace name in command line' do
          Dir.chdir flat_dir
          expect(wrapper).to receive(:terraform).with(expected_params).once
          wrapper.run ['prod', 'apply']
        end
      end

      context 'in layered dir apply' do
        let(:expected_params) { 'apply --var-file ../prod.tfvars --auto-approve' }

        it 'adds the var file with the same workspace name in command line' do
          Dir.chdir layers_dir
          expect(wrapper).to receive(:terraform).with(expected_params).exactly(3).times
          wrapper.run ['prod', 'apply']
        end
      end
      context 'in flat dir destroy' do
        let(:expected_params) { 'destroy --var-file prod.tfvars --auto-approve' }

        it 'adds the var file with the same workspace name in command line' do
          Dir.chdir flat_dir
          expect(wrapper).to receive(:terraform).with(expected_params).once
          wrapper.run ['prod', 'destroy']
        end
      end

      context 'in layered dir destroy' do
        let(:expected_params) { 'destroy --var-file ../prod.tfvars --auto-approve' }

        it 'adds the var file with the same workspace name in command line' do
          Dir.chdir layers_dir
          expect(wrapper).to receive(:terraform).with(expected_params).exactly(3).times
          wrapper.run ['prod', 'destroy']
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
