require 'salesforce_adapter/version'

require 'salesforce_adapter/helpers'
require 'salesforce_adapter/rforce_binding'
require 'salesforce_adapter/webservice_proxy'

require 'salesforce_adapter/operations/base'
require 'salesforce_adapter/operations/query'
require 'salesforce_adapter/operations/create'
require 'salesforce_adapter/operations/update'
require 'salesforce_adapter/operations/webservice_call'


# Wrapper around a rforce binding
# Forwards the 'query' method, handling the logging and error raising

require 'rforce'


module SalesforceAdapter

  class Base

    attr_reader :rforce_binding
    attr_reader :webservice


    # Initialize with the credentials
    def initialize(config)
      @rforce_binding = RforceBinding.new(config[:url], config[:login], config[:password])
    end

    def webservice(webservice_class)
      WebserviceProxy.new(self, webservice_class)
    end

    # Runs a query on salesforce and returns the result
    def query( query_string )

      # Perform the query
      Operations::Query.new(@rforce_binding, query_string).run()

    end


    # Updates a salesforce record
    def update(table_name, attributes)

      # Perform the update and returns the id
      Operations::Update.new(@rforce_binding, table_name, attributes).run()

    end


    # Creates a salesforce record
    def create(table_name, attributes)

      # Perform the creation and returns the id
      Operations::Create.new(@rforce_binding, table_name, attributes).run()

    end



    # Queries a salesforce webservice
    def call_webservice(method_name, arguments, schema_url, service_path)

      # Perform the call to the webservice and returns the result
      Operations::WebserviceCall.new(@rforce_binding, method_name, arguments, schema_url, service_path).run()

    end

  end

end

