# frozen_string_literal: true

require 'at_coder_friends'
require 'at_coder_friends/generator/cxx_iostream/version'

module AtCoderFriends
  module Generator
    # C++ variable declaration generator
    class CxxIostreamDeclFragment < InputFormatFragment
      attr_accessor :root_container

      def generate(func)
        send(func)
      end

      def decl_body
        render('decl_body', vertical_type)
      end

      def decl_line
        render('decl_line', horizontal_type)
      end

      def alloc
        render('alloc', vertical_type)
      end

      def alloc_line
        render('alloc_line', horizontal_type)
      end

      def decl_alloc_body
        render('decl_alloc_body', vertical_type)
      end

      def decl_alloc_line
        render('decl_alloc_line', horizontal_type)
      end

      def type
        render('type', item.to_s)
      end

      def vertical_type
        return 'combi' if components

        case container
        when :single
          vars.map(&:item).uniq.size == 1 ? 'single' : 'multi'
        when :harray
          'single'
        else # :varray. :matrix, :vmatrix, :hmatrix
          'multi'
        end
      end

      def horizontal_type
        case container
        when :single
          vars.map(&:item).uniq.size == 1 ? 'multi' : 'single'
        when :harray
          item == :char ? 'single' : 'array'
        when :varray
          'array'
        else # :matrix, :vmatrix, :hmatrix
          if item == :char
            'array'
          elsif root_container == :varray_matrix
            'jagged_array'
          else
            'matrix'
          end
        end
      end

      def vars
        @vars ||= super&.map do |cmp|
          cmp.tap do |c|
            c.root_container = root_container
          end
        end
      end

      def components
        @components ||= super&.map do |cmp|
          cmp.tap do |c|
            c.root_container = container
          end
        end
      end
    end

    # C++ variable input code generator
    class CxxIostreamInputFragment < InputFormatFragment
      def generate
        main
      end

      def main
        render('main', input_type, dim_type)
      end

      def item_address
        render('item_address', dim_type)
      end
    end

    # generates C++(iostream) source from problem description
    class CxxIostream < Base
      include CxxIostreamConstants
      ACF_HOME = File.realpath(File.join(__dir__, '..', '..', '..'))
      TMPL_DIR = File.join(ACF_HOME, 'templates')
      DEFAULT_TMPL = File.join(TMPL_DIR, 'cxx_iostream.cxx.erb')
      FRAGMENTS = File.join(TMPL_DIR, 'cxx_iostream_fragments.yml')
      ATTRS = Attributes.new(:cxx, DEFAULT_TMPL, FRAGMENTS)

      def attrs
        ATTRS
      end

      def gen_consts(constants = pbm.constants)
        constants.map { |c| gen_const(c) }
      end

      def gen_const(c)
        ConstFragment.new(c, fragments['constant']).generate
      end

      def gen_global_decls(inpdefs = pbm.formats)
        return [] unless cfg['use_global']

        inpdefs
          .map do |inpdef|
            gen_decl(inpdef, :decl).split("\n")
          end
          .flatten
          .compact
      end

      def gen_local_decls(inpdefs = pbm.formats)
        fnc = cfg['use_global'] ? :alloc : :decl_alloc
        inpdefs
          .map do |inpdef|
            [
              gen_decl(inpdef, fnc).split("\n"),
              gen_input(inpdef).split("\n")
            ]
          end
          .flatten
          .compact
      end

      def gen_decl(inpdef, func)
        CxxIostreamDeclFragment.new(inpdef, fragments['declaration']).generate(func)
      end

      def gen_input(inpdef)
        CxxIostreamInputFragment.new(inpdef, fragments['input']).generate
      end
    end
  end
end
