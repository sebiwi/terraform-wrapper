require_relative '../terraform_mock.rb'
describe(Terraform) do

  let(:terraform) { described_class.new }

  describe('run') do

    let(:lines) { File.readlines("/tmp/terraform_mock_output").map{ |line| line.gsub("\n","") } }
    let(:params) { 'apply --var-file ../test.tfvars' }


    it 'logs the current directory of execution' do
      terraform.run params
      expect(lines.first).to eq Dir.getwd
    end

    it 'logs the parameters passed to terraform' do
      terraform.run params
      expect(lines.last).to eq params
    end

  end
end
