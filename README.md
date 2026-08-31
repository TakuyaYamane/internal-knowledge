# Internal Knowledge

社内ナレッジを検索し、RAG（Retrieval-Augmented Generation）を利用して、
登録されたナレッジを根拠としたAI回答を生成するWebアプリケーションです。

本番環境:

https://52.193.24.8

## 概要

社内に蓄積された情報を、キーワード検索だけでなく自然言語による質問から検索できることを目的として開発しました。

ユーザーが質問すると、質問文をEmbeddingへ変換し、PostgreSQL + pgvectorによるベクトル検索で関連するナレッジを取得します。

取得した情報をコンテキストとしてOpenAI APIへ渡すことで、登録された社内ナレッジを根拠とした回答を生成します。

## 主な機能

- ナレッジの登録・編集・削除
- キーワード検索
- 自然言語によるAI質問
- Knowledge本文のChunk分割
- OpenAI Embeddings APIによるEmbedding生成
- PostgreSQL + pgvectorによるベクトル検索
- 関連KnowledgeChunkの取得
- OpenAI Responses APIによる回答生成
- Knowledge作成・本文更新時のChunk / Embedding同期
- 管理者認証
- AI質問へのレート制限

## RAGの処理フロー

```text
ユーザーの質問
        ↓
EmbeddingGenerator
        ↓
OpenAI Embeddings API
        ↓
質問Embedding
        ↓
KnowledgeRetriever
        ↓
PostgreSQL + pgvector
        ↓
関連KnowledgeChunk取得
        ↓
AiAnswerGenerator
        ↓
OpenAI Responses API
        ↓
ナレッジを根拠としたAI回答
```

質問文とKnowledgeChunkをEmbedding化し、cosine distanceを利用して関連度の高いChunkを取得しています。

取得したChunkのみをコンテキストとしてLLMへ渡すことで、社内ナレッジを根拠とした回答を生成します。

## システム構成

```text
Browser
   │
   │ HTTPS
   ▼
Nginx
   │
   │ Reverse Proxy
   ▼
Puma
   │
   ▼
Ruby on Rails
   │
   ├──────────────► OpenAI API
   │                  ├─ Embeddings API
   │                  └─ Responses API
   │
   ▼
PostgreSQL
   │
   ▼
pgvector
```

アプリケーションはAWS EC2上に構築しています。

NginxをWebサーバー / リバースプロキシとして利用し、PumaでRailsアプリケーションを実行しています。

## AWS / インフラ構成

- AWS EC2
- Ubuntu Server
- Nginx
- Puma
- PostgreSQL
- pgvector
- systemd
- Elastic IP
- HTTPS

RailsアプリケーションをEC2へデプロイし、NginxからPumaへリバースプロキシしています。

Railsアプリケーションはsystemdサービスとして管理し、サーバー上で継続して実行できる構成にしています。

## HTTPS

Let's Encrypt / Certbotを利用してHTTPS化しています。

IPアドレス向けの短期証明書を使用し、Certbotの自動更新を設定しています。

証明書更新時にはNginxを一時停止するrenewal hookを設定し、自動更新のdry-runが成功することまで確認しています。

## 認証・セキュリティ

### 管理者認証

Railsの認証機能を利用し、ナレッジを変更する操作を管理者のみに制限しています。

ログイン不要:

- AIへの質問
- ナレッジ一覧
- ナレッジ詳細

管理者ログインが必要:

- ナレッジ登録
- ナレッジ編集
- ナレッジ削除

採用担当者などの利用者がRAG機能をすぐ試せるよう、検索・AI質問機能は公開し、データを変更する操作のみ認証で保護しています。

### Rate Limit

外部APIの過剰利用を防ぐため、AI質問にレート制限を設定しています。

外部APIの過剰利用を防ぐため、AI質問にレート制限を設定しています。

同一IPからのAI質問を一定時間内の回数で制限し、通常のページ閲覧は制限対象にしていません。

### API Key

OpenAI API Keyはソースコードへ直接記述せず、環境変数から取得しています。

## 技術スタック

### Backend

- Ruby 3.4.7
- Ruby on Rails 8.1.3.1
- Puma

### Database / Vector Search

- PostgreSQL
- pgvector
- neighbor

### AI / RAG

- OpenAI Embeddings API
- OpenAI Responses API
- text-embedding-3-small

### Infrastructure

- AWS EC2
- Ubuntu
- Nginx
- systemd
- Let's Encrypt
- Certbot

## データ更新時のEmbedding同期

Knowledgeを新規作成した場合、または本文を更新した場合にChunkとEmbeddingを同期します。

```text
Knowledge作成 / 本文更新
        ↓
KnowledgeEmbeddingSync
        ↓
Chunk分割
        ↓
Embedding生成
        ↓
KnowledgeChunk保存
```

タイトルのみを変更した場合など、本文が変更されていない場合には不要なEmbedding再生成を行わないようにしています。

## 環境変数

主な環境変数:

```text
OPENAI_API_KEY
```

必要に応じて:

```text
OPENAI_MODEL
OPENAI_EMBEDDING_MODEL
```

本番環境ではDB接続情報やRailsの秘密情報についても環境変数で管理しています。

## テスト

```bash
bin/rails test
```

認証機能追加およびログイン画面改善後に全テストを実行し、

```text
110 runs
0 failures
0 errors
0 skips
```

を確認しています。

## 開発で意識した点

### 1. RAGの処理を責務ごとに分離

Embedding生成、検索、回答生成などを分離し、それぞれの責務が明確になるように実装しました。

### 2. ベクトル検索をPostgreSQLへ統合

専用のVector Databaseを別途用意するのではなく、PostgreSQL + pgvectorを利用することで、通常データとEmbeddingを同じDBで管理しています。

### 3. 公開範囲と管理機能を分離

ポートフォリオとしてRAG機能をすぐ試せることを重視し、AI質問とナレッジ閲覧は公開しています。

一方で、データを変更する操作については管理者認証を必須にしています。

### 4. 外部API利用への対策

AI質問にはレート制限を設定し、OpenAI APIの無制限な呼び出しを防止しています。

### 5. AWS上でWebサーバーを構築

EC2上にNginx、Puma、Rails、PostgreSQL、pgvectorを構築し、HTTPSを含めてアプリケーションを公開しています。
