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

    it 'converts method to type `:hash`' do
      expect(options.get_type('HASH')).to eq :hash
      expect(options.get_type('LINEAR HASH')).to eq :hash
    end

    it 'converts method to type `:key`' do
      expect(options.get_type('KEY')).to eq :key
      expect(options.get_type('LINEAR KEY')).to eq :key
    end

    it 'raises NotImplementedError for unsupported types' do
      expect { options.get_type('ABC') }.to raise_error(NotImplementedError, 'ABC')
    end
  end

  describe '#type_to_method' do
    let!(:options) { ActiveRecord::ConnectionAdapters::PartitionOptions }

    context 'when linear flag is true' do
      let!(:linear) { true }

      it 'returns with prefix or suffix' do
        expect(options.type_to_method(:range, linear: linear)).to eq 'RANGE COLUMNS'
        expect(options.type_to_method(:list, linear: linear)).to eq 'LIST COLUMNS'
        expect(options.type_to_method(:hash, linear: linear)).to eq 'LINEAR HASH'
        expect(options.type_to_method(:key, linear: linear)).to eq 'LINEAR KEY'
      end
    end

    context 'when linear flag is false' do
      let!(:linear) { false }

      it 'returns with suffix only for :range or :list' do
        expect(options.type_to_method(:range, linear: linear)).to eq 'RANGE COLUMNS'
        expect(options.type_to_method(:list, linear: linear)).to eq 'LIST COLUMNS'
        expect(options.type_to_method(:hash, linear: linear)).to eq 'HASH'
        expect(options.type_to_method(:key, linear: linear)).to eq 'KEY'
      end
    end
  end
end
