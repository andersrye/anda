defmodule AndaWeb.AnswersLive.Index do
  use AndaWeb, :live_view
  alias Anda.Contest
  alias Anda.Submission
  alias Anda.Contest.QuizUtils

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign_new(:current_scope, fn -> nil end)}
  end

  defp get_sortable_string_at(submission, num) do
    string = get_in(submission.answers, [Access.at(num), Access.key(:answers)])

    if(!is_nil(string)) do
      string
      |> String.downcase()
      |> String.normalize(:nfkd)
    end
  end

  def sort_submissions(submissions, sort_order) do
    sorter =
      case sort_order do
        "name_asc" ->
          &(&1.name <= &2.name)

        "name_desc" ->
          &(&1.name >= &2.name)

        "question_" <> rest ->
          [num, dir] = String.split(rest, "_")
          num = String.to_integer(num) - 1
          dbg(sort_order)
          dbg(num)

          case dir do
            "asc" ->
              fn sa, sb ->
                a = get_sortable_string_at(sa, num)
                b = get_sortable_string_at(sb, num)
                IO.puts("#{a} <= #{b} = #{a <= b}")

                a <= b
              end

            "desc" ->
              fn sa, sb ->
                a = get_sortable_string_at(sa, num)
                b = get_sortable_string_at(sb, num)
                IO.puts("#{a} <= #{b} = #{a >= b}")

                a >= b
              end
          end
      end

    Enum.sort(submissions, sorter)
  end

  def transform_submissions(submissions) do
    submissions
    |> Enum.map(fn submission ->
      answers_by_question_id =
        submission.answers
        |> Enum.reduce(%{}, fn e, acc ->
          Map.put(acc, e.id, e)
        end)

      struct(submission, answers_by_question_id: answers_by_question_id)
    end)
  end

  def handle_params(%{"slug" => slug, "tag_with_mac" => tag_with_mac}, uri, socket)
      when socket.assigns.live_action == :public do
    quiz =
      Contest.get_quiz_w_questions_by_slug(slug)
      |> QuizUtils.calculate_ranks()

    {:ok, tag} = Mac.verify_added_mac(tag_with_mac)
    tag = if tag == "", do: nil, else: tag

    answers =
      Submission.get_all_submissions_with_answers(quiz.id, tag)
      #|> transform_submissions()

    sort_order = "name_asc"

    {:noreply,
     socket
     |> assign(:quiz, quiz)
     |> assign(:tags, nil)
     |> assign(:tag_with_mac, tag_with_mac)
     |> assign(:show_copy_url, nil)
     |> assign(:selected_tag, nil)
     |> assign(current_uri: uri)
     |> assign(sort_order: sort_order)
     |> assign(:answers, sort_submissions(answers, sort_order))}
  end

  @impl true
  def handle_params(%{"quiz_id" => quiz_id} = params, uri, socket)
      when socket.assigns.live_action == :private do
    quiz =
      Contest.get_quiz_w_questions(quiz_id, socket.assigns.current_scope)
      |> QuizUtils.calculate_ranks()

    tags = Submission.get_all_tags(quiz_id)
    selected_tag = Map.get(params, "tag")

    answers =
      Submission.get_all_submissions_with_answers(quiz_id, selected_tag)
      #|> transform_submissions()

    sort_order = "name_asc"

    {:noreply,
     socket
     |> assign(:quiz, quiz)
     |> assign(:tags, tags)
     |> assign(:selected_tag, selected_tag)
     |> assign(:show_copy_url, nil)
     |> assign(current_uri: uri)
     |> assign(sort_order: sort_order)
     |> assign(:answers, sort_submissions(answers, sort_order))}
  end

  @impl true
  def handle_event("change_tag", %{"tag" => tag}, socket) do
    url =
      if tag == "" do
        ~p"/admin/quiz/#{socket.assigns.quiz.id}/answers"
      else
        ~p"/admin/quiz/#{socket.assigns.quiz.id}/answers?tag=#{tag}"
      end

    {:noreply, socket |> push_patch(to: url)}
  end

  @impl true
  def handle_event("set_sort_order", %{"sort_order" => sort_order}, socket) do
    {:noreply,
     assign(socket,
       sort_order: sort_order,
       answers: sort_submissions(socket.assigns.answers, sort_order)
     )}
  end

  @impl true
  def handle_event("show_url", _, socket) do
    tag_with_mac = Mac.add_mac(socket.assigns.selected_tag || "")

    url =
      URI.parse(socket.assigns.current_uri)
      |> Map.put(:path, ~p"/quiz/#{socket.assigns.quiz.slug}/answers/#{tag_with_mac}")
      |> Map.put(:query, nil)
      |> URI.to_string()

    {:noreply, socket |> assign(show_copy_url: url)}
  end

  @impl true
  def handle_event("hide_url", _, socket) do
    {:noreply, socket |> assign(show_copy_url: nil)}
  end
end
