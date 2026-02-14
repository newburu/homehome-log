module Ai
  class GroupingService
    require "gemini-ai"

    MODELS = %w[gemini-1.5-flash gemini-1.5-pro].freeze

    def self.suggest_praises(count: 5, exclude_praises: [], theme: nil)
      new.suggest_praises(count, exclude_praises, theme)
    end

    def suggest_praises(count, exclude_praises, theme = nil)
      # Normalize theme key to full string
      selected_theme = if theme.present?
                         THEME_MAPPING[theme] || (THEMES.include?(theme) ? theme : nil)
      end
      selected_theme ||= THEMES.sample

      last_error = nil

      MODELS.each do |model|
        begin
          return fetch_from_gemini(model, count, exclude_praises, selected_theme)
        rescue => e
          Rails.logger.warn "Gemini API failed with model #{model}: #{e.message}"
          last_error = e
          next
        end
      end

      # If all fail, return fallback mock data in development or raise error
      if Rails.env.development?
        Rails.logger.warn "All Gemini models failed. Returning mock data."
        return mock_praises(count, exclude_praises, selected_theme)
      end

      raise "All Gemini models failed. Last error: #{last_error&.message}"
    end

    private

    THEME_MAPPING = {
      "work" => "仕事・勉強（タスク消化、集中、準備など）",
      "housework" => "家事・生活（掃除、料理、整理整頓など）",
      "rest" => "セルフケア・休息（睡眠、食事、リラックス、体調管理など）",
      "relationship" => "人間関係・コミュニケーション（挨拶、感謝、連絡など）",
      "hobby" => "趣味・創造活動（読書、創作、学びなど）",
      "morning" => "朝のルーティン（起床、身支度、朝食など）",
      "night" => "夜のルーティン（入浴、歯磨き、就寝準備など）",
      "emotion" => "感情・メンタル（自分の気持ちに気づく、深呼吸、ポジティブな思考など）"
    }.freeze

    THEMES = THEME_MAPPING.values.freeze

    def fetch_from_gemini(model, count, exclude_praises, theme = nil)
      Rails.logger.info "Attempting to fetch from Gemini with model: #{model}"

      client = Gemini.new(
        credentials: {
          service: "generative-language-api",
          api_key: ENV["GOOGLE_API_KEY"],
          version: "v1beta"
        },
        options: { model: model, server_sent_events: false }
      )

      # Resolve theme from mapping if key provided, verify value if full string provided
      selected_theme = if theme.present?
                         THEME_MAPPING[theme] || (THEMES.include?(theme) ? theme : nil)
      end
      selected_theme ||= THEMES.sample

      Rails.logger.info "Selected theme: #{selected_theme} (from input: #{theme})"

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

      # Extract JSON object from text (handling markdown or extra text)
      # Matches the first occurrence of { ... } including newlines
      json_text = text[/{.*}/m] || text.gsub(/```json\n?/, "").gsub(/```/, "").strip

      parsed = JSON.parse(json_text)
      parsed["praises"]
    end

    def mock_praises(count, exclude_praises, theme = nil)
      theme_praises = {
        "仕事・勉強（タスク消化、集中、準備など）" => [
          "デスクに向かったこと",
          "メールを1通返したこと",
          "タスクリストを作ったこと",
          "5分だけ集中できたこと",
          "わからないことを質問できたこと"
        ],
        "家事・生活（掃除、料理、整理整頓など）" => [
          "洗濯機を回したこと",
          "ゴミをまとめたこと",
          "洗い物を水につけたこと",
          "机の上を少し片付けたこと",
          "郵便物を確認したこと"
        ],
        "セルフケア・休息（睡眠、食事、リラックス、体調管理など）" => [
          "水を一杯飲んだこと",
          "深呼吸をしたこと",
          "少し早めに布団に入ったこと",
          "野菜を一口食べたこと",
          "窓を開けて換気したこと"
        ]
      }

      # Fallback generic praises
      generic_praises = [
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

      candidates = theme ? (theme_praises[theme] || generic_praises) : generic_praises

      # If theme specific praises are too few or not found, mix with generic
      if candidates.size < count
        candidates += generic_praises
      end

      # Exclude praises that are already in the exclude list
      available_praises = candidates.uniq - exclude_praises

      # If we ran out of praises, fallback to all praises to avoid returning empty
      return candidates.sample(count) if available_praises.empty?

      available_praises.sample(count)
    end
  end
end
