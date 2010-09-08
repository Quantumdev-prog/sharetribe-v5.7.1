# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{recaptcha}
  s.version = "0.2.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Jason L. Perry"]
  s.date = %q{2009-10-23}
  s.description = %q{This plugin adds helpers for the reCAPTCHA API }
  s.email = %q{jasper@ambethia.com}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.rdoc"
  ]
  s.files = [
    "CHANGELOG",
     "LICENSE",
     "README.rdoc",
     "Rakefile",
     "VERSION",
     "init.rb",
     "lib/recaptcha.rb",
     "lib/recaptcha/client_helper.rb",
     "lib/recaptcha/merb.rb",
     "lib/recaptcha/rails.rb",
     "lib/recaptcha/verify.rb",
     "recaptcha.gemspec",
     "tasks/recaptcha_tasks.rake",
     "test/recaptcha_test.rb",
     "test/verify_recaptcha_test.rb"
  ]
  s.homepage = %q{http://ambethia.com/recaptcha}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{Helpers for the reCAPTCHA API}
  s.test_files = [
    "test/recaptcha_test.rb",
     "test/verify_recaptcha_test.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end

