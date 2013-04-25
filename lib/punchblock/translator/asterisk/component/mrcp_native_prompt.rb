# encoding: utf-8

module Punchblock
  module Translator
    class Asterisk
      module Component
        class MRCPNativePrompt < Component
          include StopByRedirect
          include MRCPRecogPrompt

          private

          def validate
            raise OptionError, "The renderer #{renderer} is unsupported." unless renderer == 'asterisk'
            raise OptionError, "The recognizer #{recognizer} is unsupported." unless recognizer == 'unimrcp'

            raise OptionError, 'A document is required.' unless output_node.render_documents.count > 0
            raise OptionError, 'Only one document is allowed.' if output_node.render_documents.count > 1
            raise OptionError, 'Only inline documents are allowed.' if first_doc.url
            raise OptionError, 'Only one audio file is allowed.' if first_doc.value.size > 1

            raise OptionError, 'A grammar is required.' unless input_node.grammars.count > 0

            super
          end

          def renderer
            (output_node.renderer || :asterisk).to_s
          end

          def recognizer
            (input_node.recognizer || :unimrcp).to_s
          end

          def execute_unimrcp_app
            execute_app 'MRCPRecog', grammars, mrcprecog_options
          end

          def first_doc
            output_node.render_documents.first
          end

          def audio_filename
            first_doc.value.first
          end

          def mrcprecog_options
            unimrcp_app_options do |opts|
              opts[:f] = audio_filename
            end
          end
        end
      end
    end
  end
end
