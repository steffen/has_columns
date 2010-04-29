module ActiveRecord
  module HasColumns
    
    def self.included(base)
      class << base
        def column_names_with_delegations
          if respond_to? :delegated_column_names
            column_names + delegated_column_names
          else
            column_names
          end
        end
        # 
        # alias_method_chain :column_names, :delegations
      end
      base.extend(ClassMethods)
    end
    
    module ClassMethods
      # has_columns :from => :dest, :except => "id"
      # has_columns :from => :dest, :only => [ "title", "name" ], :prefix => "src_"
      # attrs_from
      def has_columns(*args)
        options = args.pop
        
        raise ArgumentError, "Too many parameters" unless args.empty?
        
        unless options.is_a?(Hash) && from = options[:from]
          raise ArgumentError, "Must specify a source object"
        end
        
        options[:except] ||= []
        options[:except].push('id')
        
        from_class = reflections[from].class_name.constantize
        
        source_columns = from_class.column_names_with_delegations
        source_columns = source_columns + Array(options[:include]) if options[:include]
        source_columns = source_columns + from_class.delegated_columns if from_class.respond_to? :delegated_columns
        case
          when only = options[:only]: columns = source_columns & Array(only)
          when except = options[:except]: columns = source_columns - Array(except)
          else columns = source_columns
        end
        
        class_inheritable_accessor :delegated_column_names
        self.delegated_column_names = self.delegated_column_names || []

        prefix = options[:prefix] || "#{options[:from]}_"
        columns.each do |column|
          as = prefix.nil? ? column : prefix+column
          has_column column, :from => from, :as => as
          self.delegated_column_names << as
        end
      end
      
      # has_column :col_name, :from => :dest, :as => :new_name
      # has_column :col_name, :from => :dest
      def has_column(*args)
        # Parameter wrangling
        options = args.pop; col_name = args.pop
        col_name = col_name.to_sym if col_name.is_a?(String)
        
        raise ArgumentError, "Too many parameters" unless args.empty?
        
        unless options.is_a?(Hash) && col_name.is_a?(Symbol) && from=options[:from] 
          raise ArgumentError, "Must specify a column name and a source object" 
        end

        # Any method renaming going on?
        options[:as].nil? ? as = col_name : as = options[:as]
        
        # Squirt in the new method
        module_eval(<<-EOS, "has_column", 1)
          def #{as}(*args, &block)
            #{from}.nil? ? nil : #{from}.__send__(#{col_name.inspect}, *args, &block)
          end
        EOS
      end
      
      # delegate_attrs
      def delegate_columns(*args)
        delegated_columns = Array(args)
        class_inheritable_accessor :delegated_columns
        self.delegated_columns = delegated_columns
      end
    end
  end
end