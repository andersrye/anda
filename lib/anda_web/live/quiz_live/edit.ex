defmodule AndaWeb.QuizLive.Edit do
  use AndaWeb, :live_view

  alias Anda.Contest

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, "Quiz")
     |> assign(:quiz, Contest.get_quiz!(id))}
  end

end
