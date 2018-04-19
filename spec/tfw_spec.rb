require_relative '../tfw.rb'
describe TerraformWrapper do
  let(:wrapper) { described_class.new }
  describe 'get_layers' do

    subject { wrapper.get_layers }
    let(:result) { ['00_network', '01_vm', '02_dns'] }
    let(:list_dirs) { ['00_network/.terraform/', '01_vm/.terraform/', '02_dns/.terraform/'] }

    before do
      allow(wrapper).to receive(:list_dirs).and_return(list_dirs)
    end

    it 'returns a list of directories' do
      expect(subject).to eq result
    end

  end
end
