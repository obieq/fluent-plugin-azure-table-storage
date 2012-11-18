require 'spec_helper'
Fluent::Test.setup

ACCOUNT_NAME = 'your azure storage account_name'
ACCESS_KEY = 'your azure storage primary access key'
# need to generate unique table names b/c it takes a few seconds
# for a table to be physically deleted on Azure after the
# delete command has been received.  so, if the tests are run in quick succession,
# then you'll get an error trying to create the table if the same table name is always used.
SPEC_TABLE_NAME = "spectest#{Random.rand(999)}"
# A dynamic table name overrides the
# default table name (per the config file)
# at runtime and persisting
# to a desired table on an ad-hoc basis
SPEC_TABLE_NAME_DYNAMIC = "#{SPEC_TABLE_NAME}dynamic"

CONFIG = %[
  storage_account_name #{ACCOUNT_NAME}
  primary_access_key #{ACCESS_KEY}
  table_name #{SPEC_TABLE_NAME}
]

describe Fluent::AzureTableStorageOutput do
  include Helpers

  let(:driver) { Fluent::Test::BufferedOutputTestDriver.new(Fluent::AzureTableStorageOutput, 'test') }

  # NOTE:  before(:all) shares state, so don't use the let variable within it
  #        see https://github.com/rspec/rspec-core/issues/500
  #        keep an eye open for before(:group) feature
  before(:all) do
    d = Fluent::Test::BufferedOutputTestDriver.new(Fluent::AzureTableStorageOutput, 'test')
    d.configure(CONFIG)
    d.instance.connection.create_table(SPEC_TABLE_NAME)
    d.instance.connection.create_table(SPEC_TABLE_NAME_DYNAMIC)
  end

  after(:all) do
    d = Fluent::Test::BufferedOutputTestDriver.new(Fluent::AzureTableStorageOutput, 'test')
    d.configure(CONFIG)
    d.instance.connection.delete_table(SPEC_TABLE_NAME)
    d.instance.connection.delete_table(SPEC_TABLE_NAME_DYNAMIC)
  end

  def set_config_value(config, config_name, value)
    search_text = config.split("\n").map {|text| text if text.strip!.to_s.start_with? config_name.to_s}.compact![0]
    config.gsub(search_text, "#{config_name} #{value}")
  end

  context 'configuring' do

    it 'should be properly configured' do
      driver.configure(CONFIG)
      driver.instance.storage_account_name.should eq(ACCOUNT_NAME)
      driver.instance.primary_access_key.should eq(ACCESS_KEY)
    end

    describe 'exceptions' do
      it 'should raise an exception if storage account_name is not configured' do
        expect { driver.configure(CONFIG.gsub("storage_account_name", "invalid_config_name")) }.to raise_error Fluent::ConfigError
      end

      it 'should raise an exception if primary access key is not configured' do
        expect { driver.configure(CONFIG.gsub("primary_access_key", "invalid_config_name")) }.to raise_error Fluent::ConfigError
      end

      it 'should raise an exception if table name is not configured' do
        expect { driver.configure(CONFIG.gsub("table_name", "invalid_config_name")) }.to raise_error Fluent::ConfigError
      end
    end

  end # context configuring

  context 'logging' do

    it 'should start' do
      driver.configure(CONFIG)
      driver.instance.start
    end

    it 'should shutdown' do
      driver.configure(CONFIG)
      driver.instance.start
      driver.instance.shutdown
    end

    it 'should format' do
      driver.configure(CONFIG)
      time = Time.now.to_i
      record = {:partition_key => generate_partition_key, :row_key => generate_row_key, :tag => 'test', :time => time, :a => 1}

      driver.emit(record)
      driver.expect_format(record.to_msgpack)
      driver.run
    end

    context 'writing' do

      it 'should write' do
        driver.configure(CONFIG)
        write(driver)
      end

      it 'should override table name' do
        driver.configure(CONFIG)
        write(driver, SPEC_TABLE_NAME_DYNAMIC)
      end

    end # context writing
  end # context logging
end # AzureTableStorageOutput
