require 'spec_helper'

describe 'mylaptop' do
  let(:facts) do
    {
      'laptop_password' => 'dummy',
      'rspec'           => true,
    }
  end

  it do
    File.write(
      'catalogs/mac.json',
      PSON.pretty_generate(catalogue)
    )
  end
end
