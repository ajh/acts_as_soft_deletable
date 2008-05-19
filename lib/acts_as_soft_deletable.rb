module ActiveRecord #:nodoc:
  module Acts #:nodoc:
    # Specify this act if you wish to save a copy of the row in a special deleted table so that it can be
    # restored later.
    module SoftDeletable
      module ClassMethods
        def acts_as_soft_deletable
          # don't allow multiple calls
          return if self.included_modules.include?(Live::InstanceMethods)

          include Live::InstanceMethods
          extend Live::ClassMethods
          
          live_class = self
          @deleted_class = const_set("Deleted", Class.new(ActiveRecord::Base)).class_eval do
            # class of live (undeleted) model
            cattr_accessor :live_class 

            self.live_class = live_class
            self.set_table_name "deleted_#{live_class.table_name}"

            extend Deleted::ClassMethods
            include Deleted::InstanceMethods
          end
        end
      end

      module Deleted

        module ClassMethods
          # Creates a deleted table by introspecting on the live table
          def create_table(create_table_options = {})
            connection.create_table(table_name, create_table_options) do |t|
              live_class.columns.select{|col| col.name != live_class.primary_key}.each do |col|
                t.column col.name, col.type, :scale => col.scale, :precision => col.precision
              end
              t.datetime :deleted_at
            end
          end

          # Drops the deleted table
          def drop_table(drop_table_options = {})
            connection.drop_table(table_name, drop_table_options)
          end

          # Updates the deleted table by adding or removing rows to match the live table.
          # This is useful to call after adding or deleting columns in the live table.
          def update_columns
            live_specs = returning({}) do |h|
              live_class.columns.each do |col|
                h[col.name] = { :type => col.type, :scale => col.scale, :precision => col.precision }
              end
            end

            deleted_specs = returning({}) do |h|
              self.columns.each do |col|
                h[col.name] = { :type => col.type, :scale => col.scale, :precision => col.precision }
              end
            end
            deleted_specs.reject!{|k,v| k == "deleted_at"}

            (live_specs.keys - deleted_specs.keys).each do |name|
              connection.add_column \
                table_name, 
                name, 
                live_specs[name][:type], 
                live_specs[name].reject{|k,v| k == :type}
            end

            (deleted_specs.keys - live_specs.keys).each do |name|
              connection.remove_column table_name, name
            end

            self.reset_column_information
            live_class.reset_column_information
          end
        end

        module InstanceMethods
          # restore the model from deleted status. Will destroy the deleted record and recreate the live record
          def undestroy!
            self.class.transaction do
              model = self.class.live_class.new
              self.attributes.reject{|k,v| k == 'deleted_at'}.keys.each do |key|
                model.send("#{key}=", self.send(key))
              end
              model.save!
              self.destroy
            end
            true
          end
        end
      end

      module Live

        module ClassMethods
          # returns instance of deleted class
          def deleted_class
            @deleted_class
          end
        end

        module InstanceMethods
          def self.included(base)
            base.class_eval do
              # don't use before_destroy callback because that can't be transactional.
              alias_method_chain :destroy, :soft_delete
            end
          end

          def destroy_with_soft_delete
            self.class.transaction do
              deleted = self.class.deleted_class.new
              self.attributes.keys.each do |key|
                deleted.send("#{key}=", self.send(key))
              end
              deleted.save!
              destroy_without_soft_delete
            end
          end
        end
      end
    end
  end
end

ActiveRecord::Base.send :extend, ActiveRecord::Acts::SoftDeletable::ClassMethods
