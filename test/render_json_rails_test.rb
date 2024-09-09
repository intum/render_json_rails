require "test_helper"

class TestModel1
  include RenderJsonRails::Concern
  render_json_config name: :model1,
                     except: [:account_id],
                     allowed_methods: [:calculated0]
end

class TestModel2
  include RenderJsonRails::Concern
  render_json_config name: :model2,
                     except: [:account_id],
                     methods: [:calculated1],
                     includes: {
                       test_model1: TestModel1,
                     }
end

class TestModel3
  include RenderJsonRails::Concern
  render_json_config name: :model3,
                     except: [:account_id],
                     methods: [:calculated1],
                     allowed_methods: [:calculated2],
                     includes: {
                       test_model2: TestModel2,
                     }
end

class DefaultFieldsModel
  include RenderJsonRails::Concern
  render_json_config name: :default_fields_model,
                     default_fields: [:id, :account_id, :calculated1, :name],
                     except: [:account_id],
                     allowed_methods: [:calculated1, :calculated2]
end

class DefaultFieldsModelWithOnly
  include RenderJsonRails::Concern
  render_json_config name: :default_fields_model_with_only,
                     default_fields: [:id, :account_id, :calculated1, :name],
                     only: [:id, :name],
                     allowed_methods: [:calculated1, :calculated2]
end

