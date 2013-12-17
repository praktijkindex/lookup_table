describe LookupTable do
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
    subject { LookupTable.create 'mapping', :key, :value }
    include_context "with mapping table"
    include_context "simple content"
    include_context "nil default"
    it_behaves_like "lookup table"
  end
  describe "mixed case columns" do
    subject { LookupTable.create 'mapping', :KeyColumn, :ValueColumn }
    include_context "with mapping table"
    include_context "simple content"
    include_context "nil default"
    it_behaves_like "lookup table"
  end
  describe "with default value" do
    subject { LookupTable.create 'mapping', :key, :value, default: 'default' }
    include_context "with mapping table"
    include_context "simple content"
    let(:default_value) { 'default' }
    it_behaves_like "lookup table"
  end
  describe "with computed default" do
    subject { LookupTable.create 'mapping', :key, :value, default: proc{|k| k/6} }
    include_context "with mapping table"
    include_context "simple content"
    let(:default_value) { 111 }
    it_behaves_like "lookup table"
  end
  describe "with compound key" do
    subject { LookupTable.create 'mapping', [:key1, :key2] , :value }
    include_context "with mapping table"
    include_context "nil default"
    let(:table_content) { [[1,2,'foo'],[2,2,'bar'],[42,2,'answer']] }
    let(:unknown_key) { [666,777] }
    it_behaves_like "lookup table"
  end
  describe "simple lookup table without prefetching" do
    subject { LookupTable.create 'mapping', :key, :value, prefetch: false }
    include_context "with mapping table"
    include_context "simple content"
    include_context "nil default"
    it "doesn't prefetch" do
      expect( subject ).not_to receive( :prefetch )
      subject[1]
    end
    it_behaves_like "lookup table"
  end
end
