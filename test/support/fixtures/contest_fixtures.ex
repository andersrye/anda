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

  @doc """
  Generate a question.
  """
  def question_fixture(attrs \\ %{}) do
    {:ok, question} =
      attrs
      |> Enum.into(%{
        alternatives: "some alternatives",
        num_answers: 42,
        question: "some question"
      })
      |> Anda.Contest.create_question()

    question
  end

  @doc """
  Generate a section.
  """
  def section_fixture(attrs \\ %{}) do
    {:ok, section} =
      attrs
      |> Enum.into(%{
        description: "some description",
        title: "some title"
      })
      |> Anda.Contest.create_section()

    section
  end
end
