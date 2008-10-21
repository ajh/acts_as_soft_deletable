module ActiveRecord #:nodoc:
  module Acts #:nodoc:
    # See the README file for general usage, or ClassMethods#acts_as_soft_deletable for more info.
    module SoftDeletable
      @remove_column_warning_enabled = true

      # Returns whether the remove column warning is enabled
      def self.remove_column_warning_enabled?; @remove_column_warning_enabled end
      
      # Sets whether the remove column warning is enabled
      def self.remove_column_warning_enabled=(boolean); @remove_column_warning_enabled = (boolean ? true : false) end

      module ClassMethods
        # Specify this act if you wish to archive deleted rows in a special
        # deleted table so that they can be later restored. 
        #
        # This includes and extends Live::InstanceMethods and
        # Live::ClassMethods into this class. 
        #
        # It will also create a new ActiveRecord::Base class named after this
        # class with the suffix <tt>::Deleted</tt> added.  The new class is
        # used for dealing with rows that have been deleted. See the README for
        # more info and examples.
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

      module Deleted #:nodoc:

        # These methods will be available as class methods on the deleted
        # class.
        module ClassMethods
          # Creates a deleted table by introspecting on the live table. Useful
          # in a migration #up method.
          def create_table(create_table_options = {})
            connection.create_table(table_name, create_table_options) do |t|
              live_class.columns.select{|col| col.name != live_class.primary_key}.each do |col|
                t.column col.name, col.type, :scale => col.scale, :precision => col.precision
              end
              t.datetime :deleted_at
            end
          end

          # Drops the deleted table. Useful a migration #down method.
          def drop_table(drop_table_options = {})
            connection.drop_table(table_name, drop_table_options)
          end

          # Updates the deleted table by adding or removing rows to match the
          # live table.  This is useful to call after adding or deleting
          # columns in the live table.
          #
          # A warning will be printed if a column is being removed just to make
          # sure the behavior is expected.  The warning can be turned off by
          # setting
          # ActiveRecord::Acts::SoftDeletable#remove_column_warning_enabled= to
          # false.
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
              if ActiveRecord::Acts::SoftDeletable.remove_column_warning_enabled?
                warn "Acts_as_soft_deletable is removing column #{table_name}.#{name}. You can disable this warning by setting 'ActiveRecord::Acts::SoftDeletable.remove_column_warning_enabled = false' in your migration."
              end
              connection.remove_column table_name, name
            end

            self.reset_column_information
            live_class.reset_column_information
          end
        end

        # These methods will be available as instance methods on the deleted
        # class.
        module InstanceMethods
          # Restore the model from deleted status. Will destroy the deleted
          # record and recreate the live record. This is done in a transaction
          # and will rollback if problems occur.
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

      module Live #:nodoc:

        # These methods will be available as class methods for the Model class
        # that invoked acts_as_soft_deletable
        module ClassMethods
          # Returns Class object of deleted class
          def deleted_class
            @deleted_class
          end

          # Same as ActiveRecord::Base#find except that it will also return
          # deleted records as well as live ones.
          #
          # Some of find's options are not supported and will raise an
          # exception. These include: order, limit, and offset.
          def find_with_deleted(*args)
            if args.last.is_a?(Hash) 
              [:order, :limit, :offset].each do |option|
                raise ArgumentError.new("#{option} option is not supported") if args.last.key?(option)
              end
            end

            case args.first
            when :all
              find(*args) + deleted_class.find(*args)
            when :first
              find(*args) || deleted_class.find(*args)
            else
              (live_results = find(*args)) rescue ActiveRecord::RecordNotFound
              (deleted_results = deleted_class.find(*args)) rescue ActiveRecord::RecordNotFound

              live_results && deleted_results ? \
                live_results + deleted_results : 
                live_results || deleted_results
            end
          end

          # Enables dynamic finders like
          # find_with_deleted_by_user_name(user_name) and
          # find_all_with_deleted_by_user_name_and_password(user_name,
          # password) 
          def method_missing(method_id, *arguments)
            if /^find_(all_with_deleted_by|with_deleted_by)_([_a-zA-Z]\w*)$/.match(method_id.to_s)
              m = method_id.to_s.sub(%r/with_deleted_/, '')
              live_results = send(m, *arguments)
              deleted_results = deleted_class.send(m, *arguments)

              live_results && deleted_results ? \
                live_results + deleted_results : 
                live_results || deleted_results
            else
              super
            end
          end
        end

        # These methods will be available as instance methods for the Model
        # class that invoked acts_as_soft_deletable
        module InstanceMethods
          def self.included(base)
            base.class_eval do
              # don't use before_destroy callback because that can't be transactional.
              alias_method_chain :destroy, :soft_delete
            end
          end

          # Wraps ActiveRecord::Base#destroy to provide the soft deleting
          # behavior.  The insert into the deleted table is protected with a
          # transaction and will be rolled back if destroy raises any
          # exception.
          def destroy_with_soft_delete
            self.class.transaction do
              self.class.deleted_class.delete self.id

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
