# encoding: utf-8

module Punchblock
  module Translator
    class Asterisk
      module Component
        class MRCPPrompt < Component
          include StopByRedirect
          include MRCPRecogPrompt

          private

          def validate
            raise OptionError, "The renderer #{renderer} is unsupported." unless renderer == 'unimrcp'
            raise OptionError, "The recognizer #{recognizer} is unsupported." unless recognizer == 'unimrcp'
            raise OptionError, 'An SSML document is required.' unless output_node.render_documents.count > 0
            raise OptionError, 'A grammar is required.' unless input_node.grammars.count > 0

            super
          end

          def renderer
            (output_node.renderer || :unimrcp).to_s
          end

          def recognizer
            (input_node.recognizer || :unimrcp).to_s
          end

          def execute_unimrcp_app
            execute_app 'SynthAndRecog', render_docs, grammars, synthandrecog_options
          end

          def render_docs
            output_node.render_documents.map do |d|
              if d.content_type
                d.value.to_doc.to_s
              else
                d.url
              end
            end.join ','
          end

          def synthandrecog_options
            unimrcp_app_options do |opts|
              opts[:vn] = output_node.voice if output_node.voice
            end
          end
        end
      end
    end
  end
end
