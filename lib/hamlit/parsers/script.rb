require 'hamlit/concerns/error'
require 'hamlit/concerns/indentable'

module Hamlit
  module Parsers
    module Script
      include Concerns::Error
      include Concerns::Indentable

      INTERNAL_STATEMENTS    = %w[else elsif when].freeze
      DEFAULT_SCRIPT_OPTIONS = { disable_escape: false }.freeze

      def parse_script(scanner, options = {})
        assert_scan!(scanner, /=|&=|!=|~/)
        options = DEFAULT_SCRIPT_OPTIONS.merge(options)

        code, with_comment = scan_code(scanner, comment_check: true)
        return syntax_error("There's no Ruby code for = to evaluate.") if code.empty? && !with_comment
        unless has_block?
          return [:dynamic, code] if options[:disable_escape]
          return [:escape, true, [:dynamic, code]]
        end

        ast = [:haml, :script, code, options]
        ast += with_indented { parse_lines }
        ast << [:code, 'end']
        ast
      end

      def parse_silent_script(scanner)
        assert_scan!(scanner, /-/)
        if scanner.scan(/#/)
          with_indented { skip_lines }
          return [:multi]
        end

        code = scan_code(scanner)
        ast = [:multi, [:code, code]]
        unless has_block?
          if internal_statement?(code) && !statement_continuing?
            ast << [:code, 'end']
          end
          return ast
        end

        ast += with_indented { parse_lines }
        unless statement_continuing?
          ast << [:code, 'end']
        end
        ast
      end

      private

      def scan_code(scanner, comment_check: false)
        code = ''
        loop do
          code += (scanner.scan(/.+/) || '').strip
          break unless code =~ /,\Z/

          @current_lineno += 1
          scanner = StringScanner.new(current_line)
          code += ' '
        end
        remove_comment(code, comment_check: comment_check)
      end

      def remove_comment(code, comment_check: false)
        result = ''
        with_comment = false
        Ripper.lex(code).each do |(row, col), type, str|
          if type == :on_comment
            with_comment = true
            next
          end
          result += str
        end

        return [result, with_comment] if comment_check
        result
      end

      def has_block?
        next_indent == @current_indent + 1
      end

      def statement_continuing?
        same_indent?(next_line) && internal_statement?(next_line, silent_script: true)
      end

      def internal_statement?(line, silent_script: false)
        return false unless line

        scanner = StringScanner.new(line)
        scanner.scan(/ +/)
        if silent_script
          return false unless scanner.scan(/-/)
        end

        scanner.scan(/ +/)
        statement = scanner.scan(/[^ ]+/)
        INTERNAL_STATEMENTS.include?(statement)
      end
    end
  end
end
