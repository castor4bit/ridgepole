# frozen_string_literal: true

require 'active_record/connection_adapters/abstract_adapter'

module ActiveRecord
  module ConnectionAdapters
    class PartitionOptions
      attr_reader :table, :method, :columns, :partition_definitions, :partitions

      TYPES = %i[range list].freeze

      def initialize(
        table,
        method,
        columns,
        partition_definitions: [],
        partitions: 0
      )
        @table = table
        @method = method
        @columns = Array.wrap(columns)
        @partition_definitions = build_definitions(partition_definitions)
        @partitions = partitions
      end

      def self.get_type(method)
        case method
        when /\ALIST( COLUMNS)?\z/
          :list
        when /\ARANGE( COLUMNS)?\z/
          :range
        when /\A(LINEAR )?HASH\z/
          :hash
        when /\A(LINEAR )?KEY\z/
          :key
        else
          raise NotImplementedError, method.to_s
        end
      end

      def self.type_to_method(type, linear: false)
        prefix = %i[hash key].include?(type) && linear ? 'LINEAR ' : ''
        suffix = %i[list range].include?(type) ? ' COLUMNS' : ''

        "#{prefix}#{type.to_s.upcase}#{suffix}"
      end

      def type
        ActiveRecord::ConnectionAdapters::PartitionOptions.get_type(method)
      end

      def define_num_of_partitions?
        %i[hash key].include?(type) && @partitions > 1
      end

      def linear?
        /\A(LINEAR )(HASH|KEY)?\z/.match?(@method)
      end

      private

      def build_definitions(definitions)
        definitions.map do |definition|
          next if definition.is_a?(PartitionDefinition)

          PartitionDefinition.new(definition.fetch(:name), definition.fetch(:values))
        end.compact
      end
    end
  end
end
