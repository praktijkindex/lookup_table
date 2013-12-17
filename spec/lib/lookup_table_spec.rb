describe LookupTable do
  before :all do
    PsqlSchema.drop 'lookup_tables' if PsqlSchema.exists? 'lookup_tables'
    PsqlSchema.create 'lookup_tables'
  end
  around(:each) do |example|
    PsqlSchema.with_path 'lookup_tables' do
      example.run
    end
  end
  after :all do
    PsqlSchema.drop 'lookup_tables'
  end
  shared_context "with mapping table" do
    around(:each) do |example|
      create_mapping_table(subject, table_content)
      example.run
      drop_mapping_table(subject)
    end
  end
  shared_context "simple content" do
    let(:table_content) { [[1,'foo'],[2,'bar'],[42,'answer']] }
    let(:unknown_key) { 666 }
  end
  shared_context "nil default" do
    let(:default_value) { nil }
  end
  shared_examples "lookup table" do
    it "looks up values for known keys" do
      table_content.each do |record|
        key = record[0...record.count-1]
        value = record.last
        expect( subject[key] ).to eq value
      end
    end
    it "returns default value for unknown keys" do
      expect( subject[ unknown_key ] ).to eq default_value
    end
  end

  describe "simple lookup table" do
    subject { LookupTable.create 'lookup_tables.mapping', :key, :value }
    include_context "with mapping table"
    include_context "simple content"
    include_context "nil default"
    it_behaves_like "lookup table"
  end
  describe "mixed case columns" do
    subject { LookupTable.create 'lookup_tables.mapping', :KeyColumn, :ValueColumn }
    include_context "with mapping table"
    include_context "simple content"
    include_context "nil default"
    it_behaves_like "lookup table"
  end
  describe "with default value" do
    subject { LookupTable.create 'lookup_tables.mapping', :key, :value, default: 'default' }
    include_context "with mapping table"
    include_context "simple content"
    let(:default_value) { 'default' }
    it_behaves_like "lookup table"
  end
  describe "with computed default" do
    subject { LookupTable.create 'lookup_tables.mapping', :key, :value, default: proc{|k| k/6} }
    include_context "with mapping table"
    include_context "simple content"
    let(:default_value) { 111 }
    it_behaves_like "lookup table"
  end
  describe "with compound key" do
    subject { LookupTable.create 'lookup_tables.mapping', [:key1, :key2] , :value }
    include_context "with mapping table"
    include_context "nil default"
    let(:table_content) { [[1,2,'foo'],[2,2,'bar'],[42,2,'answer']] }
    let(:unknown_key) { [666,777] }
    it_behaves_like "lookup table"
  end
  describe "simple lookup table without prefetching" do
    subject { LookupTable.create 'lookup_tables.mapping', :key, :value, prefetch: false }
    include_context "with mapping table"
    include_context "simple content"
    include_context "nil default"
    it "doesn't prefetch" do
      expect( subject ).not_to receive( :prefetch )
      subject[1]
    end
    it_behaves_like "lookup table"
  end

  private

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
end
