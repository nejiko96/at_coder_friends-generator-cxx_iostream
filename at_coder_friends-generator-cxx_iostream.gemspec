# frozen_string_literal: true

require_relative 'lib/at_coder_friends/generator/cxx_iostream/version'

Gem::Specification.new do |spec|
  spec.name          = 'at_coder_friends-generator-cxx_iostream'
  spec.version       = AtCoderFriends::Generator::CxxIostreamConstants::VERSION
  spec.authors       = ['nejiko96']
  spec.email         = ['nejiko2006@gmail.com']

  spec.summary       = 'C++(iostream) generator for AtCoderFriends'
  spec.description   = <<-DESCRIPTION
  C++(iostream) suorce generator plugin for AtCoderFriends
  DESCRIPTION
  spec.homepage      = 'https://github.com/nejiko96/at_coder_friends-generator-cxx_iostream'
  spec.license       = 'MIT'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem
  # that have been added into git.
  spec.files         = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      f.match(%r{^(test|spec|features)/})
    end
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = Gem::Requirement.new('>= 2.3.0')

  spec.metadata = {
    'homepage_uri' => spec.homepage,
    'source_code_uri' => spec.homepage,
    'changelog_uri' => spec.homepage + '/blob/master/CHANGELOG.md'
  }

  spec.add_dependency 'at_coder_friends', '~> 0.6.6'

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'simplecov', '~> 0.10'
end
