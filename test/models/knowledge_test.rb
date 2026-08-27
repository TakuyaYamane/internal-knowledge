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

  test "search by title" do
    matching = create_knowledge(title: "経費精算の方法")
    create_knowledge(title: "VPNへの接続方法")

    assert_equal [ matching ], Knowledge.search("経費")
  end

  test "search by content" do
    matching = create_knowledge(content: "勤怠管理システムから申請してください。")
    create_knowledge(content: "VPNクライアントを起動してください。")

    assert_equal [ matching ], Knowledge.search("勤怠")
  end

  test "search by category" do
    matching = create_knowledge(category: "労務")
    create_knowledge(category: "IT")

    assert_equal [ matching ], Knowledge.search("労務")
  end

  test "search by partial match" do
    matching = create_knowledge(title: "有給休暇の申請方法")
    create_knowledge(title: "経費精算の方法")

    assert_equal [ matching ], Knowledge.search("休暇")
  end

  test "search with blank query returns all knowledges" do
    older = create_knowledge(title: "経費精算の方法", created_at: 2.days.ago)
    newer = create_knowledge(title: "VPNへの接続方法", created_at: 1.day.ago)

    assert_equal [ newer, older ], Knowledge.search("")
  end

  test "search with no matches returns none" do
    create_knowledge(title: "経費精算の方法")

    assert_empty Knowledge.search("該当なし")
  end

  test "search escapes like wildcards" do
    percent_match = create_knowledge(title: "達成率100%のルール")
    underscore_match = create_knowledge(title: "部署_Aのルール")
    create_knowledge(title: "達成率100点のルール")
    create_knowledge(title: "部署XAのルール")

    assert_equal [ percent_match ], Knowledge.search("100%")
    assert_equal [ underscore_match ], Knowledge.search("部署_A")
  end

  private

  def build_knowledge(attributes = {})
    Knowledge.new({
      title: "経費精算の方法",
      content: "経費精算はシステムから申請してください。",
      category: "経費"
    }.merge(attributes))
  end

  def create_knowledge(attributes = {})
    Knowledge.create!({
      title: "社内ルール",
      content: "本文をここに入力します。",
      category: "一般"
    }.merge(attributes))
  end
end
