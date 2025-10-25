defmodule Anda.Repo.Migrations.ChangeSubmissionNameColumn do
  use Ecto.Migration

  def change do
    alter table(:submissions) do
      modify :name, :citext
    end

    create unique_index(:submissions, [:name, :quiz_id], where: "name != ''")
  end
end
