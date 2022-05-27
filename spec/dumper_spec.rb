# frozen_string_literal: true

describe Ridgepole::Dumper do
  describe '#mysql_strip_partition_options' do
    let(:options) { {} }
    let(:dumper) { Ridgepole::Dumper.new(options) }
    let(:line) { 'create_table "example", id: :integer, default: nil, charset: "latin1", options: "ENGINE=InnoDB\n/*!50100 PARTITION BY KEY */ /*!50611 ALGORITHM = 1 */ /*!50100 ()\nPARTITIONS 4 */", force: :cascade do |t|' }
    subject { dumper.send(:mysql_strip_partition_options, line) }

    it {
      expect(subject).to eq 'create_table "example", id: :integer, default: nil, charset: "latin1", force: :cascade do |t|'
    }
  end
end
