require 'logger'

module FakeS3
  module Logging
    def logger
      @logger ||= Logging.logger_for(self.class.name)
    end

    # Use a hash class-ivar to cache a unique Logger per class:
    @loggers = {}
    @log_level = Logger::INFO

    class << self
      attr_accessor :log_level

      def logger_for(classname)
        @loggers[classname] ||= configure_logger_for(classname)
      end

      def configure_logger_for(classname)
        logger = Logger.new(STDERR)
        logger.level = @log_level
        logger.progname = classname
        logger.formatter = proc do |severity, datetime, progname, msg|
          date_format = datetime.strftime("%Y-%m-%d %H:%M:%S")
          "[#{date_format}] #{severity} (#{progname}): #{msg}\n"
        end
        logger
      end
    end
  end
end
