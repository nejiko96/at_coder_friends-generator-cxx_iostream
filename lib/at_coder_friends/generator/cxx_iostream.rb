# frozen_string_literal: true

require 'at_coder_friends'
require 'at_coder_friends/generator/cxx_iostream/version'

module AtCoderFriends
  module Generator
    # C++ variable declaration generator
    class CxxIostreamDeclFragment < InputFormatFragment
      attr_accessor :root_container

      def generate(func)
        render(func)
      end

      def vars
        @vars ||= super.map do |var|
          var.tap do |var|
            var.root_container = root_container
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

    # generates C++(iostream) source from problem description
    class CxxIostream < Base
      include CxxIostreamConstants
      ACF_HOME = File.realpath(File.join(__dir__, '..', '..', '..'))
      TMPL_DIR = File.join(ACF_HOME, 'templates')
      TEMPLATE = File.join(TMPL_DIR, 'cxx_iostream.cxx.erb')
      FRAGMENTS = File.join(TMPL_DIR, 'cxx_iostream_fragments.yml')
      ATTRS = Attributes.new(:cxx, TEMPLATE, FRAGMENTS)

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
      end

      def gen_local_decls(inpdefs = pbm.formats)
        fnc = cfg['use_global'] ? :alloc : :decl_alloc
        inpdefs
          .map do |inpdef|
            gen_decl(inpdef, fnc).split("\n") +
            gen_input(inpdef).split("\n")
          end
          .flatten
      end

      def gen_decl(inpdef, func)
        CxxIostreamDeclFragment.new(inpdef, fragments['declaration']).generate(func)
      end

      def gen_input(inpdef)
        InputFormatFragment.new(inpdef, fragments['input']).generate
      end
    end
  end
end
