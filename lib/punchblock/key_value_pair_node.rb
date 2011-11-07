module KeyValuePairNode
  def self.included(klass)
    klass.class_exec do
      ##
      # @param [String] name
      # @param [String] value
      #
      def self.new(name, value = '')
        super(self.name.split('::').last.downcase.to_sym).tap do |new_node|
          case name
          when Nokogiri::XML::Node
            new_node.inherit name
          else
            new_node.name = name
            new_node.value = value
          end
          new_node.name = new_node.name.downcase
        end
      end
    end
  end

  # The Header's name
  # @return [Symbol]
  def name
    read_attr(:name).gsub('-', '_').to_sym
  end

  # Set the Header's name
  # @param [Symbol] name the new name for the param
  def name=(name)
    write_attr :name, name.to_s.gsub('_', '-')
  end

  # The Header's value
  # @return [String]
  def value
    read_attr :value
  end

  # Set the Header's value
  # @param [String] value the new value for the param
  def value=(value)
    write_attr :value, value
  end

  def inspect_attributes # :nodoc:
    [:name, :value] + super
  end
end
