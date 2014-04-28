# Proxy for a salesforce webservice. 
# Uses method_missing behind the scenes to forward methods to salesforce calls

module SalesforceAdapter

  class WebserviceProxy

    def initialize(adapter, webservice_class)
      @adapter       = adapter
      @schema_url    = "http://soap.sforce.com/schemas/class/#{webservice_class}"
      @service_path  = "/services/Soap/class/#{webservice_class}"
    end

    # Forward calls to salesforce
    def method_missing(method_name, args = {})
      @adapter.call_webservice(method_name, args, @schema_url, @service_path)
    end

  end
end
