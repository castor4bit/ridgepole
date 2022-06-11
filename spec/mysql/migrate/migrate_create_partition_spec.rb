# frozen_string_literal: true

describe 'Ridgepole::Client#diff -> migrate' do
  context 'when create hash partition' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "hash_partitions", primary_key: ["id", "logdate"], force: :cascade do |t|
          t.integer "id", null: false
          t.date "logdate", null: false
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "hash_partitions", primary_key: ["id", "logdate"], force: :cascade do |t|
          t.integer "id", null: false
          t.date "logdate", null: false
        end
        add_partition "hash_partitions", :hash, [:id]
      ERB
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }

    it {
      delta = client(bulk_change: true).diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl
      expect(delta.script).to match_fuzzy <<-RUBY
        create_partition "hash_partitions", **{:type=>:hash, :columns=>[:id], :partition_definitions=>[], :partitions=>0, :linear=>false}
      RUBY
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }
  end

  context 'when create hash partition with options' do
    let(:actual_dsl) do
      erbh(<<-ERB)
        create_table "hash_partitions", primary_key: ["id", "logdate"], force: :cascade do |t|
          t.integer "id", null: false
          t.date "logdate", null: false
        end
      ERB
    end

    let(:expected_dsl) do
      erbh(<<-ERB)
        create_table "hash_partitions", primary_key: ["id", "logdate"], force: :cascade do |t|
          t.integer "id", null: false
          t.date "logdate", null: false
        end
        add_partition "hash_partitions", :hash, [:id], options: { partitions: 4, linear: true }
      ERB
    end

    before { subject.diff(actual_dsl).migrate }
    subject { client }

    it {
      delta = subject.diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }

    it {
      delta = client(bulk_change: true).diff(expected_dsl)
      expect(delta.differ?).to be_truthy
      expect(subject.dump).to match_ruby actual_dsl
      expect(delta.script).to match_fuzzy <<-RUBY
        create_partition "hash_partitions", **{:type=>:hash, :columns=>[:id], :partition_definitions=>[], :partitions=>4, :linear=>true}
      RUBY
      delta.migrate
      expect(subject.dump).to match_ruby expected_dsl
    }
  end
end
