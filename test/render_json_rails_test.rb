require "test_helper"

class TestModel1
  include RenderJsonRails::Concern
  render_json_config name: :model1,
                     except: [:account_id]
                    #  includes: {
                    #    last_emails: Mail::Email,
                    #  }
end

class TestModel2
  include RenderJsonRails::Concern
  render_json_config name: :model2,
                     except: [:account_id],
                     methods: [:calculate1]
end

class TestModel3
  include RenderJsonRails::Concern
  render_json_config name: :model3,
                     except: [:account_id],
                     methods: [:calculate1],
                     allowed_methods: [:calculate2]
end

class DefaultFieldsModel

  include RenderJsonRails::Concern
  render_json_config name: :default_fields_model,
                     default_fields: [:id, :account_id, :calculate1, :name],
                     except: [:account_id],
                     allowed_methods: [:calculate1, :calculate2]
end

class DefaultFieldsModelWithOnly

  include RenderJsonRails::Concern
  render_json_config name: :default_fields_model_with_only,
                     default_fields: [:id, :account_id, :calculate1, :name],
                     only: [:id, :name],
                     allowed_methods: [:calculate1, :calculate2]
end

class RenderJsonRailsTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil RenderJsonRails::VERSION
  end

  def test_model1
    out = TestModel1.render_json_options()
    expected = { except: [:account_id] }
    assert_equal expected, out, "out: #{out}"

    out = TestModel1.render_json_options(fields: { "model1" => "id,account_id,  name" })
    expected = { only: [:id, :name] }
    assert_equal expected, out, "out: #{out}"
  end

  def test_model2
    out = TestModel2.render_json_options()
    expected = { except: [:account_id], methods: [:calculate1] }
    assert_equal expected, out, "out: #{out}"

    out = TestModel2.render_json_options(fields: { "model2" => " id ,account_id,name,calculate1" })
    expected = { only: [:id, :name], methods: [:calculate1] }
    assert_equal expected, out, "out: #{out}"
  end

  def test_model3
    out = TestModel3.render_json_options()
    expected = { except: [:account_id], methods: [:calculate1] }
    assert_equal expected, out, "out: #{out}"

    out = TestModel3.render_json_options(fields: { "model3" => "id,account_id, name,calculate2" })
    expected = { only: [:id, :name], methods: [:calculate2] }
    assert_equal expected, out, "out: #{out}"
  end


  def test_default_fields_model
    out = DefaultFieldsModel.render_json_options()
    expected = { only: [:id, :name], methods: [:calculate1] }
    assert_equal expected, out, "out: #{out}"

    out = DefaultFieldsModel.render_json_options(fields: { "default_fields_model" => "id,account_id,kind,user,calculate2"})
    expected = { only: [:id, :kind, :user], methods: [:calculate2] }
    assert_equal expected, out, "out: #{out}"
  end

  def test_default_fields_model_with_only
    out = DefaultFieldsModelWithOnly.render_json_options()
    expected = { only: [:id, :name], methods: [:calculate1] }
    assert_equal expected, out, "out: #{out}"

    out = DefaultFieldsModelWithOnly.render_json_options(fields: { "default_fields_model_with_only" => "id,account_id,kind,user,calculate2"})
    expected = { only: [:id], methods: [:calculate2] }
    assert_equal expected, out, "out: #{out}"
  end
end