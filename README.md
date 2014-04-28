# SalesforceAdapter

[![Build Status](https://travis-ci.org/mru2/salesforce_adapter.png?branch=master)](https://travis-ci.org/mru2/salesforce_adapter)

Ruby client for the salesforce API
Actually, lightweight wrapper around the RForce gem

## Installation

Add this line to your application's Gemfile:

    gem 'salesforce_adapter'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install salesforce_adapter

## Usage

```
require 'salesforce_adapter'

adapter = SalesforceAdapter::Base.new(
  :url        => 'https://test.salesforce.com/services/Soap/u/16.0',
  :login      => 'your_salesforce_login',
  :password   => 'your_salesforce_password'
)

 > adapter.query("SELECT a.Id, a.Name FROM Account a WHERE Id='a_salesforce_id'")
=> [ {:type => "Account", :Id => "a_salesforce_id", :Name => "an_account" } ]

 > adapter.create(:Lead, {:type => 'Lead', :FirstName => 'Mace', :LastName => 'Windu', :Company => 'JEDI inc'})
=> 'the_new_lead_id'

 > adapter.update(:Lead, {:type => 'Lead', :Id => 'the_new_lead_id', :Company => 'One Arm Support Group'})
=> 'the_new_lead_id'


 > adapter.webservice('MyWebserviceClass').myMethod('foo')
=> 'bar'
```


## Contributing

1. Fork it ( http://github.com/<my-github-username>/salesforce_adapter/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
