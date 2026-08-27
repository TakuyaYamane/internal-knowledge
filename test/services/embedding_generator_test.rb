require "test_helper"

class EmbeddingGeneratorTest < ActiveSupport::TestCase
  FakeResponse = Data.define(:code, :body) do
    def [](key)
      nil
    end
  end

  test "returns embedding from successful response" do
    embedding = [ 0.1, 0.2, 0.3 ]
    response = FakeResponse.new("200", {
      data: [
        {
          object: "embedding",
          index: 0,
          embedding: embedding
        }
      ],
      model: "text-embedding-3-small",
      object: "list"
    }.to_json)

    result = with_http_response(response) do
      with_api_key do
        EmbeddingGenerator.call("VPNへの接続方法")
      end
    end

    assert_equal embedding, result
  end

  test "handles embedding with 1536 dimensions" do
    embedding = Array.new(1_536) { |index| index / 1_536.0 }
    response = FakeResponse.new("200", {
      data: [
        {
          object: "embedding",
          index: 0,
          embedding: embedding
        }
      ]
    }.to_json)

    result = with_http_response(response) do
      with_api_key do
        EmbeddingGenerator.call("VPNへの接続方法")
      end
    end

    assert_equal 1_536, result.size
    assert_equal embedding, result
  end

  test "returns nil when api request fails" do
    response = FakeResponse.new("500", { error: { message: "error" } }.to_json)

    result = with_http_response(response) do
      with_api_key do
        EmbeddingGenerator.call("VPNへの接続方法")
      end
    end

    assert_nil result
  end

  test "does not call api for blank input" do
    result = with_http_response(-> { raise "should not be called" }) do
      with_api_key do
        EmbeddingGenerator.call("   ")
      end
    end

    assert_nil result
  end

  test "returns nil when api key is missing" do
    response = -> { raise "should not be called" }

    result = with_http_response(response) do
      without_api_key do
        EmbeddingGenerator.call("VPNへの接続方法")
      end
    end

    assert_nil result
  end

  test "returns nil for invalid response" do
    response = FakeResponse.new("200", { data: [] }.to_json)

    result = with_http_response(response) do
      with_api_key do
        EmbeddingGenerator.call("VPNへの接続方法")
      end
    end

    assert_nil result
  end

  private

  def with_http_response(response_or_callable)
    original_start = Net::HTTP.method(:start)

    Net::HTTP.define_singleton_method(:start) do |*, &block|
      response = response_or_callable.respond_to?(:call) ? response_or_callable.call : response_or_callable
      block.call(FakeHttp.new(response))
    end

    yield
  ensure
    Net::HTTP.define_singleton_method(:start, original_start)
  end

  def with_api_key
    previous_key = ENV["OPENAI_API_KEY"]
    ENV["OPENAI_API_KEY"] = "test-api-key"

    yield
  ensure
    ENV["OPENAI_API_KEY"] = previous_key
  end

  def without_api_key
    previous_key = ENV["OPENAI_API_KEY"]
    ENV.delete("OPENAI_API_KEY")

    yield
  ensure
    ENV["OPENAI_API_KEY"] = previous_key
  end

  class FakeHttp
    def initialize(response)
      @response = response
    end

    def request(request)
      @response
    end
  end
end
