# encoding: utf-8

require 'minitest/autorun'
require 'mocha/setup'
require 'salesforce_adapter'

# Fix for ruby 1.8, make ordered hash from list of arguments
def ohash(*args)
  if RUBY_VERSION < "1.9"
    ActiveSupport::OrderedHash.new.tap do |ordered_hash|
      args.each_slice(2) do |key,value|
        ordered_hash[key] = value
      end
    end
  else
    Hash[*args]
  end
end


###########
# Mock data
###########

# Credentials
SF_URL          = "http://the.salesforce.endpoint.com"
SF_LOGIN        = "the salesforce user's login"
SF_PASSWORD     = "the salesforce user's password"
SF_BAD_PASSWORD = "a wrong password"

# Webservice
SF_WEBSERVICE_SCHEMA_URL = "http://salesforce.webservice.schema.url"
SF_WEBSERVICE_PATH = "/path/to_webservice"

# Rforce stored queries and response
RFORCE_QUERIES = {

  # A successful find with one result
  :query_with_one_result => {
    :queryString  => "SELECT a.Id, a.Name FROM Account a WHERE Id='00111000002zYnU'",
    :response => {
      :queryResponse => { 
        :result => {
          :done => true, 
          :size => "1", 
          :records => [
            { 
              :type => "Account", 
              :Id => "00111000002zYnUAAU", 
              :Name => "TEST_CONTRACT"
            }
          ], 
          :queryLocator=>nil
        }
      }
    }
  },

  # A successful find with multiple results
  :query_with_multiple_results => {
    :queryString => "SELECT f.Id, f.Name, f.Total_TTC__c FROM Facture__c f WHERE f.Contrat__c='80011000000DCM4'",
    :response => {
      :queryResponse => {
        :result => {
          :done => true, 
          :size => "2", 
          :records => [
            {
              :type => "Facture__c", 
              :Total_TTC__c => "58.6", 
              :Id => "a0711000000P6KvAAK", 
              :Name => "F1013-00005"
            }, 
            {
              :type => "Facture__c", 
              :Total_TTC__c => "58.6", 
              :Id => "a0711000000P6KaAAK", 
              :Name => "F1013-00002"
            }
          ], 
          :queryLocator => nil
        }
      }
    }
  },

  # A query with no result
  :query_with_no_result => {
    :queryString => "SELECT a.Id, a.Name FROM Account a WHERE Id='00111000002zYnu'",
    :response => {
      :queryResponse => {
        :result => {
          :done => true, 
          :size => "0", 
          :queryLocator => nil
        }
      }
    }
  },

  # A malformed query
  :malformed_query => {
    :queryString => "SELECT a.Id, a.Name FROM Account a WHERE Idd='00111000002zYnu'",
    :response => {
      :Fault => {
        :detail => {
          :InvalidFieldFault => {
            :row => "1", 
            :column => "42", 
            :exceptionCode => "INVALID_FIELD", 
            :exceptionMessage => "a.Id, a.Name FROM Account a WHERE Idd='00111000002zYnu'\n"+
                                 "                                  ^\n"+
                                 "ERROR at Row:1:Column:42\n"+
                                 "No such column 'Idd' on entity 'Account'. If you are attempting to use a custom field, be sure to append the '__c' after the custom field name. Please reference your WSDL or the describe call for the appropriate names."
          }
        }, 
        :faultstring => "INVALID_FIELD: \n"+
                        "a.Id, a.Name FROM Account a WHERE Idd='00111000002zYnu'\n"+
                        "                                  ^\n"+
                        "ERROR at Row:1:Column:42\n"+
                        "No such column 'Idd' on entity 'Account'. If you are attempting to use a custom field, be sure to append the '__c' after the custom field name. Please reference your WSDL or the describe call for the appropriate names.", 
        :faultcode => "sf:INVALID_FIELD"
      }
    }
  }
}


