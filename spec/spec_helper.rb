require "active_record"
require "lookup_table"

ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"

def connection
  ActiveRecord::Base.connection
end

def create_mapping_table model, table_content
  value =  model.value_column
  table_name = model.table_name
  connection.create_table(table_name) do |t|
    model.key_columns.each do |key|
      t.integer key
    end
    t.string value
  end
  quoted_columns = model.quoted_lookup_columns
  rows_sql = table_content.map{|row| "(#{row.map{|v| connection.quote(v)} * ','})"} * ','
  insert_sql = "INSERT INTO #{table_name} (#{quoted_columns * ','}) VALUES #{rows_sql};"
  connection.execute(insert_sql)
end

def drop_mapping_table model
  connection.drop_table model.table_name
end
