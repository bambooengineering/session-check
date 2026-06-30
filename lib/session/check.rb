require_relative 'check/configuration'
require_relative 'check/devise'
require_relative 'check/engine'

module Session
  module Check
    class << self
      def configure
        yield configuration
      end

      def configuration
        @configuration ||= Configuration.new
      end
    end
  end
end