RFORCE_UPDATES = {

  # A successful update
  :successful_update => {
    :query => {
      :Account => [
        :type, "Account", 
        :Id, "00111000002zYnUAAU", 
        :Name, "TEST_CONTRACT_BIS"
      ]
    },
    :response => {
      :updateResponse => {
        :result => {
          :success => true, 
          :id => "00111000002zYnUAAU"
        }
      }
    }
  },

  # A failed update (Id doesn't exist)
  :failed_update => {
    :query => {
      :Account => [
        :type, "Account", 
        :Id, "00111000002zYnUAAV", 
        :Name, "TEST_CONTRACT_BIS"
      ]
    },
    :response => { 
      :updateResponse => {
        :result => {
          :errors => {
            :fields => "Id", 
            :message => "ID du compte: Valeur d'ID de type incorrect: 00111000002zYnUAAV", 
            :statusCode => "MALFORMED_ID"
          }, 
          :success => false, 
          :id => nil
        }
      }
    }
  },

  # A malformed update (throwing an Api fault)
  :fault_update => {
    :query => {
      :Account => [
        :type, "WrongModel", 
        :Id, "00111000002zYnUAAU", 
        :Name, "TEST_CONTRACT_BIS"
      ]
    },
    :response => {
      :Fault => {
        :detail => {
          :InvalidSObjectFault => {
            :row => "-1", 
            :column => "-1", 
            :exceptionCode => "INVALID_TYPE", 
            :exceptionMessage => "sObject type 'WrongModel' is not supported. If you are attempting to use a custom object, be sure to append the '__c' after the entity name. Please reference your WSDL or the describe call for the appropriate names."
          }
        }, 
        :faultstring => "INVALID_TYPE: sObject type 'WrongModel' is not supported. If you are attempting to use a custom object, be sure to append the '__c' after the entity name. Please reference your WSDL or the describe call for the appropriate names.", 
        :faultcode => "sf:INVALID_TYPE"
      }
    }
  },

  # An update with nil fields
  :with_nil_fields => {
    :query => {
      :Account => [
        :type, 'Account', 
        :Id, '00111000002zYnUAAU', 
        :fieldsToNull, 'BillingCountry',
        :fieldsToNull, 'BillingState'
      ]
    },
    :response => {
      :updateResponse => {
        :result => {
          :success => true, 
          :id => "00111000002zYnUAAU"
        }
      }
    }
  }
}


RFORCE_CREATES = {

  # A successful create
  :successful_create => {
    :query => {
      :Lead => [
        :type, 'Lead', 
        :Company, 'Company Name', 
        :FirstName, 'John', 
        :LastName, 'Doe'
      ]
    },

    :response => {
      :createResponse => {
        :result => {
          :success => true, 
          :id => "00Q110000015pfUEAQ"
        }
      }
    }
  },


  # A failed create (mandatory field not given)
  :failed_create => {
    :query => {
      :Lead => [
        :type, 'Lead', 
        :FirstName, 'John', 
        :LastName, 'Doe'
      ]
    },

    :response => {
      :createResponse => {
        :result => {
          :errors => {
            :fields => "Company", 
            :message => "Des champs obligatoires n'ont pas été renseignés : [Company]", 
            :statusCode => "REQUIRED_FIELD_MISSING"
          }, 
          :success => false, 
          :id => nil
        }
      }
    }
  },


  # An api error (wrong table name given)
  :create_with_fault => {
    :query => {
      :Lead__c => [
        :type, 'Lead__c', 
        :Company, 'Company Name', 
        :FirstName, 'John', 
        :LastName, 'Doe'
      ]
    },

    :response => {
      :Fault => {
        :detail => {
          :InvalidSObjectFault => {
            :row => "-1", 
            :column => "-1", 
            :exceptionCode => "INVALID_TYPE", 
            :exceptionMessage => "sObject type 'Lead__c' is not supported. If you are attempting to use a custom object, be sure to append the '__c' after the entity name. Please reference your WSDL or the describe call for the appropriate names."
          }
        }, 
        :faultstring => "INVALID_TYPE: sObject type 'Lead__c' is not supported. If you are attempting to use a custom object, be sure to append the '__c' after the entity name. Please reference your WSDL or the describe call for the appropriate names.", 
        :faultcode => "sf:INVALID_TYPE"
      }
    }
  }
}


RFORCE_WEBSERVICES = {
  :not_existing_service => {
    :method     => "a_missing_method",
    :arguments  => [],
    :response   => {
      :Fault => {
        :faultcode => "soapenv:Client", 
        :faultstring => "No operation available for request {http://salesforce.webservice.schema.url}a_missing_method, please check the WSDL for the service."
      }
    }
  },

  :existing_service => {
    :method => "getAccountStuff",
    :arguments => [:accountId, "accountId"],
    :response => {
      :getAccountStuffResponse => {
        :result => "Error: No account found with id accountId."
      }
    }
  },


  :existing_service_with_multiple_arguments => {
    :method => "unmark_bill_as_paid",
    :arguments => [:fName, "fName", :fRejReason, "fRejReason"],
    :response => {
      :unmark_bill_as_paidResponse => {
        :result => "Error: No bill to mark as not paid for bill fName: fRejReason."
      }
    }
  }
}




