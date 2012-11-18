# Azure Table Storage plugin for Fluentd

Azure Table Storage output plugin for Fluentd.

# Installation

via RubyGems

    fluent-gem install fluent-plugin-azure-table-storage

# Quick Start

## Azure Table Storage Configuration
    # create free trial account
      http://www.windowsazure.com/en-us/pricing/free-trial/

    # create table storage instance
      https://manage.windowsazure.com/#Workspace/StorageExtension/storage

## Fluentd.conf Configuration
    <match azure_table_storage.**>
      type azure_table_storage            # fluent output plugin file name (sans fluent_plugin_ prefix)
      account_name your_account_name      # azure table storage account name
      access_key your_primary_access_key  # azure table storage primary access key.
      table_name fluentd                  # name of the destination table
    </match>

# Tests

rake rspec

    NOTE: requires the following:
          1) an active azure account
          2) an active azure table storage instance
          3) update spec/out_azure_table_storage_spec.rb with your
             account_name and primary access key prior to running the tests

# TODOs
    1) the waz-storage gem makes use of the rest-client gem, which in
       in turn uses the mime-types gem.  Fluentd, for whatever reason,
       sets default encoding to ASCII-8BIT (why not UTF-8)?
       fluentd can't start up due to the fact that the mime-type
       gem opens files using UTF-8 encoding (for default external, NOT
       default internal), which conflicts with fluentd's ASCII-8BIT encoding.

       For now, I monkey patch the mime-type gem to open the file by
       setting both the external and internal encoding to UTF-8.
       So, I'm not going to release this gem to RubyGems until this
       issue is resolved.
