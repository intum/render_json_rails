require_relative 'lib/render_json_rails/version'

Gem::Specification.new do |spec|
  spec.name          = "render_json_rails"
  spec.version       = RenderJsonRails::VERSION
  spec.licenses      = ['MIT']
  spec.authors       = ["Marcin"]
  spec.email         = ["marcin@radgost.com"]

  spec.summary       = "Simle JSON API render like JonApi"
  spec.description   = "render json with 'includes' and 'fields' with simple config"
  spec.homepage      = "https://github.com/intum/render_json_rails"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  # spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  # spec.metadata["https://radgost.pl/gems"] = spec.homepage
  # spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.add_development_dependency "activesupport"
  spec.add_development_dependency "byebug"
end
