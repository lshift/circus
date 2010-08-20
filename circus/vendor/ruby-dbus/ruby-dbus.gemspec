# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{ruby-dbus}
  s.version = "0.3.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Ruby DBus Team"]
  s.autorequire = %q{dbus}
  s.date = %q{2010-03-28}
  s.email = %q{ruby-dbus-devel@lists.luon.net}
  s.extra_rdoc_files = ["ChangeLog", "COPYING", "README", "NEWS"]
  s.files = ["doc/tutorial/src/00.index.page", "doc/tutorial/src/10.intro.page", "doc/tutorial/src/20.basic_client.page", "doc/tutorial/src/30.service.page", "doc/tutorial/src/default.css", "doc/tutorial/src/default.template", "examples/gdbus", "examples/gdbus/gdbus", "examples/gdbus/gdbus.glade", "examples/gdbus/launch.sh", "examples/no-introspect", "examples/no-introspect/nm-test.rb", "examples/no-introspect/tracker-test.rb", "examples/rhythmbox", "examples/rhythmbox/playpause.rb", "examples/service", "examples/service/call_service.rb", "examples/service/service_newapi.rb", "examples/simple", "examples/simple/call_introspect.rb", "examples/utils", "examples/utils/listnames.rb", "examples/utils/notify.rb", "lib/dbus", "lib/dbus.rb", "lib/dbus/auth.rb", "lib/dbus/bus.rb", "lib/dbus/export.rb", "lib/dbus/introspect.rb", "lib/dbus/marshall.rb", "lib/dbus/matchrule.rb", "lib/dbus/message.rb", "lib/dbus/type.rb", "setup.rb", "test/Makefile", "test/bus_driver_test.rb", "test/server_robustness_test.rb", "test/server_test.rb", "test/service_newapi.rb", "test/session_bus_test_manual.rb", "test/signal_test.rb", "test/t1", "test/t2.rb", "test/t3-ticket27.rb", "test/t5-report-dbus-interface.rb", "test/t6-loop.rb", "test/test_all", "test/test_server", "test/variant_test.rb", "ChangeLog", "COPYING", "README", "NEWS"]
  s.homepage = %q{http://trac.luon.net/data/ruby-dbus/}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{Ruby module for interaction with DBus}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
