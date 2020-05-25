# frozen_string_literal: true

require 'at_coder_friends'
require 'at_coder_friends/generator/cxx_iostream/version'

module AtCoderFriends
  module Generator
    ITEM_TBL = {
      number: { type: 'int' },
      decimal: { type: 'double' },
      string: { type: 'string' },
      char: { type: 'string', reduce: true }
    }.tap { |h| h.default = { type: 'int' } }

    # generates C++ constants
    module CxxIostreamConstGen
      def gen_const(c)
        v = cnv_const_value(c.value)
        if c.type == :max
          "const int #{c.name.upcase}_MAX = #{v};"
        else
          "const int MOD = #{v};"
        end
      end

      def cnv_const_value(v)
        v
          .sub(/\b10\^/, '1e')
          .sub(/\b2\^/, '1<<')
          .gsub(',', "'")
      end
    end

    # generates C++ variable declarations
    module CxxIostreamDeclGen
      CxxDecl = Struct.new(:type, :name, :initializer) do
        def format(fnc)
          case fnc
          when :decl
            "#{type} #{name};"
          when :alloc
            initializer && "#{name} = #{type}#{initializer};"
          when :decl_alloc
            "#{type} #{name}#{initializer};"
          end
        end
      end

      def gen_decl(inpdef, fnc)
        (inpdef.components || [inpdef])
          .map { |cmp| gen_plain_decl(inpdef, cmp) }
          .flatten
          .map { |decl| decl&.format(fnc) }
          .compact
      end

      def gen_plain_decl(parent, inpdef)
        case inpdef.container
        when :single
          gen_single_decl(inpdef)
        when :harray
          gen_harray_decl(inpdef)
        when :varray
          gen_varray_decl(inpdef)
        when :matrix, :vmatrix, :hmatrix
          gen_matrix_decl(parent, inpdef)
        end
      end

      def gen_single_decl(inpdef)
        names, cols = inpdef.vars.transpose
        if cols.uniq.size == 1
          CxxDecl.new(ITEM_TBL[cols[0]][:type], names.join(', '), nil)
        else
          inpdef.vars.map do |name, item|
            CxxDecl.new(ITEM_TBL[item][:type], name, nil)
          end
        end
      end

      def gen_harray_decl(inpdef)
        type, reduce = ITEM_TBL[inpdef.item].values_at(:type, :reduce)
        name = inpdef.names[0]
        sz = inpdef.size[0]
        if reduce
          CxxDecl.new(type, name, nil)
        else
          CxxDecl.new("vector<#{type}>", name, "(#{sz})")
        end
      end

      def gen_varray_decl(inpdef)
        sz = inpdef.size[0]
        inpdef.vars.map do |name, item|
          type = ITEM_TBL[item][:type]
          CxxDecl.new("vector<#{type}>", name, "(#{sz})")
        end
      end

      def gen_matrix_decl(parent, inpdef)
        sz1, sz2 = inpdef.size
        inpdef.vars.map do |name, item|
          type, reduce = ITEM_TBL[item].values_at(:type, :reduce)
          ctype = reduce ? "vector<#{type}>" : "vector<vector<#{type}>>"
          initializer = (
            if reduce
              "(#{sz1})"
            elsif parent.container == :varray_matrix # jagged array
              "(#{sz1})"
            else
              "(#{sz1}, vector<#{type}>(#{sz2}))"
            end
          )
          CxxDecl.new(ctype, name, initializer)
        end
      end
    end

    # generates C++(iostream) input source
    module CxxIostreamInputGen
      INPUT_FMTS = [
        ['cin >> %<addr>s;', '%<v>s'],
        ['REP(i, %<sz1>s) cin >> %<addr>s;', '%<v>s[i]'],
        ['REP(i, %<sz1>s) REP(j, %<sz2>s) cin >> %<addr>s;', '%<v>s[i][j]']
      ].freeze

      INPUT_FMTS_CMB = {
        varray_matrix:
          [
            [
              <<~TEXT,
                REP(i, %<sz1>s) {
                  cin >> %<addr1>s;
                  cin >> %<addr2>s;
                }
              TEXT
              '%<v>s[i]',
              '%<v>s[i]'
            ],
            [
              <<~TEXT,
                REP(i, %<sz1>s) {
                  cin >> %<addr1>s;
                  %<v2>s[i].resize(%<sz2>s[i]);
                  REP(j, %<sz2>s[i]) cin >> %<addr2>s;
                }
              TEXT
              '%<v>s[i]',
              '%<v>s[i][j]'
            ]
          ],
        matrix_varray:
          [
            [
              <<~TEXT,
                REP(i, %<sz1>s) {
                  cin >> %<addr1>s;
                  cin >> %<addr2>s;
                }
              TEXT
              '%<v>s[i]',
              '%<v>s[i]'
            ],
            [
              <<~TEXT,
                REP(i, %<sz1>s) {
                  REP(j, %<sz2>s) cin >> %<addr1>s;
                  cin >> %<addr2>s;
                }
              TEXT
              '%<v>s[i][j]',
              '%<v>s[i]'
            ]
          ]
      }.tap { |h| h.default = h[:varray_matrix] }

      def gen_input(inpdef)
        (inpdef.components ? gen_cmb_input(inpdef) : gen_plain_input(inpdef))
          .split("\n")
      end

      def gen_plain_input(inpdef)
        dim = inpdef.size.size
        dim -= 1 if ITEM_TBL[inpdef.item][:reduce]
        inp_fmt, addr_fmt = INPUT_FMTS[dim] || INPUT_FMTS[0]
        sz1, sz2 = inpdef.size
        addr = edit_addr(inpdef, addr_fmt)
        format(inp_fmt, sz1: sz1, sz2: sz2, addr: addr)
      end

      def gen_cmb_input(inpdef)
        dim = ITEM_TBL[inpdef.item][:reduce] ? 0 : 1
        inp_fmt, *addr_fmts = INPUT_FMTS_CMB.dig(inpdef.container, dim)
        sz1, sz2 = inpdef.size
        addr1, addr2 = inpdef.components.zip(addr_fmts).map do |cmp, addr_fmt|
          edit_addr(cmp, addr_fmt)
        end
        format(
          inp_fmt,
          v2: inpdef.names[-1], # jagged array name
          sz1: sz1,
          sz2: sz2.split('_')[0],
          addr1: addr1,
          addr2: addr2
        )
      end

      def edit_addr(inpdef, addr_fmt)
        inpdef.names.map { |v| format(addr_fmt, v: v) }.join(' >> ')
      end
    end

    # generates C++(iostream) source from problem description
    class CxxIostream < Base
      include CxxIostreamConstants
      include CxxIostreamConstGen
      include CxxIostreamDeclGen
      include CxxIostreamInputGen

      ACF_HOME = File.realpath(File.join(__dir__, '..', '..', '..'))
      TMPL_DIR = File.join(ACF_HOME, 'templates')
      DEFAULT_TMPL = File.join(TMPL_DIR, 'cxx_iostream.cxx.erb')
      ATTRS = Attributes.new(:cxx, DEFAULT_TMPL)

      def attrs
        ATTRS
      end

      def gen_consts(constants = pbm.constants)
        constants.map { |c| gen_const(c) }
      end

      def gen_decls(inpdefs = pbm.formats)
        inpdefs
          .map { |inpdef| gen_decl(inpdef, :decl) }
          .flatten
          .compact
      end

      def gen_alloc_inputs(inpdefs = pbm.formats)
        inpdefs
          .map do |inpdef|
            [gen_decl(inpdef, :alloc), gen_input(inpdef)]
          end
          .flatten
          .compact
      end

      def gen_decl_alloc_inputs(inpdefs = pbm.formats)
        inpdefs
          .map do |inpdef|
            [gen_decl(inpdef, :decl_alloc), gen_input(inpdef)]
          end
          .flatten
          .compact
      end

      def gen_global_decls(inpdefs = pbm.formats)
        cfg['use_global'] ? gen_decls(inpdefs) : []
      end

      def gen_local_decls(inpdefs = pbm.formats)
        if cfg['use_global']
          gen_alloc_inputs(inpdefs)
        else
          gen_decl_alloc_inputs(inpdefs)
        end
      end
    end
  end
end
