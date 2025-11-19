defmodule Anda.Repo.Migrations.QuizAddUser do
  use Ecto.Migration

  def change do
    alter table(:quiz) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
    end
  end
end
