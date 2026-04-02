defmodule Anda.Repo.Migrations.AddQuestionsAspectRatio do
  use Ecto.Migration

  def change do
    alter table(:questions) do
      add :media_aspect_ratio, :float
    end
  end
end
