# Global helper methods used in the salesforce adapter

module SalesforceAdapter


  # Exception : Salesforce API timeout
  class SalesforceTimeout   < StandardError ; end


  module Helpers

    class << self

      # Attemps to run a salesforce operation a given number of times, 
      # Handle timeout errors and sleep between retries
      def handle_timeout(opts= {}, &block)

        max_tries = opts[:max_tries] || 1
        sleep_between_tries = opts[:sleep_between_tries] || 1

        counter = 0

        begin
          counter += 1
          yield

        rescue Timeout::Error => e
          raise SalesforceAdapter::SalesforceTimeout.new(e.message) if counter >= max_tries

          sleep sleep_between_tries
          retry
        end

      end


      # Format a fields hash in an array, to be sent with a create or update query
      # Necessary to handle nil fields (must be submitted under the :fieldsToNull key, and there can be more than one)
      def format_fields_for_create_or_update(fields)
        fields_array = []
        fields = fields.dup

        # The type and Id have to be the first fields given
        type = fields.delete(:type)
        id   = fields.delete(:Id)

        fields_array << :type << type if type
        fields_array << :Id   << id   if id

        # Then append the other fields, handling the nil and boolean ones
        fields.each do |key, value|
          if value.nil?
            fields_array << :fieldsToNull << key.to_s
          else
            fields_array << key << format_value_for_create_or_update(value)
          end
        end

        fields_array
      end


      # Format a single value to be send in a create or update query
      def format_value_for_create_or_update(value)
        # Boolean have to be casted to strings
        if !!value == value
          value.to_s
        else
          value
        end
      end


      # Format a hash for its display in logs / error messages
      # Here for ruby 1.8's OrderedHash, to remove when migrated to ruby 2.0 +
      def hash_to_s(h)
        if h.class == Hash
          h.inspect
        elsif h.class < Hash
          Hash[h.to_a].inspect
        else
          raise ArgumentError.new('h is not a Hash or a subclass of Hash')
        end
      end

    end

  end

end
