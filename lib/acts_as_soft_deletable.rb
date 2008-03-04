module ActiveRecord #:nodoc:
  module Acts #:nodoc:
    # Specify this act if you wish to save a copy of the row in a special deleted table so that it can be
    # restored later.
    module SoftDeletable
      module ClassMethods
        def acts_as_soft_deletable
          # don't allow multiple calls
          return if self.included_modules.include?(Model::InstanceMethods)

          include Model::InstanceMethods
          extend Model::ClassMethods
          
          model_class = self
          @deleted_class = const_set("Deleted", Class.new(ActiveRecord::Base)).class_eval do
            # class of undeleted model
            cattr_accessor :model_class 

            self.model_class = model_class
            self.set_table_name "deleted_#{model_class.table_name}"

            extend Deleted::ClassMethods
            include Deleted::InstanceMethods
          end
        end
      end

      module Deleted

        module ClassMethods
          def create_table(create_table_options = {})
            connection.create_table(table_name, create_table_options) do |t|
              model_class.columns.select{|c| c.name != model_class.primary_key}.each do |col|
                t.column col.name, col.type
                  #:limit => col.limit, 
                  #:default => col.default,
                  #:scale => col.scale,
                  #:precision => col.precision
              end
              t.datetime :deleted_at
            end
          end
        end

        module InstanceMethods
          # restore the model from deleted status. Will destroy the deleted record and recreate the original record
          def undestroy!
            self.class.transaction do
              model = self.class.model_class.new
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

      module Model

        module ClassMethods
          # returns instance of deleted class
          def deleted_class
            @deleted_class
          end
        end

        module InstanceMethods
          def self.included(base)
            base.class_eval do
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
