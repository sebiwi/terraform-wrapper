require_relative '../tfw.rb'
describe TerraformWrapper do
  let(:wrapper) { described_class.new }
  describe 'get_layers' do

    subject { wrapper.get_layers }

    before do
      allow(wrapper).to receive(:list_dirs).and_return(list_dirs)
    end

    context 'when current directory is not a terrform dir' do
      let(:result) { ['00_network', '01_vm', '02_dns'] }
      let(:list_dirs) { ['00_network/config.tf', '01_vm/vm.tf', '02_dns/outputs.tf'] }
      it { is_expected.to eq result }
    end

    context 'when current directory is a terrform dir and module dir is present' do
      let(:result) { ['.'] }
      let(:list_dirs) { ['trololo.tf', 'modules/vm/vm.tf'] }
      it { is_expected.to eq result }
    end

    context 'when results are not listed alphabetically' do
      let(:result) { ['00_network', '01_vm', '02_dns'] }
      let(:list_dirs) { ['01_vm/.terraform/', '00_network/.terraform/', '02_dns/.terraform/'] }
      it { is_expected.to eq result }
    end

  end
end
