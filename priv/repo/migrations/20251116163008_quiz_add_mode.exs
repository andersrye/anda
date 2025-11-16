defmodule Anda.Repo.Migrations.QuizAddMode do
  use Ecto.Migration

  def change do
    alter table(:quiz) do
      add :mode, :string, null: false, default: "hidden"
    end

  end
end
