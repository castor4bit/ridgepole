# frozen_string_literal: true

require 'active_record/connection_adapters/mysql/schema_creation'

module Ridgepole
  module Ext
    module AbstractMysqlAdapter
      module SchemaCreation
        def visit_PartitionOptions(o)
          columns = o.columns.map { |column| quote_column_name(column) }.join(',')
          function = "#{o.method}(#{columns})"

          sqls = o.partition_definitions.map { |partition_definition| accept partition_definition }
          definitions = %i[list range].include?(o.type) ? "(#{sqls.join(',')})" : ''
          options = %i[hash key].include?(o.type) && o.partitions > 1 ? "PARTITIONS #{o.partitions}" : ''

          "ALTER TABLE #{quote_table_name(o.table)} PARTITION BY #{function} #{definitions}#{options}"
        end

        def visit_PartitionDefinition(o)
          if o.values.key?(:in)
            "PARTITION #{o.name} VALUES IN (#{o.values[:in].map do |value|
              value.is_a?(Array) ? "(#{value.map(&:inspect).join(',')})" : value.inspect
            end.join(',')})"
          elsif o.values.key?(:to)
            "PARTITION #{o.name} VALUES LESS THAN (#{o.values[:to].map(&:inspect).join(',')})"
          else
            raise NotImplementedError
          end
        end
      end
    end
  end
end

module ActiveRecord
  module ConnectionAdapters
    module MySQL
      class SchemaCreation
        prepend Ridgepole::Ext::AbstractMysqlAdapter::SchemaCreation
      end
    end
  end
end
