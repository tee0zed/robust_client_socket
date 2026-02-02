# frozen_string_literal: true

require "./lib/version.rb"

Gem::Specification.new do |spec|
  spec.name = "robust_client_socket"
  spec.version = RobustClientSocket::VERSION
  spec.authors = ["Taras Zhuk"]
  spec.email = ["tee0zed@gmail.com"]
  spec.summary = "Robust Client Socket"
  spec.description = "Methods that should be used to interact with Robust inner ecosystem."
  spec.required_ruby_version = ">= 2.7.7"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[features/ .git .circleci Gemfile])
    end
  end
  spec.require_paths = %w[lib config]
  spec.add_dependency 'oj'
  spec.add_dependency 'httparty'
  spec.add_dependency 'rspec'
  spec.add_dependency 'rake'

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
