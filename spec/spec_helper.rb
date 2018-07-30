require 'puppetlabs_spec_helper/module_spec_helper'

FileUtils::mkdir_p 'catalogs'

RSpec.configure do |c|
  c.manifest = './mac.pp'
  c.hiera_config = './hiera.yaml'
  c.default_facts = {
    'networking'  => {
      'domain'   => "tpgi.com.au",
      'fqdn'     => "192-168-1-2.tpgi.com.au",
      'hostname' => "192-168-1-2",
      'ip'       => "192.168.1.2",
    }
  }
end
