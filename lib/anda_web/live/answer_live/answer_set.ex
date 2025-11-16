defmodule AndaWeb.AnswerLive.AnswerSet do
  use Ecto.Schema

  schema "answerset" do
    embeds_many :answers, Anda.Submission.Answer
  end

end
