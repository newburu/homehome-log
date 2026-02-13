module Ai
  class GroupingService
    require "gemini-ai"

    MODELS = %w[gemini-1.5-flash gemini-1.5-pro gemini-1.0-pro].freeze

    def self.suggest_praises(count: 5, exclude_praises: [])
      new.suggest_praises(count, exclude_praises)
    end

    def suggest_praises(count, exclude_praises)
      last_error = nil

      MODELS.each do |model|
        begin
          return fetch_from_gemini(model, count, exclude_praises)
        rescue => e
          Rails.logger.warn "Gemini API failed with model #{model}: #{e.message}"
          last_error = e
          next
        end
      end

      # If all fail, return fallback mock data in development or raise error
      if Rails.env.development?
        Rails.logger.warn "All Gemini models failed. Returning mock data."
        return mock_praises(count, exclude_praises)
      end

      raise "All Gemini models failed. Last error: #{last_error&.message}"
    end

    private

    THEMES = [
      "仕事・勉強（タスク消化、集中、準備など）",
      "家事・生活（掃除、料理、整理整頓など）",
      "セルフケア・休息（睡眠、食事、リラックス、体調管理など）",
      "人間関係・コミュニケーション（挨拶、感謝、連絡など）",
      "趣味・創造活動（読書、創作、学びなど）",
      "朝のルーティン（起床、身支度、朝食など）",
      "夜のルーティン（入浴、歯磨き、就寝準備など）",
      "感情・メンタル（自分の気持ちに気づく、深呼吸、ポジティブな思考など）"
    ].freeze

    def fetch_from_gemini(model, count, exclude_praises)
      Rails.logger.info "Attempting to fetch from Gemini with model: #{model}"

      client = Gemini.new(
        credentials: {
          service: "generative-language-api",
          api_key: ENV["GOOGLE_API_KEY"]
        },
        options: { model: model, server_sent_events: false }
      )

      theme = THEMES.sample
      Rails.logger.info "Selected theme: #{theme}"

      exclude_text = ""
      if exclude_praises.any?
        exclude_text = <<~EXCLUDE

        # 除外リスト（以下の内容は既に提案済みのため、今回は提案しないでください）
        #{exclude_praises.map { |p| "- #{p}" }.join("\n")}
        EXCLUDE
      end

      prompt = <<~TEXT
        ADHDの特性を持つ人が、自己肯定感を高めるために、自分自身を褒めることができるような「小さな行動」や「出来事」を#{count}つ提案してください。

        今回は特に【#{theme}】に関連する内容を中心に提案してください。#{exclude_text}

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

      Rails.logger.debug "Gemini Raw Result: #{result.inspect}"

      # gemini-ai gem response structure depends on version, usually raw hash or object
      # Handle both hash access and method access if necessary
      candidates = result["candidates"] || result.dig("candidates")

      unless candidates
        # Fallback for different response structure or error
        Rails.logger.error "No candidates found in Gemini response: #{result.inspect}"
        raise "Gemini API response format unexpected: #{result.inspect}"
      end

      text = candidates.first.dig("content", "parts", 0, "text") ||
             candidates.first.dig("content", "parts", 0, "text")

      # Clean up markdown code blocks if present
      json_text = text.gsub(/```json\n?/, "").gsub(/```/, "").strip

      parsed = JSON.parse(json_text)
      parsed["praises"]
    end

    def mock_praises(count, exclude_praises)
      all_praises = [
        "朝、目が覚めたこと",
        "深呼吸を一度したこと",
        "窓を開けて空気を入れ替えたこと",
        "誰かに挨拶をしたこと",
        "今の時間を大切にしようと思ったこと",
        "コップ一杯の水を飲んだこと",
        "好きな音楽を聴いたこと",
        "鏡を見て自分に微笑んだこと",
        "少しだけストレッチをしたこと",
        "温かい飲み物を飲んでリラックスしたこと",
        "雲を眺めてぼんやりしたこと",
        "今日やることを一つリストアップしたこと",
        "スマホを置いてデジタルデトックスしたこと",
        "自分の体を労わる言葉をかけたこと",
        "小さなごみを一つ拾ったこと"
      ]

      # Exclude praises that are already in the exclude list
      available_praises = all_praises - exclude_praises

      # If we ran out of praises, fallback to all praises to avoid returning empty
      return all_praises.sample(count) if available_praises.empty?

      available_praises.sample(count)
    end
  end
end
