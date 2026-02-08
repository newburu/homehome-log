module Ai
  class GroupingService
    require "gemini-ai"

    MODELS = %w[gemini-1.5-flash gemini-1.5-pro gemini-1.0-pro].freeze

    def self.suggest_praises(count: 5)
      new.suggest_praises(count)
    end

    def suggest_praises(count)
      last_error = nil

      MODELS.each do |model|
        begin
          return fetch_from_gemini(model, count)
        rescue => e
          Rails.logger.warn "Gemini API failed with model #{model}: #{e.message}"
          last_error = e
          next
        end
      end

      # If all fail, return fallback mock data in development or raise error
      if Rails.env.development?
        Rails.logger.warn "All Gemini models failed. Returning mock data."
        return mock_praises(count)
      end

      raise "All Gemini models failed. Last error: #{last_error&.message}"
    end

    private

    def fetch_from_gemini(model, count)
      Rails.logger.info "Attempting to fetch from Gemini with model: #{model}"

      client = Gemini.new(
        credentials: {
          service: "generative-language-api",
          api_key: ENV["GOOGLE_API_KEY"]
        },
        options: { model: model, server_sent_events: false }
      )

      prompt = <<~TEXT
        ADHDの特性を持つ人が、自己肯定感を高めるために、自分自身を褒めることができるような「小さな行動」や「出来事」を#{count}つ提案してください。

        # 条件
        - 親しみやすい、優しい口調で。
        - 具体的な行動（例：「朝、起き上がれた」「歯を磨いた」など）。
        - JSON形式で出力してください。配列のキーは "praises" としてください。

        # 出力例
        {
          "praises": [
            "朝、布団から出られたこと",
            "コップ一杯の水を飲んだこと",
            ...
          ]
        }
      TEXT

      result = client.generate_content({
        contents: {
          role: "user",
          parts: { text: prompt }
        }
      })

      # gemini-ai gem response structure depends on version, usually raw hash or object
      # Assuming result is a Hash or Object with 'candidates'

      text = result.dig("candidates", 0, "content", "parts", 0, "text") ||
             result.dig("candidates", 0, "content", "parts", 0, "text")

      # Clean up markdown code blocks if present
      json_text = text.gsub(/```json\n?/, "").gsub(/```/, "").strip

      parsed = JSON.parse(json_text)
      parsed["praises"]
    end

    def mock_praises(count)
      [
        "朝、目が覚めたこと",
        "深呼吸を一度したこと",
        "窓を開けて空気を入れ替えたこと",
        "誰かに挨拶をしたこと",
        "今の時間を大切にしようと思ったこと"
      ].take(count)
    end
  end
end
