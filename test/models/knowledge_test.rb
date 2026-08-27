require "test_helper"

class KnowledgeTest < ActiveSupport::TestCase
  test "invalid without title" do
    knowledge = build_knowledge(title: nil)

    assert_not knowledge.valid?
  end

  test "invalid without content" do
    knowledge = build_knowledge(content: nil)

    assert_not knowledge.valid?
  end

  test "invalid without category" do
    knowledge = build_knowledge(category: nil)

    assert_not knowledge.valid?
  end

  test "valid with title up to 255 characters" do
    knowledge = build_knowledge(title: "a" * 255)

    assert knowledge.valid?
  end

  test "invalid with title longer than 255 characters" do
    knowledge = build_knowledge(title: "a" * 256)

    assert_not knowledge.valid?
  end

  test "valid with category up to 100 characters" do
    knowledge = build_knowledge(category: "a" * 100)

    assert knowledge.valid?
  end

  test "invalid with category longer than 100 characters" do
    knowledge = build_knowledge(category: "a" * 101)

    assert_not knowledge.valid?
  end

  test "valid with title content and category" do
    knowledge = build_knowledge

    assert knowledge.valid?
  end

  private

  def build_knowledge(attributes = {})
    Knowledge.new({
      title: "経費精算の方法",
      content: "経費精算はシステムから申請してください。",
      category: "経費"
    }.merge(attributes))
  end
end
