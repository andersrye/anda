defmodule Anda.Repo.Migrations.QuizAddSlug do
  use Ecto.Migration

  def up do

    alter table(:quiz) do
      add :slug, :citext
    end

    execute "UPDATE quiz SET slug = id"

    alter table(:quiz) do
      modify :slug, :citext, null: false
    end

    create unique_index(:quiz, [:slug])

  end

  def down do
    alter table(:quiz) do
      remove :slug
    end
  end
end
