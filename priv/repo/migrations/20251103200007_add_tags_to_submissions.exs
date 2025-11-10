defmodule Anda.Repo.Migrations.AddTagsToSubmissions do
  use Ecto.Migration

  def change do
    alter table(:submissions) do
      add :tags, {:array, :string}, null: false, default: []
    end
  end
end
