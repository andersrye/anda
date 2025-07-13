defmodule Anda.ContestFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Anda.Contest` context.
  """

  @doc """
  Generate a quiz.
  """
  def quiz_fixture(attrs \\ %{}) do
    {:ok, quiz} =
      attrs
      |> Enum.into(%{
        description: "some description",
        title: "some title"
      })
      |> Anda.Contest.create_quiz()

    quiz
  end
end
