require 'thor'
require 'logger'
require 'fakes3/logging'
require 'fakes3/server'
require 'fakes3/version'

module FakeS3
  class CLI < Thor
    include Logging

    default_task("server")

    desc "server", "Run a server on a particular hostname"
    method_option :root, :type => :string, :aliases => '-r', :required => true
    method_option :port, :type => :numeric, :aliases => '-p', :required => true
    method_option :address, :type => :string, :aliases => '-a', :required => false, :desc => "Bind to this address. Defaults to 0.0.0.0"
    method_option :hostname, :type => :string, :aliases => '-H', :desc => "The root name of the host.  Defaults to s3.amazonaws.com."
    method_option :limit, :aliases => '-l', :type => :string, :desc => 'Rate limit for serving (ie. 50K, 1.0M)'
    method_option :sslcert, :type => :string, :desc => 'Path to SSL certificate'
    method_option :sslkey, :type => :string, :desc => 'Path to SSL certificate key'
    method_option :create_buckets, :type => :boolean, :desc => 'Create non existing buckets when accessed'
    method_option :replicate, :type => :boolean, :desc => 'Clone not found objects from equivalent bucket in a real S3 enpoint'
    method_option :log, :type => :string, :desc => 'Log level'

    def server
      Logging.log_level = case options[:log]
        when "debug" then Logger::DEBUG
        when "info" then Logger::INFO
        when "warn" then Logger::WARN
        when "error" then Logger::ERROR
        when "critical","fatal" then Logger::FATAL
        else Logger::INFO
      end

      store = nil
      if options[:root]
        root = File.expand_path(options[:root])
        # TODO Do some sanity checking here
        store = FileStore.new(root, options[:create_buckets])
      end

      if store.nil?
        abort "You must specify a root to use a file store (the current default)"
      end

      hostname = 's3.amazonaws.com'
      if options[:hostname]
        hostname = options[:hostname]
        # In case the user has put a port on the hostname
        if hostname =~ /:(\d+)/
          hostname = hostname.split(":")[0]
        end
      end

      if options[:limit]
        begin
          store.rate_limit = options[:limit]
        rescue
          abort $!.message
        end
      end

      address = options[:address] || '0.0.0.0'
      ssl_cert_path = options[:sslcert]
      ssl_key_path = options[:sslkey]

      if (ssl_cert_path.nil? && !ssl_key_path.nil?) || (!ssl_cert_path.nil? && ssl_key_path.nil?)
        abort "If you specify an SSL certificate you must also specify an SSL certificate key"
      end

      logger.info "Loading FakeS3 with #{root} on port #{options[:port]} with hostname #{hostname}"
      server = FakeS3::Server.new(address,options[:port],store,hostname,ssl_cert_path,ssl_key_path,options[:replicate])
      server.serve
    end

    desc "version", "Report the current fakes3 version"
    def version
      puts <<"EOF"
======================
FakeS3 #{FakeS3::VERSION}

Copyright 2012, Curtis Spencer (@jubos)
EOF
    end
  end
end
