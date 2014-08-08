require "active_record"

module LookupTable

  attr_reader :key_columns, :value_column

  def self.create *args, &block
    Class.new(ActiveRecord::Base) do
      extend LookupTable
      act_as_lookup_table *args
      class_eval &block if block_given?
    end
  end

  class << self
    attr_accessor :prefetch
    alias_method :prefetch?, :prefetch
    attr_accessor :prefetch_limit
  end
  LookupTable.prefetch = true

  attr_writer :prefetch

  def prefetch?
    (!LookupTable.prefetch_limit or
     (lookup_domain.count <= LookupTable.prefetch_limit)) and
     LookupTable.prefetch? and
     @prefetch
  end

  def act_as_lookup_table table, key, value, options = {}
    self.table_name = table
    @key_columns = [key].flatten
    @value_column = value

    self.default = options[:default]
    self.prefetch = options.fetch(:prefetch, true)
  end

  def [] *keys
    check_table_exists!
    lookup_table[ keys.flatten ]
  end

  def check_table_exists!
    @table_exists ||= table_exists?
    raise "No such table #{table_name}" unless @table_exists
  end

  def lookup_table
    @lookup_table ||= prefetch_if_requested( create_lookup_table )
  end

  def db_lookup keys
    record = lookup_domain.where( quoted_where keys ).first
    record_value record
  end

  def quoted_where key_values
    Hash[ key_columns.zip(key_values) ]
  end

  def quoted_key_columns
    key_columns.map{|col| connection.quote_column_name col}
  end

  def default keys
    @default.call *keys
  end

  def default= default
    @default = (Proc === default) ? default : proc { default }
  end

  def lookup_columns
    key_columns + [value_column]
  end

  def quoted_lookup_columns
    lookup_columns.map{|col| connection.quote_column_name col}
  end

  def lookup_domain
    select quoted_lookup_columns
  end

  def record_key record
    key_columns.map{|column| record[column]}
  end

  def record_value record
    record.try :[], value_column
  end

  def prefetch_if_requested hash
    if prefetch?
      lookup_domain.all.inject(hash) do |hash,record|
        hash[ record_key(record) ] = record_value(record)
        hash
      end
    end
    hash
  end

  def create_lookup_table
    Hash.new do |lookup_table, keys|
      lookup_table[keys] = db_lookup(keys) || default(keys)
    end
  end

end

