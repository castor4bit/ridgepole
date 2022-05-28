# frozen_string_literal: true

describe ActiveRecord::ConnectionAdapters::PartitionOptions do
  describe '#get_type' do
    let!(:options) { ActiveRecord::ConnectionAdapters::PartitionOptions }

    it 'converts method to type `:range`' do
      expect(options.get_type('RANGE')).to eq :range
      expect(options.get_type('RANGE COLUMNS')).to eq :range
    end

    it 'converts method to type `:list`' do
      expect(options.get_type('LIST')).to eq :list
      expect(options.get_type('LIST COLUMNS')).to eq :list
    end

    it 'raises NotImplementedError for unsupported types' do
      expect { options.get_type('ABC') }.to raise_error(NotImplementedError, 'ABC')
    end
  end

  describe '#type_to_method' do
    let!(:options) { ActiveRecord::ConnectionAdapters::PartitionOptions }

    it 'returns with suffix' do
      expect(options.type_to_method(:range)).to eq 'RANGE COLUMNS'
      expect(options.type_to_method(:list)).to eq 'LIST COLUMNS'
    end
  end
end