class RenderJsonRailsTest < Minitest::Test
  def test_that_it_has_a_version_number
    assert RenderJsonRails::VERSION.present?
  end

  def test_model1
    out = TestModel1.render_json_options
    expected = { except: [:account_id] }
    assert_equal expected, out, "out: #{out}"

    out = TestModel1.render_json_options(fields: { "model1" => "id,account_id,  name" })
    expected = { only: [:id, :name] }
    assert_equal expected, out, "out: #{out}"
  end

  def test_model2
    out = TestModel2.render_json_options
    expected = { except: [:account_id], methods: [:calculated1] }
    assert_equal expected, out, "out: #{out}"

    out = TestModel2.render_json_options(fields: {
      "model2" => " id ,account_id,name,calculated1",
    })
    expected = { only: [:id, :name], methods: [:calculated1] }
    assert_equal expected, out, "out: #{out}"

    out = TestModel2.render_json_options(
      fields: { "model2" => " id ,account_id,name,calculated1" },
      includes: ['test_model1']
    )
    expected = {
      only: [:id, :name],
      methods: [:calculated1],
      include: [
        { test_model1: { except: [:account_id] } },
      ],
    }
    assert_equal expected, out, "out: #{out}"

    out = TestModel2.render_json_options(
      fields: {
        "model2" => " id ,account_id,name,calculated1",
        "model1" => "id,account_id,  name",
      },
      includes: ['test_model1']
    )
    expected = {
      only: [:id, :name],
      methods: [:calculated1],
      include: [
        { test_model1: { only: [:id, :name] } },
      ],
    }
    assert_equal expected, out, "out: #{out}"
  end

  def test_model3
    out = TestModel3.render_json_options
    expected = { except: [:account_id], methods: [:calculated1] }
    assert_equal expected, out, "out: #{out}"

    out = TestModel3.render_json_options(fields: { "model3" => "id,account_id, name,calculated2" })
    expected = { only: [:id, :name], methods: [:calculated2] }
    assert_equal expected, out, "out: #{out}"

    out = TestModel3.render_json_options(
      fields: {
        "model3" => "id,account_id, name,calculated2",
        "model2" => " id,name,calculated1",
        "model1" => " id1,name1,calculated0",
      },
      includes: ['test_model2', 'test_model2.test_model1']
    )
    expected = {
      only: [:id, :name],
      methods: [:calculated2],
      include: [{
        test_model2: {
          only: [:id, :name],
          methods: [:calculated1],
          include: [{
            test_model1: {
              only: [:id1, :name1],
              methods: [:calculated0],
            },
          }],
        },
      }],
    }
    assert_equal expected, out, "out: #{out}"
  end

  def test_default_fields_model
    out = DefaultFieldsModel.render_json_options
    expected = { only: [:id, :name], methods: [:calculated1] }
    assert_equal expected, out, "out: #{out}"

    out = DefaultFieldsModel.render_json_options(fields: { "default_fields_model" => "id,account_id,kind,user,calculated2" })
    expected = { only: [:id, :kind, :user], methods: [:calculated2] }
    assert_equal expected, out, "out: #{out}"
  end

  def test_default_fields_model_with_only
    out = DefaultFieldsModelWithOnly.render_json_options
    expected = { only: [:id, :name], methods: [:calculated1] }
    assert_equal expected, out, "out: #{out}"

    out = DefaultFieldsModelWithOnly.render_json_options(fields: {
      "default_fields_model_with_only" => "id,account_id,kind,user,calculated2",
    })
    expected = { only: [:id], methods: [:calculated2] }
    assert_equal expected, out, "out: #{out}"
  end

  def test_override_render_json_config
    out = TestModel1.render_json_options
    expected = { except: [:account_id] }
    assert_equal expected, out, "out: #{out}"

    out = TestModel1.render_json_options(
      override_render_json_config: {
        only: [:id, :email],
        default_fields: [:calculated0, :id, :email],
      }
    )
    expected = { only: [:id, :email] }
    assert_equal expected, out, "out: #{out}"
  end

  def test_additional_fields
    out = DefaultFieldsModel.render_json_options # default_fields_model
    expected = { only: [:id, :name], methods: [:calculated1] }
    assert_equal expected, out, "out: #{out}"

    out = DefaultFieldsModel.render_json_options(
      additional_fields: { "default_fields_model" => "account_id,number,calculated2" }
    )
    expected = { only: [:id, :name, :number], methods: [:calculated1, :calculated2] }
    assert_equal expected, out, "out: #{out}"

    out = TestModel1.render_json_options(
      additional_fields: { "model1" => "calculated0" }
    )
    expected = { except: [:account_id], methods: [:calculated0] }
    assert_equal expected, out, "out: #{out}"

    out = DefaultFieldsModelWithOnly.render_json_options(
      additional_fields: {"default_fields_model_with_only" => "calculated2"}
    )
    expected = { only: [:id, :name], methods: [:calculated1, :calculated2] }
    assert_equal expected, out, "out: #{out}"
  end

  def test_find_render_json_options_class
    object = nil
    out = RenderJsonRails::Helper.find_render_json_options_class!(object)
    assert_nil out

    object = []
    out = RenderJsonRails::Helper.find_render_json_options_class!(object)
    assert_nil out

    object = TestModel1.new
    out = RenderJsonRails::Helper.find_render_json_options_class!(object)
    assert_equal TestModel1, out

    object = [TestModel1.new]
    out = RenderJsonRails::Helper.find_render_json_options_class!(object)
    assert_equal TestModel1, out

    object = { a: TestModel1.new }
    out = RenderJsonRails::Helper.find_render_json_options_class!(object)
    assert_nil out

    object = [1, TestModel1.new]
    out = RenderJsonRails::Helper.find_render_json_options_class!(object)
    assert_nil out
  end

  def test_nested_additional_fields
    out = TestModel2.render_json_options(
      fields: { "model2" => " id ,account_id,name,calculated1" },
      includes: ['test_model1'],
      additional_fields: { "model1" => "calculated0" }
    )
    expected = {
      only: [:id, :name],
      methods: [:calculated1],
      include: [
        { test_model1: { except: [:account_id], methods: [:calculated0] } },
      ],
    }
    assert_equal expected, out, "out: #{out}"
  end

  def test_except_in_additional_config_should_work_on_methods
    out = DefaultFieldsModel.render_json_options
    expected = { only: [:id, :name], methods: [:calculated1] }
    assert_equal expected, out, "out: #{out}"

    out = DefaultFieldsModel.render_json_options(
      additional_config: {
        except: [:calculated1]
      }
    )
    expected = { only: [:id, :name], except: [:calculated1] }
    assert_equal expected, out, "out: #{out}"
  end
end
