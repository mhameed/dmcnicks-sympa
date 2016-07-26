require 'spec_helper'
describe 'sympa' do

  context 'with defaults for all parameters' do
    it { should contain_class('sympa') }
  end
end
