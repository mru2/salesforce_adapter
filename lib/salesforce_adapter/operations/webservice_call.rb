# Responsible for validating, running and formatting the results of a webservice operation

module SalesforceAdapter
  module Operations

    class WebserviceCall < Base

      def initialize(rforce_binding, method_name, arguments, schema_url, service_path)
        @method_name  = method_name.to_s
        @arguments    = arguments || {}
        @schema_url   = schema_url
        @service_path = service_path

        super(rforce_binding)
      end


      private

      def context
        "calling webservice method #{@method_name} with arguments #{@arguments.inspect}.\n Schema url: #{@schema_url}, service path: #{@service_path}"
      end

      def perform
        rforce_binding.call_remote(@method_name, formatted_arguments){ [@schema_url, @service_path] }
      end

      def format_response
        @response[:"#{@method_name}Response"][:result]
      end

      # Rescue missing methods by inspecting the content of the response
      def validate_response!
        begin
          super
        rescue SalesforceApiFault => e

          # Change the exception to a NoMethodError if undefined on salesforce
          if e.message =~ /No operation available for request/
            raise NoMethodError.new(e.message)
          else
            raise e
          end
        end
      end


      # Formatted arguments for WS call : need to be like [:key1, value1, :key2, value2]
      def formatted_arguments
        [].tap do |formatted_arguments|
          @arguments.each do |name, value|
            formatted_arguments << name << cast(value)
          end
        end
      end

      # Convert a value before sending it to salesforce
      def cast(value)
        if [TrueClass, FalseClass].include? value.class
          value
        else
          value.to_s
        end
      end

    end

  end
end
