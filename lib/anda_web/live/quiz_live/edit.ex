defmodule AndaWeb.QuizLive.Edit do
  use AndaWeb, :live_view

  alias Anda.Contest
  alias Phoenix.PubSub

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    if connected?(socket) do
      PubSub.subscribe(Anda.PubSub, "quiz:#{id}:new_answer")
    end

    {:ok,
     socket
     |> assign(:page_title, "Quiz")
     |> assign(:quiz, Contest.get_quiz!(id))
     |> stream(:sections, Contest.list_sections(id))}
  end

  @impl true
  def handle_params(params, _, socket) do
    #quiz_id = Map.fetch!(params, "id")

    section_id =
      if Map.has_key?(params, "section_id") do
        params |> Map.fetch!("section_id") |> String.to_integer()
      else
        nil
      end

    {:noreply,
     socket
     |> assign(:section_id, section_id)}
  end

  @impl true
  def handle_info({AndaWeb.QuizLive.Form.SectionForm, {:saved, section}}, socket) do
    {:noreply, stream_insert(socket, :sections, section)}
  end

  @impl true
  def handle_info({AndaWeb.QuizLive.Form.QuestionForm, {:saved, _question}}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info({AndaWeb.QuizLive.Form.QuizForm, {:saved, quiz}}, socket) do
    {:noreply, assign(socket, :quiz, quiz)}
  end

  @impl true
  def handle_info({:new_answer, %{:section_id => section_id, :question_id => question_id}}, socket) do
    dbg(question_id)
    send_update(AndaWeb.QuizLive.Section, id: "sections-#{section_id}", new_answer: question_id)
    {:noreply, socket}
  end
end
