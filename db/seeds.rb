# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

portfolio_demo_knowledges = [
  {
    title: "リモートワーク制度",
    category: "社内制度",
    content: "リモートワークは週2日まで利用できます。利用する場合は原則として前営業日までに社内システムから申請してください。チームで対面ミーティングが予定されている日は出社を優先します。"
  },
  {
    title: "有給休暇の申請方法",
    category: "社内制度",
    content: "有給休暇は原則として取得希望日の3営業日前までに勤怠管理システムから申請してください。緊急の場合は直属の上長へ連絡したうえで事後申請も可能です。"
  },
  {
    title: "社内勉強会制度",
    category: "社内制度",
    content: "社内勉強会は毎週金曜日18時から開催しています。全社員が参加でき、参加希望者は社内チャットの勉強会チャンネルから申し込みます。"
  },
  {
    title: "新入社員のオンボーディング",
    category: "人事",
    content: "入社初日は会社説明、各種アカウントの発行、セキュリティ研修、開発環境のセットアップを行います。その後、担当メンターと今後の学習計画を確認します。"
  },
  {
    title: "開発環境のセットアップ",
    category: "開発",
    content: "開発環境ではRuby、Ruby on Rails、PostgreSQLを使用します。GitHubからリポジトリをcloneし、bundle install、データベース作成、Railsサーバー起動の順にセットアップします。"
  },
  {
    title: "コードレビューのルール",
    category: "開発",
    content: "mainブランチへマージする前にPull Requestを作成します。原則として1名以上のレビューとCIの成功が必要です。修正依頼がある場合は対応後に再レビューを依頼します。"
  },
  {
    title: "本番障害発生時の対応",
    category: "運用",
    content: "本番環境で障害を発見した場合は、最初に障害対応チャンネルへ報告します。発生時刻、確認した事象、影響範囲を共有し、重大な障害の場合は担当責任者へ連絡して復旧作業を優先します。"
  },
  {
    title: "経費精算のルール",
    category: "経理",
    content: "業務で発生した経費は翌月5営業日までに経費精算システムから申請します。領収書またはレシートを添付し、1万円を超える支出は事前承認が必要です。"
  },
  {
    title: "社内チャットの利用ルール",
    category: "社内ルール",
    content: "業務上の連絡には社内チャットを使用します。緊急性の低い質問は各チームのチャンネルへ投稿し、個人情報やパスワードなどの認証情報は投稿してはいけません。"
  },
  {
    title: "技術書購入支援制度",
    category: "福利厚生",
    content: "業務や技術学習に必要な書籍は会社負担で購入できます。月額5,000円までを目安とし、購入前に上長へ申請します。電子書籍も対象です。"
  }
]

portfolio_demo_knowledges.each do |attributes|
  knowledge = Knowledge.find_or_initialize_by(title: attributes[:title])
  knowledge.update!(attributes)
end

puts "#{portfolio_demo_knowledges.size} demo knowledges loaded."
