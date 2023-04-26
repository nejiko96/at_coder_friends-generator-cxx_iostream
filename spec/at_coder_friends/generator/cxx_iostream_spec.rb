# frozen_string_literal: true

RSpec.describe AtCoderFriends::Generator::CxxIostream do
  it 'has a version number' do
    expect(described_class::VERSION).not_to be nil
  end

  subject(:generator) { described_class.new(cfg) }
  let(:cfg) { nil }

  describe '#process' do
    subject { generator.process(pbm) }
    let(:pbm) { AtCoderFriends::Problem.new('A') }
    let(:ext) { pbm.sources[0].ext }

    it 'returns generator specific extension' do
      subject
      expect(ext).to match(:cxx)
    end
  end

  describe '#gen_consts' do
    subject { generator.gen_consts(constants) }
    let(:constants) do
      [
        AtCoderFriends::Problem::Constant.new('N', :max, '10,000'),
        AtCoderFriends::Problem::Constant.new('M', :max, '10^9'),
        AtCoderFriends::Problem::Constant.new('C_i', :max, '2*10^5'),
        AtCoderFriends::Problem::Constant.new(nil, :mod, '998,244,353')
      ]
    end

    it 'generates constant decls' do
      expect(subject).to match(
        [
          "const int N_MAX = 10'000;",
          'const int M_MAX = 1e9;',
          'const int C_I_MAX = 2*1e5;',
          "const int MOD = 998'244'353;"
        ]
      )
    end
  end

  describe '#gen_decl' do
    subject { generator.gen_decl(inpdef, fnc) }
    let(:inpdef) do
      AtCoderFriends::Problem::InputFormat.new(
        container: container,
        item: item,
        names: names,
        size: size,
        delim: delim,
        cols: cols
      )
    end
    let(:fnc) { :decl_alloc }
    let(:item) { nil }
    let(:size) { [] }
    let(:names) { %w[A] }
    let(:delim) { '' }
    let(:cols) { [] }

    context 'for a plain number' do
      let(:container) { :single }
      let(:cols) { %i[number] }
      it 'generates decl' do
        expect(subject).to eq('int A;')
      end

      context 'in declaration only mode' do
        let(:fnc) { :decl }

        it 'generates decl' do
          expect(subject).to eq('int A;')
        end
      end

      context 'in allocation only mode' do
        let(:fnc) { :alloc }

        it 'returns nothing' do
          expect(subject).to eq('')
        end
      end
    end

    context 'for plain numbers' do
      let(:container) { :single }
      let(:cols) { %i[number] * 2 }
      let(:names) { %w[A B] }
      it 'generates decl' do
        expect(subject).to eq('int A, B;')
      end
    end

    context 'for a plain decimal' do
      let(:container) { :single }
      let(:cols) { %i[decimal] }
      it 'generates decl' do
        expect(subject).to eq('double A;')
      end
    end

    context 'for a plain string' do
      let(:container) { :single }
      let(:cols) { %i[string] }
      it 'generates decl' do
        expect(subject).to eq('string A;')
      end
    end

    context 'for plain variables of mixed types' do
      let(:container) { :single }
      let(:cols) { %i[number decimal string] }
      let(:names) { %w[A B C] }
      it 'generates decl' do
        expect(subject).to eq(
          <<~SRC
            int A;
            double B;
            string C;
          SRC
        )
      end

      context 'in declaration only mode' do
        let(:fnc) { :decl }

        it 'generates decl' do
          expect(subject).to eq(
            <<~SRC
              int A;
              double B;
              string C;
            SRC
          )
        end
      end

      context 'in allocation only mode' do
        let(:fnc) { :alloc }

        it 'returns nothing' do
          expect(subject).to eq("\n\n\n")
        end
      end
    end

    context 'for a horizontal array of numbers' do
      let(:container) { :harray }
      let(:cols) { %i[number] }
      let(:size) { %w[N] }
      it 'generates decl' do
        expect(subject).to eq('vector<int> A(N);')
      end

      context 'in declaration only mode' do
        let(:fnc) { :decl }

        it 'omits initializer' do
          expect(subject).to eq('vector<int> A;')
        end
      end

      context 'in allocation only mode' do
        let(:fnc) { :alloc }

        it 'generates allocation code' do
          expect(subject).to eq('A = vector<int>(N);')
        end
      end
    end

    context 'for a horizontal array of numbers with size specified' do
      let(:container) { :harray }
      let(:cols) { %i[number] }
      let(:size) { %w[10] }
      it 'generates decl' do
        expect(subject).to eq('vector<int> A(10);')
      end
    end

    context 'for a horizontal array of decimals' do
      let(:container) { :harray }
      let(:cols) { %i[decimal] }
      let(:size) { %w[N] }
      it 'generates decl' do
        expect(subject).to eq('vector<double> A(N);')
      end
    end

    context 'for a horizontal array of strings' do
      let(:container) { :harray }
      let(:cols) { %i[string] }
      let(:size) { %w[N] }
      it 'generates decl' do
        expect(subject).to eq('vector<string> A(N);')
      end
    end

    context 'for a horizontal array of characters' do
      let(:container) { :harray }
      let(:item) { :char }
      let(:size) { %w[N] }
      it 'generates decl' do
        expect(subject).to eq('string A;')
      end
    end

    context 'for vertical array of numbers' do
      let(:container) { :varray }
      let(:cols) { %i[number] * 2 }
      let(:names) { %w[A B] }
      let(:size) { %w[N] }
      it 'generates decl' do
        expect(subject).to eq(
          <<~SRC
            vector<int> A(N);
            vector<int> B(N);
          SRC
        )
      end

      context 'in declaration only mode' do
        let(:fnc) { :decl }

        it 'omits initializer' do
          expect(subject).to eq(
            <<~SRC
              vector<int> A;
              vector<int> B;
            SRC
          )
        end
      end

      context 'in allocation only mode' do
        let(:fnc) { :alloc }

        it 'generates allocation code' do
          expect(subject).to eq(
            <<~SRC
              A = vector<int>(N);
              B = vector<int>(N);
            SRC
          )
        end
      end
    end

    context 'for vertical array of numbers with size specified' do
      let(:container) { :varray }
      let(:cols) { %i[number] * 2 }
      let(:names) { %w[A B] }
      let(:size) { %w[10] }
      it 'generates decl' do
        expect(subject).to eq(
          <<~SRC
            vector<int> A(10);
            vector<int> B(10);
          SRC
        )
      end
    end

    context 'for vertical array of decimals' do
      let(:container) { :varray }
      let(:cols) { %i[decimal] * 2 }
      let(:names) { %w[A B] }
      let(:size) { %w[N] }
      it 'generates decl' do
        expect(subject).to eq(
          <<~SRC
            vector<double> A(N);
            vector<double> B(N);
          SRC
        )
      end
    end

    context 'for vertical array of strings' do
      let(:container) { :varray }
      let(:cols) { %i[string] * 2 }
      let(:names) { %w[A B] }
      let(:size) { %w[N] }
      it 'generates decl' do
        expect(subject).to eq(
          <<~SRC
            vector<string> A(N);
            vector<string> B(N);
          SRC
        )
      end
    end

    context 'for vertical array of mixed types' do
      let(:container) { :varray }
      let(:cols) { %i[number decimal string] }
      let(:names) { %w[A B C] }
      let(:size) { %w[N] }
      it 'generates decl' do
        expect(subject).to eq(
          <<~SRC
            vector<int> A(N);
            vector<double> B(N);
            vector<string> C(N);
          SRC
        )
      end
    end

    context 'for a matrix of numbers' do
      let(:container) { :matrix }
      let(:cols) { %i[number] }
      let(:size) { %w[R C] }
      it 'generates decl' do
        expect(subject).to eq(
          <<~SRC
            vector<vector<int>> A(R, vector<int>(C));
          SRC
        )
      end

      context 'in declaration only mode' do
        let(:fnc) { :decl }

        it 'omits initializer' do
          expect(subject).to eq(
            <<~SRC
              vector<vector<int>> A;
            SRC
          )
        end
      end

      context 'in allocation only mode' do
        let(:fnc) { :alloc }

        it 'generates allocation code' do
          expect(subject).to eq(
            <<~SRC
              A = vector<vector<int>>(R, vector<int>(C));
            SRC
          )
        end
      end
    end

    context 'for a matrix of numbers with size specified' do
      let(:container) { :matrix }
      let(:cols) { %i[number] }
      let(:size) { %w[8 8] }
      it 'generates decl' do
        expect(subject).to eq(
          <<~SRC
            vector<vector<int>> A(8, vector<int>(8));
          SRC
        )
      end
    end

    context 'for a matrix of decimals' do
      let(:container) { :matrix }
      let(:cols) { %i[decimal] }
      let(:size) { %w[R C] }
      it 'generates decl' do
        expect(subject).to eq(
          <<~SRC
            vector<vector<double>> A(R, vector<double>(C));
          SRC
        )
      end
    end

    context 'for a matrix of strings' do
      let(:container) { :matrix }
      let(:cols) { %i[string] }
      let(:size) { %w[R C] }
      it 'generates decl' do
        expect(subject).to eq(
          <<~SRC
            vector<vector<string>> A(R, vector<string>(C));
          SRC
        )
      end
    end

    context 'for a matrix of characters' do
      let(:container) { :matrix }
      let(:item) { :char }
      let(:size) { %w[R C] }
      it 'generates decl' do
        expect(subject).to eq(
          <<~SRC
            vector<string> A(R);
          SRC
        )
      end
    end

    context 'for a vertical array and a matrix of numbers' do
      let(:container) { :varray_matrix }
      let(:cols) { %i[number] * 2 }
      let(:names) { %w[K A] }
      let(:size) { %w[N K_N] }
      it 'generates decl' do
        expect(subject).to eq(
          <<~SRC
            vector<int> K(N);
            vector<vector<int>> A(N);
          SRC
        )
      end

      context 'in declaration only mode' do
        let(:fnc) { :decl }

        it 'omits initializer' do
          expect(subject).to eq(
            <<~SRC
              vector<int> K;
              vector<vector<int>> A;
            SRC
          )
        end
      end

      context 'in allocation only mode' do
        let(:fnc) { :alloc }

        it 'generates allocation code' do
          expect(subject).to eq(
            <<~SRC
              K = vector<int>(N);
              A = vector<vector<int>>(N);
            SRC
          )
        end
      end
    end

    context 'for a vertical array and a matrix of characters' do
      let(:container) { :varray_matrix }
      let(:item) { :char }
      let(:cols) { %i[number string] }
      let(:names) { %w[K p] }
      let(:size) { %w[Q 26] }
      it 'generates decl' do
        expect(subject).to eq(
          <<~SRC
            vector<int> K(Q);
            vector<string> p(Q);
          SRC
        )
      end
    end

    context 'for a matrix and a vertical array of numbers' do
      let(:container) { :matrix_varray }
      let(:cols) { %i[number] * 2 }
      let(:names) { %w[city cost] }
      let(:size) { %w[M 2] }
      it 'generates decl' do
        expect(subject).to eq(
          <<~SRC
            vector<vector<int>> city(M, vector<int>(2));
            vector<int> cost(M);
          SRC
        )
      end
    end

    context 'for vertically expanded matrices(number)' do
      let(:container) { :vmatrix }
      let(:cols) { %i[number] * 2 }
      let(:names) { %w[idol p] }
      let(:size) { %w[1 C_1] }
      it 'generates decl' do
        expect(subject).to eq(
          <<~SRC
            vector<vector<int>> idol(1, vector<int>(C_1));
            vector<vector<int>> p(1, vector<int>(C_1));
          SRC
        )
      end
    end

    context 'for vertical expanded matrices of mixed types' do
      let(:container) { :vmatrix }
      let(:cols) { %i[number decimal string] }
      let(:names) { %w[A B C] }
      let(:size) { %w[N M] }
      it 'generates decl' do
        expect(subject).to eq(
          <<~SRC
            vector<vector<int>> A(N, vector<int>(M));
            vector<vector<double>> B(N, vector<double>(M));
            vector<vector<string>> C(N, vector<string>(M));
          SRC
        )
      end
    end

    context 'for horizontally expanded matrices(number)' do
      let(:container) { :hmatrix }
      let(:cols) { %i[number] * 2 }
      let(:names) { %w[x y] }
      let(:size) { %w[Q 2] }
      it 'generates decl' do
        expect(subject).to eq(
          <<~SRC
            vector<vector<int>> x(Q, vector<int>(2));
            vector<vector<int>> y(Q, vector<int>(2));
          SRC
        )
      end
    end

    context 'for format with delimiters' do
      let(:container) { :varray }
      let(:item) { :number }
      let(:names) { %w[S E] }
      let(:size) { %w[N] }
      let(:delim) { '-' }
      it 'generates decl' do
        expect(subject).to eq(
          <<~SRC
            vector<int> S(N);
            vector<int> E(N);
            char delim;
          SRC
        )
      end

      context 'in declaration only mode' do
        let(:fnc) { :decl }

        it 'omits initializer' do
          expect(subject).to eq(
            <<~SRC
              vector<int> S;
              vector<int> E;
              char delim;
            SRC
          )
        end
      end

      context 'in allocation only mode' do
        let(:fnc) { :alloc }

        it 'generates allocation code' do
          expect(subject).to eq(
            <<~SRC
              S = vector<int>(N);
              E = vector<int>(N);
            SRC
          )
        end
      end
    end
  end

  describe '#gen_input' do
    subject { generator.gen_input(inpdef) }
    let(:inpdef) do
      AtCoderFriends::Problem::InputFormat.new(
        container: container,
        item: item,
        names: names,
        size: size,
        delim: delim,
        cols: cols
      )
    end
    let(:item) { nil }
    let(:size) { [] }
    let(:names) { %w[A] }
    let(:delim) { '' }
    let(:cols) { [] }

    context 'for a plain number' do
      let(:container) { :single }
      let(:cols) { %i[number] }
      it 'generates input code' do
        expect(subject).to eq('cin >> A;')
      end
    end

    context 'for plain numbers' do
      let(:container) { :single }
      let(:cols) { %i[number] * 2 }
      let(:names) { %w[A B] }
      it 'generates input code' do
        expect(subject).to eq('cin >> A >> B;')
      end
    end

    context 'for a plain decimal' do
      let(:container) { :single }
      let(:cols) { %i[decimal] }
      it 'generates input code' do
        expect(subject).to eq('cin >> A;')
      end
    end

    context 'for a plain string' do
      let(:container) { :single }
      let(:cols) { %i[string] }
      it 'generates input code' do
        expect(subject).to eq('cin >> A;')
      end
    end

    context 'for plain variables of mixed types' do
      let(:container) { :single }
      let(:cols) { %i[number decimal string] }
      let(:names) { %w[A B C] }
      it 'generates input code' do
        expect(subject).to eq('cin >> A >> B >> C;')
      end
    end

    context 'for a horizontal array of numbers' do
      let(:container) { :harray }
      let(:cols) { %i[number] }
      let(:size) { %w[N] }
      it 'generates input code' do
        expect(subject).to eq('REP(i, N) cin >> A[i];')
      end
    end

    context 'for a horizontal array of decimals' do
      let(:container) { :harray }
      let(:cols) { %i[decimal] }
      let(:size) { %w[N] }
      it 'generates input code' do
        expect(subject).to eq('REP(i, N) cin >> A[i];')
      end
    end

    context 'for a horizontal array of strings' do
      let(:container) { :harray }
      let(:cols) { %i[string] }
      let(:size) { %w[N] }
      it 'generates input code' do
        expect(subject).to eq('REP(i, N) cin >> A[i];')
      end
    end

    context 'for a horizontal array of characters' do
      let(:container) { :harray }
      let(:item) { :char }
      let(:size) { %w[N] }
      it 'generates input code' do
        expect(subject).to eq('cin >> A;')
      end
    end

    context 'for vertical array of numbers' do
      let(:container) { :varray }
      let(:cols) { %i[number] }
      let(:names) { %w[A B] }
      let(:size) { %w[N] }
      it 'generates input code' do
        expect(subject).to eq('REP(i, N) cin >> A[i] >> B[i];')
      end
    end

    context 'for vertical array of decimals' do
      let(:container) { :varray }
      let(:cols) { %i[decimal] * 2 }
      let(:names) { %w[A B] }
      let(:size) { %w[N] }
      it 'generates input code' do
        expect(subject).to eq('REP(i, N) cin >> A[i] >> B[i];')
      end
    end

    context 'for vertical array of strings' do
      let(:container) { :varray }
      let(:cols) { %i[string] * 2 }
      let(:names) { %w[A B] }
      let(:size) { %w[N] }
      it 'generates input code' do
        expect(subject).to eq('REP(i, N) cin >> A[i] >> B[i];')
      end
    end

    context 'for vertical array of mixed types' do
      let(:container) { :varray }
      let(:cols) { %i[number decimal string] }
      let(:names) { %w[A B C] }
      let(:size) { %w[N] }
      it 'generates input code' do
        expect(subject).to eq('REP(i, N) cin >> A[i] >> B[i] >> C[i];')
      end
    end

    context 'for a matrix of numbers' do
      let(:container) { :matrix }
      let(:cols) { %i[number] }
      let(:size) { %w[R C] }
      it 'generates input code' do
        expect(subject).to eq('REP(i, R) REP(j, C) cin >> A[i][j];')
      end
    end

    context 'for a matrix of decimals' do
      let(:container) { :matrix }
      let(:cols) { %i[decimal] }
      let(:size) { %w[R C] }
      it 'generates input code' do
        expect(subject).to eq('REP(i, R) REP(j, C) cin >> A[i][j];')
      end
    end

    context 'for a matrix of strings' do
      let(:container) { :matrix }
      let(:cols) { %i[string] }
      let(:size) { %w[R C] }
      it 'generates input code' do
        expect(subject).to eq('REP(i, R) REP(j, C) cin >> A[i][j];')
      end
    end

    context 'for a matrix of characters' do
      let(:container) { :matrix }
      let(:item) { :char }
      let(:size) { %w[R C] }
      it 'generates input code' do
        expect(subject).to eq('REP(i, R) cin >> A[i];')
      end
    end

    context 'for a vertical array and a matrix of numbers' do
      let(:container) { :varray_matrix }
      let(:cols) { %i[number] * 2 }
      let(:names) { %w[K A] }
      let(:size) { %w[N K_N] }
      it 'generates input code' do
        expect(subject).to eq(
          <<~SRC
            REP(i, N) {
              cin >> K[i];
              A[i].resize(K[i]);
              REP(j, K[i]) cin >> A[i][j];
            }
          SRC
        )
      end
    end

    context 'for a vertical array and a matrix of characters' do
      let(:container) { :varray_matrix }
      let(:item) { :char }
      let(:cols) { %i[number string] }
      let(:names) { %w[K p] }
      let(:size) { %w[Q 26] }
      it 'generates input code' do
        expect(subject).to eq(
          <<~SRC
            REP(i, Q) {
              cin >> K[i];
              cin >> p[i];
            }
          SRC
        )
      end
    end

    context 'for a matrix and a vertical array of numbers' do
      let(:container) { :matrix_varray }
      let(:cols) { %i[number] * 2 }
      let(:names) { %w[city cost] }
      let(:size) { %w[M 2] }
      it 'generates input code' do
        expect(subject).to eq(
          <<~SRC
            REP(i, M) {
              REP(j, 2) cin >> city[i][j];
              cin >> cost[i];
            }
          SRC
        )
      end
    end

    context 'for vertically expanded matrices(number)' do
      let(:container) { :vmatrix }
      let(:cols) { %i[number] * 2 }
      let(:names) { %w[idol p] }
      let(:size) { %w[1 C_1] }
      it 'generates input code' do
        expect(subject).to eq(
          'REP(i, 1) REP(j, C_1) cin >> idol[i][j] >> p[i][j];'
        )
      end
    end

    context 'for horizontally expanded matrices(number)' do
      let(:container) { :hmatrix }
      let(:cols) { %i[number] }
      let(:names) { %w[x y] }
      let(:size) { %w[Q 2] }
      it 'generates input code' do
        expect(subject).to eq(
          'REP(i, Q) REP(j, 2) cin >> x[i][j] >> y[i][j];'
        )
      end
    end

    context 'for format with delimiters' do
      let(:container) { :varray }
      let(:item) { :number }
      let(:names) { %w[S E] }
      let(:size) { %w[N] }
      let(:delim) { '-' }
      it 'generates input code' do
        expect(subject).to eq(
          'REP(i, N) cin >> S[i] >> delim >> E[i];'
        )
      end
    end
  end

  shared_context :common_formats do
    let(:formats) do
      [
        AtCoderFriends::Problem::InputFormat.new(
          container: :single,
          names: %w[N],
          cols: %i[number]
        ),
        AtCoderFriends::Problem::InputFormat.new(
          container: :harray,
          names: %w[A],
          size: %w[N],
          cols: %i[number] * 4
        )
      ]
    end
  end

  describe '#gen_global_decls' do
    include_context :common_formats
    subject { generator.gen_global_decls(formats) }

    context 'in default setting' do
      it 'generates nothing' do
        expect(subject).to match([])
      end
    end

    context 'when use_global is set to true' do
      let(:cfg) { { 'use_global' => true } }
      it 'generates decl code only' do
        expect(subject).to match(
          [
            'int N;',
            'vector<int> A;'
          ]
        )
      end
    end
  end

  describe '#gen_local_decls' do
    include_context :common_formats
    subject { generator.gen_local_decls(formats) }

    context 'in default setting' do
      it 'generates decl, alloc, and input code' do
        expect(subject).to match(
          [
            'int N;',
            'cin >> N;',
            'vector<int> A(N);',
            'REP(i, N) cin >> A[i];'
          ]
        )
      end
    end

    context 'when use_global is set to true' do
      let(:cfg) { { 'use_global' => true } }
      it 'generates alloc and input code' do
        expect(subject).to match(
          [
            'cin >> N;',
            'A = vector<int>(N);',
            'REP(i, N) cin >> A[i];'
          ]
        )
      end
    end
  end

  describe '#generate' do
    subject { generator.generate(pbm) }
    let(:pbm) do
      AtCoderFriends::Problem.new('A') do |pbm|
        pbm.formats_src = formats
        pbm.constants = constants
        pbm.options.interactive = interactive
        pbm.options.binary_values = binary_values
      end
    end

    context 'for a general problem' do
      before do
        allow(pbm).to receive(:url) do
          'https://atcoder.jp/contests/practice/tasks/practice_1'
        end
      end
      let(:formats) do
        [
          AtCoderFriends::Problem::InputFormat.new(
            container: :single,
            names: %w[N M],
            cols: %i[number] * 2
          ),
          AtCoderFriends::Problem::InputFormat.new(
            container: :varray,
            names: %w[A B C T],
            size: %w[M],
            cols: %i[number] * 4
          ),
          AtCoderFriends::Problem::InputFormat.new(
            container: :varray_matrix,
            names: %w[K A],
            size: %w[N K_N],
            cols: %i[number] * 2
          )
        ]
      end
      let(:constants) do
        [
          AtCoderFriends::Problem::Constant.new('N', :max, '100000'),
          AtCoderFriends::Problem::Constant.new('M', :max, '10^9'),
          AtCoderFriends::Problem::Constant.new('C_i', :max, '2*10^5'),
          AtCoderFriends::Problem::Constant.new('T_i', :max, '1,000,000'),
          AtCoderFriends::Problem::Constant.new(nil, :mod, '10^9+7')
        ]
      end
      let(:interactive) { false }
      let(:binary_values) { nil }

      it 'generates source' do
        expect(subject).to eq(
          <<~SRC
            // https://atcoder.jp/contests/practice/tasks/practice_1

            #include <bits/stdc++.h>
            #include <atcoder/all>
            using namespace std;
            using namespace atcoder;

            #define REP(i,n)   for(int i=0; i<(int)(n); i++)
            #define FOR(i,b,e) for(int i=(b); i<=(int)(e); i++)
            #if ONLINE_JUDGE
              #define DUMP(a)
              #define DUMP2D(b)
            #else
              #define _GLIBCXX_DEBUG
              #define DUMP(a) REP(_i, a.size()) cout << a[_i] << (_i + 1 == a.size() ? "\\n" : " ")
              #define DUMP2D(b) REP(_j, b.size()) DUMP(b[_j]); cout << endl
            #endif

            const int N_MAX = 100000;
            const int M_MAX = 1e9;
            const int C_I_MAX = 2*1e5;
            const int T_I_MAX = 1'000'000;
            const int MOD = 1e9+7;

            int main() {
              int N, M;
              cin >> N >> M;
              vector<int> A(M);
              vector<int> B(M);
              vector<int> C(M);
              vector<int> T(M);
              REP(i, M) cin >> A[i] >> B[i] >> C[i] >> T[i];
              vector<int> K(N);
              vector<vector<int>> A(N);
              REP(i, N) {
                cin >> K[i];
                A[i].resize(K[i]);
                REP(j, K[i]) cin >> A[i][j];
              }

              int ans = 0;
              cout << ans << endl;
            }
          SRC
        )
      end

      context 'when use_global is set to true' do
        let(:cfg) { { 'use_global' => true } }

        it 'generates source' do
          expect(subject).to eq(
            <<~SRC
              // https://atcoder.jp/contests/practice/tasks/practice_1

              #include <bits/stdc++.h>
              #include <atcoder/all>
              using namespace std;
              using namespace atcoder;

              #define REP(i,n)   for(int i=0; i<(int)(n); i++)
              #define FOR(i,b,e) for(int i=(b); i<=(int)(e); i++)
              #if ONLINE_JUDGE
                #define DUMP(a)
                #define DUMP2D(b)
              #else
                #define _GLIBCXX_DEBUG
                #define DUMP(a) REP(_i, a.size()) cout << a[_i] << (_i + 1 == a.size() ? "\\n" : " ")
                #define DUMP2D(b) REP(_j, b.size()) DUMP(b[_j]); cout << endl
              #endif

              const int N_MAX = 100000;
              const int M_MAX = 1e9;
              const int C_I_MAX = 2*1e5;
              const int T_I_MAX = 1'000'000;
              const int MOD = 1e9+7;

              int N, M;
              vector<int> A;
              vector<int> B;
              vector<int> C;
              vector<int> T;
              vector<int> K;
              vector<vector<int>> A;

              int main() {
                cin >> N >> M;
                A = vector<int>(M);
                B = vector<int>(M);
                C = vector<int>(M);
                T = vector<int>(M);
                REP(i, M) cin >> A[i] >> B[i] >> C[i] >> T[i];
                K = vector<int>(N);
                A = vector<vector<int>>(N);
                REP(i, N) {
                  cin >> K[i];
                  A[i].resize(K[i]);
                  REP(j, K[i]) cin >> A[i][j];
                }

                int ans = 0;
                cout << ans << endl;
              }
            SRC
          )
        end
      end
    end

    context 'for an interactive problem' do
      before do
        allow(pbm).to receive(:url) do
          'https://atcoder.jp/contests/practice/tasks/practice_2'
        end
      end
      let(:formats) do
        [
          AtCoderFriends::Problem::InputFormat.new(
            container: :single,
            names: %w[N Q],
            cols: %i[number] * 2
          )
        ]
      end
      let(:constants) do
        [
          AtCoderFriends::Problem::Constant.new('N', :max, '26'),
          AtCoderFriends::Problem::Constant.new(nil, :mod, '2^32')
        ]
      end
      let(:interactive) { true }
      let(:binary_values) { nil }

      it 'generates source' do
        expect(subject).to eq(
          <<~SRC
            // https://atcoder.jp/contests/practice/tasks/practice_2

            #include <bits/stdc++.h>
            #include <atcoder/all>
            using namespace std;
            using namespace atcoder;

            #define DEBUG
            #define REP(i,n)   for(int i=0; i<(int)(n); i++)
            #define FOR(i,b,e) for(int i=(b); i<=(int)(e); i++)
            #if ONLINE_JUDGE
              #define DUMP(a)
              #define DUMP2D(b)
            #else
              #define _GLIBCXX_DEBUG
              #define DUMP(a) REP(_i, a.size()) cout << a[_i] << (_i + 1 == a.size() ? "\\n" : " ")
              #define DUMP2D(b) REP(_j, b.size()) DUMP(b[_j]); cout << endl
            #endif

            //------------------------------------------------------------------------------
            #ifdef DEBUG
            string source;
            vector<string> responses;
            #endif

            string query(string req) {
              cout << "? " << req << endl;
              string res;
            #ifdef DEBUG
              res = "*** generate response from source ***";
              responses.push_back(res);
            #else
              cin >> res;
            #endif
              return res;
            }

            //------------------------------------------------------------------------------
            const int N_MAX = 26;
            const int MOD = 1<<32;

            int main() {
              int N, Q;
              cin >> N >> Q;
            #ifdef DEBUG
              cin >> source;
            #endif

              string ans;
              cout << "! " << ans << endl;
            #ifdef DEBUG
              cout << "query count: " << responses.size() << endl;
              cout << "query results:" << endl;
              for (string res : responses) cout << res << endl;
            #endif
            }
          SRC
        )
      end
    end

    context 'for a binary problem' do
      before do
        allow(pbm).to receive(:url) do
          'https://atcoder.jp/contests/abc006/tasks/abc006_1'
        end
      end
      let(:formats) do
        [
          AtCoderFriends::Problem::InputFormat.new(
            container: :single,
            names: %w[N],
            cols: %i[number]
          )
        ]
      end
      let(:constants) do
        [
          AtCoderFriends::Problem::Constant.new('N', :max, '9')
        ]
      end
      let(:interactive) { false }
      let(:binary_values) { %w[YES NO] }

      it 'generates source' do
        expect(subject).to eq(
          <<~SRC
            // https://atcoder.jp/contests/abc006/tasks/abc006_1

            #include <bits/stdc++.h>
            #include <atcoder/all>
            using namespace std;
            using namespace atcoder;

            #define REP(i,n)   for(int i=0; i<(int)(n); i++)
            #define FOR(i,b,e) for(int i=(b); i<=(int)(e); i++)
            #if ONLINE_JUDGE
              #define DUMP(a)
              #define DUMP2D(b)
            #else
              #define _GLIBCXX_DEBUG
              #define DUMP(a) REP(_i, a.size()) cout << a[_i] << (_i + 1 == a.size() ? "\\n" : " ")
              #define DUMP2D(b) REP(_j, b.size()) DUMP(b[_j]); cout << endl
            #endif

            const int N_MAX = 9;

            int main() {
              int N;
              cin >> N;

              bool cond = false;
              cout << (cond ? "YES" : "NO") << endl;
            }
          SRC
        )
      end
    end
  end
end
