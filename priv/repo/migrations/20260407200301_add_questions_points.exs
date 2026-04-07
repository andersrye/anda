defmodule Anda.Repo.Migrations.AddQuestionsPoints do
  use Ecto.Migration

  def change do
    alter table(:questions) do
      add :points, :integer
    end
  end
end
