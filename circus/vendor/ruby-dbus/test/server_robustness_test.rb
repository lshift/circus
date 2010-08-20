#!/usr/bin/env ruby
# Test that a server survives various error cases
require "test/unit"
require "dbus"

class ServerRobustnessTest < Test::Unit::TestCase
  def setup
    @bus = DBus::SessionBus.instance
    @svc = @bus.service("org.ruby.service")
  end

  # https://trac.luon.net/ruby-dbus/ticket/31
  # the server should not crash
  def test_no_such_path_with_introspection
    obj = @svc.object "/org/ruby/NotMyInstance"
    obj.introspect
    assert false, "should have raised"
  rescue DBus::Error => e
    assert_no_match(/timeout/, e)
  end

  def test_no_such_path_without_introspection
    obj = @svc.object "/org/ruby/NotMyInstance"
    ifc = DBus::ProxyObjectInterface.new(obj, "org.ruby.SampleInterface")
    ifc.define_method("the_answer", "out n:i")
    ifc.the_answer
    assert false, "should have raised"
  rescue DBus::Error => e
    assert_no_match(/timeout/, e)
  end

  def test_a_method_that_raises
    obj = @svc.object "/org/ruby/MyInstance"
    obj.introspect
    obj.default_iface = "org.ruby.SampleInterface"
    obj.will_raise
    assert false, "should have raised"
  rescue DBus::Error => e
    assert_no_match(/timeout/, e)
  end
end