class SalesforceAdapterTest < MiniTest::Unit::TestCase


  def setup

    # Mock the rforce binding
    @binding = mock('a rforce 0.11 binding')

    @binding.stubs(:login).with(SF_LOGIN, SF_PASSWORD)

    RFORCE_QUERIES.each do |_, query|
      @binding.stubs(:query).with(:queryString => query[:queryString]).returns(query[:response])
    end

    RFORCE_UPDATES.each do |_, update|
      @binding.stubs(:update).with(update[:query]).returns(update[:response])
    end

    RFORCE_CREATES.each do |_, create|
      @binding.stubs(:create).with(create[:query]).returns(create[:response])
    end

    RFORCE_WEBSERVICES.each do |_, webservice|
      @binding.stubs(:call_remote).with(webservice[:method], webservice[:arguments]).returns(webservice[:response])
    end

    # The tested adapter
    @adapter = SalesforceAdapter::Base.new(
      :url        => SF_URL,
      :login      => SF_LOGIN,
      :password   => SF_PASSWORD,
      :webservice => {
        :schema_url   => SF_WEBSERVICE_SCHEMA_URL,
        :service_path => SF_WEBSERVICE_PATH
      }
    )

    @adapter.instance_variable_set(:@rforce_binding, @binding)

  end



  def test_query

    # It should return an array of results. The array can be empty
    res = @adapter.query(RFORCE_QUERIES[:query_with_one_result][:queryString])
    assert_equal Array, res.class
    assert_equal 1, res.count

    res = @adapter.query(RFORCE_QUERIES[:query_with_multiple_results][:queryString])
    assert_equal Array, res.class
    assert_equal 2, res.count

    res = @adapter.query(RFORCE_QUERIES[:query_with_no_result][:queryString])
    assert_equal [], res


    # It should throw an exception on a failed query
    exception = assert_raises(SalesforceAdapter::SalesforceApiFault) do
      res = @adapter.query(RFORCE_QUERIES[:malformed_query][:queryString])
    end

    assert_equal "Salesforce API Fault : INVALID_FIELD: \na.Id, a.Name FROM Account a WHERE Idd='00111000002zYnu'\n                                  ^\nERROR at Row:1:Column:42\nNo such column 'Idd' on entity 'Account'. If you are attempting to use a custom field, be sure to append the '__c' after the custom field name. Please reference your WSDL or the describe call for the appropriate names..\nContext : querying salesforce with : SELECT a.Id, a.Name FROM Account a WHERE Idd='00111000002zYnu'", exception.message
    assert_equal "sf:INVALID_FIELD", exception.code

  end




  def test_update

    # It should raise an error if the type or the Id are not specified in the query
    exception = assert_raises(ArgumentError){ @adapter.update(:Account, ohash(:Name, "New name")) }
    assert_equal "Id must be specified for a Salesforce Update", exception.message

    exception = assert_raises(ArgumentError){ @adapter.update(:Account, ohash(:Id, "an id", :Name, "New name")) }
    assert_equal "type must be specified for a Salesforce Update", exception.message

    exception = assert_raises(ArgumentError){ @adapter.update(:Account, ohash(:type, :Account, :Name, "New name")) }
    assert_equal "Id must be specified for a Salesforce Update", exception.message


    # It should return the updated Id on a successful update
    # Mock : RFORCE_UPDATES[:successful_update]
    res = @adapter.update(:Account, ohash(:type, "Account", :Id, "00111000002zYnUAAU", :Name, "TEST_CONTRACT_BIS"))
    assert_equal "00111000002zYnUAAU", res


    # It should raise an exception on a failed update
    # Mock : RFORCE_UPDATES[:failed_update]
    exception = assert_raises(SalesforceAdapter::SalesforceFailedUpdate) do
      @adapter.update(:Account, ohash(:type, "Account", :Id, "00111000002zYnUAAV", :Name, "TEST_CONTRACT_BIS"))
    end

    assert_equal 'MALFORMED_ID', exception.code
    assert exception.message.start_with? "ID du compte: Valeur d'ID de type incorrect: 00111000002zYnUAAV\nContext : updating salesforce Account with attributes"


    # It should also raise an exception on an api fault
    # Mock : RFORCE_UPDATES[:fault_update]
    exception = assert_raises(SalesforceAdapter::SalesforceApiFault) do
      @adapter.update(:Account, ohash(:type, "WrongModel", :Id, "00111000002zYnUAAU", :Name, "TEST_CONTRACT_BIS"))
    end

    assert_equal 'sf:INVALID_TYPE', exception.code
    assert exception.message.start_with? "Salesforce API Fault : INVALID_TYPE: sObject type 'WrongModel' is not supported. If you are attempting to use a custom object, be sure to append the '__c' after the entity name. Please reference your WSDL or the describe call for the appropriate names..\nContext : updating salesforce Account with attributes"


    # It should set the nil values by querying the fields with a fieldToNull key
    # Mock : RFORCE_UPDATES[:with_nil_fields]
    assert_equal "00111000002zYnUAAU", @adapter.update(:Account, ohash(:type, "Account", :Id, "00111000002zYnUAAU", :BillingCountry, nil, :BillingState, nil))

  end


  def test_create

    # It should raise an error if the type is not specified
    exception = assert_raises(ArgumentError){ @adapter.create(:Lead, ohash(:Company, "Company Name")) }
    assert_equal "type must be specified for a Salesforce Create", exception.message


    # It should return the id on a successful create
    assert_equal "00Q110000015pfUEAQ", @adapter.create(:Lead, ohash(:type, "Lead", :Company, "Company Name", :FirstName, "John", :LastName, "Doe"))


    # It should raise an exception on a failed create
    exception = assert_raises(SalesforceAdapter::SalesforceFailedCreate) do
      @adapter.create(:Lead, ohash(:type, "Lead", :FirstName, "John", :LastName, "Doe"))
    end

    assert_equal 'REQUIRED_FIELD_MISSING', exception.code
    assert exception.message.start_with? "Des champs obligatoires n'ont pas été renseignés : [Company]\nContext : creating salesforce Lead with attributes "


    # It should raise an exception on an API fault
    exception = assert_raises(SalesforceAdapter::SalesforceApiFault) do
      @adapter.create(:Lead__c, ohash(:type, "Lead__c", :Company, "Company Name", :FirstName, "John", :LastName, "Doe"))
    end

    assert_equal 'sf:INVALID_TYPE', exception.code
    assert exception.message.start_with? "Salesforce API Fault : INVALID_TYPE: sObject type 'Lead__c' is not supported. If you are attempting to use a custom object, be sure to append the '__c' after the entity name. Please reference your WSDL or the describe call for the appropriate names..\nContext : creating salesforce Lead__c with attributes"

  end


  def test_webservice_calls

    # It should raise an exception if the webservice does not exist
    assert_raises(NoMethodError) do
      @adapter.webservice('my_webservice_name').a_missing_method
    end



    # Otherwise it should forward to the webservice and return the result
    assert_equal "Error: No account found with id accountId.", @adapter.webservice('my_webservice_name').getAccountStuff(:accountId => "accountId")

    if RUBY_VERSION >= "1.9.0"
      assert_equal "Error: No bill to mark as not paid for bill fName: fRejReason.", @adapter.webservice('clicrdv_webservice').unmark_bill_as_paid(:fName => "fName", :fRejReason => "fRejReason")
    end
  end


  def test_webservice_proxy
    ws_proxy = @adapter.webservice('my_webservice_name')

    @adapter.expects(:call_webservice).with(:my_method, {:foo => 'bar'}, 'http://soap.sforce.com/schemas/class/my_webservice_name', '/services/Soap/class/my_webservice_name')

    ws_proxy.my_method(:foo => 'bar')
  end


  def test_timeouts
    Kernel.stubs(:sleep).returns() # No sleep between retries

    # Standard timeout
    @binding.expects(:query).times(4).raises(Errno::EPIPE, '') # 4 tries
    assert_raises(SalesforceAdapter::SalesforceTimeout){ @adapter.query('a query') }

    # RForce error
    @binding.expects(:query).times(4).raises(RuntimeError, 'Incorrect user name / password [{:faultcode=>"SERVER_UNAVAILABLE", :faultstring=>"SERVER_UNAVAILABLE: server temporarily unavailable", :detail=>{:UnexpectedErrorFault=>{:exceptionCode=>"SERVER_UNAVAILABLE", :exceptionMessage=>"server temporarily unavailable"}}}]')
    assert_raises(SalesforceAdapter::SalesforceTimeout){ @adapter.query('a query') }
  end


end