require 'oauth2'
require 'uri'
require 'yaml'

module Puppet
  class GoogleCompute
    attr_reader :project_name

    def initialize(project_name)
      @project_name = project_name
    end

    def project_get
      get
    end

    def instance_list
      get('instances')
    end

  private

    def get(path = '')
      token.get(build_url(path)).body
    end

    def build_url(path)
      url = "#{api_url}/projects/#{URI.escape(project_name)}"
      url += "/#{URI.escape(path)}" unless path == ''
      url
    end

    def api_url
      "https://www.googleapis.com/compute/v1beta11"
    end

    def token
      @token ||= authenticate
    end

    def authenticate
      new_token = OAuth2::AccessToken.from_hash(client, { :refresh_token => refresh_token })
      new_token.refresh!
    end

    def client
      @client ||= OAuth2::Client.new(
        client_id,
        client_secret,
        :site => 'https://accounts.google.com',
        :token_url => '/o/oauth2/token',
        :authorize_url => '/o/oauth2/auth')
    end

    def refresh_token
      credentials[:refresh_token]
    end

    def client_id
      credentials[:client_id]
    end

    def client_secret
      credentials[:client_secret]
    end

    def credentials
      @credentials ||= validate_credentials
    end

    def validate_credentials
      unvalidated_credentials = fetch_credentials

      [:client_id, :client_secret, :refresh_token].each do |arg|
        raise(ArgumentError, ":#{arg} must be specified in credentials") unless unvalidated_credentials[arg]
      end

      unvalidated_credentials
    end

    def fetch_credentials
      @fetched_credentials = load_credentials[:gce]
    end

    def load_credentials
      YAML.load(File.read(credentials_path))
    end

    def credentials_path
      File.expand_path('~/.fog')
    end
  end
end
