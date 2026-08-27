# Internal Knowledge

## 概要

社内ナレッジを登録・検索し、RAGを利用して社内ナレッジを根拠としたAI回答を生成するWebアプリ。

## 主な機能

- Knowledgeの登録・編集・削除
- キーワード検索
- Knowledge本文のChunk分割
- OpenAI Embeddings APIによるEmbedding生成
- PostgreSQL + pgvectorによるvector search
- 自然文質問から関連Knowledgeを検索
- 関連Knowledgeを根拠にOpenAI Responses APIで回答生成
- Knowledge作成・本文更新時のChunk/Embedding同期

## RAGの処理フロー

ユーザーの質問
↓
EmbeddingGenerator
↓
OpenAI Embeddings API
↓
KnowledgeRetriever
↓
PostgreSQL / pgvector
↓
関連KnowledgeChunk取得
↓
AiAnswerGenerator
↓
OpenAI Responses API
↓
根拠付きAI回答

## 技術スタック

- Ruby 3.4.7
- Ruby on Rails 8.1.3.1
- PostgreSQL
- pgvector
- neighbor
- OpenAI Embeddings API
- OpenAI Responses API
- Puma

## 環境変数

OPENAI_API_KEY

必要に応じて:

OPENAI_MODEL
OPENAI_EMBEDDING_MODEL

## テスト

bin/rails test

現在確認済み:
98 runs, 308 assertions, 0 failures, 0 errors, 0 skips
