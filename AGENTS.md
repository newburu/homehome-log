# AGENTS.md

## 1. プロジェクト概要
**プロジェクト名**: ほめほめログ
**目的**: ADHDの特性を持つ人が、小さなことを褒めあうことで、自己肯定感を高め、何かのきっかけを作れるようにする。
**コア機能**:
- レスポンシブデザインであること。
- ヘッダーにタイトル、ログインのリンクがあること。
- 利用規約、プライバシーポリシーがフッターにあること。
- ログインは、Googleアカウント、Xアカウントで可能とすること。
- メールアドレスでのログインは不可能とすること。
- ゲストユーザーはログインなしで使えるものとする。
- TOPページに、LPを表示すること。
- ログイン後、AIが自動で誉めれることを５つ提案する。
- 誉められることの中から、ユーザーが選ぶ（複数選択可能）と、その内容がログとして保存される。
- ５つの提案以外に、「次へ」を追加すること。
- 「次へ」を押すと、AIが自動で誉めれることを、再度５つ提案する。
- これを繰り返し、その日の誉められることを貯めていく。

## 2. 技術スタック (Strict Constraints)
以下の技術選定を厳守すること。
- **Backend Framework**: Ruby on Rails の安定版最新
- **Frontend**: Rails Server-Side Rendering (ERB) + **Hotwire (Turbo + Stimulus)**
※ React, Next.js, Vue.js は**使用しない**。
- **Database**: **MariaDB** (Gem: `mysql2`)
- **Infrastructure**: **No Docker**. ローカル環境（Mac/Linux）での直接実行を前提とし、現在のディレクトリをルートとして開発を進める。
- **Testing**: Minitest (Rails標準)
- **CSS**: Tailwind CSS
- **AI**: Google Gemini API

## 3. ディレクトリ・アーキテクチャ構成
Railsの標準構成（Convention over Configuration）に従う。

## 4. 開発・実装ルール
### A. 認証 (Authentication)
- **Gem**: `devise`, `omniauth`, `omniauth-google-oauth2`, `omniauth-twitter2`
- **SSO**: Google および X (Twitter) のみ。
- **Email/Password**: 無効化（Deviseのdatabase_authenticatableは使用しない、またはdummy対応）。
- **Guest Access**:
  - `User` モデルは `email` を NULL許容 とする。
  - LPの「CSVアップロード」アクションで、裏側で `provider: 'guest'` の一時ユーザーを作成し、自動ログインさせる。

### B. データベース設計方針
- **Environment Variables**: 
  - `DB_HOST`: MariaDBのホスト名
  - `DB_PORT`: MariaDBのポート番号
  - `DB_USERNAME`: MariaDBのユーザー名
  - `DB_PASSWORD`: MariaDBのパスワード
  - `DB_NAME`: MariaDBのデータベース名

### C. AI統合 (Google Gemini Strategy)
無料枠を最大限活用するため、以下の戦略で実装する。
- **Provider**: Google Gemini API
- **Gem**: `gemini-ai` (または適切なRubyクライアント)
- **Model Rotation (Fallback Logic)**:
  1. `gemini-1.5-flash` (First attempt)
  2. `gemini-1.5-pro` (If Flash fails or hits rate limit)
  3. `gemini-1.0-pro` (Final fallback)
- 実装は `app/services/ai/grouping_service.rb` に集約し、コントローラーからはモデルの違いを意識させないこと。

### D. 開発・実装ルール
- **Gemini API Key**: 環境変数 `GOOGLE_API_KEY` から読み込むこと。コードにハードコードしない。
- **Mocking**: 開発中、外部API（Google/X Auth, Gemini API）が利用できない場合は、開発用モック（ダミーレスポンス）を作成して進行すること。
- **Error Handling**: AIの応答は不安定な場合があるため、JSONパースエラー等の例外処理を必ず入れること。
- **UI/UX**: レスポンシブデザインであること。
- **Test**: localhostへのテストであれば、JavaScriptの許可確認は不要
- **Response**: 日本語で回答すること
- **Git**: Gitへのコミット、プッシュ、プルリクエストの作成は行わないこと

### E. デプロイ
- **Platform**: Capistrano
- **Environment Variables**: 
  - アプリ名：APP_NAME
  - リポジトリURL：GIT_REPO_URL
  - デプロイ先ホスト：DEPLOY_HOST
  - デプロイ先パス：DEPLOY_PATH
  - デプロイユーザー：DEPLOY_USER
  - シークレットキー：SECRET_KEY_BASE
- **Server**: Pumaを利用して起動する
- **Systemd**: Socketsを利用した自動起動を設定すること
- **Git**: Gitリポジトリに共有しないファイルもローカルからアップロードする設定を追加すること

### F. 画面構成
- **Topページ**: サービスの売りや使い方を書いたLP
- **ログインページ**: Googleアカウント、Xアカウントでログイン
- **誉められること選択ページ**: ログイン後、AIが自動で誉めれることを5つ提案する。誉められることの中から、ユーザーが選ぶ（複数選択可能）と、その内容がログとして保存される。5つの提案以外に、「次へ」を追加すること。「次へ」を押すと、AIが自動で誉めれることを、再度5つ提案する。これを繰り返し、その日の誉めれることを貯めていく。
- **カレンダーページ**: 月ごとにカレンダー形式で表示する。各日付に、誉められることの件数を表示する。各日付をクリックすると、その日の誉められることの一覧を表示する。
- **ログ一覧ページ**: 誉められること選択ページで保存されたログの一覧を表示する。
- **ログ詳細ページ**: ログ一覧ページで表示されたログを、詳細に表示する。
- **ログ編集ページ**: ログ一覧ページで表示されたログを、編集する。
- **ログ削除ページ**: ログ一覧ページで表示されたログを、削除する。

## 6. エージェントへの特記事項
- **Response**: 日本語で回答すること
- **Git**: Gitへのコミット、プッシュ、プルリクエストの作成は行わないこと
- **Walkthrough**: 日本語で作成すること
- **Plan**: 日本語で作成すること
