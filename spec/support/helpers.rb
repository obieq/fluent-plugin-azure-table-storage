module Helpers

  def generate_partition_key
    "spec_pk_#{Random.rand(999)}"
  end

  def generate_row_key
    Random.rand(999).to_s
  end

  def write(driver, dynamic_table_name=nil)
    table_name = dynamic_table_name || driver.instance.table_name
    pk = generate_partition_key
    key1 = generate_row_key
    key2 = (key1.to_i + 1).to_s # must be greater than the first key
    tag1 = "spec test1"
    tag2 = "spec test2"
    time1 = Time.now.to_i
    time2 = time1 + 2

    record1 = {:partition_key => pk, :row_key => key1, :tag => tag1, :time => time1, :a => 10, :b => 'Tesla'}
    record2 = {:partition_key => pk, :row_key => key2, :tag => tag2, :time => time2, :a => 20, :b => 'Edison'}

    # store both records in an array to aid with verification
    test_records = [record1, record2]

    # set dynamic table name if necessary
    test_records.each { |record| record.merge!({:table_name => dynamic_table_name}) } if dynamic_table_name

    driver.emit(test_records[0])
    driver.emit(test_records[1])
    driver.run # persists to azure table storage

    # query azure table storage to verify data was correctly persisted
    db_records = driver.instance.connection.query(table_name,
                                                  {:expression => "(PartitionKey eq '#{pk}')"})

    db_records.count.should eq(test_records.count)
    db_records.each_with_index do |db_record, idx| # records should be sorted by row_key asc
      test_record = test_records[idx]
      db_record[:table_name].should be_nil # table name should never be persisted
      db_record[:partition_key].should eq(test_record[:partition_key])
      db_record[:row_key].should eq(test_record[:row_key])
      db_record[:tag].should eq(test_record[:tag])
      db_record[:time].should eq(test_record[:time])
      db_record[:a].should eq(test_record[:a])
      db_record[:b].should eq(test_record[:b])
    end

  end # def write

end # module Helpers
