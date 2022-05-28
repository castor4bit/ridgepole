# frozen_string_literal: true

require 'active_record/connection_adapters/abstract_mysql_adapter'

module Ridgepole
  module Ext
    module AbstractMysqlAdapter
      module Partitioning
        def partition(table_name)
          scope = quoted_scope(table_name)

          partition_info = exec_query(<<~SQL, 'SCHEMA')
            SELECT PARTITION_NAME, PARTITION_DESCRIPTION, PARTITION_METHOD, PARTITION_EXPRESSION
            FROM information_schema.partitions
            WHERE partition_name IS NOT NULL
              AND table_schema = #{scope[:schema]}
              AND table_name = #{scope[:name]}
          SQL
          return if partition_info.count == 0

          method = partition_info.first['PARTITION_METHOD']
          type = ActiveRecord::ConnectionAdapters::PartitionOptions.get_type(method)
          columns = partition_info.first['PARTITION_EXPRESSION'].delete('`').split(',').map(&:to_sym)

          partition_definitions = partition_info.map do |row|
            values = case type
                     when :list
                       { in: instance_eval("[#{row['PARTITION_DESCRIPTION'].gsub(/\(/, '[').gsub(/\)/, ']')}] # [1,2]", __FILE__, __LINE__) }
                     when :range
                       { to: instance_eval("[#{row['PARTITION_DESCRIPTION']}] # [1,2]", __FILE__, __LINE__) }
                     when :hash, :key
                       nil
                     else
                       raise NotImplementedError
                     end

            { name: row['PARTITION_NAME'], values: values } unless values.nil?
          end

          ActiveRecord::ConnectionAdapters::PartitionOptions.new(table_name, method, columns, partition_definitions: partition_definitions.compact, partitions: partition_definitions.size)
        end

        # SchemaStatements
        def create_partition(table_name, type:, columns:, partition_definitions:, partitions:, linear:)
          method = ActiveRecord::ConnectionAdapters::PartitionOptions.type_to_method(type, linear: linear)
          execute schema_creation.accept(ActiveRecord::ConnectionAdapters::PartitionOptions.new(table_name, method, columns, partition_definitions: partition_definitions, partitions: partitions))
        end

        def add_partition(table_name, name:, values:)
          pd = ActiveRecord::ConnectionAdapters::PartitionDefinition.new(name, values)
          execute "ALTER TABLE #{quote_table_name(table_name)} ADD PARTITION (#{schema_creation.accept(pd)})"
        end

        def remove_partition(table_name, name:)
          execute "ALTER TABLE #{quote_table_name(table_name)} DROP PARTITION #{name}"
        end
      end
    end
  end
end

module ActiveRecord
  module ConnectionAdapters
    class AbstractMysqlAdapter < AbstractAdapter
      prepend Ridgepole::Ext::AbstractMysqlAdapter::Partitioning
    end
  end
end
