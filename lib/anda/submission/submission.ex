defmodule Anda.Submission.Submission do
  use Ecto.Schema
  import Ecto.Changeset

  schema "submissions" do
    field :name, :string
    field :secret, :string
    has_many :answers, Anda.Submission.Answer
    belongs_to :quiz, Anda.Contest.Quiz

    timestamps(type: :utc_datetime)
  end

  @spec changeset(
          {map(),
           %{
             optional(atom()) =>
               atom()
               | {:array | :assoc | :embed | :in | :map | :parameterized | :supertype | :try,
                  any()}
           }}
          | %{
              :__struct__ => atom() | %{:__changeset__ => any(), optional(any()) => any()},
              optional(atom()) => any()
            },
          :invalid | %{optional(:__struct__) => none(), optional(atom() | binary()) => any()}
        ) :: Ecto.Changeset.t()
  @doc false
  def changeset(section, attrs) do
    section
    |> cast(attrs, [:name, :secret, :quiz_id])
    |> validate_required([:secret, :quiz_id])
  end
end
