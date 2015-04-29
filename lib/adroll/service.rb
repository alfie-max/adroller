module AdRoll
  module Api
    class Service
      def initialize(args = {})
        args.each do |attribute, value|

          send(attribute.to_sym)
          send("#{attribute}=", value)

        end

        self
      end

      def attributes
        self.class::SERVICE_ATTRIBUTES.each_with_object({}) do |attribute, hash|
          hash[attribute] = instance_variable_get("@#{attribute}")
        end
      end

      def respond_to?(method_name, include_all = false)
        if self.class::SERVICE_ATTRIBUTES.include?(method_name)
          true
        else
          super
        end
      end

      def method_missing(method_name, *args, &block)
        if self.class::SERVICE_ATTRIBUTES.include?(method_name)
          self.class.send(:attr_accessor, method_name)
        else
          super
        end
      end

      def self.respond_to?(method_name, include_all = false)
        if api_endpoints.include?(method_name)
          true
        else
          super
        end
      end

      def self.method_missing(method_name, *args, &block)
        if api_endpoints.include?(method_name)

          define_singleton_method(method_name) do |request_params|
            call_api(method_name, request_params.first)
          end

          send(method_name, args)

        else
          super
        end
      end

      def self.service_url
        File.join(AdRoll::Api.base_url, to_s.demodulize.downcase)
      end

      def self.basic_auth
        { username: AdRoll::Api.user_name, password: AdRoll::Api.password }
      end

      def self.api_endpoints
        self::API_METADATA.map { |hash| hash[:endpoint] }.flatten
      end

      def self.request_method(endpoint_name)
        self::API_METADATA.find do |metadata|
          metadata[:endpoint] == endpoint_name
        end[:request_method]
      end

      def self.call_api(endpoint, query_params)
        request_uri = File.join(service_url, endpoint.to_s)

        response = HTTParty.send(
          request_method(endpoint), request_uri,
          basic_auth: basic_auth, query: query_params)

        service_attributes = JSON.parse(response.body)['results']
        new(service_attributes)
      end

      private_class_method :service_url, :basic_auth, :api_endpoints
      private_class_method :request_method, :call_api
    end
  end
end
