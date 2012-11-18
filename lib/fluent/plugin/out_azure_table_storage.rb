require 'waz-storage'
require 'waz-tables'
require 'msgpack'
require 'json'
require 'active_support/core_ext/hash'

module Fluent

  class AzureTableStorageOutput < BufferedOutput
    Fluent::Plugin.register_output('azure_table_storage', self)

    config_param :storage_account_name,  :string
    config_param :primary_access_key,    :string
    config_param :table_name,            :string

    def connection
      @connection ||= get_connection(self.storage_account_name, self.primary_access_key)
    end

    def configure(conf)
      super

      # perform validations
      raise ConfigError, "'storage_account_name' is required by Azure Table Storage output (ex: dev01)" unless self.storage_account_name
      raise ConfigError, "'primary_access_key' is required by Azure Table Storage output (ex: MYw8oioBtuuh..)" unless self.primary_access_key
      raise ConfigError, "'table_name' is required by Azure Table Storage output (ex: events)" unless self.table_name
    end

    def start
      super
      connection
    end

    def shutdown
      super
    end

    def format(tag, time, record)
      record.to_msgpack
    end

    def write(chunk)
      chunk.msgpack_each  { |record|
        # NOTE: msgpack stringifies keys whereas the WAZ gem expects
        #       symbolized keys
        record.symbolize_keys!
        connection.insert_entity(record.delete(:table_name) || self.table_name, record)
      }
    end

    private

    def get_connection(account, key)
      # first, establish the connection
      WAZ::Storage::Base.establish_connection!(:account_name => "#{account}",
                                               :access_key => "#{key}")
      # now, prepare the table service and return
      WAZ::Tables::Table.service_instance
    end

  end
end
