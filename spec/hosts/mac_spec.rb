require 'spec_helper'

describe '192-168-1-2.tpgi.com.au' do
  it {
    File.write(
      'catalogs/mac.json',
      PSON.pretty_generate(catalogue)
    )
  }
end
