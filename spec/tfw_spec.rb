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

  describe '#terraform' do
    subject { wrapper.terraform }
    it { is_expected.to eq 'terraform' }
  end
  describe '#terraform_init' do
    before do
      File.delete(mock_file) if File.exist?(mock_file)
      allow(wrapper).to receive(:terraform).and_return("#{working_dir}/terraform.rb")
    end
    context 'in the root directory of a layered project' do
      let(:result) {
        ["#{layers_dir}/00_rg", 'init',
        "#{layers_dir}/01_network", 'init',
        "#{layers_dir}/02_vms", 'init'
        ] }
      it 'goes through all directories in the right order' do
        Dir.chdir(layers_dir)
        wrapper.terraform_init
        expect(lines).to eq result
      end
    end
    context 'in the root directory of a flat project' do
      let(:result) { ["#{flat_dir}", 'init' ] }
      it 'runs terraform init on the current (flat) directory' do
        Dir.chdir(flat_dir)
        wrapper.terraform_init
        expect(lines).to eq result
      end
    end
  end
end
