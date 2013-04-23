# encoding: utf-8

module Punchblock
  module Component
    class Prompt < ComponentNode
      register :prompt, :prompt

      ##
      # Create a prompt command
      #
      # @param [Output] output
      # @param [Input] input
      # @param [Hash] options
      # @option options [true, false, optional] :barge_in Indicates wether or not the input should interrupt then output
      #
      # @return [Component::Prompt] a formatted Rayo prompt command
      #
      # @example
      #    output = Output.new :voice => 'allison', :text => 'Hello world'
      #    input = Input.new :grammar => {:value => '[5 DIGITS]', :content_type => 'application/grammar+custom'},
      #                      :mode    => :speech
      #    Prompt.new output, input, :barge_in => true
      #
      #    returns:
      #       <prompt xmlns="urn:xmpp:rayo:prompt:1" barge-in="true">
      #         <output xmlns="urn:xmpp:rayo:output:1" voice="allison">Hello world</output>
      #         <input xmlns="urn:xmpp:rayo:input:1" mode="speech">
      #           <grammar content-type="application/grammar+custom">
      #             <![CDATA[ [5 DIGITS] ]]>
      #           </grammar>
      #         </input>
      #       </prompt>
      #
      def self.new(output = nil, input = nil, options = {})
        super().tap do |new_node|
          options.each_pair { |k,v| new_node.send :"#{k}=", v }
          new_node.output = output
          new_node.input  =  input
        end
      end

      ##
      # @return [true, false] Indicates wether or not the input should interrupt then output
      #
      def barge_in
        read_attr(:'barge-in') && read_attr(:'barge-in') == 'true'
      end

      ##
      # @param [true, false] other Indicates wether or not the input should interrupt then output
      #
      def barge_in=(other)
        write_attr :'barge-in', other, :to_s
      end

      def output
        node = at_xpath 'ns:output', ns: 'urn:xmpp:rayo:output:1'
        RayoNode.import node if node
      end

      def output=(other)
        case other
        when nil
        when Output
          self << other
        else
          self << Output.new(other)
        end
      end

      def input
        node = at_xpath 'ns:input', ns: 'urn:xmpp:rayo:input:1'
        RayoNode.import node if node
      end

      def input=(other)
        case other
        when nil
        when Input
          self << other
        else
          self << Input.new(other)
        end
      end

      def inspect_attributes # :nodoc:
        [:barge_in, :output, :input] + super
      end
    end
  end
end
